local maniaJudgement = Class:extend("maniaJudgement")

function maniaJudgement:new(x, y, size, judgementsTable, parent)
    self.parent = parent
    self.x = x or 0
    self.y = y or 0
    self.size = size or 1
    self.judgementsTable = judgementsTable or error("fucking dumbass how do you think the judgements object will work without judgements")
    self.judgements = {}
    self.activeTweens = {}
    self.noStacking = false
end

function maniaJudgement:judge(judgement)
    local image
    for i = 1, #self.judgementsTable do
        if judgement == self.judgementsTable[i].name then
            image = self.judgementsTable[i].image
            break
        end
    end
    if not image then return end

    if AchievementHandler then 
        if judgement == "Perfect" then
            AchievementHandler:unlock("first perfect judge")
        elseif judgement == "Great" then
            AchievementHandler:unlock("first great judge")
        elseif judgement == "Good" then
            AchievementHandler:unlock("first good judge")
        elseif judgement == "Alright" then
            AchievementHandler:unlock("first alright judge")
        elseif judgement == "Awful" then
            AchievementHandler:unlock("first awful judge")
        elseif judgement == "Miss" then
            AchievementHandler:unlock("first miss judge")
        end
    end

    local w, h
    if image.getViewport then
        _, _, w, h = image:getViewport()
    else
        w, h = image:getWidth(), image:getHeight()
    end

    local newJudgement = {
        image = image,
        x = self.x,
        y = self.y,
        width = w,
        height = h,
        timer = 500,
        bumped = false
    }

    if self.noStacking then
        self.judgements = {newJudgement}
    else
        table.insert(self.judgements, newJudgement)
    end

    self:startTween(newJudgement)
end

function maniaJudgement:startTween(j)
    if j.bumped then return end
    j.bumped = true

    local duration = SkinHandler:getParam("Judgement Bump Time")
    local amount = SkinHandler:getParam("Judgement Bump Amount")
    local tweenType = SkinHandler:getParam("Judgement Bump Tween Type")
    local easing = Ease[tweenType] or Ease.linear

    local startY = j.y
    local endY = startY + amount
    local time = 0

    table.insert(self.activeTweens, {
        target = j,
        update = function(dt)
            time = time + dt
            local t = math.min(time / duration, 1)
            j.y = startY + (endY - startY) * easing(t)
            return t >= 1
        end
    })
end

function maniaJudgement:update(dt)
    for i = #self.activeTweens, 1, -1 do
        if self.activeTweens[i].update(dt) then
            table.remove(self.activeTweens, i)
        end
    end

    for i = #self.judgements, 1, -1 do
        local j = self.judgements[i]
        j.timer = j.timer - dt * 1000
        if j.timer <= 0 and not (i == #self.judgements) then
            table.remove(self.judgements, i)
        end
    end
end

function maniaJudgement:draw()
    local judgementBatch = SkinHandler:getBatch("Judgements")

    for i, j in ipairs(self.judgements) do
        local img = j.image
        if not img then goto continue end

        local x, y, size = j.x, j.y, self.size
        local alpha = j.timer / 500
        local isTop = (i == #self.judgements)
        if isTop then alpha = 1 end
        local color = isTop and {1, 1, 1, alpha} or {0.5, 0.5, 0.5, alpha}

        local ox, oy
        if img.getViewport then
            local _, _, w, h = img:getViewport()
            ox, oy = w / 2, h / 2
        else
            ox, oy = img:getWidth() / 2, img:getHeight() / 2
        end

        if judgementBatch then
            judgementBatch:setColor(color)
            judgementBatch:add(img, x, y, 0, size, size, ox, oy)
        else
            love.graphics.setColor(color)
            love.graphics.draw(img, x, y, 0, size, size, ox, oy)
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1)
end

return maniaJudgement
