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

#define DBG(n) if (_config->_debug & n)

struct sound_t {
    const char *filename;
    ma_device* pDevice;
    ma_decoder* pDecoder;
    int state;
    void* extra;
};

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
                ma_device_uninit(p->pDevice);
                ma_decoder_uninit(p->pDecoder);
                free(p->pDevice);
                free(p->pDecoder);
                p->pDevice = NULL;
                p->pDecoder = NULL;
                free(p);
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
    return sound;
}

int audio_play(sound_t* sound) {
    if (!sound || !sound->pDevice) {
        return -1;
    }
    logu_("playing: %s\n", sound->filename);
    _sound_tracker->add(sound);
    if (ma_device_start(sound->pDevice) != MA_SUCCESS) {
        sound->state = Audio::finished;
        return -2;
    }
    return 0;
}

static int audio_new(lua_State *L)
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
    lua_newtable(L);
    return 1;
}

void init_audio_lib(lua_State *L)
{
    lua_newtable(L);
    lua_pushstring(L, "new");
    lua_pushcclosure(L, audio_new, 0);
    lua_settable(L, -3);
}

