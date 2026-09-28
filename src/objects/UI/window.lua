local window = Class:extend()

-- i have hardcoded this in a way that you cannot call the window in any state anything other than "window" and there can only be one of them.
--i suck ass at coding

function window:new(parent,title,msg,buttons,checkbox,checkBoxDefault,checkBoxText)
    print("WINDOW")
    -- these will be centered to their center (am i wording that right?) cuz it just seems like it should be idfk
    -- buttons should be a table,, i think ,,, idk im just making it up as i go
    if type(buttons) ~= "table" then GlobalNotificationsHandler:addNotification("window created with non-table buttons!", "error") self.buttons = {} end -- this is temp, itll just destroy the window if its not a table 
    if type(parent) ~= "table" then GlobalNotificationsHandler:addNotification("window created with no parent!", "error") return end
    self.parent = parent

    self.title, self.msg = title, msg
    self.x, self.y = baseScreenRatio.x/2, baseScreenRatio.y/2 -- might make this able to change later,, idk 

    self.hasCheckbox = checkbox
    if self.hasCheckbox then
        self.checkBoxDefault = checkBoxDefault or false
        self.checkBoxText = checkBoxText or "you forgot to type this dumbass :3"
    end

    if self.bodyText then self.bodyText:release() end
    self.bodyText = love.graphics.newText(SkinHandler:getFont("Menu", 50), self.msg)    -- we dont even end up drawing this lol, we just use it for its size (i was too lazy to redo the draw func)
    self.width, self.height = self.bodyText:getDimensions()
    self.width = self.width + 150   -- hardcoded value!!! everyone's favorite!!!!!
    self.height = self.height + 250

    --if self.width == 0 then -- we will deal with this later
    self.rectX,self.rectY = self.x - self.width/2, self.y - self.height/2
    self.coolFuckingRectangle = coolFuckingRectangle(self.rectX,self.rectY,self.width,self.height,25,70,{1,1,1,1},{31/255,32/255,34/255,1})

    self.titleBarHeight = 90 -- idk, im just gonna hardcode this cuz it doesnt matter

    self.buttons = {}
    self.buttonFont = SkinHandler:getFont("Menu", 35)
    self.font = SkinHandler:getFont("Menu", 50)

    self.buttonSpacing = 100
    self.buttonHeight = 50

    if not buttons then return end
    for i, Button in ipairs(buttons) do
        local btn = {}
        if not Button.text then goto continue end
        btn.text = Button.text
        if Button.func then
            btn.func = Button.func
        end

        -- now we figure out the size and spacing and shit, depending on how many buttons there are
        -- get the inner rectangle width
        local innerRectWidth = self.coolFuckingRectangle.width - self.coolFuckingRectangle.padding -- this is horrendous oh my god
        -- then we divide this by the number of buttons to get the width of the buttons BEFORE padding
        local btnWidthWithNoPadding = innerRectWidth / #buttons
        -- then we subtract padding from this to get width AFTER padding
        local btnWidthWithPadding = btnWidthWithNoPadding - self.buttonSpacing
        -- finally we figure out the X position of the buttons using the before padding value
        local allBtnWidth = (#buttons * btnWidthWithPadding) + ((#buttons - 1) * self.buttonSpacing)
        local startX = self.x - allBtnWidth / 2
        local btnX = startX + (i - 1) * (btnWidthWithPadding + self.buttonSpacing)
        -- we're finally done, add it to the fucking table and hope its all correct
        btn.x = btnX

        -- y position is easy, its just like 100 pixels above the bottom of the window
        btn.y = (self.rectY+self.height)-100
        btn.btnWidthWithPadding = btnWidthWithPadding
        btn.height = self.buttonHeight

        table.insert(self.buttons, btn)
        ::continue::
    end
    self:animation("open")

    
end

function window:update(dt)
    self:checkForClicks()
end

function window:checkForClicks()
    local mx,my = cursor:getPosition()
    if not Input:pressed("menuClickLeft") then return end
    for i, Button in ipairs(self.buttons) do
        if mx >= Button.x and 
        mx <= Button.x+Button.btnWidthWithPadding and 
        my >= Button.y and 
        my <= Button.y+Button.height then
            if Button.func then Button.func() end
            return Button.text
        end
    end
end

function window:killYourself()
    self:animation("close", function() self.parent.window = nil end)
end

local funct
function window:animation(type,func)
    local funct

    if func then funct = function() func() end else funct = function() end end
    -- the line ever

    if type == "open" then -- fade in twice as fast as window scales up
        self.alpha = 0
        self.coolFuckingRectangle.alpha = 0
        self.scale = 0.9
        local time = 0.15
        Timer.tween(time/2, self, {alpha = 1})
        Timer.tween(time, self, {scale = 1}, "out-elastic", function()funct()end)

        -- cant forget the cool fucking rectangle's alpha too!
        Timer.tween(time, self.coolFuckingRectangle, {alpha = 1})

    elseif type == "close" then  -- fade in at same rate as window scales down
        self.alpha = 1
        self.coolFuckingRectangle.alpha = 1
        self.scale = 1
        local time = 0.15
        Timer.tween(time, self, {scale = 0.9, alpha = 0}, "linear", function()funct()end)
        Timer.tween(time, self.coolFuckingRectangle, {alpha = 0})

    else
        GlobalNotificationsHandler:addNotification("invalid animation in window!", "error")
    end
end

--[[  awesome animations
function window:animation(type,func)
    local funct

    if func then funct=function()func()end else funct = function()end end
    -- the line ever

    if type == "open" then -- fade in twice as fast as window scales up
        self.alpha = 1
        self.coolFuckingRectangle.alpha = 1
        self.scale = 0
        local time = 1
        Timer.tween(time/2, self, {alpha = 1})
        Timer.tween(time, self, {scale = 1}, "out-elastic", function()funct()end)

        -- cant forget the cool fucking rectangle's alpha too!
        Timer.tween(time, self.coolFuckingRectangle, {alpha = 1})

    elseif type == "close" then  -- fade in at same rate as window scales down
        self.alpha = 1
        self.coolFuckingRectangle.alpha = 1
        self.scale = 1
        local time = 0.5
        self.COCK = 0
        Timer.tween(time, self, {COCK = baseScreenRatio.x/2+self.width/2}, "in-back",function()funct()end)
       -- Timer.tween(time, self, {scale = 0.9, alpha = 0}, "linear", function()funct()end)
        --Timer.tween(time, self.coolFuckingRectangle, {alpha = 0})

    else
        GlobalNotificationsHandler:addNotification("invalid animation in window!", "error")
    end
end
--]]
function window:draw()
    love.graphics.push()

    love.graphics.setColor(1,1,1,self.alpha)
    -- center-scaling
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(self.scale)
    love.graphics.translate(-self.x, -self.y)

    -- the fucking font. 
    love.graphics.setFont(self.font)

    --stencil shit
    love.graphics.stencil(function()
        self.coolFuckingRectangle:draw()
    end, "replace", 1)
    love.graphics.setStencilTest("equal", 1)

    -- draw the cool fucking rectangle as the window background
    self.coolFuckingRectangle:draw()

    --draw the title bar bg
    local r,g,b = unpack(self.coolFuckingRectangle.color2)
    love.graphics.setColor(r,g,b,self.alpha)
    love.graphics.rectangle("fill",self.rectX,self.rectY,self.width,self.titleBarHeight)

    -- draw window text 
    love.graphics.setColor(1,1,1,self.alpha)
    local fontHeight = love.graphics.getFont():getHeight()
    local titleY = self.rectY + (self.titleBarHeight - fontHeight) / 2
    love.graphics.printf(self.title, self.rectX, titleY, self.width, "center")
    local r,g,b = unpack(self.coolFuckingRectangle.color2)
    love.graphics.setColor(r,g,b,self.alpha)
    love.graphics.printf(self.msg, self.rectX, self.rectY + self.titleBarHeight+self.coolFuckingRectangle.padding, self.width, "center")

            -- draw the checkbox if we have one
        if self.hasCheckbox then
            love.graphics.rectangle("line", self.x-469, self.y+264, 40, 40, 10, 10)
        end

    -- now we draw the buttons
    love.graphics.setFont(self.buttonFont)
    for i, Button in ipairs(self.buttons) do
        --draw the button background
        local r,g,b = unpack(self.coolFuckingRectangle.color2)
        love.graphics.setColor(r,g,b,self.alpha)
        love.graphics.rectangle("fill", Button.x, Button.y, Button.btnWidthWithPadding, Button.height, 10)
        love.graphics.setColor(1,1,1,self.alpha)
        love.graphics.printf(Button.text,Button.x,Button.y+(Button.height/2)-love.graphics.getFont():getHeight()/2,Button.btnWidthWithPadding,"center")
    end




    love.graphics.setStencilTest()

    love.graphics.setColor(1,1,1,1)

    love.graphics.pop()
end

return window