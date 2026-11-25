local preloadState = State("preloadState")
                                             --i hate the preload crash.
                                            --I am gonna buy a revolver with 1 bullet
                                            --keep the gun loaded on my desk, and everytime preloader crashes, im gonna spin the chamber and then shoot myself 
                                            -- after just a few preloader crashes, it wont be my problem anymore!!! 
local t = 0
local progress = 0
local step = -10
local totalSteps = 12
local installing = false
local songDifficultiesDone = false

difficultyCalculatorVersionNumber = 3

function preloadState:enter()
    self.BG = SkinHandler:getImage("Menu", "Background")
    self.wavesY = 0
    self.debug = false
    self.skipSafetyTimer = true

    States.menu.titleScreen.setUpThoseLinesThatIHate(self, 10)
    States.menu.titleScreen.setUpThoseWavesThatIHate(self, 4)
    States.menu.titleScreen.setUpThoseBubblesThatIHate(self, 20)
              
    self.images = {
        ["H"] = {image = SkinHandler:getImage("Menu", "H"), sizeX  = 1, sizeY = 1, x = 0, y = 0},
        ["logo"] = {image = SkinHandler:getImage("Menu", "Main Logo"), sizeX  = 1, sizeY = 1, x = 0, y = 0},
    }

    self.throbbert = throbbert({{1,1,1,1}, {1,1,1,1}, {1,1,1,1}})
    if not self.debug then  end
    love.timer.sleep(0.5)

    GlobalNotificationsHandler:addNotification("TEST", "error")
    GlobalNotificationsHandler:addNotification("TEST", "warning")
    GlobalNotificationsHandler:addNotification("TEST", "info")

end

function preloadState:update(dt)
    self.frame = self.frame and self.frame + 1 or 0
    if self.frame>10 and not self.fuck and not self.debug then
        self.fuck = true
        CLibs:setupIfNeeded()
        --love.timer.sleep(1)   --i ran a test here
                                -- 50 launches with the sleep(1) enabled, and 50 launches with the sleep(1) commented out
                                -- i got 4 crashes with it enabled, but when its commented out, i got 1 crash. so we leave it commented out.
                                -- i really expected the sleep here to lower the chances of the crash, but no, it made the chances higher

        love.audio.newAdvancedSource = require("engine.lib.asl.asl")
        tryExcept(function()
            if love.system.getOS() ~= "Windows" then
                return
            end
            print("Loading Steam...")
            Steam = require("engine.lib.sworks.main")
            print("Steam loaded!")
        end, function(err)
            print("Warning: Could not load Steamworks. Steam features will be disabled.")
            print("Error message: " .. err)
        end)

        if Steam then
            if not Steam.init() or not Steam.isRunning() then
                Steam = nil
                print("Steam failed to initialize!")
            else
                Steam.USER = Steam.getUser()
                Steam.USERNAME = Steam.USER:getName()
            end
        end
    end

    if self.debug then if Input:pressed("menuConfirm") then CLibs:setupIfNeeded() end end

    t = t + dt
    if step < 0 then
    if not installing then
        installing = true
        step = step + 1
    elseif installing then
        Timer.after(self.skipSafetyTimer and 0 or 5, function()
            step = step + 1
            Timer.after(0.1, function()  
            States.menu.titleScreen.bubbles = self.bubbles
            States.menu.titleScreen.wavesY = self.wavesY
            States.menu.titleScreen.squiglyLines = self.squiglyLines
            States.menu.titleScreen.layerWaves = self.layerWaves
            States.menu.titleScreen.images = self.images
            State.switch(States.menu.songPreloader)
            if AMERICA then PATRIOTIC:play() end
            end)
    
        end)
    end
 
    else step = step + 1 end 
           -- local targetProgress = math.abs(step / totalSteps)       -- i am literally fucking guessing

        --    progress = progress + (targetProgress - math.abs(progress)) * math.min(dt * 10, 1)

end
function preloadState:draw()
    
    local w, h = baseScreenRatio.x, baseScreenRatio.y
    love.graphics.setColor(1,1,1,1)
        
    love.graphics.setFont(SkinHandler:getFontLegacy("Menu Extra Large"))

    local msg = "Loading...\n:3"

    love.graphics.printf(msg, 0, h*0.5, w, "center")




    local barW = w * 0.5
    local barX = w/2 - barW/2
    local barY = h*0.6
    local segments = 200
    local amp = 15
    local speed = 5
    local points = {}

    local lastLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(15)
    love.graphics.setColor(1,1,1,0.10)
    local lastX, lastY


    points = {}
    love.graphics.setColor(1,1,1,0.85)
    lastX, lastY = nil, nil
    
    for i = 0, segments * progress do
        local x = barX + (i/segments)*barW
        local y = barY + math.sin((i/segments)*math.pi*15 + t*speed) * amp

        points[#points+1] = lastX or x
        points[#points+1] = lastY or y
        points[#points+1] = x
        points[#points+1] = y
        lastX, lastY = x, y
    end
    
    if #points > 2 then
     love.graphics.line(points)
    end

    local r = 6
    for i = 1, 6 do
        local angle = (i/6)*math.pi*2
        local pulse = math.sin(t*4 + i)*2
        local cx = w/2 + math.cos(angle)*(20 + pulse)
        local cy = h*0.7 + math.sin(angle)*(20 + pulse)
        love.graphics.setColor(1,1,1,0.2 + (pulse/4))
        love.graphics.circle("fill", cx, cy, r + pulse)
    end

    love.graphics.setColor(1,1,1,1)

    States.menu.titleScreen.drawLogo(self)
    --self.throbbert:draw()
    
end

return preloadState