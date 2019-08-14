-- Set match settings for Exhibition match

local m = {}

-- difficulty: nil - game choice, 0 - beginner, 1 - amateur, ... 6 - Legend
m.difficulty = 6

-- extra time: nil - game choice, 0 - off, 1 - on
m.extra_time = 0

-- penalty shootout: nil - game choice, 0 - off, 1 - on
m.penalties = 1

function m.set_match_settings(ctx, options)
    if ctx.tournament_id == 65535 then
        options.difficulty = m.difficulty
        options.extra_time = m.extra_time
        options.penalties = m.penalties
        return options
    end
end

function m.init(ctx)
    ctx.register("set_match_settings", m.set_match_settings)
end

return m
