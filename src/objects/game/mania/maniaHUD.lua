local maniaHUD = Class:extend("maniaHUD")

function maniaHUD:new(parent)
    self.parent = parent
    self.debug = false
    self.fontLarge = SkinHandler:getFont("HUD", 65)
    self.fontSmall = SkinHandler:getFont("HUD", 15)
    self.fontExtraSmall = SkinHandler:getFont("HUD", 12)

    self.font = SkinHandler:getFont("HUD", 160)
    self.debugFont = SkinHandler:getFont("HUD", 70)
    self.grade = "N/A"
end

function maniaHUD:update(dt)
    self.grade = maniaGrades.getGrade(self.scores.trueAccuracy)
end

function maniaHUD:sendValues()  -- will be called every frame (obviously) to pass shit to the hud 

end

function maniaHUD:sendScoreHandlerScores(scoreHandlerScores)
    self.scores = scoreHandlerScores
end

function maniaHUD:draw()
    if self.debug then self:debugDraw() end

    love.graphics.setFont(self.font)

    local scores = self.scores
    local parent = self.parent

    local scoreText = string.format("%.0f", scores.printableScore)

    local accuracyText = "0%"
    if scores.trueAccuracy == 100 then
        accuracyText = "100%"
    elseif scores.trueAccuracy == 0 then
        accuracyText = "0%"
    else
        accuracyText = string.format("%.2f%%", scores.printableAccuracy)
    end

    local prText = string.format("%.2f", scores.truePerformanceRating)
    local ips = #parent.inputsPerSecond
    local nps = #parent.notesPerSecond

    if parent.mods["BP"] then ips = nps end

    local ipsOverNpsText = string.format("%02d/%02d", ips, nps)

    -- lefrt
    love.graphics.printf(scoreText .. "\n" .. ipsOverNpsText, 10, 10, baseScreenRatio.x, "left")

    -- righjt
    love.graphics.printf(prText .. "\n" .. accuracyText .. "\n" .. (self.grade.grade or "N/A"), baseScreenRatio.x - 1000, 10, 990, "right")

   -- love.graphics.printf
end

function maniaHUD:debugDraw()
    love.graphics.setFont(self.debugFont)
    love.graphics.setColor(1,1,0)
    love.graphics.print("DEBUG SHIT" .. "\n"
                    .. "SCORE: " .. self.scores.trueScore .. "\n"
                    .. "ACCURACY: " .. self.scores.trueAccuracy .. "\n"
                    .. "PERFORMANCE RATING: " .. self.scores.truePerformanceRating .. "\n"
                    .. "DIFFICULTY RATING: " .. self.scores.difficultyRating,
                    100,100
    )

    love.graphics.setColor(1,1,1)
end

return maniaHUD