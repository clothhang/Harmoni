local drumsNote = Class:extend("drumsNote")


PLACEHOLDERdrumsscrollspeed = 2

local noteColors = 
{
    {1,0,0}, -- left
    {0,1,0}, -- down
    {1,1,1}, -- center
    {0,0,1}, -- up
    {0,1,1}, -- down
}



function drumsNote:new(parent, noteDirection, noteTime)
    self.parent, self.noteDirection, self.noteTime = parent, noteDirection, noteTime
    self.x,self.y = 0, self.parent.y+(self.parent.height/2)
    self.radius = (self.parent.height/2) 
    self.hit = false
    self.approachCircle = self.parent.parent.inputField.approachCircles[tonumber(noteDirection)]
    for i, circle in ipairs(self.parent.parent.inputField.approachCircles) do
        print("circle",i)
    end
end

function drumsNote:onHit(judgement)
    -- judgement table has name, time, and absTime
    local judgement = judgement
    self.hit = true
    self.judgement = judgement.name
    self.hitTime = judgement.time
    self.hitColor = judgement.color
    self.hitTimeAbs = judgement.absTime -- yes i know this is unnessary I DONT CARE  probably wont even be used but whatever
    print("HIT")
 --   self:getHitColor()
end

function drumsNote:getPosition()
    self.x = ((self.noteTime - MusicTime) * PLACEHOLDERdrumsscrollspeed) + (baseScreenRatio.x/2)
    self.visible = (self.x - self.radius < baseScreenRatio.x and self.x > 0-self.radius)
end

function drumsNote:update(dt)
    self:getPosition()
end

function drumsNote:getHitColor()
    local judgements = self.parent.parent.judgements
    for _,Judgement in ipairs(judgements) do
        -- we gotta find the color of the judgment corresponding to the one this note was hit with (god i suck at wording things)
        if Judgement.name == self.judgement then self.hitColor = Judgement.color end
    end

end

function drumsNote:draw()
    if not self.visible then return end
    love.graphics.setColor(noteColors[tonumber(self.noteDirection)])
    if self.hitColor then love.graphics.setColor(self.hitColor) end
    love.graphics.circle("fill", self.x, self.y, self.radius)
        love.graphics.setColor(0,0,0)

        local previousLineWidth = love.graphics.getLineWidth()
        love.graphics.setLineWidth(10)
            love.graphics.line(self.x,self.y-self.radius, self.x, self.y+self.radius)

    love.graphics.circle("line", self.x, self.y, self.radius)
    love.graphics.setLineWidth(previousLineWidth)

    love.graphics.setColor(1,1,1)
    if not self.hit and self.noteTime-MusicTime > 0 then self.approachCircle:draw(MusicTime-self.noteTime) end
end

return drumsNote