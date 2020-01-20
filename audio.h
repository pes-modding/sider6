#ifndef _SIDER_AUDIO_H
#define _SIDER_AUDIO_H

#include "lua.hpp"
#include "lauxlib.h"
#include "lualib.h"

namespace Audio {
    enum State {
        created = 0,
        playing,
        paused,
        finished,
    };
}

struct sound_t;

void init_audio_lib(lua_State *L);

// C API
void audio_init();
sound_t* audio_new_sound(const char* filename, sound_t* sound);
int audio_play(sound_t* sound);
int audio_stop(sound_t* sound);

#endif
