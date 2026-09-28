local drumsApproachCircle = Class:extend("drumsApproachCircle")

function drumsApproachCircle:new(parent,x,y,targetRadius)
    self.parent,self.x,self.y,self.targetRadius = parent,x,y,targetRadius
end

function drumsApproachCircle:update(dt)
end

function drumsApproachCircle:draw(time)
    local approachTime = 500
    local progress = math.max(0, math.min(1, time / approachTime))
    self.currentRadius = self.targetRadius * (1 + progress * 2)
    love.graphics.circle("line", self.x, self.y, self.currentRadius, 30)
end

return drumsApproachCircle