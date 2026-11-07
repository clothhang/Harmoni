local resultsCircle = Class:extend("resultsCircle")

local function remap(value, oldMin, oldMax, newMin, newMax)
    return (value - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin
end

function resultsCircle:new(x,y,percent)
    self.emptyImage = SkinHandler:getImage("Results", "Circle Empty")
    self.fillImage = SkinHandler:getImage("Results", "Circle Fill")

    self.x, self.y = x,y

    self.arcCanvas = love.graphics.newCanvas(2560, 1440)

    self.percent = 100

    Timer.tween(1, self, {percent = 0}, "linear", function() Timer.tween(1, self, {percent = 100}) end)
end

function resultsCircle:update(dt)
end

function resultsCircle:draw()
    love.graphics.push()
        
        love.graphics.draw(self.emptyImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)

        -- this is hacky as FUCK
        local bullshitttttt = remap(self.percent, 0, 100, 100, 0)

        local arc2val = remap(100-self.percent, 0, 100, 37, -217)

        self.arcCanvas:renderTo(function()
            love.graphics.clear()
            love.graphics.arc("fill", "pie", self.x-(baseScreenRatio.x/2), self.y, 372, math.rad(arc2val), math.rad(-217))
        end)

        -- min is 37, max is -217
        love.graphics.stencil(function() 
            love.graphics.push()
            love.graphics.scale(-1,1)
            love.graphics.draw(self.arcCanvas)
            love.graphics.pop()
        end, replace, 1)

        love.graphics.setStencilTest("notequal", 1)
        love.graphics.draw(self.fillImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)
        love.graphics.setStencilTest()

    love.graphics.pop()
end

return resultsCircle



