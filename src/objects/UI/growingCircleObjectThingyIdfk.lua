local circleThing = Class:extend("growingCircleObjectThingyIdfk")

--this thingy wont have any arguments i dont think cuz like,,,it just wont ok?
function circleThing:new()
    self.thingies = {self:setUpAThingy()}   -- i made this a table for no fucking reason
    self.circles = {}
    self.time = 0
    --self:doShit(1)
    Timer.after(love.math.random(1,2), function() self:doShit(love.math.random(1,3)) end)
    self.colors = SkinHandler:getRandomColors()
    self.debug = false
end

function circleThing:setUpAThingy()
    --first we gotta figure out the start and end positions (these will just be random y positions on the far left and far right edges)
    local startPos, endPos = {0, love.math.random(0,baseScreenRatio.y)}, {baseScreenRatio.x, love.math.random(0,baseScreenRatio.y)}
    -- now we choose a random point literally anywhere on the screen for the control thingy for the curve thingy
    local controlPoint = {love.math.random(0,baseScreenRatio.x), love.math.random(0, baseScreenRatio.y)}
    -- now we make the curve thingy 
    local curve = love.math.newBezierCurve(startPos[1], startPos[2], controlPoint[1], controlPoint[2], endPos[1], endPos[2])
    return({startPos = startPos, endPos = endPos, controlPoint = controlPoint, curve = curve, theThingItselfPos = startPos, time = 0, lastCircleThingy = 0})
end

function circleThing:setUpACircle(x,y)
    local x,y = x,y
    local width = 20
    local size = 0
    local targetSize = 100
    local targetWidth = 0  -- why did i type it like this i could have just put those in the table lmao, too late im not changing it
    local color = self.colors[love.math.random(1,#self.colors)]
    return {x = x, y = y, width = width, size = size, targetSize = targetSize, targetWidth = targetWidth, color = color}
end

function circleThing:doShit(time)
    self.thingies = {self:setUpAThingy()}
    self.time = 0
    Timer.tween(time, self, {time = 1}, "linear", function() Timer.after(love.math.random(1,2), function() self:doShit(love.math.random(1,3)) end) end)   -- this is fucking gross 
end

function circleThing:update(dt)
    for i, Thingies in ipairs(self.thingies) do
        Thingies.theThingItselfPos[1], Thingies.theThingItselfPos[2] = Thingies.curve:evaluate(Thingies.time)
        Thingies.time = self.time
        -- now we check if its time to make a circle thingy
        -- we just see if we have gone some amount of pixels since last one (yes i know this isnt actually good since it doesnt take Y into account but i dont care (what i mean is that i am too stupid to figure that out))
        if math.abs(Thingies.theThingItselfPos[2] - Thingies.lastCircleThingy) > 100 then
            Thingies.lastCircleThingy = Thingies.theThingItselfPos[2]
            table.insert(self.circles, self:setUpACircle(Thingies.theThingItselfPos[1], Thingies.theThingItselfPos[2]))
        end
    end
    self:raiseACircleRobloxNoWay()
end


function circleThing:raiseACircleRobloxNoWay()
    for i, Circle in ipairs(self.circles) do
        if math.abs(Circle.targetSize - Circle.size) < 1 then table.remove(self.circles, i); break end
        if not Circle.raised then  -- yep we are just gonna try every frame  #lol  (i fucking suck at programming)
            Circle.raised = true
            Timer.tween(1, Circle, {size = Circle.targetSize, width = Circle.targetWidth}, "out-quad")
        end
    end
end

function circleThing:draw()
    if self.debug then
        for i, Thingies in ipairs(self.thingies) do
            love.graphics.line(Thingies.curve:render())
            love.graphics.circle("fill", Thingies.theThingItselfPos[1], Thingies.theThingItselfPos[2], 20)
        end

    end
    for i, Circle in ipairs(self.circles) do
        local originalLineWidth = love.graphics.getLineWidth()
        love.graphics.setLineWidth(Circle.width)
        love.graphics.setColor(Circle.color)
        love.graphics.circle("line", Circle.x, Circle.y, Circle.size)
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(originalLineWidth)
    end
end

return circleThing