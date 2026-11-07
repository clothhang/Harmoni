local resultsState = State("resultsState")

function resultsState:enter(s, parent)

   -- State.switch(States.extra.markus)

    self.score = parent.scoreHandler.Scores.trueScore
    self.heighestCombo = 459
    self.performanceRating = parent.scoreHandler.Scores.truePerformanceRating
    
    self.parent = parent
    self.grades = require("modules.gamemodes.mania.maniaGrades")
    self.accuracy = parent.scoreHandler.Scores.trueAccuracy
    self.x, self.y = baseScreenRatio.x / 2, baseScreenRatio.y / 2
    self.width, self.height = 700, 700
    self.rectX, self.rectY = self.x - (self.width / 2), self.y - (self.height / 2)
    self.arcX, self.arcY = self.x, self.y
    self.arcR = 300
    self.rectRC = 90
    self.background = self.parent.background
    self.bump = 1
    self.hitSound = love.audio.newSource("sounds/hit.mp3", "static")     --THIS SOUND IS A PLACEHOLDER
    self.arcLineWidth = 20

    self.printableAccuracy = 0
    

    self.accuracyCircleAngle = (self.printableAccuracy / 100) * 2 * math.pi
    self:tweenArc(self.accuracyCircleAngleFinal)
    self.lastGradeMet = nil
end

function resultsState:update(dt)
    self.rectX, self.rectY = self.x - (self.width / 2), self.y - (self.height / 2)
    self.accuracyCircleAngle = (self.printableAccuracy / 100) * 2 * math.pi

    for i, Grade in ipairs (self.grades) do
        if Grade.accuracy <= self.printableAccuracy and not Grade.hit then
            Grade.hit = true
            self:onGradeReached(Grade.grade)
        end
    end


    if Input:pressed("menuConfirm") then State.switch(States.menu.songSelect) end
end

function resultsState:onGradeReached(grade)
    self.bump = 1.05
    if self.bumpTimer then Timer.cancel(self.bumpTimer) end
    self.bumpTimer = Timer.tween(0.25, self, {bump = 1}, "out-quad")
    self.printableGrade = grade
   -- local hitClone = self.hitSound:clone()
    --hitClone:setPitch(self.printableAccuracy / 100)
    --hitClone:play()

    print(grade)
end

function resultsState:tweenArc(amount)
    Timer.tween(1, self, {printableAccuracy = self.accuracy}, "out-quad", function()
    self:expandRectangle()
        self.printableAccuracy = self.accuracy -- we do this because the fucking tween doesnt get it the whole way for some reason
                                               -- nah it makes sense because floating point precision is lowkey doo-doo butt
    end)
end

function resultsState:moveArcUp(amount)
    Timer.tween(0.3,self, {arcY = self.arcY-amount}, "out-circ")
end

function resultsState:expandRectangle()
    local newHeight = 1112
    local difference = newHeight - self.height
        self:moveArcUp(difference/2)

    Timer.tween(0.3,self,{height = newHeight}, "out-circ")
end

function resultsState:draw()

    self.background:draw()
    love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.scale(self.bump or 1, self.bump or 1)
        love.graphics.translate(-self.x, -self.y)

        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", self.rectX, self.rectY, self.width, self.height, self.rectRC, self.rectRC)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(self.arcLineWidth)

        local function stencilFunc()
            love.graphics.circle("fill", self.arcX, self.arcY, self.arcR - 10)
        end

        love.graphics.stencil(stencilFunc, "replace", 1)
        love.graphics.setStencilTest("less", 1)

        love.graphics.arc("line", self.arcX, self.arcY, self.arcR, -math.pi/2, -math.pi/2 + self.accuracyCircleAngle)
        love.graphics.setStencilTest()

        love.graphics.setFont(SkinHandler:getFont("Menu", 400))
        love.graphics.printf(self.printableGrade or "F", self.arcX-self.arcR, self.arcY-love.graphics.getFont():getHeight()/2, self.arcR*2, "center")
    love.graphics.pop()

        self:drawSmallRectangles()
    self:debugDraw()
end


function resultsState:drawSmallRectangles()
    local function stencilFunc()
        love.graphics.rectangle("fill", self.rectX, self.rectY, self.width, self.height, self.rectRC, self.rectRC)
    end

    love.graphics.stencil(stencilFunc, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    local smallRectHeights = 130
    local smallRectSpacing = 20
   
    local cornerRadius = 70 


    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(SkinHandler:getFont("Menu", 50))
    love.graphics.printf(LocaleHandler:getText("Results", "Score") .. ": " .. self.score,self.rectX+10,(self.arcY+self.arcR+(self.arcLineWidth/2)+smallRectSpacing)+love.graphics.getFont():getHeight()/2,self.width-20,"center")


    love.graphics.setColor(1,1,1)

    -- accuracy 
    love.graphics.printf(LocaleHandler:getText("Results", "Accuracy") .. ": " .. self.accuracy .. "%",self.rectX+10,(self.arcY+self.arcR+(self.arcLineWidth/2)+smallRectSpacing*2)+(smallRectHeights+love.graphics.getFont():getHeight()/2),self.width-20,"center")
    love.graphics.setColor(1,1,1)


    -- pr 
    love.graphics.printf(LocaleHandler:getText("Results", "Performance Rating") .. ": " .. self.performanceRating,self.rectX+10,(self.arcY+self.arcR+(self.arcLineWidth/2)+smallRectSpacing*3)+(smallRectHeights*2+love.graphics.getFont():getHeight()/2),self.width-20,"center")
    love.graphics.setColor(1,1,1)
    love.graphics.setStencilTest()
end

function resultsState:debugDraw()
    love.graphics.setFont(SkinHandler:getFont("Menu", 50))
    love.graphics.print("DEBUG SHIT    :3\n" .. 
                        "Accuracy: " .. self.accuracy .. "\n" .. 
                        "printableAccuracy: " .. self.printableAccuracy,
                        10, 10)
end

return resultsState
