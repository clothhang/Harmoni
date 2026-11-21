local cursor = Class:extend("MenuCursor")

local function lerp(a, b, t)
    return a + (b - a) * t
end

local rad, abs = math.rad, math.abs
local max, min = math.max, math.min
local getMousePos = love.mouse.getPosition

local DEG45 = 45
local function aproxAtan2Deg(y, x)
    if x == 0 then
        return (y > 0 and 90) or (y < 0 and -90) or 0
    end

    local absY = y >= 0 and y or -y
    local r, angle

    if x >= 0 then
        r = (x - absY) / (x + absY)
        angle = DEG45 - DEG45 * r
    else
        r = (x + absY) / (absY - x)
        angle = 135 - DEG45 * r
    end

    if y < 0 then angle = -angle end
    return angle
end

function cursor:setupClickParticles()
    local image1 = love.graphics.newImage("images/particles/ring.png")
    image1:setFilter("linear", "linear")

    local ps = love.graphics.newParticleSystem(image1, 4)
    ps:setColors(0.0078125, 0, 1, 0, 0, 0.25, 1, 1, 0, 0.765625, 1, 1, 0.21875, 0, 1, 0)
    ps:setDirection(-1.5657712221146)
    ps:setEmissionArea("none", 0, 0, 0, false)
    ps:setEmissionRate(3.266339302063)
    ps:setEmitterLifetime(0)
    ps:setInsertMode("top")
    ps:setLinearAcceleration(0, 0, 0, 0)
    ps:setLinearDamping(4.1745858192444, 4.4113955497742)
    ps:setOffset(50, 50)
    ps:setParticleLifetime(0.56850636005402, 0.66894632577896)
    ps:setRadialAcceleration(0, 0)
    ps:setRelativeRotation(false)
    ps:setRotation(0, 0)
    ps:setSizes(0.32010126113892)
    ps:setSizeVariation(0)
    ps:setSpeed(477.88586425781, 477.88586425781)
    ps:setSpin(0, 0)
    ps:setSpinVariation(0)
    ps:setSpread(6.2831854820251)
    ps:setTangentialAcceleration(0, 0)

    return ps
end




function cursor:new()
    self.x, self.y = getMousePos()
    self.prevX, self.prevY = self.x, self.y
    self.mouseDownX, self.mouseDownY = nil, nil
    self.rotating = false

    self.clickParticle = self:setupClickParticles()
    self.particlesTable = {} -- i am so fucking sorry 

    self.angle = 0-- 99999999999999999999999999999999999999991
    self.targetAngle = 0
    self.angularVelocity = 0
    self.angularAcceleration = 0

    self.rotateSpeed = 15
    self.damping = 6
    self.followSpeed = 10

    self.visible = true
    self.scale = 0.35
    self.tgtScale = 0.35

    self.mouseDownFloatSpeed = 5

    self.image = love.graphics.newImage("images/UI/cursor.png")

    self.weight = 100
    self.weightAngle = 0

    self.fadeOutWhenIdle = false
    self.fadeOutTime = 0.5
    self.fadeOutTimer = 0
    self.fadeOutAlpha = 1
    self.didMove = false

    self.debug = false
end

function cursor:update(dt)

    --if self.angle > 99999999999999999999999999999999999999990 then self.angle = 0 end 
    -- fix for cursor breaking if its wound up for 45.6 sextillion times longer than the age of the universe (634.7 nonillion years)
    --  (assuming its wound continuously at 5 rotations per second)

    self.clickParticle:update(dt)
    for i = 1,#self.particlesTable do
        local system = self.particlesTable[i]
        system.ps:update(dt)
        if system.ps:getCount() == 0 then table.remove(self.particlesTable, i); break end
    end



    self.x, self.y = getMousePos()
    if self.x ~= self.prevX or self.y ~= self.prevY then
        self.didMove = true
        self.fadeOutTimer = 0
        self.fadingBackIn = true
    else
        self.didMove = false
    end

    if self.fadeOutWhenIdle and self.angle == 0 and self.angularVelocity == 0 then
        if not self.didMove and not self.fadingBackIn then
            self.fadeOutTimer = self.fadeOutTimer + dt
            if self.fadeOutTimer >= self.fadeOutTime then
                self.fadeOutAlpha = max(0, 1 - (self.fadeOutTimer - self.fadeOutTime) / self.fadeOutTime)
            end
        elseif self.fadingBackIn then
            self.fadeOutAlpha = self.fadeOutAlpha + dt * 5
            if self.fadeOutAlpha >= 1 then
                self.fadeOutAlpha = 1
                self.fadingBackIn = false
            end
        end
    elseif not self.fadeOutWhenIdle and self.fadeOutAlpha < 1 then
        self.fadeOutAlpha = self.fadeOutAlpha + dt * 5
    end

    --self.didMove = false

    if self.mouseDownX then
        local dx = self.x - self.mouseDownX
        local dy = self.y - self.mouseDownY
        local lengthSquared = dx * dx + dy * dy

        if not self.rotating and lengthSquared > 20 then
            self.rotating = true
        end

        if self.rotating then
            local angle = aproxAtan2Deg(-dx, dy) + 24.3
            local diff = (angle - self.angle + 180) % 360 - 180
            self.targetAngle = self.angle + diff

            local t = min(dt * self.followSpeed, 1)
            self.angle = self.angle + diff * t

            self.angularVelocity = 0
            self.angularAcceleration = 0
        else
            self.angularVelocity = 0
            self.angularAcceleration = 0
        end

        self.mouseDownX = lerp(self.mouseDownX, self.x, dt * self.mouseDownFloatSpeed)
        self.mouseDownY = lerp(self.mouseDownY, self.y, dt * self.mouseDownFloatSpeed)
    else
        local diff = (0 - self.angle)

        self.angularAcceleration = self.rotateSpeed * diff

        self.angularVelocity = self.angularVelocity + self.angularAcceleration * dt
        self.angularVelocity = self.angularVelocity * (1 - self.damping * dt)

        self.angle = self.angle + self.angularVelocity * dt

        if abs(diff) < 0.5 and abs(self.angularVelocity) < 0.5 then
            self.angle = 0
            self.angularVelocity = 0
            self.angularAcceleration = 0
        end
    end

    if self.tgtScale ~= self.scale then
        local scaleDelta = (self.tgtScale - self.scale) * dt * 25
        self.scale = self.scale + scaleDelta

        if abs(self.tgtScale - self.scale) < 0.01 then
            self.scale = self.tgtScale
        end
    end

    local weightDelta = (self.x - self.prevX) * 0.08
    self.prevX, self.prevY = self.x, self.y
    if self.mouseDownX then
        return
    end

    self.weightAngle = self.weightAngle + weightDelta

    if self.weightAngle > 360 then
        self.weightAngle = self.weightAngle - 360
    elseif self.weightAngle < 0 then
        self.weightAngle = self.weightAngle + 360
    end

    if self.weightAngle > 180 then
        self.weightAngle = self.weightAngle - 360
    elseif self.weightAngle < -180 then
        self.weightAngle = self.weightAngle + 360
    end

    if abs(self.weightAngle) < 0.01 then
        self.weightAngle = 0
    else
        self.weightAngle = lerp(self.weightAngle, 0, dt * 10)
        if abs(self.weightAngle) < 0.01 then
            self.weightAngle = 0
        end
        if self.weightAngle > 180 then
            self.weightAngle = self.weightAngle - 360
        elseif self.weightAngle < -180 then
            self.weightAngle = self.weightAngle + 360
        end
    end


end

function cursor:getX()
    local cx, _ = toCanvasCoords(self.x, self.y)
    return cx
end

function cursor:getY()
    local _, cy = toCanvasCoords(self.x, self.y)
    return cy
end

function cursor:getPosition()
    local cx, cy = toCanvasCoords(self.x, self.y)
    return cx, cy, (self.dx or 0), (self.dy or 0)
end

function cursor:isMouseDown()
    return self.mouseDownX ~= nil
end

function cursor:getYDirection()
    if not self:isMouseDown() then
        return 0
    end

    local dy = self.y - self.mouseDownY
    if dy > 0 then
        return 1
    elseif dy < 0 then
        return -1
    else
        return 0
    end
end

function cursor:draw()
    if not self.visible then return end
    local lastColor = {love.graphics.getColor()}

    love.graphics.push()
    love.graphics.setColor(1, 1, 1, self.fadeOutAlpha)
    love.graphics.draw(
        self.image,
        self.x, self.y,
        rad(self.angle + self.weightAngle),
        self.scale, self.scale
    )
    love.graphics.pop()

    if self.debug then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.circle("line", self.x, self.y, 5)
        love.graphics.print(string.format("Angle: %.2f, WeightAngle: %.2f", self.angle, self.weightAngle), self.x + 10, self.y - 10)
        love.graphics.print(string.format("Scale: %.2f", self.scale), self.x + 10, self.y + 10)
        love.graphics.print(string.format("X: %.2f, Y: %.2f", self.x, self.y), self.x + 10, self.y + 40)

        if self.mouseDownX then
            love.graphics.print(string.format("Mouse Down: (%.2f, %.2f)", self.mouseDownX, self.mouseDownY), self.x + 10, self.y + 30)
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.line(self.mouseDownX, self.mouseDownY, self.x, self.y)
            love.graphics.circle("line", self.mouseDownX, self.mouseDownY, 5)
        end
    end

    for i = 1,#self.particlesTable do
        local system = self.particlesTable[i]
        love.graphics.draw(system.ps, system.x, system.y)
    end
  love.graphics.draw(self.clickParticle)
    love.graphics.setColor(lastColor)
end

function cursor:mousepressed(x, y, button)
    if button == 1 then
        self:cloneParticleSystem() -- do the thingy
        self.particlesTable[#self.particlesTable].ps:emit(4) -- make the last created system emit
   --   self.clickParticle:moveTo(self.x,self.y) 
    --  self.clickParticle:start()
     -- self.clickParticle:emit(4)
     -- self.clickParticle:stop()

        if AchievementHandler then AchievementHandler:unlock("left click") end
        self.mouseDownX, self.mouseDownY = x, y

        self:scaleDown()
    end
end

function cursor:mousereleased(x, y, button)
    if button == 1 then
        self.mouseDownX, self.mouseDownY = nil, nil
        self.rotating = false

        self.targetAngle = 0

        self:scaleUp()
    end
end

function cursor:cloneParticleSystem()
    local clone = self.clickParticle:clone()
    clone:start()
    print(clone, self.x, self.y)
    table.insert(self.particlesTable, {ps = clone, x = self.x, y = self.y})

end

function cursor:scaleDown()
    self.tgtScale = 0.3
end

function cursor:scaleUp()
    self.tgtScale = 0.35
end

return cursor
