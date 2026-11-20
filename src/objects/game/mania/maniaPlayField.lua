local maniaPlayField = Class:extend("maniaPlayField")

function maniaPlayField:new(chart, parent)
    self.parent = parent
    self.chart = chart
    self.laneYOffset = Settings:getValue("Skin", "Mania", "Lane Height") -- ?? Right??
    self.lanes = {}
    self.svMarks = {}
    self.scrollSpeedFactors = chart.scrollSpeedFactors or {}
    self.finished = false
    self.svIndex = 1
    self.sfIndex = 1
    self.currentTime = 0
    self.endNoteTime = 0
    self.totalNotes = 0
    self.laneSpacing = 200
    self.offset = { x = 0, y = 0 }
    self.id = 1
    self.inputAllowed = true

    if #self.chart.scrollVelocities > 0 then
        local svs = self.chart.scrollVelocities
        self.svMarks = {}
        local initialSV = self.chart.meta.initialSV or 1

        local position = svs[1].startTime * initialSV
        self.svMarks[1] = position
        for i = 2, #svs do
            local multiplier = svs[i - 1].multiplier
            if not multiplier or multiplier ~= multiplier then
                multiplier = 0
            end
            position = position + ((svs[i].startTime - svs[i - 1].startTime) * multiplier)
            self.svMarks[i] = position
        end
    end

    local mode = tonumber(self.chart.meta.laneCount)

    for laneIndex = 1, mode do
        local hitObjects = {}

        for _, hitObj in ipairs(self.chart.hitObjects) do
            if laneIndex == hitObj.lane then
                table.insert(hitObjects, {
                    type = hitObj.type,
                    startTime = hitObj.startTime,
                    endTime = hitObj.endTime,
                    initialSVTime = self:getPositionFromTime(hitObj.startTime),
                    initialSVEndTime = hitObj.endTime and self:getPositionFromTime(hitObj.endTime) or nil
                })

                local noteEndTime = hitObj.startTime
                if hitObj.endTime and hitObj.endTime > noteEndTime then
                    noteEndTime = hitObj.endTime
                end
                if noteEndTime > self.endNoteTime then
                    self.endNoteTime = noteEndTime
                end
                print(noteEndTime)
            end
        end

        table.insert(self.lanes, maniaLane(mode, laneIndex, self.laneSpacing, self.laneYOffset, hitObjects, self))
    end

    if self.endNoteTime == 0 then
        self.endNoteTime = self.parent.song:getDuration() * 1000
    end
end

function maniaPlayField:gameOver()
    for _, lane in ipairs(self.lanes) do
        lane:gameOver()
    end
end

function maniaPlayField:getPositionFromTime(time, index)
    local svs = self.chart.scrollVelocities
    local initialSV = self.chart.meta.initialSV or 1

    if #svs == 0 then
        return time * initialSV
    end

    if index == -1 or not index then
        index = 1
        while index <= #svs and svs[index].startTime <= time do
            index = index + 1
        end
    end

    if index == 1 then
        return time * initialSV
    end

    index = index - 1

    if index < 1 or index > #self.svMarks then
        return time * initialSV
    end

    local curPos = self.svMarks[index]
    local multiplier = svs[index].multiplier
    if not multiplier or multiplier ~= multiplier then
        multiplier = 0
    end
    curPos = curPos + ((time - svs[index].startTime) * multiplier)

    return curPos
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function maniaPlayField:getScrollSpeedFactorFromTime(time)
    if self.sfIndex < 1 or self.sfIndex >= #self.chart.scrollSpeedFactors then
        self.sfIndex = 1
    end

    local sf = self.chart.scrollSpeedFactors[self.sfIndex] or {startTime = 0, multiplier = 1}
    if self.sfIndex == #self.chart.scrollSpeedFactors or time < sf.startTime then
        return sf.multiplier or 1
    end

    local nextSf = self.chart.scrollSpeedFactors[self.sfIndex + 1]
    if not nextSf then return sf.multiplier or 1 end

    return lerp(sf.multiplier or 1, nextSf.multiplier or 1,
        (time - sf.startTime) / (nextSf.startTime - sf.startTime))
end

function maniaPlayField:update(dt)
    while (self.svIndex <= #self.chart.scrollVelocities and
           MusicTime >= self.chart.scrollVelocities[self.svIndex].startTime) do
        self.svIndex = self.svIndex + 1
    end

    while (self.sfIndex <= #self.chart.scrollSpeedFactors and
           MusicTime >= self.chart.scrollSpeedFactors[self.sfIndex].startTime) do
        self.sfIndex = self.sfIndex + 1
    end

    self.currentTime = self:getPositionFromTime(MusicTime, self.svIndex)

    self.totalNotes = 0
    self.finished = true
    for _, lane in ipairs(self.lanes) do
        lane:update(dt, self.currentTime)
        if not lane.empty then self.finished = false end
        self.totalNotes = self.totalNotes + #lane.notes
        if not lane.empty then self.finished = false end
    end

  --  if MusicTime > self.endNoteTime then
   --     self.finished = true
   -- end
end

function maniaPlayField:draw()
    love.graphics.push()
    love.graphics.translate(self.offset.x, self.offset.y)
    for _, lane in ipairs(self.lanes) do
        lane:draw()
    end
    love.graphics.pop()
end

return maniaPlayField
