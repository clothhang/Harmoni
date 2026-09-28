---@diagnostic disable: inject-field
local jukebox = State("jukebox")

local function distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function jukebox:enter(parent)
    love.audio.stop()   
    self.parent = parent
    self.background = self.parent.BG

    self.songButtonX = 10
    self.songButtonWidth = 475
    self.songButtonHeight = 75
    self.songButtonSpacing = 10
    self.songButtons = {}
    self.scrubber = nil
    self.frametimer = 0
    self.currentBGPos = { x = 0, y = 0 }

    self.songBGX = 520
    self.songBGY = 30
    self.songBGWidth = 1430
    self.songBGHeight = 804

    self:setupSongList()

    self.screenCoverAlpha = 0
    self.faded = false

    self.videoHudAlpha = 0

    if AchievementHandler then AchievementHandler:unlock("jukebox mode") end
end

local validTypes = {
    "srt",
    "vtt",
    "sbv",
    "stl",
    "ass",
    "lua"
}

-- https://love2d.org/wiki/Image_Formats
-- Plus some specially programmed ones
local validImages = {
    "png",
    "jpg", "jpeg",
    "bmp",
    "tga",
    "hdr", "pic",
    "exr",

    -- Custom formats support
    "gif",
}

local function findValidImageExtension(filename)
    for _, ext in ipairs(validImages) do
        if filename:sub(-#ext):lower() == ext then
            return ext
        end
    end
    return nil
end

function jukebox:switchSong(songInfo)
    if self.audio and self.audio:isPlaying() then self.audio:stop() end
    self.audio = nil
    self.lyricsDisplay = nil
    self.currentSongInfo = songInfo
    self.audio = love.audio.newSource(self.currentSongInfo.path .. "/" .. self.currentSongInfo.audio, "stream")
    self.audio:play()

    if findValidImageExtension(self.currentSongInfo.bg) then
        self.video = false
        if love.filesystem.getInfo(self.currentSongInfo.path .. "/" ..self.currentSongInfo.bg, "file") then
            self.songBG = love.graphics.newImage(self.currentSongInfo.path .. "/" ..self.currentSongInfo.bg)
            if self.songBG:typeOf("GIF") then
                self.songBG:setLooping(true)
            end
            print(self.songBG:type())
        else
            self.songBG = nil
        end
    else
        self.songBG = video(self.currentSongInfo.path .. "/" .. self.currentSongInfo.bg, self.songBGX, self.songBGY, 1, 1)
        love.timer.step()
        self.videoHudAlpha = 1
        Timer.after(3, function() 
            Timer.tween(1, self, {videoHudAlpha = 0})
        end)
        self.songBG:play()
        self.video = true   -- if time machines ever exist im going to go to the exact moment i wrote this and i am shooting myself in the face 
                            -- WHY would i not make self.video just BE THE FUCKING VIDEO
                            -- what the FUCK was i thinking
                            -- fucking self.songBG can just be a video or an image??
                            -- self.video = tru- SHUT THE FUCK UP!!!!!

        local targetSizeX = self.songBGWidth
        local targetSizeY = self.songBGHeight

        self.songBG.scaleX = targetSizeX / self.songBG.image:getWidth()
        self.songBG.scaleY = targetSizeY / self.songBG.image:getHeight()
        self.songBG.x = self.songBGX + (targetSizeX / 2)
        self.songBG.y = self.songBGY + (targetSizeY / 2)

        self.currentBGPos.x = self.songBG.x
        self.currentBGPos.y = self.songBG.y
        self.currentBGPos.scaleX = self.songBG.scaleX
        self.currentBGPos.scaleY = self.songBG.scaleY

        if AchievementHandler then AchievementHandler:unlock("jukebox video") end
    end

    local type = ""
    local path = self.currentSongInfo.path .. "/lyrics."
    for _, t in ipairs(validTypes) do
        if love.filesystem.getInfo(path .. t, "file") then
            type = t
            break
        end
    end
    self.lyricsDisplay = nil
    local lyrics
    if type ~= "lua" and type ~= "" then
        lyrics = CaptionParser.parse(love.filesystem.read(path .. type), type)
        self.lyricsDisplay = lyricsDisplay(baseScreenRatio.x-570,30,540,baseScreenRatio.y-200,lyrics)
    elseif type == "lua" then
        lyrics = CaptionParser.parse(path .. type, type)
        self.lyricsDisplay = lyricsDisplay(baseScreenRatio.x-570,30,540,baseScreenRatio.y-200,lyrics)
    end

    self.lyricsRenderer = lyricsRenderer(baseScreenRatio.x-570,30,540,baseScreenRatio.y-200, lyrics)

    -- genuinely the easiest way that I thought of
    self.scrubBack = UIsquiglyLine(
        0, baseScreenRatio.y - 50,
        baseScreenRatio.x, baseScreenRatio.y - 50,
        30, 5, 200, -5, 5
    )
    self.scrubber = UITimeRemaing(
        0, self.audio:getDuration(),
        0, baseScreenRatio.y - 50,
        baseScreenRatio.x,
        self,
        5, -5, 5, 30
    )
end

function jukebox:toggleFullscreen()
    --[[ if not self.video then return end ]] -- i hate myself so much why the fuck did i make it work this way 
                                        -- looking at this by itself you would think this just checks that the video object self.video exists,, nope. self.video is a FUCKING BOOLEAN 
    self.videoHudAlpha = 1
    Timer.after(3, function() 
        Timer.tween(1, self, {videoHudAlpha = 0})
    end)
    --save the original video size shit first
    if self.fullscreened then  -- unfullscren
        self.fullscreened = false
        self.currentBGPos.x, self.currentBGPos.y, self.currentBGPos.scaleX, self.currentBGPos.scaleY = self.originalvideoX, self.originalvideoY, self.originalvideoScaleX, self.originalvideoScaleY
    else                        -- fullscreen
        self.originalvideoScaleX = self.currentBGPos.scaleX
        self.originalvideoScaleY = self.currentBGPos.scaleY
        self.originalvideoX = self.currentBGPos.x
        self.originalvideoY = self.currentBGPos.y

        self.fullscreened = true

        -- now we just change the video's size and position to be fullscreened 
        -- it draws from center, so we set it to the center of the screen
        self.currentBGPos.x, self.currentBGPos.y = baseScreenRatio.x/2, baseScreenRatio.y/2

        -- and finally, we just make it fullscreen 
        local targetSizeX = baseScreenRatio.x
        local targetSizeY = baseScreenRatio.y

        if (self.songBG or {}).image then
            self.currentBGPos.scaleX = targetSizeX / self.songBG.image:getWidth()
            self.currentBGPos.scaleY = targetSizeY / self.songBG.image:getHeight()
        else
            self.currentBGPos.scaleX = targetSizeX / self.songBG:getWidth()
            self.currentBGPos.scaleY = targetSizeY / self.songBG:getHeight()
        end

        if AchievementHandler and self.video then AchievementHandler:unlock("jukebox fullscreen video") end
    end
end

function jukebox:setupSongList()
    self.songButtons = {}

    self.songLoadChannel = love.thread.getChannel("jukebox_song_load")
    self.songDoneChannel = love.thread.getChannel("jukebox_song_done")

    self.songLoadChannel:clear()
    self.songDoneChannel:clear()

    self.songThread = love.thread.newThread([[
local oprint = print
function print(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    oprint("[Jukebox Thread] " .. table.concat(args, "\t"))
end
local ChartParse = require("modules.game.chartParse")
local musicPath = ...

local loadChannel = love.thread.getChannel("jukebox_song_load")
local doneChannel = love.thread.getChannel("jukebox_song_done")

local function getExtension(path)
    return path:match("^.+%.(.+)$")
end

local function loadHarmc(directory)
    local items = love.filesystem.getDirectoryItems(directory)
    for _, f in ipairs(items) do
        if getExtension(f) == "harmc" then
            local ok, meta = pcall(function()
                return ChartParse.harmcMeta(directory .. "/" .. f)
            end)
            if ok then return meta end
        end
    end
    return nil
end

local songs = love.filesystem.getDirectoryItems(musicPath)
for _, folder in ipairs(songs) do
    local fullPath = musicPath .. folder .. "/"

    local meta = loadHarmc(fullPath)
    if meta then
        local bg = meta.backgroundVideo or meta.backgroundFile
        loadChannel:push({
            name   = meta.title or "???",
            artist = meta.artist or "???",
            audio  = meta.audioFile or "",
            bg     = bg,
            path   = fullPath
        })
    end
end

doneChannel:push(true)
]])
    self.songThread:start(musicPath)

    self.songLoadTimer = 0
end

function jukebox:update(dt)
    if self.songLoadChannel then
        local info = self.songLoadChannel:peek()
        if info then
            self.songLoadChannel:pop()

            local x = self.songButtonX
            local y = (self.songButtonHeight + self.songButtonSpacing) * (#self.songButtons + 1)

            table.insert(self.songButtons, jukeboxSongButton(
                x, y,
                self.songButtonWidth, self.songButtonHeight,
                info.name, info.artist, info.audio,
                info.path, info.bg
            ))
        end
    end

    if self.scrubberHeld then
        self.frametimer = self.frametimer + 1
    else
        self.frametimer = 0
    end
    local audioTime = 0
    if self.audio and self.audio:isPlaying() then
        audioTime = self.audio:tell("seconds")
    end

    if self.lyricsDisplay then
        self.lyricsDisplay:update(dt, audioTime)
    end
    if self.lyricsRenderer then
        self.lyricsRenderer:update(dt, audioTime)
    end

    if self.video and not self.scrubberHeld then
        self.songBG.x = self.currentBGPos.x
        self.songBG.y = self.currentBGPos.y
        self.songBG.scaleX = self.currentBGPos.scaleX
        self.songBG.scaleY = self.currentBGPos.scaleY
        self.songBG:update(dt)
    end
    self:checkForFullscreenInput()
    if self.audio and self.scrubber then
        self.scrubBack:update(dt)
        self.scrubber:update(dt, self.audio:tell()/self.audio:getDuration())
    end

    if Input:pressed("menuBack") then
        State.transition("waveDissolve", States.menu.titleScreen)
    end

    local dontContinue = self:checkForSongButtonClicks()
    if dontContinue then return end
    dontContinue = self:checkForLyricClick()
    if dontContinue then return end
    dontContinue = self:checkForScrubberHead()
    if dontContinue then return end
    dontContinue = self:checkForScrubberHeadRelease()
    if dontContinue then return end
    dontContinue = self:checkForScrubber()
    if dontContinue then return end
end

function jukebox:checkForFullscreenInput()
    local mx,my = cursor:getPosition()
    local x,y,width,height = self.songBGX,self.songBGY,self.songBGWidth,self.songBGHeight
    if mx >= x and mx <= x+width and my >= y and my <= y+height then -- cursor is over the video
        local funct = function() 
            self:toggleFullscreen()
            self:fade("in")
        end
        if Input:pressed("menuClickLeft") then self:fade("out",funct) end
        cursor.fadeOutWhenIdle = true
        if cursor.didMove then
            self.videoHudAlpha = 1
            if self.fadeTimerVideo then Timer.cancel(self.fadeTimerVideo) end
            self.fadeTimerVideo = Timer.after(1, function() Timer.tween(1, self, {videoHudAlpha = 0}) end)
        end
    else
        if self.fullscreened then -- we need to fade the cursor and also let the user unfullscreen when they click anywhere
            cursor.fadeOutWhenIdle = true
            local funct = function() 
                self:toggleFullscreen()
                self:fade("in")
            end
            if Input:pressed("menuClickLeft") and not (mouseOver(self.scrubBack)) then self:fade("out", funct) end

            else -- video must not be fullscreen, so we dont fade the cursor out and we obviously dont let the user unfullscreen
                cursor.fadeOutWhenIdle = false
            end
        end
end

function jukebox:checkForSongButtonClicks()
    local MX,MY = cursor:getPosition()
    local ok = false

    for _, Button in ipairs(self.songButtons) do
        if Input:pressed("menuClickLeft") then
            if MX >= Button.x and MX <= Button.x+Button.width then
                if MY >= Button.y and MY <= Button.y+Button.height then
                    if AchievementHandler then AchievementHandler:unlock("jukebox song") end
                    self:switchSong(Button:onClick())
                    ok = true
                end
            end
        end
    end

    return ok
end

function jukebox:checkForScrubberHead()
    if not self.scrubber or not self.audio then return false end

    local mx, my = cursor:getPosition()
    local headX, headY, headRadius = self.scrubber:getHeadData()

    if Input:pressed("menuClickLeft") then
        if distance(mx, my, headX, headY) <= headRadius then
            self.scrubberHeld = true
        end
    end

    if self.scrubberHeld and Input:down("menuClickLeft") then
        local percent = math.max(0, math.min(1, mx / baseScreenRatio.x))
        local seekTime = percent * self.audio:getDuration()
        self.audio:seek(seekTime)
        return true
    end

    return false
end

function jukebox:checkForScrubberHeadRelease()
    if not self.scrubberHeld then return false end

    if not Input:down("menuClickLeft") then
        local mx = cursor:getX()
        local percent = math.max(0, math.min(1, mx / baseScreenRatio.x))
        local seekTime = percent * self.audio:getDuration()
        self.audio:seek(seekTime)
        if self.video then
            self.songBG:seek(seekTime)
            self.songBG.forcedUpdate = true
        end
        self.scrubberHeld = false
        return true
    end

    return false
end


function jukebox:checkForScrubber()
    if not self.scrubber or not self.audio then return false end

    local mx, my = cursor:getPosition()
    local scrubberY = self.scrubber.y
    local clickRadius = 50

    if Input:pressed("menuClickLeft") and not self.scrubberHeld then
        if math.abs(my - scrubberY) <= clickRadius then
            local percent = math.max(0, math.min(1, mx / baseScreenRatio.x))
            local seekTime = percent * self.audio:getDuration()
            self.audio:seek(seekTime)

            if self.video then
                self.songBG:seek(seekTime)
                self.songBG.forcedUpdate = true
            end

            self.scrubber.percent = percent
            return true
        end
    end

    return false
end

function jukebox:fade(dir,func)
    local funct 
    local value
    if func then funct = function() func() end else funct = function() end end
    if not dir then return end
    if dir == "in" then value = 0 elseif dir == "out" then value = 1 end
    self.screenFadeTimer = Timer.tween(0.15, self, {screenCoverAlpha = value}, "linear", function() funct() end)
end

function jukebox:checkForLyricClick()
    local ok = false
    -- check if we're in the lyric box
    local mx, my = cursor:getPosition()
    if mx < baseScreenRatio.x - 570 or mx > baseScreenRatio.x - 30
        and my < 30 or my > baseScreenRatio.y - 170 then
        return false
    end
    if Input:pressed("menuClickLeft") then
        if self.lyricsDisplay then
            local lyricClick = self.lyricsDisplay:clickLyric()
            if lyricClick and lyricClick.lyricClick then
                self.audio:seek(lyricClick.time)
                if self.video then
                    self.songBG:seek(lyricClick.time)
                    self.songBG.forcedUpdate = true
                    ok = true
                end
            end
        end
    end

    return ok
end

function jukebox:draw()
    love.graphics.draw(self.background)
    if self.lyricsDisplay then self.lyricsDisplay:draw() end

    for _, Button in ipairs(self.songButtons) do
        Button:draw()
    end

    --lyrics skeleton
    if not self.lyricsDisplay then love.graphics.rectangle("fill",baseScreenRatio.x-570,30,540,baseScreenRatio.y-200) end

        --song info skeleton 
    love.graphics.rectangle("fill", 520, 1070, 1430, 200)

    --songBG skeleton        -- we have all these skeletons because its halloween so we gotta be spooky
    if not self.video and not self.songBG then -- its no longer halloween bro!!! skeletons can't be here anymore !!!
        love.graphics.rectangle("fill", self.songBGX, self.songBGY, self.songBGWidth, self.songBGHeight)
    else
        self:drawBG()
    end

    --scrubber and button skeleton
    if not self.scrubber then
        love.graphics.rectangle("fill", 0, 1305, baseScreenRatio.x, 200)
    else
        self:drawScrubber()
    end

    -- draw screen cover
    love.graphics.setColor(0,0,0,self.screenCoverAlpha)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1,1,1,1)
end

function jukebox:drawScrubber()
    love.graphics.setColor(.25, .25, .25, 0.4)
    self.scrubBack:draw()
    love.graphics.setColor(1, 1, 1, 1)
    self.scrubber:draw()

    if self.scrubberHeld and self.audio then
        local mx, _ = cursor:getPosition()
        local _, headY, headRadius = self.scrubber:getHeadData()
        local currentTime = self.audio:tell()
        local totalTime = self.audio:getDuration()
        local timeString = string.format("%02d:%02d / %02d:%02d",
            math.floor(currentTime / 60), math.floor(currentTime % 60),
            math.floor(totalTime / 60), math.floor(totalTime % 60)
        )
        local padding = 10
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(timeString)
        local textHeight = font:getHeight()

        local boxX = math.min(
            math.max(mx - (textWidth / 2) - padding, 0),
            baseScreenRatio.x - textWidth - (2 * padding)
        )
        local boxY = headY - headRadius - textHeight - (2 * padding) - 5

        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", boxX, boxY, textWidth + (2 * padding), textHeight + (2 * padding), 10, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(timeString, boxX + padding, boxY + padding)
    end
end

function jukebox:drawBG()
    local x, y, width, height = self.songBGX, self.songBGY, self.songBGWidth, self.songBGHeight
    -- stencil 
    -- define stencil mask
    local function maskShape()
        love.graphics.rectangle("fill", x, y, width, height, 50, 50)
    end

    love.graphics.stencil(maskShape, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    if self.video then
        self.songBG:draw()
    elseif self.songBG then
        
        love.graphics.draw(self.songBG,x, y,nil,width / self.songBG:getWidth(),height / self.songBG:getHeight())
    end
    love.graphics.setStencilTest()
    love.graphics.setColor(1,1,1)

    -- here we draw the video outside of the stencil if its fullscreened
    if self.fullscreened then
        if self.video then
            self.songBG:draw()
        else
            love.graphics.draw(self.songBG,0, 0,nil,self.currentBGPos.scaleX,self.currentBGPos.scaleY)
        end

        if self.lyricsRenderer then
            self.lyricsRenderer:draw(self.audio:tell())
        end
    end

    if self.video then
        love.graphics.setColor(1,1,1,self.videoHudAlpha)
        local text = (not self.fullscreened and LocaleHandler:getText("UI", "Click Fullscreen")) or LocaleHandler:getText("UI", "Click Unfullscreen")
        love.graphics.printf(text, x, y, width, "center")
    end

    love.graphics.setColor(1,1,1,1)
end

function jukebox:exit()
    if self.audio and self.audio:isPlaying() then self.audio:stop() end
    self.audio = nil
    self.lyricsDisplay = nil
    if self.video then
        self.songBG = nil
        self.video = false
    end

    if self.songThread and self.songThread:isRunning() then
        self.songThread:kill()
    end

    if self.fullscreened then
        self.fullscreened = false
    end

    cursor.fadeOutWhenIdle = false
end

return jukebox