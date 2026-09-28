local drumsApproachCircle = Class:extend("drumsApproachCircle")

function drumsApproachCircle:new(parent,x,y,targetRadius)
    self.parent,self.x,self.y,self.targetRadius = parent,x,y,targetRadius
end

function drumsApproachCircle:update(dt)
end

function drumsApproachCircle:draw(time)
    self.currentRadius = time + self.targetRadius
    love.graphics.circle("line", self.x, self.y, self.currentRadius/3, 30)
end

return drumsApproachCircle