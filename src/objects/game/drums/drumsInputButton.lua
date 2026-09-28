local drumsInputButton = Class:extend("drumsInputButton")

local noteColors = 
{
    {1,0,0}, -- left
    {0,1,0}, -- down
    {1,1,1}, -- center
    {0,0,1}, -- up
    {0,1,1}, -- down
}



function drumsInputButton:new(parent,x,y,direction,radius)
    self.parent,self.x,self.y,self.direction,self.radius = parent,x,y,direction,radius
    self.judgements = require("modules.gamemodes.drums.drumsJudgements")

end

function drumsInputButton:onClick()
    print("drumsInputButton:onClick()")
    -- we need to check all notes and see if we hit one that matches this button's direction (lane) and the note is actually within hit timings 
    local notes = self.parent.parent.lane.hitObjects -- dont wanna type all that every time

    for i, Note in ipairs(notes) do
        if Note.visible then  -- we shouldnt check this for every note, that would be slow, just check ones that are on the screen
            print(i, type(Note.noteDirection), type(self.direction))
            if tonumber(Note.noteDirection) == tonumber(self.direction) and not Note.hit then -- first we make sure the note even corresponds do this button and hasnt already been hit
                print("HAIII")
                local judgement = self:checkJudgement(Note)
                if judgement then
                    -- we hit the note, we need to run the hit function for that note
                    Note:onHit(judgement)
                    break -- we hit the note, we dont need to keep going
                end
            end
        end
    end


end

function drumsInputButton:checkJudgement(note)
    local Note = note
    local judgement = nil -- set this to nil so we can check if this returns nil
    for i, Judgement in ipairs(self.judgements) do
        if math.abs(MusicTime - Note.noteTime) <= Judgement.timing then
            judgement = {name = Judgement.name, time = MusicTime - Note.noteTime, absTime = math.abs(MusicTime - Note.noteTime), color = Judgement.colorTEMP}
            break -- break cuz we found it
        end
    end
    return judgement
end

function drumsInputButton:update(dt)
end

function drumsInputButton:draw()
    love.graphics.setColor(noteColors[tonumber(self.direction)])
    love.graphics.circle("fill", self.x,self.y,self.radius)
    love.graphics.setColor(1,1,1)
end

return drumsInputButton