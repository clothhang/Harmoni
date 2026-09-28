local tabButton = settingsbaseshitthingy:extend("tabButton")

function tabButton:new(name)
    self.name = name

    self.members = {}

    self.x = 0
    self.y = 0

    self.width = States.menu.settingsMenu.tabWidth
    self.height = States.menu.settingsMenu.tabWidth
    
    self.settingsX = 0
    self.settingsBaseY = 0
    self.settingSpacing = 0
    self.settingsWidth = 0
    self.settingsHeight = 0

    self.font = SkinHandler:getFont("Menu", 35)
end

function tabButton:add(member)
    table.insert(self.members, member)
end

function tabButton:remove(member)
    for i, m in ipairs(self.members) do
        if m == member then
            table.remove(self.members, i)
        end
    end
end

function tabButton:mousemoved(x, y)
    for i, member in ipairs(self.members) do
        member:mousemoved(x, y)
    end
    
end

function tabButton:mousepressed(x, y, button)
    local dontContinue = false
    for i, member in ipairs(self.members) do
        dontContinue = member:mousepressed(x, y, button)
        if dontContinue then break end
    end
end

function tabButton:mousereleased(x, y, button)
    for i, member in ipairs(self.members) do
        member:mousereleased(x, y, button)
    end
end

function tabButton:draw()
    love.graphics.setFont(self.font)
    love.graphics.print(self.name, self.x, self.y)


    -- draw the rectangly thingy!!!! :D im sohappy !!
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

function tabButton:getDimensions()
    -- change this when its a normal button in the #future
    return self.width, self.height --self.font:getWidth(self.name), self.font:getHeight()
end

function tabButton:getWidth()
    return self.width
end

function tabButton:getHeight()
    return self.height
end

function tabButton:drawMembers()
    local y = self.settingsBaseY
    for i, member in ipairs(self.members) do
        if not member:isInstanceOf(settingsModeSeperator) then
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", self.settingsX, y, self.settingsWidth, self.settingsHeight)
        end
        y = y + member:draw(self.settingsWidth, self.settingsHeight, self.settingsX, y)
        y = y + self.settingSpacing
    end
end

return tabButton