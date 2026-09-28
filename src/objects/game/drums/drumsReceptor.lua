local drumsReceptor = Class:extend("drumsReceptor")

function drumsReceptor:new(parent)
    self.parent = parent
    self.x,self.y = baseScreenRatio.x/2, self.parent.y+(self.parent.height/2)
    self.radius = (self.parent.height/2) + love.graphics.getLineWidth()/2
end

function drumsReceptor:update(dt)
end

function drumsReceptor:draw()
    love.graphics.setColor(1,1,0)
    local previousLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(10)
    self.radius = (self.parent.height/2) + love.graphics.getLineWidth()/2
    love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.line(self.x,self.y-self.radius, self.x, self.y+self.radius)
    love.graphics.setLineWidth(previousLineWidth)
    love.graphics.setColor(1,1,1)
end

return drumsReceptor