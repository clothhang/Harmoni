local resultsCircle = Class:extend("resultsCircle")

local function remap(value, oldMin, oldMax, newMin, newMax)
    return (value - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin
end

function resultsCircle:setupSparkles()    -- thank you hot particles ur the goat 
                                            --https://love2d.org/forums/viewtopic.php?t=88860
    local image1 = love.graphics.newImage("Images/particles/star.png")
    image1:setFilter("linear", "linear")

    local ps = love.graphics.newParticleSystem(image1, 15)
    ps:setColors(1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 0)
    ps:setDirection(-1.5707963705063)
    ps:setEmissionArea("ellipse", 400, 400, 0, false)
    ps:setEmissionRate(18.494899749756)
    ps:setEmitterLifetime(-1)
    ps:setInsertMode("top")
    ps:setLinearAcceleration(-138.00521850586, 0, 0, -751.36175537109)
    ps:setLinearDamping(0, 0)
    ps:setOffset(16, 16)
    ps:setParticleLifetime(0.62307155132294, 0.76153188943863)
    ps:setRadialAcceleration(166.96928405762, 412.31188964844)
    ps:setRelativeRotation(false)
    ps:setRotation(0, 0)
    ps:setSizes(1.4146923065186, 1.096515750885, 0.5902546882629)
    ps:setSizeVariation(1)
    ps:setSpeed(39.867832183838, 28.544424057007)
    ps:setSpin(-0.17934989929199, 0.65366369485855)
    ps:setSpinVariation(1)
    ps:setSpread(6.2831854820251)
    ps:setTangentialAcceleration(3.4075362682343, 0)

    return ps
end

function resultsCircle:setupLeftConfetti()
    local image1 = love.graphics.newImage("Images/particles/light.png")
    image1:setFilter("linear", "linear")

    local ps = love.graphics.newParticleSystem(image1, 48)
    ps:setColors(1, 0.890625, 0, 0, 0, 1, 0.859375, 1, 0.5234375, 0, 1, 1, 1, 0, 0.984375, 1)
    ps:setDirection(-1.0516501665115)
    ps:setEmissionArea("uniform", 0, 59.281661987305, 0, false)
    ps:setEmissionRate(80.357177734375)
    ps:setEmitterLifetime(0.56413877010345)
    ps:setInsertMode("top")
    ps:setLinearAcceleration(0.45932897925377, 520.62384033203, 0.051036551594734, 541.44677734375)
    ps:setLinearDamping(0.31050637364388, 0.31050637364388)
    ps:setOffset(75, 75)
    ps:setParticleLifetime(4.0770449638367, 4.1288161277771)
    ps:setRadialAcceleration(0, 0)
    ps:setRelativeRotation(false)
    ps:setRotation(-3.1415927410126, 0)
    ps:setSizes(0.76988649368286, 0.53716236352921)
    ps:setSizeVariation(0.76677316427231)
    ps:setSpeed(729.23065185547, 744.74578857422)
    ps:setSpin(1.6669819355011, -2.303195476532)
    ps:setSpinVariation(0.65814697742462)
    ps:setSpread(0.53855872154236)
    ps:setTangentialAcceleration(0, 0)


end



function resultsCircle:new(x,y,percent,callback,delay)
    self.sparkles = self:setupSparkles()
    self.leftConfetti = self:setupLeftConfetti()
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
    self.tween = Timer.tween(3, self, {printablePercent = self.percent}, "in-out-quint", 
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

    self.sparkles:update(dt)
    if self.colorTween then Timer.cancel(self.colorTween) end

    self.colorTween = Timer.tween(0.15, self.fillColor, {[1] = self.targetColor[1], [2] = self.targetColor[2], [3] = self.targetColor[3]})
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

    local printableThing = (self.gradePresented and self.grade.grade) or math.floor(self.printablePercent) .. "%"
    love.graphics.printf(printableThing, self.x-self.emptyImage:getWidth()*(1+self.printablePercentLiquidAssValue)/2, self.y-love.graphics.getFont():getHeight()*(1+self.printablePercentLiquidAssValue)/2, self.emptyImage:getWidth(), "center", nil, 1+self.printablePercentLiquidAssValue, 1+self.printablePercentLiquidAssValue)
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
    love.graphics.setColor(self.fillColor)
    love.graphics.draw(self.fillImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)
   --     love.graphics.rectangle("fill", 0, 0, 2560, 1440)

    love.graphics.setColor(1,1,1)
    love.graphics.setStencilTest()
        love.graphics.draw(self.emptyImage, self.x, self.y, nil, 1, 1, self.emptyImage:getWidth()/2, self.emptyImage:getHeight()/2)

    love.graphics.setBlendMode("add")
    love.graphics.draw(self.sparkles, self.x, self.y-100)


    love.graphics.draw(self.leftConfetti, 0, baseScreenRatio.y-500)


end
 
return resultsCircle


