local resultsCircle = Class:extend("resultsCircle")

local function remap(value, oldMin, oldMax, newMin, newMax)
    return (value - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin
end

function resultsCircle:new(x,y,percent,callback,delay)
    self.emptyImage = SkinHandler:getImage("Results", "Circle Empty")
    self.fillImage = SkinHandler:getImage("Results", "Circle Fill")

    self.callback = callback or function() end
    self.delay = delay or 0
    self.scoreTickSound = love.audio.newSource("sounds/scoreTick.ogg", "static")

    self.x, self.y = x,y

    self.printablePercent = 0 
    self.percent = percent
    self.doingTween = true

    self.grade = maniaGrades.getGrade(self.percent)

    self.printablePercentLiquidAssValue = 0
    self.tween = Timer.tween(10, self, {printablePercent = self.percent}, "in-out-quint", 
    function() 
        self.printablePercent = self.percent 
        self.doingTween = false 
        Timer.after(1, function()
            self:presentGrade()
        end)
    end)

    self.soundEffectsHitTable = {}
    self.font = SkinHandler:getFont("Menu", 230)
    for i = 1,50 do
        table.insert(self.soundEffectsHitTable, false)
    end
    self.fillColor = maniaGrades.getGrade(0).color
end

function resultsCircle:presentGrade()
    self.gradePresented = true
    self:printablePercentLiquidAss(true)
    Timer.after(self.delay, function() self.callback() end)
end

function resultsCircle:update(dt)
    self.targetColor = maniaGrades.getGrade(self.printablePercent).color
    if math.floor(self.printablePercent)%2 == 0 and not self.soundEffectsHitTable[(math.floor(self.printablePercent))/2] then
        self.soundEffectsHitTable[(math.floor(self.printablePercent))/2] = true
        local clone = self.scoreTickSound:clone()
        local pitch = remap(self.printablePercent, 0, 100, 0.7, 1)
        clone:setPitch(pitch)
        clone:play()
        print("click")
        self:printablePercentLiquidAss()
    end

    if self.colorTween then Timer.cancel(self.colorTween) end

   -- self.colorTween = Timer.tween(0.15, self.fillColor, {[1] = self.targetColor[1], [2] = self.targetColor[2], [3] = self.targetColor[3]})

end

function resultsCircle:printablePercentLiquidAss(big)
    self.printablePercentLiquidAssValue = (big and 0.3) or 0.1
    self.printablePercentLiquidAssTween = Timer.tween(1, self, {printablePercentLiquidAssValue = 0},  "out-elastic")
end


function resultsCircle:draw()
    if self.debug then 
        for i = 1,#self.soundEffectsHitTable do
            love.graphics.print(tostring(self.soundEffectsHitTable[i]), 30, 20*i)
        end
    end

    love.graphics.setFont(self.font)

    local printableThing = (self.gradePresented and self.grade) or math.floor(self.printablePercent) .. "%"
    love.graphics.printf(printableThing, self.x-self.emptyImage:getWidth()*(1+self.printablePercentLiquidAssValue)/2, self.y-love.graphics.getFont():getHeight()*(1+self.printablePercentLiquidAssValue)/2, self.emptyImage:getWidth(), "center", nil, 1+self.printablePercentLiquidAssValue, 1+self.printablePercentLiquidAssValue)
    love.graphics.draw(self.emptyImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)
 --   love.graphics.setFont(defaultFont)



    local arc2val = remap(self.printablePercent, 0, 100, 37, -217)
    --print(arc2val)

    -- min is 37, max is -217
    love.graphics.stencil(function() 
        love.graphics.push()
        love.graphics.translate(baseScreenRatio.x/2, baseScreenRatio.y/2)
        love.graphics.scale(-1, 1)
        love.graphics.translate(-baseScreenRatio.x/2, -baseScreenRatio.y/2)

        love.graphics.arc("fill", "pie", self.x + baseScreenRatio.x/2 - 155, self.y, 372, math.rad(arc2val), math.rad(-217))
        love.graphics.pop()
    end, "replace", 1)

    love.graphics.setStencilTest("notequal", 1)
    love.graphics.rectangle("fill", 0, 0, 2560, 1440)
    love.graphics.setColor(self.fillColor)
    love.graphics.draw(self.fillImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)
    love.graphics.setColor(1,1,1)
    love.graphics.setStencilTest()

end
 
return resultsCircle