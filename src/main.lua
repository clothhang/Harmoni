require("love.init")
--require("modules.things")

-- i can NOT work on this game anywhere people can see my laptop cuz these fucking weird 
-- ass backgrounds FUCK YOU QUAVER AND OSU MAPPERS WHAT IS WRONG WITH YOU FUCKING PEOPLE
dontShowBG = false

aprilFools = false
AMERICA = false

spongebirth = love.graphics.newImage("images/spongebirth.png")

IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

---@diagnostic disable-next-line: duplicate-set-field
	function love.errorhandler(msg)
		error(msg, 2)
	end
end

-- TODO: Update deprecations to the new stuff
love.setDeprecationOutput(false)

function ithink(nums, whatDoYouThink)
    if type(nums) ~= "table" then return "i think you messed up the function call" end
    local count = 0
    for i = 1,#nums do
        if type(nums[i]) == "number" then
            count = count + nums[i]
        end
    end
    -- is the count within like 3 of the thinknumber? 
    return (math.abs(count - whatDoYouThink) <3 and "yeah i think so") or "nah probably not"
end

function love.graphics.bullshit(x,y,size)
    love.graphics.rectangle("fill", x, y, size, 0, x-(size/2), y-(size/2))
end

if love.system.getOS() == "OS X" then -- disable jit on arm osx becaus e it performs like dookie rn
    if jit.arch == "arm64" or jit.arch == "arm" then
        jit.off()
    end
end

function love.load(args)
    Settings = require("modules.game.Settings")
    Settings.default = Settings:defaultSettings()
    Settings:loadSettings()

    GPUInfo = {test = "HI"}
    love.graphics.setDefaultFilter("linear","linear")
    require("modules.extraFunctions")
    love.filesystem.createDirectory("Music")
    love.filesystem.createDirectory("Settings")

    SkinHandler = require("modules.game.skinHandler")
    SDL2 = require("engine.modules.SDL2")
    LocaleHandler = require("modules.game.localeHandler")
    local preferredLocales
    if SDL2 then
        --preferredLocales = SDL2.getPreferredLocales()
        preferredLocales = { { language = "en", country = "US" } }
    else
        preferredLocales = { { language = "en", country = "US" } }
    end
    local mostPreferred = preferredLocales[1] or {language = "en", country = "US"}
    if mostPreferred.language == "en" and mostPreferred.country ~= "US" then mostPreferred.country = "US" end
    print("Most preferred locale: " .. mostPreferred.language .. "-" .. mostPreferred.country)
    LocaleHandler:loadLocale(mostPreferred.language .. "-" .. mostPreferred.country .. ".lua")
    CLibs = require("modules.game.handleCLibs")
    Settings:addSkinsToSettings(SkinHandler:getAllSkins())

    --SongScript = require("scripting.songScript")

    if AMERICA then LocaleHandler:loadLocale("AMERICAN!!!.lua") end

    if AMERICA then PATRIOTIC = love.audio.newSource("Skins/AMERICA/stars and stripes forever.mp3", "stream"); PATRIOTIC:setLooping(true) end

    CHE = require("engine.CHE")
    CHE:init()
    _G.GlobalNotificationsHandler = notificationsHandler()

    VolumeControl = volumeControl()

    require("modules.gamemodes")

    require("bob")  -- bob 💖
    -- bob will not be added

    maniaChartDifficultyCalculator = require("modules.gamemodes.mania.maniaChartDifficultyCalculator")
    ChartParse = require("modules.game.chartParse")
    MusicTimeManager = require("modules.game.musicTimeManager")
    ScoreHandler = require("modules.game.scoreHandler")
    SongListManager = require("modules.game.songListManager")
    CaptionParser = require("modules.game.captionParser")
    Point = require("modules.math.Point")
    -- seems to be the best place to load these so,,, we load modifiers in main lol 
    modifiersTable = require("modules.game.data.modifiers")

    spookyGlitchShader = love.graphics.newShader("shaders/spookyglitch.glsl")

    SongScript = require("modules.Modscript.ModscriptManager")

    if aprilFools then require("aprilfools") end -- fucking awesome

    State.switch(States.menu.preloadState)

    -- load objects
    throbbert = throbbert(SkinHandler:getRandomColors())
end

if AMERICA then murica = love.graphics.newShader("shaders/murica.glsl") end
local t = 0

function love.update(dt)
    GIF:resetGifs()
    CHE:update(dt)
    throbbert:update(dt)
    _G.GlobalNotificationsHandler:update(dt)
    VolumeControl:update(dt)
    t = t + dt
    if murica then
        murica:send("time", t)
    end
end

function love.mousepressed(x, y, b)
    CHE:mousepressed(x, y, b)
end

function love.mousemoved(x, y, dx, dy)
    cursor.dx, cursor.dy = toCanvasCoords(dx, dy)
    CHE:mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, b)
    CHE:mousereleased(x, y, b)
end

function love.keypressed(key, scancode, isrepeat)
    CHE:keypressed(key, scancode, isrepeat)
end

function love.textinput(text)
    CHE:textinput(text)
end

function love.wheelmoved(x,y)
    State.scroll(y)
    VolumeControl:wheelmoved(y)
end

function love.resize(w, h)
    State.resize(w, h)
end

function love.focus(f)
    Input:_sendFocusToAsyncInput(f)
end

--if you wanna edit this, go to engine/CHE.lua and edit the CHE:draw() function to keep drawing in a letterboxed environment
function love.draw(dt)
    love.graphics.draw(spongebirth, 0, 0, 0, 0.5, 0.5)

    CHE:draw(dt)
    love.graphics.setShader()
    if not Settings:getValue("Debug"," ", "disable notifications") then     GlobalNotificationsHandler:draw() end
end

function love.quit()
    CHE:exit()
    Settings:writeSettings()

    if State.current() == States.menu.titleScreen then
        if not States.menu.titleScreen.quitInProgress and not AMERICA then
            States.menu.titleScreen.quitInProgress = true
            States.menu.titleScreen:raiseWaves()
            States.menu.titleScreen:fadeScreen()
            Timer.after(0.8, function() love.event.quit() end)
            return true
        elseif AMERICA then
            if not AMERICA then
                return false
            else
                if States.extra.america.finishedAnthem then
                    return false
                else
                    State.switch(States.extra.america)
                    return true
                end
            end
        else
            return false
        end
    else
        if not AMERICA then
            return false
        else
            if States.extra.america.finishedAnthem then
                return false
            else
                return true
            end
        end
    end
end
