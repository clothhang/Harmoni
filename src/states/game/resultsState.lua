local resultsState = State("resultsState")

local function standardDeviance(t)
    local mean = 0

    for i = 1, #t do
        mean = mean + t[i]
    end

    mean = mean / #t

    local variance = 0

    for i = 1, #t do
        local difference = t[i] - mean
        variance = variance + difference * difference
    end

    variance = variance / #t

    return math.sqrt(variance)
end

local function mean(t)
    local mean = 0

    for i = 1, #t do
        mean = mean + t[i]
    end

    mean = mean / #t
    return mean
end


function resultsState:enter(s, parent)


    love.audio.stop()
    self.parent = parent
    self.background = parent.background or sharedBackground("Images/burgerr.jpg", 0.5, 1)
    self.upperBackground = (self.parent.background and self.parent.background.image) or love.graphics.newImage("Images/burgerr.jpg")

    self.upperBackgroundCanvas = love.graphics.newCanvas(baseScreenRatio.x, baseScreenRatio.y)
    self.upperBackgroundAlpha = 1


  --  self.resultsCircle = resultsCircle(716,720,100)
    self.resultsCircle = resultsCircle(baseScreenRatio.x/2,720,self.parent.scoreHandler.Scores.trueAccuracy or 100, function() self:theThingAfterTheCircleIDK() end, 1)

    self.cornerRadius = 7

    self.stats = {
        {text = LocaleHandler:getText("Results", "Stats"), value =""},
        {text = LocaleHandler:getText("Results", "Accuracy"), value = string.format("%.2f%%",self.parent.scoreHandler.Scores.trueAccuracy)},
        {text = LocaleHandler:getText("Results", "Max Combo"), value = ":3"},
        {text = LocaleHandler:getText("Results", "Score"), value = string.format("%.0f", self.parent.scoreHandler.Scores.trueScore)},
        {text = LocaleHandler:getText("Results", "Rating"), value = string.format("%.2f",self.parent.scoreHandler.Scores.truePerformanceRating)},
        {text = LocaleHandler:getText("Results", "Standard Deviation"), value = string.format("%.2f",standardDeviance(self.parent.hits)).." ms"},
        {text = LocaleHandler:getText("Results", "Mean"), value = string.format("%.2f",mean(self.parent.hits)).." ms"}
    }

    self.judge = {
        {text = LocaleHandler:getText("Results", "Judgements")},
        {text = self.parent.judgementCount.judgements[1].name, value = self.parent.judgementCount.judgements[1].count},
        {text = self.parent.judgementCount.judgements[2].name, value = self.parent.judgementCount.judgements[2].count},
        {text = self.parent.judgementCount.judgements[3].name, value = self.parent.judgementCount.judgements[3].count},
        {text = self.parent.judgementCount.judgements[4].name, value = self.parent.judgementCount.judgements[4].count},
        {text = self.parent.judgementCount.judgements[5].name, value = self.parent.judgementCount.judgements[5].count},
        {text = self.parent.judgementCount.judgements[6].name, value = self.parent.judgementCount.judgements[6].count},
    }
end


function resultsState:theThingAfterTheCircleIDK()
    Timer.tween(0.15, self.resultsCircle, {x = 716}, "out-expo", function() 
        Timer.after(0.2, function()
            print(type(upperBackgroundAlpha))
            Timer.tween(0.15, self, {upperBackgroundAlpha = 0})
        end)
    end)
end

function resultsState:update(dt)
    self.resultsCircle:update(dt)
    self.background:update(dt)
end

function resultsState:draw()
    if self.background then self.background:draw() end




    --table stuff
    local font = SkinHandler:getFont("Menu", 45)
    love.graphics.setFont(font)
    local currentLineWidth = love.graphics.getLineWidth()
    local thickLine = 8
    local tec = 7 -- 7 cuz 6 judgements plus the label at the top
    local tx,ty,tw,th = 1431, 308, 824, 824
    local tc = tw/2+tx
    local teh = th/tec

    local leftSide
    local rightSide

    local function drawTableLine(y, width)
        local x1,x2 = tx, tx+tw
        love.graphics.setLineWidth(width)
        love.graphics.line(x1,y,x2,y)
        love.graphics.setLineWidth(currentLineWidth)
    end

    local function setupTablePositionsThingsIdk()
        leftSide = {}
        rightSide = {}
        for i = 1,tec do
            table.insert(leftSide, {x = tx, y = ty+((i)*teh), w = tw/2, h = teh})
            table.insert(rightSide, {x = tx+tw/2, y = ty+((i)*teh), w = tw/2, h = teh})
        end
    end

    setupTablePositionsThingsIdk()


    love.graphics.setLineWidth(thickLine)
    love.graphics.rectangle("line", tx, ty, tw, th, self.cornerRadius, self.cornerRadius)
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", tx, ty, tw, th, self.cornerRadius, self.cornerRadius)
    love.graphics.setColor(1,1,1)
    love.graphics.line(tc,ty,tc,ty+th)
    love.graphics.setLineWidth(currentLineWidth)
    for i = 1,tec do
        local y = ty+((i-1)*teh)
        if i >1 then drawTableLine(y, i == 2 and thickLine or currentLineWidth) end
    end

    for i = 1,#self.stats do
        local text
        if i == 1 then
            text = self.stats[i].text
        else
            text = self.stats[i].text .. ": " .. self.stats[i].value
        end
        love.graphics.printf(text, leftSide[i].x, leftSide[i].y-(teh/2)-(font:getHeight()/2), leftSide[i].w, "center")
    end

    for i = 1,#self.judge do
        local text
        if i == 1 then
            text = self.judge[i].text
        else
            text = self.judge[i].text .. ": " .. self.judge[i].value
        end
        love.graphics.printf(text, rightSide[i].x, leftSide[i].y-(teh/2)-(font:getHeight()/2), rightSide[i].w, "center")
    end




    -- upper background (covers the table and shit so i can fake those fading in)
    local prevCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas({self.upperBackgroundCanvas,stencil = true})
        love.graphics.draw(
            self.upperBackground,
            0, 0,
            nil,
            baseScreenRatio.x/self.upperBackground:getWidth(),
            baseScreenRatio.y/self.upperBackground:getHeight()
        )
        love.graphics.setColor(0,0,0,(gameplayBackgroundDim or 0.5))
        love.graphics.rectangle("fill",0,0,baseScreenRatio.x,baseScreenRatio.y)

    love.graphics.setCanvas({prevCanvas, stencil = true})
    love.graphics.setColor(1,1,1,self.upperBackgroundAlpha)
    love.graphics.draw(self.upperBackgroundCanvas)

    love.graphics.setColor(1,1,1)

    -- circle

    self.resultsCircle:draw()
end

return resultsState