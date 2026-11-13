local maniaHealthBar = Class:extend("maniaHealthBar")


function maniaHealthBar:setupParticles()
    local image1 = love.graphics.newImage("images/particles/light.png")
    image1:setFilter("linear", "linear")

    local ps = love.graphics.newParticleSystem(image1, 47)
ps:setColors(1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 0)
ps:setDirection(-1.5707963705063)
ps:setEmissionArea("none", 0, 0, 0, false)
ps:setEmissionRate(20)
ps:setEmitterLifetime(0.098853953182697)
ps:setInsertMode("top")
ps:setLinearAcceleration(0, 0, 0, 0)
ps:setLinearDamping(0, 0)
ps:setOffset(75, 75)
ps:setParticleLifetime(1.7999999523163, 2.2000000476837)
ps:setRadialAcceleration(0, 0)
ps:setRelativeRotation(false)
ps:setRotation(0, 0)
ps:setSizes(0.55895233154297)
ps:setSizeVariation(0)
ps:setSpeed(90, 100)
ps:setSpin(0, 0)
ps:setSpinVariation(0)
ps:setSpread(0.31415927410126)
ps:setTangentialAcceleration(0, 0)
-- At draw time:
-- love.graphics.setBlendMode("add")
-- love.graphics.draw(ps, -116+0, 228.5+0)

    return ps
end



function maniaHealthBar:new(x,y,width,height,health,max)
    self.x,self.y = x or 0, y or 0
    self.width,self.height = width or 10, height or 30
    self.health = (health or 1)

    self.max = (max or 0.95)  -- i really like the health bar having this it looks nice
    self.printableHealth = self.health

    self.line = UIsquiglyLine(self.x, self.y, self.x, self.y-self.height,4,5,50,1,self.width)
    self.particle = self:setupParticles()
end

local maxHealthLerpSpeed = 10
local HealthLerpSpeed = 10

function maniaHealthBar:update(dt)
    self.line:update(dt)

    if self.health > self.max then
        --self.particle:start()
        self.health = self.health + (self.max - self.health) * (1 - math.exp(-dt * maxHealthLerpSpeed))
    end

    self.printableHealth = self.printableHealth + (self.health - self.printableHealth) * (1 - math.exp(-dt *HealthLerpSpeed))
    self.particle:update(dt)
end

function maniaHealthBar:changeHealth(amount)
    self.health = self.health + amount
    if self.health > 1 then self.health = 1 elseif self.health < 0 then self.health = 0 end
end

function maniaHealthBar:justFuckingDie()
    self.health = 0
end

function maniaHealthBar:draw()
    love.graphics.setBlendMode("add")
    love.graphics.draw(self.particle, self.x, self.y-(self.height*self.max)+140)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1,1,1,0.45)
    love.graphics.stencil(function()
    love.graphics.rectangle("fill", self.x-self.width,((self.y-self.height-10)), self.x+self.width,(self.y-(self.height*self.printableHealth))+10)
    end, "replace", 1)

    love.graphics.setStencilTest("notequal", 1)

    self.line:draw()
        love.graphics.setStencilTest()
    love.graphics.setColor(1,1,1,1)

    love.graphics.circle("fill", self.x, self.y, self.width)



end


return maniaHealthBar