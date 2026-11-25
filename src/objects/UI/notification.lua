local notification = Class:extend("notification")

function notification:new(x,y,width,height,text,type)
    self.x = x
    self.y = y
    self.width = width
    self.text = text or "Ignore me! I'm not supposed to show up!"
    self.height = height
    self.timer = 5
    self.images = {
        ["error"] = love.graphics.newImage("images/UI/error.png"),
        ["warning"]  = love.graphics.newImage("images/UI/warning.png"),
        ["info"] = love.graphics.newImage("images/UI/info.png")
    }

    self.colors = {
        ["error"] = rgb({208,52,54}),
        ["warning"] = rgb({239,189,20}),
        ["info"] = rgb({28,130,195})
    }

    if self.colors[type] then self.color = self.colors[type] end
    if self.images[type] then self.image = self.images[type] end

end

function notification:update(dt)
    self.timer = self.timer - dt
end

function notification:setupColorAndImage(type) -- yes i know i could use a table for this but i dont want to
    if type == "error" then
        self.color = {}
    elseif type == "warning" then
        self.color = {1,1,0}
    elseif type == "info" then
        self.color = {1,1,1}
    elseif type == "success" then  -- what the fuck was this planned for
        self.color = {0,1,0}
    else
        self.color = {1,1,1}
    end
end

function notification:draw()
    self.color[4] = 1
    love.graphics.setColor(self.color)
    local function stencilShape()
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4,4)
    end
    love.graphics.stencil(stencilShape, "replace", 1)

    love.graphics.setStencilTest( "greater", 0)
    -- first we draw te background

    love.graphics.setColor(0,0,0,0.7)  -- we do this to darken the background a bit
    love.graphics.rectangle("fill",self.x, self.y, self.width, self.height)
    self.color[4] = 0.75
    love.graphics.setColor(self.color)
    local oldLineWidth = love.graphics.getLineWidth()
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line",self.x, self.y, self.width, self.height)
    love.graphics.setLineWidth(oldLineWidth)

    -- the we draw the tiny rectangle on the left
    self.color[4] = 1
    love.graphics.setColor(self.color)

    love.graphics.rectangle("fill",self.x, self.y, 10, self.height)

    -- now we draw the text 
    love.graphics.setColor(1,1,1,1)
    local textX, textY = self.x + 15, self.y + self.height / 2 - love.graphics.getFont():getHeight() / 2
    love.graphics.printf(self.text, textX, textY, self.width - 15, "left")

    -- then the image
    -- we gotta make the colors brighter for the icons to look good 
    for i = 1,#self.color do
        self.color[i] = self.color[i] + 0.3
    end
    love.graphics.setColor(self.color)
    for i = 1,#self.color do
        self.color[i] = self.color[i] - 0.3  -- undo that bullshit
    end

    if self.image then love.graphics.draw(self.image, self.x + (self.width-self.image:getWidth()), self.y) end

    -- now we draw the time bar
    love.graphics.setColor(0.9,0.9,0.9)
    love.graphics.rectangle("fill", self.x, self.y+self.height-3, self.width*(self.timer/5), 2)

    love.graphics.setColor(1,1,1)
    love.graphics.setStencilTest()
end

return notification
