local resultsCircle = Class:extend("resultsCircle")

local function remap(value, oldMin, oldMax, newMin, newMax)
    return (value - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin
end

function resultsCircle:new(x,y,percent)
    self.emptyImage = SkinHandler:getImage("Results", "Circle Empty")
    self.fillImage = SkinHandler:getImage("Results", "Circle Fill")

    self.scoreTickSound = love.audio.newSource("sounds/scoreTick.ogg", "static")

    self.x, self.y = x,y

    self.printablePercent = 0 
    self.percent = percent
    self.doingTween = true

    Timer.tween(3, self, {printablePercent = self.percent}, "out-quint", function() self.doingTween = false end)
end

function resultsCircle:update(dt)
    if self.doingTween and math.floor(self.printablePercent)%2 == 0 then
        local clone = self.scoreTickSound:clone()
        local pitch = remap(self.printablePercent, 0, 100, 0.7, 1)
        clone:setPitch(pitch)
        clone:play()
        print("click")
    end
end

function resultsCircle:draw()
    love.graphics.draw(self.emptyImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)

    -- this is hacky as FUCK
    local bullshitttttt = remap(self.printablePercent, 0, 100, 100, 0)

    local arc2val = remap(bullshitttttt, 0, 100, 37, -217)
    --print(arc2val)

    -- min is 37, max is -217
    love.graphics.stencil(function() 
    love.graphics.arc("fill", "pie", self.x, self.y, 372, math.rad(-217), math.rad(arc2val))
    end, "replace", 1)

    love.graphics.setStencilTest("notequal", 1)
    love.graphics.draw(self.fillImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)
    love.graphics.setStencilTest()

end

return resultsCircle