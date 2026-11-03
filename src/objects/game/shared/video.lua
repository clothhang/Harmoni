---@type table
local video = Class:extend("video")

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then f:close() end
    return f ~= nil
end

function video:new(video,x,y,scaleX,scaleY,dimness)
    self.path = video
    self.visible = true
    self.x, self.y = x,y
    self.scaleX, self.scaleY = scaleX or 1,scaleY or 1
    self.checkTimer = 0
    if not DLL_Video then
        --error("Video not supported on this platform") --temp until logging is added

        return self
    end

    if not video then return self, error("Video path not provided") end -- temp
    print("Loading video: " .. tostring(video))

    local fullPath = love.filesystem.getSource() .. "/" .. video
    if not fileExists(fullPath) then
        print("Video (" .. fullPath .. ") not found in source directory, checking save directory...")
        fullPath = love.filesystem.getSaveDirectory() .. "/" .. video
    end

    fullPath = fullPath:gsub("//", "/")

    --[[ if not fileExists(fullPath) then
        error("Video file not found: " .. fullPath)
    end ]]

    local vid, err
    if DLL_Video.openFile then
        vid, err = DLL_Video.openFile(fullPath)
    end
    if not vid then
        local video = love.filesystem.newFileData(video)
        vid, err = DLL_Video.open(video:getPointer(), video:getSize())
    end
    if not vid then return self, error("Video not loaded\n" .. err .. "\n" .. fullPath) end -- yet again

    self.video = vid
    self.filedata = video
    self.checkPerFrame = vid:getFPS() or 30
    self.dimness = dimness or 0

    self.imageData = love.image.newImageData(self.video:getDimensions())
    self.image = love.graphics.newImage(self.imageData)

    self.baseWidth = self.image:getWidth()
    self.baseHeight = self.image:getHeight()

    self.playing = false
    self.time = 0
    self.previousFrameTime = 0

    self.angle = 0  -- i guess this was handled by the sprite thingy in rit?? idk
    self.blendMode = "alpha"
    self.blendModeAlpha = "alphamultiply"
    self.alpha = 1

    self.forcedUpdate = false
end

function video:changeDimness(targetDimness, time, callback)
    targetDimness = targetDimness or 1
    if not time then
        self.dimness = targetDimness
        if callback then callback() end
        return
    end

    local start = self.dimness
    local change = targetDimness - start
    local t = 0
    local easing = Ease.linear

    table.insert(self.activeTweens, {
        update = function(dt)
            t = t + dt
            local progress = math.min(t / time, 1)
            self.dimness = start + change * easing(progress)
            return progress >= 1
        end,
        callback = callback
    })
end

function video:getFPS()
    if self.video then
        return self.video:getFPS()
    end

    return 0
end

function video:update(_)
    if not (self.playing or self.forcedUpdate) or not self.video then
        return
    end

    local currentTime = love.timer.getTime()

    local targetAdvance = currentTime - self.previousFrameTime

    self.checkTimer = self.checkTimer + targetAdvance
    self.previousFrameTime = currentTime

    local interval = 1 / self.checkPerFrame

    while self.checkTimer >= interval do
        self.checkTimer = self.checkTimer - interval

        if not self.video:read(self.imageData:getPointer()) then
            self.playing = false
            break
        end
    end

    self.image:replacePixels(self.imageData)
end

function video:play()
    if not self.playing and self.video then
        self.playing = true
        self.previousFrameTime = love.timer.getTime()
    end
end

function video:pause()
    if self.playing then
        self.playing = false
    end
end

function video:seek(time)
    if self.video then
        self.video:seek(time)
        tryExcept(function()
            self.video:read(self.imageData:getPointer())
            self.image:replacePixels(self.imageData)
        end)
        self.time = time
        self.previousFrameTime = love.timer.getTime()
        self.forcedUpdate = false
    end
end

function video:draw()
    local lastColor = {love.graphics.getColor()}
    love.graphics.setColor(lastColor[1], lastColor[2], lastColor[3], (self.alpha or 1) * lastColor[4])
    if not self.video or not self.visible or not self.image then return end

    love.graphics.push()
    love.graphics.setBlendMode(self.blendMode, self.blendModeAlpha)

    local sx = self.scaleX
    local sy = self.scaleY
    local ox, oy = self.image:getWidth() / 2, self.image:getHeight() / 2

    love.graphics.draw(self.image, self.x, self.y, math.rad(self.angle), sx, sy, ox, oy)

    love.graphics.pop()
    love.graphics.setColor(lastColor)

        -- Draw dimness overlay
    love.graphics.setColor(0, 0, 0, self.dimness)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1, 1, 1)
end

function video:close()
    if self.video then
        self.video:close()
        self.video = nil
    end
end

return video