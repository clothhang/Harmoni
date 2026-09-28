local menuSongButton = Class:extend("menuSongButton")

menuSongButton.alertInstance = nil
menuSongButton.total = { updating = 0, drawing = 0 }

--- @param instance table -- The instance of the menu   -- what does this mean 
--- @param width number
--- @param height number
--- @param x number
--- @param y number
--- @param name string
--- @param artist string
--- @param charter string
--- @param bpm number
--- @param image string | love.Texture
--- @param isDifficultyButton boolean
--- @param gameMode string
--- @param path string
--- @param cornerRadius number
--- @param color table <number, number, number>
function menuSongButton:new(instance, width, height, x, y, name, artist, charter, bpm, image, isDifficultyButton, gameMode, path, cornerRadius, color, warnings, songPreviewTime, audioFile, difficulty, isNew)
    self.isDifficultyButton = isDifficultyButton or false
    self.instance = instance
    self.width = width or 10
    self.height = height or 10
    self.x = x or 10
    self.y = y or 10

    self.isNew = isNew

    if not menuSongButton.alertInstance then
        menuSongButton.alertInstance = newAlert(0, 0)
    end
    if self.isNew then self.newAlert = menuSongButton.alertInstance end

    self.warnings = warnings
    self.songPreviewTime = songPreviewTime or 0

    self.audioFile = audioFile -- how was this not already here????????
    print(self.songPreviewTime)

    self.difficulty = difficulty

    self.onlySkeleton = false -- why did i even add this we wont use it       -- this describes like half the code in this fucking game now

    self.mode = gameMode or "???"

    self.name = name or "???"
    self.artist = artist or "???"
    self.charter = charter or "???"
    self.bpm = bpm or "???"

    self.imagePath = image

    self.image = image or nil
    self.imageLoaded = false

    if not self.isDifficultyButton and self.imagePath then
        self.instance.bannerInputChannel:push(self.imagePath)
    end

    self.path = path or "???"
    print(self.path)
    self.color = color or {1, 1, 1}
    self.cornerRadius = cornerRadius or 7

    self.fontLarge = SkinHandler:getFont("Menu",40)
    self.fontSmall = SkinHandler:getFont("Menu",30)
    self.sizeXOffset,self.sizeYOffset = 0,0

    self.borderHoverAlpha = 0
    self.hovered = false

    self.canvas = nil
    self.cacheDirty = true
end

function menuSongButton:onClick()
    if self.isDifficultyButton then
        return {loadSong = true, mode = self.mode, path = self.path, warnings = self.warnings}    -- why do we even have this and returnInfo honestly..  (not changing it now  though)
    else

        return {loadSong = false, mode = self.mode, path = self.path, color = self.color}
    end

    local time = 0.4   
    self.sizeXOffset,self.sizeYOffset = -30,-30
    self.sizeTween = Timer.tween(time*3, self, {sizeXOffset = 0, sizeYOffset = 0}, "out-elastic")
end

function menuSongButton:returnInfo()
    return {
        mode = self.mode,
        name = self.name,
        artist = self.artist,
        charter = self.charter,
        bpm = self.bpm,
        image = self.image,
        path = self.path,
        isDifficultyButton = self.isDifficultyButton,
        color = self.color,
        warnings = self.warnings,
        songPreviewTime = self.songPreviewTime,
        audioFile = self.audioFile,  -- why the FUCK was this not already here??? its a fucking SONG BUTTON, of course it needs to have the fucking audio file name in it
        difficulty = self.difficulty
    }
end

function menuSongButton:rebuildCache(newCanvas)
    if not self.width or not self.height then return end
    if not self.canvas then newCanvas = true end

    if newCanvas then
        self.canvas = love.graphics.newCanvas(self.width, self.height)
    end

    local lastCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas({self.canvas, stencil=true})
        love.graphics.clear(0,0,0,0)

        local x, y = 0, 0

        local function stencilShape()
            love.graphics.rectangle("fill", x, y, self.width, self.height, self.cornerRadius, self.cornerRadius)
        end

        love.graphics.stencil(stencilShape, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        if self.imageLoaded and self.image and not dontShowBG then
            local imageScale = self.width / self.image:getWidth()
            local imageDrawY = y - (self.image:getHeight() * imageScale) / 2

            love.graphics.setColor(1,1,1)
            love.graphics.draw(self.image, x, imageDrawY, 0, imageScale, imageScale)
        end

        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, self.width / 7, self.height)

        drawGradientRect(
            x + self.width / 7, y,
            self.width, self.height,
            {self.color[1], self.color[2], self.color[3], 1},
            {self.color[1], self.color[2], self.color[3], 0},
            false
        )

        love.graphics.setStencilTest()

        local textColor = getTextColor(self.color[1], self.color[2], self.color[3])

        love.graphics.setFont(self.fontLarge)
        love.graphics.setColor(textColor)
        love.graphics.print(self.name, x + 3, y + 3)

        love.graphics.setFont(self.fontSmall)

        if self.isDifficultyButton then
            love.graphics.print(
                string.format("Difficulty: %s  Charted by: %s", self.difficulty, self.charter),
                x + 3, y + self.height / 2
            )

            love.graphics.setLineWidth(5)
            love.graphics.rectangle("line", x, y, self.width, self.height, self.cornerRadius, self.cornerRadius)
            love.graphics.setLineWidth(1)
        else
            love.graphics.print(
                string.format("By: %s  BPM: %s", self.artist, self.bpm),
                x + 3, y + self.height / 2
            )
        end
    love.graphics.setCanvas({ lastCanvas, stencil=true })

    self.cacheDirty = false
end


function menuSongButton:update(dt)
    self.hovered = mouseOver(self)
    menuSongButton.total.updating = menuSongButton.total.updating + 1
end

local function remap(value, oldMin, oldMax, newMin, newMax)
    return (value - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin
end

function menuSongButton:draw()
    if self.x + self.width < 0 or self.x > baseScreenRatio.x or
       self.y + self.height < 0 or self.y > baseScreenRatio.y then
        return
    end

    menuSongButton.total.drawing = menuSongButton.total.drawing + 1

    if self.cacheDirty or not self.canvas then
        self:rebuildCache()
    end

    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.canvas, self.x, self.y)

    local x, y = 0, 0

    local function stencilShape()
        love.graphics.rectangle("fill", self.x, self.y, self.width - self.sizeXOffset, self.height-self.sizeYOffset, self.cornerRadius, self.cornerRadius)
    end
    
    love.graphics.stencil(stencilShape, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    if self.hovered then
        local mouseX = toCanvasCoords(love.mouse.getPosition())
        local remappedX = (mouseX - self.x) / self.width

        local gradientWidth = self.width
        local gradientX = self.x + (remappedX * self.width) - (gradientWidth / 2)

        drawMultiGradientRect(
            gradientX, self.y,
            gradientWidth, self.height,
            {
                {self.color[1]*0.75, self.color[2]*0.75, self.color[3]*0.75, 0},
                {self.color[1]*0.75, self.color[2]*0.75, self.color[3]*0.75, 1},
                {self.color[1]*0.75, self.color[2]*0.75, self.color[3]*0.75, 0}
            }
        )

        self.borderHoverAlpha = math.min(self.borderHoverAlpha + 10 * love.timer.getDelta(), 1)
    else
        self.borderHoverAlpha = math.max(self.borderHoverAlpha - 10 * love.timer.getDelta(), 0)
    end

    love.graphics.setStencilTest()

    love.graphics.setColor(1,1,1,self.borderHoverAlpha)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.cornerRadius, self.cornerRadius)

    if not self.imageLoaded and not self.isDifficultyButton then
        local throbbertRadius = 30
        throbbert:draw(self.x + self.width - (throbbertRadius*2), self.y+self.height/2, throbbertRadius, 15)
    end

    if self.newAlert and self.isNew and Settings:getValue("Menu", "Song Select", "Enable New Song Indicator") then
        self.newAlert:draw(self.x, self.y)
    end

    love.graphics.setColor(1,1,1,1)
end


function menuSongButton:resetCounts()
    menuSongButton.total.updating = 0
    menuSongButton.total.drawing = 0
end

return menuSongButton
