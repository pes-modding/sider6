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
        fading_in,
        fading_out,
    };
}

struct sound_t;

void init_audio_lib(lua_State *L);

void audio_init();
sound_t* audio_new_sound(const char* filename);
int audio_play(sound_t* sound);

#endif
