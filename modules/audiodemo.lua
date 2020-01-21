-- examples of using sider audio library

local m = { version = "1.0" }
local content_root = ".\\content\\audio-server\\"

-- tables to keep track of active sounds
local sounds = {}
local volumes = {}

local music_is_playing
local seq
local test_sound
local test_sound2

local VKEY_3 = 0x33
local VKEY_4 = 0x34
local VKEY_5 = 0x35
local VKEY_6 = 0x36
local VKEY_7 = 0x37

local function pause_sounds()
    for _,s in pairs(sounds) do
        volumes[s] = s:get_volume()
        -- pause with 2.5 second fade-out
        s:fade_to(0, 2.5)
        s:pause()
    end
end

local function resume_sounds()
    for _,s in pairs(sounds) do
        -- resume play with 2.5 second fade-in
        s:fade_to(volumes[s], 2.5)
        s:play()
    end
end

function m.data_ready(ctx, filename)
    if string.match(filename, "%.json$") then
        log(filename)
        if filename == "common\\script\\flow\\Match\\MatchPrePause.json" then
            -- pause sounds when Pause Menu shows up
            pause_sounds()
        elseif filename == "common\\script\\flow\\Match\\MatchPostPause.json" then
            -- resume sounds, when Pause Menu exits
            resume_sounds()
        end
    end
end

function m.key_down(ctx, vkey)
    if vkey == VKEY_5 then
        if not test_sound then
            -- start playing a sound
            test_sound = audio.new(content_root .. "uefa.mp3")
            test_sound:set_volume(0.4)
            test_sound:play()
            test_sound:when_done(function(ctx)
                test_sound = nil
            end)
        else
            -- slowly fade out one sound if it is still playing
            if test_sound then
                -- 4 second fade-out
                test_sound:fade_to(0, 4)
                test_sound:finish()
            end

            -- fade in another sound
            test_sound2 = audio.new(content_root .. "sample.wav")
            test_sound2:set_volume(0)
            test_sound2:fade_to(0.6, 2.5)
            test_sound2:play()
        end

    elseif vkey == VKEY_6 then
        if test_sound then
            -- immediate finish
            test_sound:finish()
        end

    elseif vkey == VKEY_7 then
        if test_sound then
            -- 2 second fade-out finish
            test_sound:fade_to(0, 2)
            test_sound:finish()
        end

    elseif vkey == VKEY_3 then
        -- create a sequence of 3 plays
        if seq then
            log("sequence already playing")
        else
            seq = true
            log("sequence started playing")
            local s1 = audio.new(content_root .. "toggle.wav")
            s1:set_volume(1.0)
            s1:when_done(function(ctx)
                sounds["s1"] = nil
                local music = audio.new(content_root .. "uefa.mp3")
                music:set_volume(0.4)
                music:when_done(function(ctx)
                    sounds["music"] = nil
                    local s2 = audio.new(content_root .. "toggle.wav")
                    s2:set_volume(1.0)
                    s2:when_done(function(ctx)
                        sounds["s2"] = nil
                        seq = nil
                        log("sequence done playing")
                    end)
                    s2:play()
                    sounds["s2"] = s2
                end)
                music:play()
                sounds["music"] = music
            end)
            s1:play()
            sounds["s1"] = s1
        end

    elseif vkey == VKEY_4 then
        -- play/pause all sounds
        for k,v in pairs(sounds) do
            if is_playing then
                v:pause()
            else
                v:play()
            end
        end
        is_playing = not is_playing
    end
end

function m.overlay_on(ctx)
    local lines = {}
    for k,v in pairs(sounds) do
        lines[#lines + 1] = string.format("sound: %s, volume: %0.2f", v:get_filename(), v:get_volume())
    end
    return string.format("version: %s\r\n%s", m.version, table.concat(lines, "\r\n"))
end

function m.init(ctx)
    if content_root:sub(1,1) == "." then
        content_root = ctx.sider_dir .. content_root
    end
    if not audio then
        error("audio library not found. Upgrade your sider")
    end
    ctx.register("livecpk_data_ready", m.data_ready)
    ctx.register("key_down", m.key_down)
    ctx.register("overlay_on", m.overlay_on)
end

return m
