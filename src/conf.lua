require("love.window")

local w, h = love.window.getDesktopDimensions()
local targetAspectRatio = 16 / 9
local targetW, targetH = w * 0.8, h * 0.8
if (w / h) > targetAspectRatio then
    targetW = targetH * targetAspectRatio
else
    targetH = targetW / targetAspectRatio
end

HarmoniVersion = "R-0.2.0"

---@diagnostic disable-next-line: duplicate-set-field
function love.conf(t)
    local debug = true
    t.console = true
    t.window.title = "Harmoni V." .. HarmoniVersion
    t.identity = "Harmoni"  
    t.window.width =  targetW      -- why did you even put "Rewrite" in it even ?? Just keep it as Harmoni brah
    t.window.height = targetH      -- its changed now
    t.window.resizable = true
    t.highdpi = true
    t.window.msaa = 8
    t.window.vsync = 0

    t.modules.physics = false

    if debug then 
        t.window.title = "Harmoni V." .. HarmoniVersion .. " |  LOVE Version " .. (love.getVersion() or "UNKNOWN (how is this possible?")
                                                                                            -- I made this conf.lua when love12 didn't have a codename
                                                                                            -- idk how it ended up like this though? idk
    end


    t.window.icon = "images/icon.png"

    t.version = "12.0"
end
