local drumsLane = Class:extend("drumsLane")

function drumsLane:new(parent, chart)
    self.parent, self.notes = parent, chart.hitObjects


    self.hitObjects = {}

    print(#chart.hitObjects)
    self.width, self.height = baseScreenRatio.x, 197
    self.x, self.y = 0, 1074

    self.missTime = self.parent.judgements[4].timing -- used for checking for misses


    self.receptor = drumsReceptor(self)

    self:setUpNotes()
end

function drumsLane:setUpNotes()
    for _, Note in ipairs(self.notes) do
        print("DRUMS NOTE",Note.type, Note.lane, Note.startTime)
        table.insert(self.hitObjects,drumsNote(self, Note.lane, Note.startTime))
    end
    
end

function drumsLane:checkForMisses()   -- SUPER hacky solution but whatever lol!!
    -- all this needs to do is check the first not hit note, if its MusicTime-noteTime is less than -missTime, then its a miss
    for _,Note in ipairs(self.hitObjects) do
        if not Note.hit then
            if Note.noteTime-MusicTime < -self.missTime then
                Note:onHit({name = "Miss", time = Note.noteTime-MusicTime, color = {0,0,0}})
                break
            end
        end
    end
end

function drumsLane:update(dt)
    for _, Note in ipairs(self.hitObjects) do
        Note:update(dt)
    end
    self:checkForMisses()
    self.receptor:update(dt)
end

function drumsLane:draw()
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    for _, Note in ipairs(self.hitObjects) do
        Note:draw()
    end
    self.receptor:draw()
end

return drumsLane