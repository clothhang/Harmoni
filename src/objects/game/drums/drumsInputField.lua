local drumsInputField = Class:extend("drumsInputField")


TEMPSKINBUTTONSIZE = 115
TEMPSKINBUTTONSEPERATION = 15

function drumsInputField:new(parent,x,y,width,height)
    self.parent,self.x ,self.y,self.width,self.height = parent,x,y,width,height

    
    self.buttons = self:setUpInputButtons()  
    self.approachCircles = self:setUpApproachCircles()

    
end

function drumsInputField:setUpInputButtons()
    local buttons = {}
    -- uh we gotta do shit here idk
    -- first we'll make the center so we can just create the others based on the center's location
    --find the center of the input field
    local centerX, centerY = self.width/2 + self.x, self.height/2 + self.y
    local x,y = centerX, centerY -- just so the code is consistent 
        --left
    local x,y = centerX - (TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2), centerY
    table.insert(buttons, drumsInputButton(self, x,y,4, TEMPSKINBUTTONSIZE/2))
        --down
    local x,y = centerX, centerY + TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2
    table.insert(buttons, drumsInputButton(self, x,y,2, TEMPSKINBUTTONSIZE/2))
        --center
    table.insert(buttons, drumsInputButton(self, centerX, centerY, 3, TEMPSKINBUTTONSIZE/2))
        -- up
    local x,y = centerX , (centerY - (TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2))
    table.insert(buttons, drumsInputButton(self, x,y,1, TEMPSKINBUTTONSIZE/2))
        --right
    local x,y = centerX + (TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2), centerY
    table.insert(buttons, drumsInputButton(self, x,y,5, TEMPSKINBUTTONSIZE/2))
    return buttons
end

function drumsInputField:setUpApproachCircles()
    local circles = {}
    -- uh we gotta do shit here idk
    -- first we'll make the center so we can just create the others based on the center's location
    --find the center of the input field
    local centerX, centerY = self.width/2 + self.x, self.height/2 + self.y
    local x,y = centerX, centerY -- just so the code is consistent 
        --left
    local x,y = centerX - (TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2), centerY
    table.insert(circles, drumsApproachCircle(self, x,y, TEMPSKINBUTTONSIZE/2))
        --down
    local x,y = centerX, centerY + TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2
    table.insert(circles, drumsApproachCircle(self, x,y, TEMPSKINBUTTONSIZE/2))
        --center
    table.insert(circles, drumsApproachCircle(self, centerX, centerY, 3, TEMPSKINBUTTONSIZE/2))
        -- up
    local x,y = centerX , (centerY - (TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2))
    table.insert(circles, drumsApproachCircle(self, x,y, TEMPSKINBUTTONSIZE/2))
        --right
    local x,y = centerX + (TEMPSKINBUTTONSEPERATION + TEMPSKINBUTTONSIZE/2*2), centerY
    table.insert(circles, drumsApproachCircle(self, x,y, TEMPSKINBUTTONSIZE/2))
    return circles
end

function drumsInputField:update(dt)
    for i, Button in ipairs(self.buttons) do
        Button:update(dt)
    end
    

end

function drumsInputField:onClick()
    print("drumsInputField:onClick()")
    -- check if the cursor is over any buttosn, if it does, run onClick for that button 
    local cx,cy = cursor:getPosition()
    for _,Button in ipairs(self.buttons) do
        if math.abs(cx - Button.x) <= Button.radius and math.abs(cy - Button.y) <= Button.radius then  -- this one was clicked
            Button:onClick()
            break -- no need to keep checking after we found the clicked one
        end
    end
        
end

function drumsInputField:draw()
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    for i, Button in ipairs(self.buttons) do
        Button:draw()
    end
end

return drumsInputField