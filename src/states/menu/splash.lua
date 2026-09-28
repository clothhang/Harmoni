local splash = State("splash")

local funct

function splash:enter()
    self.splashNumber = 1
    self.alpha = 0
    self.splashScreens = {
        {screen = "beta", time = 2, msg = LocaleHandler:getText("Misc", "Is Beta")},
        {screen = "headphones", time = 5, msg = LocaleHandler:getText("UI", "Headphones Recommended") .. "\n\n" .. LocaleHandler:getText("UI","Headphones Better"), img = love.graphics.newImage("images/menu/headphones.png")},
   --     {screen = "crash", time = 5, msg = LocaleHandler:getText("Misc", "might fucking die")}

    }
    self:setupShit()
end

function splash:setupShit()
    -- first we check if theres any more splashes to show
    if self.splashNumber <= #self.splashScreens then -- we continue
    -- do the fade stuff 
        local function func()
            self.timerAfter = Timer.after(self.splashScreens[self.splashNumber].time or 3, function() self:fade("out", function() self.splashNumber = self.splashNumber+1;self:setupShit() end) end)
        end
        self:fade("in", func)
        --self.currentMessageuhhhhhhh = love.graphics.newTextBatch(SkinHandler:getFont("Menu", 50),self.splashScreens[self.splashNumber].msg)  -- yes i know i can just draw this instead of using printf, im just too fucking lazy to edit the draw function
        self.currentMessage = self.splashScreens[self.splashNumber].msg
        if self.splashScreens[self.splashNumber].img then self.currentImage = self.splashScreens[self.splashNumber].img end
    else -- no more splashes, go to the title screen
        State.switch(States.menu.titleScreen, false, true) 
    end
end

function splash:fade(dir, func)
    if func then funct = func else funct = function() end end   -- this goddamn line is the worse thing to ever come out of my mind and I KEEP PUTTING IT EVERYWHERE

    local value = (dir == "in" and 1) or 0
    self.timerTween = Timer.tween(0.25, self, {alpha = value}, "linear", function() funct() end)
end

function splash:update()
    if Input:pressed("menuConfirm") then
        if self.timerAfter then Timer.cancel(self.timerAfter) end
        if self.timerTween then Timer.cancel(self.timerTween) end
        self.splashNumber = self.splashNumber+1           -- math.min(self.splashNumber+1, #self.splashScreens)
        self:setupShit()
    end
end

function splash:draw()
    love.graphics.setColor(1,1,1,self.alpha)
    love.graphics.setFont(SkinHandler:getFont("Menu", 50))
    love.graphics.printf(self.currentMessage or "", 0, baseScreenRatio.y/2-100, baseScreenRatio.x, "center")
    if self.currentImage and self.splashScreens[self.splashNumber].img then
        local image = self.currentImage
        local x,y = baseScreenRatio.x/2, image:getHeight()/2+50
        love.graphics.draw(image, x, y, nil, 1, 1, image:getWidth()/2, image:getHeight()/2)
    end
end

return splash