-- Module to prevent the game from connecting to network

local strings = {
    "pes20-x64-gate.cs.konami.net",
}

local m = {}

function m.init(ctx)
    local replacer = ""
    for _,s in ipairs(strings) do
        addr, info = memory.search_process(s .. "\x00")
        if not addr then
            log(string.format('warning: unable to find string: "%s" in memory', s))
        else
            log(string.format('string "%s" found at %s. Replacing with "%s"', s, memory.hex(addr), replacer))
            memory.write(addr, replacer .."\x00")
        end
    end
end

return m
