local titleScreen = State("titleScreen")
local fade = 0
local screenFade = {0}

local btnStrEasterEgg = "X"
function titleScreen:enter(from, resetItems, fadeIn)
    fade = 0
    self.bubbleClickedCount = 0
    self.coverAlpha = (fadeIn and 1) or 0
    if resetItems == nil then resetItems = true end
    self.BG = SkinHandler:getRandomBG()
    if resetItems then self.wavesY = 0 end
    if not self.wavesY then
        self.wavesY = 0
    end

    self.icons = {
        ["play"] = love.graphics.newImage("images/menu/play.png"),
        ["jukebox"] = love.graphics.newImage("images/menu/jukebox.png"),
        ["settings"] = love.graphics.newImage("images/menu/settings.png"),
        ["exit"] = love.graphics.newImage("images/menu/exit.png")
    }


   -- self.moth = love.graphics.newImage("images/moth.png")

    self.noteImage = love.graphics.newImage("images/menu/note.png")

    self.buttonWidth = 350
    self.buttonHeight = 120
    self.buttonX = 300 - self.buttonWidth / 2 
    self.buttonLabels = {
        {
            label = LocaleHandler:getText("Menu", "Play"), 
            func = function() 
                self:raiseWaves()
                State.transition("waveDissolve", States.menu.songSelect) 
            end,
            color1 = {94/255,252/255,141/255,1},
            color2 = {44/255,251/255,106/255,0},
            icon = self.icons["play"],
            animate = "fill",
        },
        {
            label = LocaleHandler:getText("Menu", "Jukebox"), 
            --func = function() State.switch(States.aprilfools.tutorialState, "aprilfools/tutorials/fishsave.lua") end,
            func = function() State.transition("waveDissolve", States.menu.jukebox) end, 

            color1 = {142/255,249/255,243/255,1},
            color2 = {88/255,246/255,238/255,1},
            icon = self.icons["jukebox"]

        },
        {
            label = LocaleHandler:getText("Menu", "Settings"), 
            func = function() State.transition("waveDissolve", States.menu.settingsMenu) end, 
            color1 = {147/255,190/255,223/255,1},
            color2 = {106/255,165/255,210/255,1},
            icon = self.icons["settings"]

        },
        {
            label = LocaleHandler:getText("Menu", "Exit"), 
            func = function() 
                self.window = window(self, LocaleHandler:getText("UI", "Exit Title"), LocaleHandler:getText("UI", "Exit Confirm"),
                    {
                        {
                            text = LocaleHandler:getText("UI", "Exit"),
                            func = function() self.window.msg = LocaleHandler:getText("UI", "Exited"); love.quit() end  -- changing the window text like that is such a hack but it works lol
                        },
                        {
                            text = LocaleHandler:getText("UI", "Cancel"),
                            func = function() self.window:killYourself() end
                        }
                    }
                )
            end, 
            color1 = {1,1,1,1}, 
            color2 = {1,1,1,1},
            icon = self.icons["exit"]

        },
    }

    if resetItems then
        self.images = {
            ["H"] = {image = SkinHandler:getImage("Menu", "H"), sizeX  = 1, sizeY = 1, x = 0, y = 0},
            ["logo"] = {image = SkinHandler:getImage("Menu", "Main Logo"), sizeX  = 1, sizeY = 1, x = 0, y = 0},
        }
    end

   -- module.showNotification(title, text, timeout_ms, opts)
    if NOTIFICATIONS then NOTIFICATIONS.showNotification("HI", "HELLO", 1000) end

    self.socialsX = baseScreenRatio.x - (5*120)
    self.socialsY = baseScreenRatio.y - 120

    self.socialButtons = {}
    self.clickedXCount = 0
    self.socials = {
        {
            label = "YouTube",
            link = "https://www.youtube.com/@Harmoni-de7zk",
            images = {love.graphics.newImage("images/menu/YouTube.png")},
            colors = {{1,0,51/255}},
            scales = {{scaleLARGE = 1.2, scaleSMALL = 1}},
            func = function(button)
                self.clickedXCount = 0

                self.window = window(self, LocaleHandler:getText("UI", "Leaving Harmoni"), LocaleHandler:getText("UI", "Take To YouTube")  .. "\n\n" .. button.link,
                    {
                        {
                            text = LocaleHandler:getText("UI", "Ok"),
                            func = function() love.system.openURL(button.link);self.window:killYourself() end
                        },
                        {
                            text = LocaleHandler:getText("UI", "Cancel"),
                            func = function() self.window:killYourself() end
                        }
                    }
                )
            end
        },
        {
            label = "Discord",
            link = "https://discord.gg/E2xc2YjADs",  -- TEMP!! the real link will be on a website and the game will open the website, which redirects to the invite
                                                     -- (so if the invite breaks it wont stop working for people who arent updated)
            images = {love.graphics.newImage("images/menu/Discord.png")},
            colors = {{88/255,101/255,242/255}},
            scales = {{scaleLARGE = 1.2, scaleSMALL = 1}},
            func = function(button)
                self.clickedXCount = 0
                self.window = window(self, LocaleHandler:getText("UI", "Leaving Harmoni"), LocaleHandler:getText("UI", "Take To Discord")  .. "\n\n" .. button.link,
                    {
                        {
                            text = LocaleHandler:getText("UI", "Ok"),
                            func = function() love.system.openURL(button.link);self.window:killYourself() end
                        },
                        {
                            text = LocaleHandler:getText("UI", "Cancel"),
                            func = function() self.window:killYourself() end
                        }
                    }
                )
            end
        },
        
        {
            label = "GitHub",
            link = "https://github.com/clothhang/Harmoni",
            images = {love.graphics.newImage("images/menu/GitHub.png")},
            colors = {{14/255,16/255,18/255}},
            scales = {{scaleLARGE = 1.2, scaleSMALL = 1}},
            func = function(button)
                self.clickedXCount = 0
                self.window = window(self, LocaleHandler:getText("UI", "Leaving Harmoni"), LocaleHandler:getText("UI", "Take To GitHub") .. "\n\n" .. button.link,
                    {
                        {
                            text = LocaleHandler:getText("UI", "Ok"),
                            func = function() love.system.openURL(button.link);self.window:killYourself() end
                        },
                        {
                            text = LocaleHandler:getText("UI", "Cancel"),
                            func = function() self.window:killYourself() end
                        }
                    }
                )
            end
        },
        { -- i find it fucking crazy you're making it a fucking bluesky link
            label = "Bluesky",    -- fuck you Elon
            link = "https://bsky.app/profile/ch-1.bsky.social",  -- TEMP!!!
            images = {love.graphics.newImage("images/menu/Bluesky.png")},
            colors = {{0,133/255,1}},
            scales = {{scaleLARGE = 1.2, scaleSMALL = 1}},
            func = function(button)
            self.clickedXCount = self.clickedXCount + 1
                self.window = window(self, LocaleHandler:getText("UI", "Leaving Harmoni"), LocaleHandler:getText("UI", "Take To Bluesky") .. 
                    "\n\n" .. button.link,
                    {
                        {
                            text = LocaleHandler:getText("UI", "Ok"),
                            func = function() love.system.openURL(button.link);self.window:killYourself() end
                        },
                        {
                            text = LocaleHandler:getText("UI", "Cancel"),
                            func = function() self.window:killYourself() end
                        }
                    }
                ) 
            end
        },z
    }

    self:setupSocialButtons()
    buttonSpacing = 10
    self.buttons = {}

    for i = 1,#self.buttonLabels do
        table.insert(self.buttons,
            buttonSlideOut(self.buttonX, 770 + (i-1) * (self.buttonHeight + buttonSpacing), 
                            self.buttonWidth, self.buttonHeight, self.buttonLabels[i].label, self.buttonLabels[i].func, 7, 
                            self.buttonLabels[i].color1, self.buttonLabels[i].color2, self.buttonLabels[i].icon, self.buttonLabels[i].animate
            )
        )
    end

    if resetItems then
        print("HI")
        self:setUpThoseLinesThatIHate(10)
        self:setUpThoseWavesThatIHate(4)
        self:setUpThoseBubblesThatIHate(20)
        self:setUpThoseSqauresThatIHate()
    end
    self.thoseWeirdGrowingCirclesThatIHate = growingCircleObjectThingyIdfk()

    if self.coverAlpha > 0 then
        self:fadeIn(function()
            if AchievementHandler then AchievementHandler:unlock("title screen") end
        end)
    end


end

function titleScreen:setupSocialButtons()
    self.socialButtons = {}
        for i, Social in ipairs(self.socials) do
        local width, height = 100,100
        local spacing = 10

        local x = self.socialsX + ((width+spacing)*i)
        local y = self.socialsY
        -- testing out doing arguments like this
        table.insert(self.socialButtons,
            socialButton({
                x = x, y = y, hasImage = true, link = Social.link,
                parts = Social.images, text = Social.label, func = Social.func, width = 100,
                height = 100, scales = Social.scales, colors = Social.colors
            })
        )
    end

end

function titleScreen:fuckElon()   -- the fuckElon function can stay just because i REALLY hate him 
    self.socials[4].image = self.socials[4].image2
    btnStrEasterEgg = "Twitter"
    self.socials[4].label = "Twitter"
    self.socials[4].link = "https://twitter.com/clothinghanger_"  -- knowing how dumb X is they might end up making this link not work 
    self.socials[4].color = {29/255, 161/255, 242/255}
    
    self:setupSocialButtons()
    self.socialButtons[4].x = self.socialButtons[4].x+20
end

function titleScreen:fadeIn(callback)
    Timer.tween(0.25, self, {coverAlpha = 0}, "linear", callback)
end

function titleScreen:setUpThoseBubblesThatIHate(numberOfBubbles)
    self.bubbles = {}
    
    if Settings:getValue("Menu", "Title Screen", "Enable Bubbles") then
        transparency = 0.1
        local colors = SkinHandler:getRandomColors()

        local allArrows = love.math.random(1,1000) == 1 -- had to chance this cuz i used my own chance function comletely incorrectly by accident

        for i = 1,numberOfBubbles do 
            ::start::
            local x,y = love.math.random(0, baseScreenRatio.x), love.math.random(baseScreenRatio.y, 0)

            local color = colors[love.math.random(1,#colors)]
            table.insert(self.bubbles, UISquigleCircle("fill", x, y, love.math.random(90,130), 5, 5, 3, color))
        end

        for i, Bubble in ipairs(self.bubbles) do
            Bubble.type = "Spinner"
            if chance(10) then
                Bubble.type = "Squisher"
            end
            if chance(10) then
                Bubble.isNote = true   -- we do it like this instead of setting the type to note so we can have squisher notes (these are super rare so thats cool)
            end
            if allArrows then Bubble.isNote = true end
        end

        table.insert(self.bubbles, UISquigleCircle("fill", love.math.random(0, baseScreenRatio.x), love.math.random(baseScreenRatio.y, 0), love.math.random(90,130), 5, 5, 3, colors[love.math.random(1,#colors)], {squishX = 0.5}))
        table.insert(self.bubbles, UISquigleCircle("fill", love.math.random(0, baseScreenRatio.x), love.math.random(baseScreenRatio.y, 0), love.math.random(90,130), 5, 5, 3, colors[love.math.random(1,#colors)], {rotation = 0}))

        self.bubbles[#self.bubbles].type = "Squisher"
        self.bubbles[#self.bubbles-1].type = "Spinner"

        self.bubbles[#self.bubbles].isNote = true
    end
end

function titleScreen:setUpThoseWavesThatIHate(numberOfWaves)
    local colors = {
        {1,1,1,0.5},
        {0,1,1,0.5},
        {1,0,1,0.5},
        {0,0,1,0.5}
    }
    local transparency = 0.5
    local colors = SkinHandler:getRandomColors()
    colorsREAL = {}

    -- we need to randomly choose numberOfWaves amount of these colors 
    if Settings:getValue("Menu", "Title Screen", "Enable Squiglly Lines") then
        for _ = 1,numberOfWaves do
            table.insert(colorsREAL, colors[love.math.random(1,#colors)])
        end
        self.layerWaves = UILayerWave(0,baseScreenRatio.y+50,baseScreenRatio.x,250,#colorsREAL,300, 30, 50, colorsREAL)
    end
end

function titleScreen:setUpThoseLinesThatIHate(numberOfLines)
    self.squiglyLines = {}
    if Settings:getValue("Menu", "Title Screen", "Enable Squiglly Lines") then
        for i = 1,numberOfLines do
            local y = ((baseScreenRatio.y+400)/numberOfLines)*(i-2)
            local x1,x2 = -50, baseScreenRatio.x+50
            table.insert(self.squiglyLines, UIsquiglyLine(x1,y+300,x2,y-300,10,30,200,1,70,{1,1,1,0.15}))
        end
    end
end

function titleScreen:setUpThoseSqauresThatIHate()
    -- decide how long till the first one appearrs
    local delay = love.math.random(5,5)
    local colors = SkinHandler:getRandomColors()
    print("SQUARE!!! SQAURREE!!!!!!", delay)

    -- set da timer 
    Timer.after(delay, function()

        local x,y,size,color = love.math.random(0,baseScreenRatio.x), love.math.random(0,baseScreenRatio.y), love.math.random(100,500),colors[love.math.random(1,#colors)]
                    print("SQUARE!!! SQAURREE!!!!!!", x,y,size,color)

        self.awesomeSquare =  growingSquare(x,y,size,color)
        self:setUpThoseSqauresThatIHate()
    end)
end

function titleScreen:switchState(state)
    if state == "H" then

    elseif state == "logo" then

    end
end

function titleScreen:raiseWaves()
    Timer.tween(0.5, self, {wavesY = -500}, "in-quad")
end

function titleScreen:fadeScreen()
    Timer.tween(0.5, screenFade, {1}, "in-quad")
end

local function sortByScale(a,b)
    --[[ return a.scale < b.scale ]]
    return a.scales[1].scale > b.scales[1].scale
end

function titleScreen:update(dt)
    fade = math.min(fade + dt*5, 1)

    for i, Button in ipairs(self.buttons) do
        Button:update(dt)
    end
    for i, squiglyLines in ipairs(self.squiglyLines) do
        squiglyLines:update(dt)
    end
    for i, Button in ipairs(self.socialButtons) do
        Button:update()
    end

    table.sort(self.socialButtons, sortByScale)

    if self.window then self.window:update(dt) end

    if self.layerWaves then
        self.layerWaves:update(dt)
    end

    self:updateBubbles(dt) 

        if self.awesomeSquare then self.awesomeSquare:update(dt) end
        self.thoseWeirdGrowingCirclesThatIHate:update(dt)



end

function titleScreen:updateBubbles(dt)
    local t = love.timer.getTime() * 0.5
    for i, Bubble in ipairs(self.bubbles) do
        local ang = t + i
        local sinv = math.sin(ang)
        local cosv = math.cos(ang)
        Bubble:update(dt)

        Bubble.rotation = Bubble.rotation + cosv * 30 * dt
        Bubble.x = Bubble.x + sinv * 30 * dt
        Bubble.x = Bubble.x +20 * dt

        Bubble.y =  Bubble.y - 20 * dt
        Bubble.y = Bubble.y + cosv* dt*50
        if Bubble.x > baseScreenRatio.x + Bubble.radius+10 then Bubble.x = -Bubble.radius+10 elseif Bubble.x < -Bubble.radius+10 then Bubble.x = baseScreenRatio.x + Bubble.radius+10 end
        if Bubble.y < -Bubble.radius+10 then Bubble.y = baseScreenRatio.y + Bubble.radius+10 end

        if Input:pressed("menuClickLeft") then
            local mx,my = cursor:getPosition()
            if math.abs(mx - Bubble.x) < Bubble.radius and math.abs(my - Bubble.y) < Bubble.radius then
                local unsquish

                local squish = function()
                    if AchievementHandler then
                        if Bubble.isNote then
                            AchievementHandler:unlock("touched a squishy arrow")
                        else
                            AchievementHandler:unlock("touched a squishy circle")
                        end
                    end
                    unsquish = function(l)
                        if self.unsquishTimer then Timer.cancel(self.unsquishTimer) end
                        self.unsquishTimer = Timer.tween(1, Bubble, {squishX = 0,squishY = 0, }, "out-elastic", function() unsquish() end)
                    end
                    Timer.tween(0.5, Bubble, {squishX = love.math.random(-0.5,0.5),squishY = love.math.random(-0.5,0.5)}, "out-back", function()unsquish()end)
                end

                local spin = function()
                    if AchievementHandler then
                        if Bubble.isNote then
                            AchievementHandler:unlock("touched a spinning arrow")
                        else
                            AchievementHandler:unlock("touched a spinning circle")
                        end
                    end
                    Bubble.shit = Timer.tween(2, Bubble, {rotation = Bubble.rotation + 360}, "out-quad")
                end

                if Bubble.type == "Spinner" then spin() end
                if Bubble.type == "Squisher" then squish() end
                self.bubbleClickedCount = (self.bubbleClickedCount or 0) + 1

                if self.bubbleClickedCount > 10 and not self.shownOsuWindow then
                    self.shownOsuWindow = true
                    self.window = window(self,LocaleHandler:getText("easterEggs","Isn't osu"), LocaleHandler:getText("easterEggs","Stop Clicking Circles"), {{text = LocaleHandler:getText("easterEggs","Sorry"), func = function() self.window:killYourself() end}})
                end

                -- save original alpha 
                if not Bubble.originalAlpha then Bubble.originalAlpha = Bubble.color[4] end
                Bubble.color[4] = 1
                if Bubble.poop then Timer.cancel(Bubble.poop) end
                Bubble.poop = Timer.tween(2, Bubble.color, {[4] = Bubble.originalAlpha})
                break  -- so you cant click multiple cuz it it just looks bad
            end
        end
    end
end

function titleScreen:draw()
    love.graphics.draw(self.BG) -- TEMP 
    if self.awesomeSquare then self.awesomeSquare:draw() end
    self.thoseWeirdGrowingCirclesThatIHate:draw()
    for i, Bubble in ipairs(self.bubbles) do
        if not Bubble.isNote then
            Bubble:draw()
        else
            love.graphics.setColor(Bubble.color)
            love.graphics.draw(self.noteImage,Bubble.x,Bubble.y, math.rad(Bubble.rotation), 1+Bubble.squishX*(Bubble.radius/130), 1+Bubble.squishY*(Bubble.radius/130), self.noteImage:getWidth()/2, self.noteImage:getHeight()/2)
        end
    end
    love.graphics.print("harmoni lol")

    love.graphics.setColor(1,1,1,0.1)
    love.graphics.push()
        love.graphics.translate(0, self.wavesY)
        if self.layerWaves then
            self.layerWaves:draw()
        end
    love.graphics.pop()
    love.graphics.setColor(1,1,1,0.05)
    for i, squiglyLines in ipairs(self.squiglyLines) do
        squiglyLines:draw()
    end

    for i, Button in ipairs(self.buttons) do
        Button:draw(fade)
    end
    love.graphics.setColor(1,1,1,1)

    for i, Button in ipairs(self.socialButtons) do
        Button:draw()
    end
    self:drawLogo()


   -- love.graphics.draw(self.moth)

    if self.window then self.window:draw() end
    love.graphics.setColor(0,0,0,self.coverAlpha + screenFade[1])
    love.graphics.rectangle("fill", 0, 0 , baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1,1,1,1)
end

function titleScreen:drawLogo()
    -- logo variables 
    local fullLogo = self.images["logo"].image
    local fullLogoSizeX, fullLogoSizeY, fullLogoX, fullLogoY = 0.3,0.3, baseScreenRatio.x/2, baseScreenRatio.y/2
    ---@diagnostic disable-next-line: need-check-nil
    local fullLogoCenterX, fullLogoCenterY = fullLogo:getWidth()/2, fullLogo:getHeight()/2

    love.graphics.draw(fullLogo, baseScreenRatio.x/2, baseScreenRatio.y/2-350, 0, fullLogoSizeX, fullLogoSizeY, fullLogoCenterX, fullLogoCenterY)

--    self.coolFuckingRectangle:draw()
end

return titleScreen