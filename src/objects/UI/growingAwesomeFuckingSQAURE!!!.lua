local growingSquare = Class:extend("growingSquare")

function growingSquare:new(x,y,size,color)
    self.x,self.y = x or 0,y or 0
    self.growSize = size or 100
    self.size = 0
    self.color = color or {0,0,0}
    self.opacity = 0.5
    self.rotation =   love.math.random(0,360)

    --this useless piece of shit square does NOTHING until the first square DIES !! :(
    self.squareTwoOpacity = 0
    self.squareTwoSize = 0
    self.squareTwoColor = self.color

    self:raiseASquareRobloxNoWayOMGThisIsSoAwesome()
end

function growingSquare:raiseASquareRobloxNoWayOMGThisIsSoAwesome()
    Timer.tween(1, self, {size = self.growSize}, "out-quad", function()
        self:theSquareGrewButNowItHasToFadeOutAndDieWhichIsVerySadButItHasToHappenPoorSquareItIsSoSadWhyDoesThatHaveToHappen()
    end)
end


function growingSquare:theSquareGrewButNowItHasToFadeOutAndDieWhichIsVerySadButItHasToHappenPoorSquareItIsSoSadWhyDoesThatHaveToHappen()
     -- we make the other square as a memorial for the first square because the first square is gonna DIE!! :(  it doesnt deserve that but it must happen :(( life is unfair for these squares :( 

    self:makeTheMemorialSquareGrow🤑🤑🤑🤑()

    Timer.tween(0.5, self, {opacity = 0}, "linear", function()
        
    end)
end

function growingSquare:makeTheMemorialSquareGrow🤑🤑🤑🤑()
    self.squareTwoOpacity = self.opacity
    self.squareTwoSize = self.size

    local grow = (self.size*0.3)+self.size -- 30% larger than the first square (what a fat greedy piece of shit)
    Timer.tween(1, self, {squareTwoSize = grow, squareTwoOpacity = 0})
end
    
function growingSquare:update(dt)
end

function growingSquare:draw()

    love.graphics.push()
        love.graphics.translate(baseScreenRatio.x/2, baseScreenRatio.y/2)
        love.graphics.rotate(self.rotation)
        love.graphics.translate(-baseScreenRatio.x/2, -baseScreenRatio.y/2)
        love.graphics.push()
            
            love.graphics.setColor(self.color[1],self.color[2],self.color[3],self.opacity)
            love.graphics.translate(-self.size/2, -self.size/2)

            love.graphics.rectangle("fill",self.x, self.y, self.size, self.size)
        love.graphics.pop()

        love.graphics.push()
            love.graphics.setColor(self.squareTwoColor[1],self.squareTwoColor[2],self.squareTwoColor[3],self.squareTwoOpacity)
            love.graphics.translate(-self.squareTwoSize/2, -self.squareTwoSize/2)
            local oldLineWidth = love.graphics.getLineWidth()
            love.graphics.setLineWidth(10)
            love.graphics.rectangle("line", self.x, self.y, self.squareTwoSize, self.squareTwoSize)
            love.graphics.setLineWidth(oldLineWidth)       
            love.graphics.pop()
    love.graphics.pop()

end

return growingSquare