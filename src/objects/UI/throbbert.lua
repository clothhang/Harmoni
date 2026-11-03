local throbbert = Class:extend("throbbert")

function throbbert:new(colors)
    self.colors = colors or {1,1,1,1}

    self.color = self.colors[love.math.random(1,#self.colors)]
    self.color2 = self.colors[love.math.random(1,#self.colors)]
    self.color3 = self.colors[love.math.random(1,#self.colors)]

    self.rotateSpeed = 5
    self.x,self.y = 0,0 -- instead of properly removing it im doing this hack lmao 
    self.time = 1.9
    self.radius = 200
    self.arcLengthSmall = 0
    self.arcLengthLarge = 270
    self.segments = 20
    self.arcLength = self.arcLengthSmall
    self.rotation = 0

    self:throb()
end

function throbbert:throb()  -- god why did they name these things "throbbers"
    self.color = self.colors[love.math.random(1,#self.colors)]
    self.color2 = self.colors[love.math.random(1,#self.colors)]
    self.color3 = self.colors[love.math.random(1,#self.colors)]

    Timer.tween(self.time, self, {arcLength = self.arcLengthLarge}, "in-out-quad", function()
        Timer.tween(self.time, self, {arcLength = self.arcLengthSmall}, "in-out-quad", function()
            self:throb()
        end) -- a function calling itself... surely this wont lead to any problems
    end)
end

function throbbert:update(dt)
    self.rotation = self.rotation + self.rotateSpeed*dt
end

function throbbert:draw(x,y,radius,linewidth)
    x, y, radius, linewidth = x or 0, y or 0, radius or 10, linewidth or 5

    local thingies = {
        {rotation = self.rotation*3, color = {self.color[1], self.color[2], self.color[3]}},
       -- {rotation = self.rotation*2, color = {self.color2[1], self.color2[2], self.color2[3]}},
        --{arotation = self.rotation, color = self.color3},  -- yes there is a real reason for the color tables being like this
    }
    love.graphics.setLineWidth(linewidth)

    for _, Thingy in ipairs(thingies) do -- 3 throbberts  🤤🤤🤤
        love.graphics.push()             -- 1 throbbert ☹
        love.graphics.translate(x,y)
        love.graphics.rotate(Thingy.rotation)
        love.graphics.setColor(Thingy.color)
        love.graphics.arc("line", "open", 0, 0, radius, 0, math.rad(self.arcLength), self.segments)
        love.graphics.pop()
    end
    love.graphics.setColor(1,1,1,1)
end

return throbbert