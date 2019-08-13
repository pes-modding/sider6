-- Set match settings for Exhibition match

local m = {}

function m.set_match_settings(ctx, options)
    if ctx.tournament_id == 65535 then
        options.difficulty = 6 -- Legend difficulty
        options.extra_time = 0 -- extra-time: off
        options.penalties = 1  -- penalties: on
        return options
    end
end

function m.init(ctx)
   ctx.register("set_match_settings", m.set_match_settings)
end

return m
