#define UNICODE

#define DR_FLAC_IMPLEMENTATION
#include "extras/dr_flac.h"  /* Enables FLAC decoding. */
#define DR_MP3_IMPLEMENTATION
#include "extras/dr_mp3.h"   /* Enables MP3 decoding. */
#define DR_WAV_IMPLEMENTATION
#include "extras/dr_wav.h"   /* Enables WAV decoding. */

#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include "audio.h"
#include "common.h"
#include "config.h"
#include "sider.h"

#include <deque>

extern config_t*_config;
extern void module_call_callback_with_context(lua_State *L, lua_State *from_L, int callback_index);

#define DBG(n) if (_config->_debug & n)

struct sound_t {
    const char *filename;
    ma_device* pDevice;
    ma_decoder* pDecoder;
    int state;
    void* extra;
};

struct extra_info_t {
    lua_State *L;
    int callback_index;
};

lua_State *_audio_L;

class sound_tracker_t {
    std::deque<sound_t*> _dq;
    CRITICAL_SECTION _cs;
public:
    sound_tracker_t() {
        InitializeCriticalSection(&_cs);
    }
    ~sound_tracker_t() {
        DeleteCriticalSection(&_cs);
    }
    void add(sound_t* p) {
        lock_t lock(&_cs);
        _dq.push_back(p);
        logu_("added sound object %p\n", p);
    }
    void check() {
        size_t sz;
        {
            lock_t lock(&_cs);
            sz = _dq.size();
        }
        DBG(8192) logu_("checking sound objects (%d)\n", sz);
        for (int i=0; i<sz; i++) {
            lock_t lock(&_cs);
            std::deque<sound_t*>::iterator it = _dq.begin();
            sound_t *p = *it;
            _dq.pop_front();
            if (p->state == Audio::finished) {
                // signalled: remove and destroy
                logu_("sound object %p is done\n", p);
                // check if there is a callback then call it
                if (p->extra) {
                    extra_info_t* info = (extra_info_t*)p->extra;
                    if ((info->L) && (info->callback_index > 0)) {
                        module_call_callback_with_context(info->L, _audio_L, info->callback_index);
                    }
                }
                if (p->pDevice) {
                    ma_device_uninit(p->pDevice);
                    free(p->pDevice);
                    p->pDevice = NULL;
                }
                if (p->pDecoder) {
                    ma_decoder_uninit(p->pDecoder);
                    free(p->pDecoder);
                    p->pDecoder = NULL;
                }
                //free(p);
            }
            else {
                // re-enqueue
                _dq.push_back(p);
                DBG(8192) logu_("sound object %p is not done yet\n", p);
            }
        }
    }
};

static sound_tracker_t* _sound_tracker(NULL);
static HANDLE _sound_manager_handle(INVALID_HANDLE_VALUE);

static DWORD sound_manager_thread(LPVOID param)
{
    bool done(false);
    sound_tracker_t* tracker = (sound_tracker_t*)param;
    logu_("sound-manager thread started\n");
    while (!done) {
        tracker->check();
        Sleep(1000);
    }
    logu_("sound-manager thread finished\n");
    return 0;
}

static void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount)
{
    sound_t* p = (sound_t*)pDevice->pUserData;
    if (!p || p->pDecoder == NULL) {
        logu_("warning: pDevice=%p, pDecoder=%p\n", pDevice, p->pDecoder);
        return;
    }

    ma_uint64 n = ma_decoder_read_pcm_frames(p->pDecoder, pOutput, frameCount);
    //logu_("read %llu frames\n", n);

    if (n == 0 && p->state != Audio::finished) {
        logu_("signaling finish event for sound object %p\n", p);
        p->state = Audio::finished;
    }

    (void)pInput;
}

void audio_init()
{
    if (_sound_tracker == NULL) {
        _sound_tracker = new sound_tracker_t();
        DWORD thread_id;
        _sound_manager_handle = CreateThread(NULL, 0, sound_manager_thread, _sound_tracker, 0, &thread_id);
        SetThreadPriority(_sound_manager_handle, THREAD_PRIORITY_LOWEST);
    }
}

sound_t* audio_new_sound(const char *filename)
{
    ma_result result;
    ma_decoder* pDecoder;
    ma_device* pDevice;
    ma_device_config deviceConfig;
    sound_t* sound;

    pDevice = (ma_device*)malloc(sizeof(ma_device));
    pDecoder = (ma_decoder*)malloc(sizeof(ma_decoder));
    sound = (sound_t*)malloc(sizeof(sound_t));

    result = ma_decoder_init_file(filename, NULL, pDecoder);
    if (result != MA_SUCCESS) {
        logu_("ma_decoder_init_file failed\n");
        free(sound);
        return NULL;
    }

    deviceConfig = ma_device_config_init(ma_device_type_playback);
    deviceConfig.playback.format   = pDecoder->outputFormat;
    deviceConfig.playback.channels = pDecoder->outputChannels;
    deviceConfig.sampleRate        = pDecoder->outputSampleRate;
    deviceConfig.dataCallback      = data_callback;
    deviceConfig.pUserData         = sound;

    if (ma_device_init(NULL, &deviceConfig, pDevice) != MA_SUCCESS) {
        logu_("Failed to open playback device.\n");
        ma_decoder_uninit(pDecoder);
        free(pDecoder);
        free(sound);
        return NULL;
    }

    sound->filename = strdup(filename);
    sound->pDecoder = pDecoder;
    sound->pDevice = pDevice;
    sound->state = Audio::created;
    sound->extra = NULL;
    return sound;
}

int audio_play(sound_t* sound) {
    if (!sound || !sound->pDevice) {
        return -1;
    }
    switch (sound->state) {
        case Audio::created:
            _sound_tracker->add(sound);
        case Audio::paused:
            if (ma_device_start(sound->pDevice) != MA_SUCCESS) {
                sound->state = Audio::finished;
                return -2;
            }
            break;
        case Audio::finished:
            return 0;
    }
    sound->state = Audio::playing;
    logu_("playing: %s\n", sound->filename);
    return 0;
}

int audio_stop(sound_t* sound) {
    if (!sound || !sound->pDevice) {
        return -1;
    }
    switch (sound->state) {
        case Audio::playing:
            if (ma_device_stop(sound->pDevice) != MA_SUCCESS) {
                sound->state = Audio::finished;
                return -2;
            }
            break;
        case Audio::finished:
            return 0;
    }
    sound->state = Audio::paused;
    logu_("paused: %s\n", sound->filename);
    return 0;
}

static int audio_lua_play(lua_State *L)
{
    sound_t* sound = (sound_t*)lua_topointer(L, lua_upvalueindex(1));
    if (!sound) {
        luaL_error(L, "sound object does not exist");
    }
    audio_play(sound);
    return 0;
}

static int audio_lua_stop(lua_State *L)
{
    sound_t* sound = (sound_t*)lua_topointer(L, lua_upvalueindex(1));
    if (!sound) {
        luaL_error(L, "sound object does not exist");
    }
    audio_stop(sound);
    return 0;
}

static int audio_lua_set_volume(lua_State *L)
{
    sound_t* sound = (sound_t*)lua_topointer(L, lua_upvalueindex(1));
    if (!sound || !sound->pDevice) {
        lua_pop(L, 1);
        luaL_error(L, "sound object does not exist");
    }
    double volume = luaL_checknumber(L, 1);
    lua_pop(L, 1);
    if (volume < 0.0) {
        volume = 0.0;
    }
    if (volume > 1.0) {
        volume = 1.0;
    }
    ma_device_set_master_volume(sound->pDevice, volume);
    return 0;
}

static int audio_lua_when_done(lua_State *L)
{
    sound_t* sound = (sound_t*)lua_topointer(L, lua_upvalueindex(1));
    if (!sound || !sound->pDevice) {
        lua_pop(L, 1);
        luaL_error(L, "sound object does not exist");
    }
    if (!lua_isfunction(L, 1)) {
        lua_pop(L, 1);
        luaL_error(L, "first parameter must be a function");
    }

    lua_pushvalue(L, lua_upvalueindex(2)); // table
    lua_pushvalue(L, -2); // callback function
    lua_setfield(L, -2, "_callback");
    lua_pop(L, 1);

    lua_pushvalue(L, -1);
    lua_xmove(L, _audio_L, 1);

    extra_info_t* info = (extra_info_t*)malloc(sizeof(extra_info_t));
    info->L = L;
    info->callback_index = lua_gettop(_audio_L);
    logu_("info->callback_index = %d\n", info->callback_index);

    sound->extra = info;
    lua_pop(L, 1);
    return 0;
}

static int audio_lua_new(lua_State *L)
{
    size_t len = 0;
    const char *filename = luaL_checklstring(L, 1, &len);
    if (!filename || len == 0) {
        lua_pop(L, 1);
        lua_pushnil(L);
        lua_pushstring(L, "filename cannot be empty");
        return 2;
    }
    lua_pop(L, 1);

    sound_t* sound = audio_new_sound(filename);
    if (!sound) {
        lua_pushnil(L);
        lua_pushfstring(L, "unable to create new sound object for: %s", filename);
        return 2;
    }

    lua_newtable(L);
    lua_pushlightuserdata(L, sound);
    lua_pushcclosure(L, audio_lua_play, 1);
    lua_setfield(L, -2, "play");
    lua_pushlightuserdata(L, sound);
    lua_pushcclosure(L, audio_lua_set_volume, 1);
    lua_setfield(L, -2, "set_volume");
    lua_pushlightuserdata(L, sound);
    lua_pushvalue(L, -2); // new table
    lua_pushcclosure(L, audio_lua_when_done, 2);
    lua_setfield(L, -2, "when_done");
    lua_pushlightuserdata(L, sound);
    lua_pushcclosure(L, audio_lua_stop, 1);
    lua_setfield(L, -2, "stop");
    // 2nd return value: no error
    lua_pushnil(L);
    return 2;
}

void init_audio_lib(lua_State *L)
{
    _audio_L = luaL_newstate();
    //lua_pushvalue(L, -2);
    //lua_remove(L, -3);

    lua_newtable(L);
    lua_pushstring(L, "new");
    lua_pushcclosure(L, audio_lua_new, 0);
    lua_settable(L, -3);
}

