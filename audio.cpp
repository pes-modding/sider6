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
int _audio_callbacks_index = 0;

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

sound_t* audio_new_sound(const char *filename, sound_t *sound)
{
    ma_result result;
    ma_decoder* pDecoder;
    ma_device* pDevice;
    ma_device_config deviceConfig;

    pDevice = (ma_device*)malloc(sizeof(ma_device));
    pDecoder = (ma_decoder*)malloc(sizeof(ma_decoder));
    if (sound == NULL) {
        sound = (sound_t*)malloc(sizeof(sound_t));
    }

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
    logu_("sound->pDecoder = %p\n", sound->pDecoder);
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

static sound_t* checksound(lua_State *L) {
    void *ud = luaL_checkudata(L, 1, "Sider.sound");
    luaL_argcheck(L, ud != NULL, 1, "'sound' expected");
    return (sound_t*)ud;
}

static int audio_lua_play(lua_State *L)
{
    sound_t* sound = checksound(L);
    audio_play(sound);
    lua_pop(L, lua_gettop(L));
    return 0;
}

static int audio_lua_stop(lua_State *L)
{
    sound_t* sound = checksound(L);
    audio_stop(sound);
    lua_pop(L, lua_gettop(L));
    return 0;
}

static int audio_lua_set_volume(lua_State *L)
{
    sound_t* sound = checksound(L);
    double volume = luaL_checknumber(L, 2);
    if (volume < 0.0) {
        volume = 0.0;
    }
    if (volume > 1.0) {
        volume = 1.0;
    }
    if (sound->pDevice) {
        ma_device_set_master_volume(sound->pDevice, volume);
    }
    lua_pop(L, lua_gettop(L));
    return 0;
}

static int audio_lua_get_volume(lua_State *L)
{
    sound_t* sound = checksound(L);
    lua_pop(L, lua_gettop(L));
    float volume = 0.0f;
    if (sound->pDevice) {
        ma_device_get_master_volume(sound->pDevice, &volume);
    }
    lua_pushnumber(L, volume);
    return 1;
}

static int audio_lua_get_filename(lua_State *L)
{
    sound_t* sound = checksound(L);
    lua_pop(L, lua_gettop(L));
    lua_pushstring(L, sound->filename);
    return 1;
}

static int audio_lua_when_done(lua_State *L)
{
    sound_t* sound = checksound(L);
    if (!sound || !sound->pDevice) {
        lua_pop(L, lua_gettop(L));
        luaL_error(L, "sound object does not exist");
    }

    if (!lua_isfunction(L, 2)) {
        lua_pop(L, lua_gettop(L));
        luaL_error(L, "expecting a function");
    }

    lua_pushvalue(L, 1);
    lua_pushvalue(L, 2);
    lua_xmove(L, _audio_L, 2); // key/value pair: userdata --> callback function
    lua_settable(_audio_L, _audio_callbacks_index);

    lua_pushvalue(L, 2);
    lua_xmove(L, _audio_L, 1); // store a copy in the stack too

    extra_info_t* info = (extra_info_t*)malloc(sizeof(extra_info_t));
    info->L = L;
    info->callback_index = lua_gettop(_audio_L);
    logu_("info->callback_index = %d\n", info->callback_index);

    sound->extra = info;
    lua_pop(L, lua_gettop(L));
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

    sound_t* sound = (sound_t*)lua_newuserdata(L, sizeof(sound_t));
    sound = audio_new_sound(filename, sound);
    if (!sound) {
        lua_pushnil(L);
        lua_pushfstring(L, "unable to create new sound object for: %s", filename);
        return 2;
    }

    luaL_getmetatable(L, "Sider.sound");
    lua_setmetatable(L, -2);

    // 2nd return value: no error
    lua_pushnil(L);
    return 2;
}

static const struct luaL_Reg audiolib_f [] = {
    {"new", audio_lua_new},
    {NULL, NULL}
};

static const struct luaL_Reg audiolib_m [] = {
    {"play", audio_lua_play},
    {"stop", audio_lua_stop},
    {"set_volume", audio_lua_set_volume},
    {"get_volume", audio_lua_get_volume},
    {"get_filename", audio_lua_get_filename},
    {"when_done", audio_lua_when_done},
    {NULL, NULL}
};

void init_audio_lib(lua_State *L)
{
    // keep new state anchored.
    // we will keep callbacks on its stack
    _audio_L = lua_newthread(L);
    lua_newtable(_audio_L);
    _audio_callbacks_index = lua_gettop(_audio_L);

    luaL_newmetatable(L, "Sider.sound");

    lua_pushstring(L, "__index");
    lua_pushvalue(L, -2);  /* pushes the metatable */
    lua_settable(L, -3);  /* metatable.__index = metatable */

    luaL_openlib(L, NULL, audiolib_m, 0);

    luaL_openlib(L, "array", audiolib_f, 0);
}
