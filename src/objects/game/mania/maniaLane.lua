local maniaLane = Class:extend("maniaLane")

function buildLanePositions(count)
    local positions = {}

    local center = (count + 1) / 2
    for i = 1, count do
        local offset = i - center
        positions[i] = (baseScreenRatio.x)/2 + offset * (maniaNoteSize + Settings:getValue("Skin", "Mania", "Lane Spacing"))
    end

    return positions
end

function getPositionFromLane(count, id)
    local center = (count + 1) / 2
    local offset = id - center
    return (baseScreenRatio.x)/2 + offset * (maniaNoteSize + Settings:getValue("Skin", "Mania", "Lane Spacing"))
end

function maniaLane:new(mode, laneIndex, spacing, yOffset, hitObjects, parent)
    self.maniaMode = mode
    self.maniaLane = laneIndex
    self.spacing = spacing
    self.yOffset = yOffset
    self.hitObjects = hitObjects
    self.parent = parent
    self.notes = {}
    self.drawableNotes = {}
    self.empty = false

    self.inputBind = maniaInputs[mode][self.maniaLane]

    self.x = getPositionFromLane(tonumber(self.parent.chart.meta.laneCount), self.maniaLane)
    self.y = self.yOffset

    self:setUpHitObjects(self.hitObjects)
    self:setUpReceptor()
end

function maniaLane:setUpReceptor()
    self.receptor = maniaReceptor(self.maniaMode, self.maniaLane, self.inputBind, self.x, self.y, self)
end

function maniaLane:setUpHitObjects(hitObjects)
    for _, hitObject in ipairs(hitObjects) do
        if hitObject.type == "note" then
            table.insert(self.notes, maniaNote(
                hitObject.startTime,
                hitObject.endTime,
                self.maniaLane,
                self.maniaMode,
                hitObject.initialSVTime,
                hitObject.initialSVEndTime,
                self
            ))
        end
    end
end

function maniaLane:update(dt)
    while #self.notes > 0 and self:isOnScreen(self.notes[1]) do
        table.insert(self.drawableNotes, table.remove(self.notes, 1))
    end

    for _, note in ipairs(self.drawableNotes) do
        note:update(dt)
    end

    self.receptor:update(dt)
    self:handleInput()
    self:checkHoldReleases()
    self:checkForMisses()

    self.empty = (#self.notes == 0 and #self.drawableNotes == 0)

    self.receptor.y = self.y
end

function maniaLane:gameOver()
    for _, note in ipairs(self.drawableNotes) do
        note:gameOver()
    end
end

function maniaLane:isOnScreen(note)
    return note.startTime - MusicTime <= 10000
end

function maniaLane:handleInput()
    if not Input then return end -- why would input be nil???????????
    if self.parent.parent.paused then return end
    
    if not self.parent.parent.mods["BP"] then
        if not Input:pressed(self.inputBind) then return end
    end
    if self.parent.id == 1 then
        table.insert(self.parent.parent.inputsPerSecond, 1000)
    end

    local bestJudgement = nil
    local bestTimeDiff = math.huge
    local note = self.drawableNotes[1]
    if not note then return end

    local timeDiff = math.abs(MusicTime - note.startTime)

    if not self.parent.parent.mods["BP"] then
        for _, judgement in ipairs(mania.judgements) do
            if timeDiff <= judgement.timing and timeDiff < bestTimeDiff then
                bestTimeDiff = timeDiff
                bestJudgement = judgement
            end
        end
    else
        local judgement = mania.judgements[1] -- should always be perfect
        if timeDiff <= judgement.timing and timeDiff < bestTimeDiff and not note.botplayhit then
            bestTimeDiff = timeDiff
            bestJudgement = judgement
            note.botplayhit = true
        end
    end

    if bestJudgement then
        local state = self.parent.parent
        if not note.holdLength then
            table.remove(self.drawableNotes, 1)
            table.insert(self.parent.parent.notesPerSecond, 1000)
        else
            note.held = true
            note.holdStartTime = MusicTime
        end

        if self.parent.id == 1 then
            state.judgementObject:judge(bestJudgement.name)
            state.judgementCount:incrementJudgement(bestJudgement.name)
            if bestJudgement.name == "Miss" then self.parent.parent.comboCount:breakCombo() end -- pretty self explanitory, huh?

            state.scoreHandler:addScore(bestJudgement.score)
            local healthChange

            if self.parent.parent.mods["EZ"] and bestJudgement.name == "Miss" then
                healthChange = bestJudgement.health/2   -- i have no clue if this works or not honestly
            else
                healthChange = bestJudgement.health
            end

        --if self.parent.parent.mods["SD"] and bestJudgement.name == "Miss" then state.healthBar:justFuckingDie() end

            state.healthBar:changeHealth(healthChange)

            if AchievementGranter then AchievementGranter:noteHit() end
            state.comboCount:incrementCombo()
            if bestJudgement.name == ("Perfect" or "Great") then self.receptor:emitParticles(); print(bestJudgement.name) end
            table.insert(self.parent.parent.hits, MusicTime - note.startTime)  -- the thing that keeps up with note hit times idk
            if state.comboCount:getCombo()%100 == 0 then state.comboAlert:doComboAlert(state.comboCount:getCombo()) end
        end
    end
end

function maniaLane:checkHoldReleases()
    if not Input then return end

    if not self.parent.parent.mods["BP"] and self.parent.inputAllowed then
        if not Input:released(self.inputBind) then return end
    end

    for i = #self.drawableNotes, 1, -1 do
        local note = self.drawableNotes[i]

        if note.holdLength and note.held and not note.released then
            local releaseDiff = math.abs(MusicTime - note.endTime)

            local bestJudgement = nil
            local bestDiff = math.huge

            if self.parent.parent.mods["BP"] then
                if math.abs(MusicTime - note.endTime) <= mania.judgements[1].timing then
                    bestDiff = releaseDiff
                    bestJudgement = mania.judgements[1]
                end
            else

                for _, judgement in ipairs(mania.judgements) do
                    local holdWindow = judgement.timing * 1.5
                    if judgement.name == "Miss" then
                        holdWindow = judgement.timing
                    end
                    if releaseDiff <= holdWindow and releaseDiff < bestDiff then
                        bestDiff = releaseDiff
                        bestJudgement = judgement
                    end
                end

            end
            --if bestJudgement then
                note.held = false
                note.released = true
                table.remove(self.drawableNotes, i)

                -- Uncomment this block to enable hold note release judgements -Guglio       no
                --[[
                local parentParent = self.parent.parent
                parentParent.comboCount:incrementCombo()
                parentParent.judgementObject:judge(bestJudgement.name)
                state.judgementCount:incrementJudgement(bestJudgement.name)
                parentParent.healthBar:changeHealth(bestJudgement.health)
                --]]
                
            --end
        end
    end
end

function maniaLane:checkForMisses()
    local missJudgement = nil
    for _, judgement in ipairs(mania.judgements or {}) do
        if judgement.name == "Miss" then
            missJudgement = judgement
            break
        end
    end

    if not missJudgement then return end

    local currentTime = MusicTime
    local timingWindow = missJudgement.timing

    for i = #self.drawableNotes, 1, -1 do
        local note = self.drawableNotes[i]

        if not note.holdLength and currentTime - note.startTime > timingWindow then
            table.remove(self.drawableNotes, i)
            if self.parent.id == 1 then
                local parentParent = self.parent.parent
                parentParent.comboCount:breakCombo()
                parentParent.judgementObject:judge("Miss")
                parentParent.judgementCount:incrementJudgement("Miss")

                parentParent.scoreHandler:addScore(missJudgement.score)
                parentParent.healthBar:changeHealth(missJudgement.health)
            end
        end

        if note.holdLength and not note.released and not note.held then
            if currentTime > note.endTime + 100 then
                table.remove(self.drawableNotes, i)
                note.held = false
                note.released = true

                if self.parent.id == 1 then
                    local parentParent = self.parent.parent
                    parentParent.comboCount:breakCombo()
                    parentParent.judgementObject:judge("Miss")
                    parentParent.judgementCount:incrementJudgement("Miss")
                    parentParent.scoreHandler:addScore(missJudgement.score)
                    parentParent.healthBar:changeHealth(missJudgement.health)
                end
            end
        end
    end
end

local function msToMulti(speed)
    return baseScreenRatio.y / speed
end

function maniaLane:draw()
    if States.game.gameModeManager.gameMode.ableToModscript then
        local pos = SongScript:getPos(0, 0, 0, States.game.gameModeManager.gameMode.bpmHandler.fullBeatTime, self.maniaLane, self.parent.id)
        SongScript:updateObject(States.game.gameModeManager.gameMode.bpmHandler.fullBeatTime, self.receptor, pos, self.parent.id)
        self.receptor.x, self.receptor.y = pos.x, pos.y
        self.receptor.z = pos.z * 200
    end
    self.receptor:draw()
    local scrollSpeed = Settings:getValue("Gameplay", "Mania", "Scroll Speed")
    local multiplier = msToMulti(scrollSpeed)
    for _, note in ipairs(self.drawableNotes) do
        if States.game.gameModeManager.gameMode.ableToModscript then
            local vis = -((MusicTime - note.startTime) * multiplier)
            if not note.moveWithScroll then
                vis = 0
            end
            local pos = SongScript:getPos(note.startTime, vis, note.startTime - MusicTime, 
                States.game.gameModeManager.gameMode.bpmHandler.fullBeatTime, note.lane, self.parent.id, note, {}, Point()
            )
            SongScript:updateObject(States.game.gameModeManager.gameMode.bpmHandler.fullBeatTime, note, pos, self.parent.id)
            note.x, note.y = pos.x, pos.y
            note.z = pos.z * 200
            --[[ if note.holdLength then
                local vis = -((MusicTime - note.endTime) *multiplier)
                local pos2 = SongScript:getPos(note.startTime, vis, note.endTime - MusicTime, 
                    States.game.gameModeManager.gameMode.bpmHandler.fullBeatTime, note.data, self.id, note.children[1], {}
                )
            end ]]
        end
        note:draw()
    end
end

return maniaLane
