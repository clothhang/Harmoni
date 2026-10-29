local songSelect = State("songSelect")
local songList = {}
local difficultyList = {} -- hate having to have 2 but its better this way
local songButtons = {}
local difficultyButtons = {}
local songButtonWidth = 780
local songButtonHeight = 97.5
local songButtonSpacing = 15
local selectedSong = 1
local hoveredSong = 0
local BGAlpha = {1}


local currentDisplayedBG
local previousBG

local BGDarkness = 0

local songButtonX = baseScreenRatio.x - songButtonWidth - songButtonSpacing +70

local difficultyButtonX = songButtonX

local switchingState

function songSelect:resetBpmShit(newBpm)
    self.bpmHandler:init()
    self.bpmHandler:setBpm(newBpm or 100)
end

function songSelect:enter()
    self.debug = true

    self.bpmHandler = require("modules.game.bpm")


    self.currentSongInfo = {}

    self.songInfoY = 20
    -- selectedSong = 1
    switchingState = false
    self.colors = {
        light = {0, 0, 0, 0},
        dark = {0, 0, 0, 0.8}
    }

    self.songThread = self.songThread or love.thread.newThread [[
local oprint = print
function print(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    oprint("[SongLoader Thread] " .. table.concat(args, "\t"))
end

require("love.timer")
require("love.filesystem")

local chartParse = require("modules.game.chartParse")

local channel = love.thread.getChannel("thread.songLoader")
local outChannel = love.thread.getChannel("thread.songLoader.out")

-- we're just loading metadata here, so we use chartParse.harmcMeta
local function loadSongMetadata(path)
    local songInfo = chartParse.harmcMeta(path)
    return songInfo
end

local path, songInfo, folderPath, ok, err
local loaded = false
while true do
    loaded = false
    path = channel:demand()
    if not path then goto continue end

    if path == "exit" then
        break
    end

    if not love.filesystem.getInfo(path, "file") then 
        goto continue 
    else 
        --songInfo = loadSongMetadata(path) 
        ok, err = pcall(function() songInfo = loadSongMetadata(path) end)
        if not ok then
            print("ERROR: Failed to load song metadata from " .. path .. ": " .. err)
            goto continue
        end
    end

    -- get folder path
    -- e.g.  Music/33409 - 179/143301.qua.harmc/ -> Music/33409 - 179/
    if string.sub(path, -1) == "/" then
        path = string.sub(path, 1, -2)  -- remove trailing slash if it exists
    end
    -- if path starts with "Music/" then remove it
    path = string.gsub(path, "^Music/", "")  -- remove "Music/" from the start of the path
    folderPath = (path:match("(.+)/[^/]+$") or "") .. "/"  -- get everything before the last slash, or return empty string if no slashes found

    outChannel:push({
        path = path,
        folderPath = folderPath,
        songInfo = songInfo
    })
    
    loaded = true

    ::continue::
    --if not loaded then
        love.timer.sleep(0.03)
    --end
end
]]

    self.bannerThread = self.bannerThread or love.thread.newThread [[
require("love.timer")
require("love.image")

local channel = love.thread.getChannel("thread.bannerLoader")
local outChannel = love.thread.getChannel("thread.bannerLoader.out")

local function getAverageColor(imageData)
    local r, g, b = 0, 0, 0
    local width, height = imageData:getDimensions()
    local totalPixels = width * height

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local pr, pg, pb = imageData:getPixel(x, y)
            r = r + pr
            g = g + pg
            b = b + pb
        end
    end

    r = r / totalPixels
    g = g / totalPixels
    b = b / totalPixels

    return {r, g, b}
end

local avg = {0, 0, 0}

local path, image
local loaded = false
while true do
    loaded = false
    path = channel:demand()
    if not path then goto continue end

    if path == "exit" then
        break
    end

    if not love.filesystem.getInfo(path, "file") then 
        goto continue 
    else 
        if path:sub(-4):lower() ~= ".gif" then
            image = love.image.newImageData(path)
        else
            image = path
        end
    end

    if type(image) ~= "string" then
        avg = getAverageColor(image)
    end

    outChannel:push({
        path = path,
        image = image,
        averageColor = avg
    })
    
    loaded = true

    ::continue::
    if not loaded then
        love.timer.sleep(0.1)
    end
end
]]

    local popupbuttons = {}
    for i = 1, 7 do
        table.insert(popupbuttons, {text = tostring(i)})
    end

    self.bannerInputChannel = self.bannerInputChannel or love.thread.getChannel("thread.bannerLoader")
    self.bannerChannel = self.bannerChannel or love.thread.getChannel("thread.bannerLoader.out")

    self.songInputChannel = self.songInputChannel or love.thread.getChannel("thread.songLoader")
    self.songChannel = self.songChannel or love.thread.getChannel("thread.songLoader.out")

    self.bannerThread:start()
    self.songThread:start()

    if #songList == 0 then
        self:setupSongList()
    else
        self:loadBanners()
        self.currentSongInfo = songButtons[selectedSong]:returnInfo()
        self:resetBpmShit(self.currentSongInfo.bpm or 100)
    end
    self:setUpThoseBubblesThatIHate(10)
    self:setUpThoseLinesThatIHate(11)
    self:setUpThoseWavesThatIHate(4)

    self.logoCircle = UISquigleCircle("line", 0,baseScreenRatio.y, 350, 5, 20, 5, {1,1,1,1})
    self.logoCircleFill = UISquigleCircle("fill", 0,baseScreenRatio.y, 350, 5, 20, 5, {0,0,0,0.5})
    self.logoH = UIlogoH(90,1300,0.17)

    self.coverBG = {alpha = 0}

    self.modifiersMenu = modifiersMenu(20,400,600,670)

  --  self:checkForSongButtonClicks(false)
    self.buttonBezierCurveMiddleXControlPoint = 100
  self.buttonBezierCurve = love.math.newBezierCurve(baseScreenRatio.x, 0,
                                                    baseScreenRatio.x-self.buttonBezierCurveMiddleXControlPoint, baseScreenRatio.y/2,
                                                    baseScreenRatio.x, 0)
end

function songSelect:setUpThoseLinesThatIHate(numberOfLines)
    self.squiglyLines = {}
    if Settings:getValue("Menu", "Song Select", "Enable Squiglly Lines") then
        for i = 1,numberOfLines do
            local y = ((baseScreenRatio.y+400)/numberOfLines)*(i-2)
            local x1,x2 = -50, baseScreenRatio.x+50
            table.insert(self.squiglyLines, UIsquiglyLine(x1,y+300,x2,y-300,10,30,200,1,70,{1,1,1,0.15}))
        end
    end
end

function songSelect:setUpThoseBubblesThatIHate(numberOfBubbles)
    self.bubbles = {}
    if Settings:getValue("Menu", "Song Select", "Enable Bubbles") then
        transparency = 0.1
        local colors = SkinHandler:getRandomColors()

        for i = 1,numberOfBubbles do 
            ::start::
            local x,y = love.math.random(0, baseScreenRatio.x), love.math.random(baseScreenRatio.y, 0)

            local color = colors[love.math.random(1,#colors)]
            table.insert(self.bubbles, UISquigleCircle("fill", x, y, love.math.random(90,130), 5, 5, 3, color))
        end

        for i, Bubble in ipairs(self.bubbles) do
            Bubble.type = "Spinner"
            if love.math.random(1,10) == 1 then
                Bubble.type = "Squisher"
            end
        end
    end

end


function songSelect:setUpThoseWavesThatIHate(numberOfWaves)
    if Settings:getValue("Menu", "Song Select", "Enable Squiglly Lines") then
        local colors = {
            {1,1,1,0.5},
            {0,1,1,0.5},
            {1,0,1,0.5},
            {0,0,1,0.5}
        }
        self.layerWaves = UILayerWave(0,baseScreenRatio.y-100,baseScreenRatio.x,500,numberOfWaves,200, 30, 50, colors)
    end
end

function songSelect:setupSongList()
    songList = SongListManager.getSongList(musicPath)

    self.menuState = "song"

    for i, song in ipairs(songList) do
        if not song then
            table.remove(songList, i)
            goto continue
        end

        local diffList = SongListManager.getDifficultyList(musicPath .. song)
        if not diffList[1] then
            table.remove(songList, i)
            goto continue
        end

        if not love.filesystem.getInfo(musicPath .. song .. "/" .. diffList[1], "file") then
            table.remove(songList, i)
            goto continue
        end

        self.songInputChannel:push(musicPath .. song .. "/" .. diffList[1] .. "/")

        ::continue::
    end
end


function songSelect:loadBanners()
    for _, button in ipairs(songButtons) do
        if button.imagePath and not button.imageLoaded then
            if love.filesystem.getInfo(button.imagePath, "file") then
                self.bannerInputChannel:push(button.imagePath)
            else
                button.imageLoaded = false
                button.color = {1, 1, 1}
            end
        end
    end
end

function songSelect:clearBanners()
    for _, SongButton in ipairs(songButtons) do
        if SongButton.image == currentDisplayedBG then
            goto continue
        end
        SongButton.image = nil
        SongButton.imageLoaded = false
        SongButton.color = {1, 1, 1}

        ::continue::
    end

    collectgarbage("step")
end

function songSelect:setupDifficultyList(path,color)
    difficultyList = SongListManager.getDifficultyList(path)
    difficultyButtons = {}

    local difficultyListBoxHeight = #difficultyList*(songButtonHeight+songButtonSpacing)

    local baseX = -10
    local baseY = 0

    local slope = 0

    for i = 1, #difficultyList do
        local songInfo = nil
        songInfo = ChartParse.harmcMeta(path .. "/" .. difficultyList[i] .. "/", "get")
        if songInfo then
            local y = i * (songButtonHeight + songButtonSpacing)
            local x = difficultyButtonX + baseX + slope * (y - baseY) 
            table.insert(difficultyButtons,
                menuSongButton(
                    self,
                    songButtonWidth,
                    songButtonHeight,
                    x,
                    y,
                    songInfo.difficultyName,
                    nil,
                    songInfo.charter,
                    nil,
                    nil,
                    true,
                    songInfo.gameMode,
                    path .. "/" .. difficultyList[i],
                    7,
                    color,
                    songInfo.warnings,  -- this is just hacked in,,,, its so bad   there was absolutely NO planning for this when the song button object was made
                    nil,
                    nil,
                    songInfo.difficulty
                )
            )
        end
    end

    table.sort(difficultyButtons, function(a, b)
        return tonumber(a.difficulty) < tonumber(b.difficulty)
    end)

    for i = 1, #difficultyButtons do
        local y = i * (songButtonHeight + songButtonSpacing)
        difficultyButtons[i].y = y
    end

    function songSelect:difficultyListDraw()
        for _, DifficultyButton in ipairs(difficultyButtons) do
            DifficultyButton:draw()
        end
    end
end

function songSelect:loadSongs()
    if self.songChannel:peek() then
        local data = self.songChannel:pop()
        if data then
            -- add to songButtons
            local songInfo = data.songInfo
            if songInfo then
                local isNew = true
                local settingsData
                if love.filesystem.getInfo(musicPath .. data.folderPath .. "/settings.lua") then    -- this will work because if the file is missing, then the song def hasnt been played, and itll be created when starting the song for the first time (it shouldnt be possible for the file to be missing anyway tho)
                    settingsData = love.filesystem.load(musicPath .. data.folderPath .. "/settings.lua")()
                    if settingsData.playedBefore then isNew = false end
                end
                table.insert(songButtons, menuSongButton(
                    self,
                    songButtonWidth,songButtonHeight,songButtonX,(#songButtons+1)*(songButtonHeight+songButtonSpacing),
                    songInfo.title,
                    songInfo.artist,
                    songInfo.charter,
                    songInfo.bpm,
                    musicPath .. data.folderPath .. (songInfo.backgroundFile or ""),
                    false,
                    songInfo.gameMode,
                    musicPath .. data.folderPath,
                    nil,
                    nil,
                    nil,
                    songInfo.songPreviewTime,
                    songInfo.audioFile,
                    nil,
                    isNew
                ))
            end
            if not self.currentAudio and #songButtons == 1 then    -- this whole thing is so hacky but it works
                -- now that we have created the first button, we call checkforsongbuttonclicks and i guess we just hope it works lmao 
                self:checkForSongButtonClicks(false)
                -- now we do smth even more hacky, just set the menustate to song
                self.menuState = "song"
            end
        end
    end
end

local function getAverageColor(imageData)
    local r, g, b = 0, 0, 0
    local width, height = imageData:getDimensions()
    local totalPixels = width * height

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local pr, pg, pb = imageData:getPixel(x, y)
            r = r + pr
            g = g + pg
            b = b + pb
        end
    end

    r = r / totalPixels
    g = g / totalPixels
    b = b / totalPixels

    return {r, g, b}
end

function songSelect:loadSongButtonImages()
    if self.bannerChannel:peek() then
        local data = self.bannerChannel:pop()
        if data then
            for i, SongButton in ipairs(songButtons) do
                if SongButton.imagePath == data.path and love.filesystem.getInfo(data.path, "file") then
                    SongButton.imageData = data.image
                    if type(data.image) ~= "string" then
                        SongButton.image = love.graphics.newImage(data.image)
                        SongButton.cacheDirty = true
                        SongButton.color = data.averageColor
                    else
                        SongButton.image = GIF.new(data.image)
                        SongButton.cacheDirty = true
                        SongButton:update(0)
                        SongButton.color = getAverageColor(SongButton.image.imageData)
                    end
                    SongButton.imageLoaded = true
                    break
                end
            end
        end
    end
end

function songSelect:update(dt)
    if menuSongButton.alertInstance then menuSongButton.alertInstance:update(dt) end
    self.bpmHandler:update(dt)
    if self.currentAudio and self.currentAudio:isPlaying() then MusicTime = MusicTimeManager.updateMusicTime(MusicTime,dt) end
    local mx,my = cursor:getPosition()
    if Input:pressed("menuBack") then
        if self.menuState == "difficulty" then self.menuState = "song"; return end
      --  if switchingState then return end

        State.transition("waveDissolve", States.menu.titleScreen, function()
            self:clearBanners()
        end)
        return
    end
    local lineBeatTimers = {}
    for i, squiglyLine in ipairs(self.squiglyLines) do
        squiglyLine:update(dt)
        if self.bpmHandler:wasBeatHit() then
            if lineBeatTimers[i] then Timer.cancel(lineBeatTimers[i]) end
            lineBeatTimers[i] = Timer.tween(0.5, squiglyLine, {time = squiglyLine.time + 1}, "out-quad")
        end
    end

    if self.layerWaves then
        self.layerWaves:update(dt)
    end
    self:updateBGImage()
    self:checkForSongButtonClicks(true)
    self:checkForDifficultyButtonClicks()
    self:updateSongButtons(dt)
    self:updateDifficultyButtons(dt)
    self:loadSongs()
    self:loadSongButtonImages()
    self:checkForSongLoop()
    self.modifiersMenu:update(dt)
    self.ignoreInterpolation = false

    local modMenuTargetX = (self.menuState == "song" and -600) or 10
    self.modifiersMenu.x = self.modifiersMenu.x + (modMenuTargetX - self.modifiersMenu.x) * 10 * dt
    local BGDimTarget = (self.menuState == "song" and 0) or 0.7
    BGDarkness = BGDarkness + (BGDimTarget - BGDarkness) * 10 * dt

    self.logoCircle:update(dt)
    self.logoCircleFill:update(dt)

    self.logoCircle.rotation = self.logoCircle.rotation +5*dt

    if self.bpmHandler:wasBeatHit() then
        if self.beatLogoCircleTween then Timer.cancel(self.beatLogoCircleTween);Timer.cancel(self.logoHSizeBeatTween) end
        self.beatLogoCircleTween = Timer.tween(0.5, self.logoCircle, {rotation = self.logoCircle.rotation + 10}, "out-quad")
        self.logoH.sx, self.logoH.sy = 0.18, 0.18
        self.logoHSizeBeatTween = Timer.tween(0.5, self.logoH, {sx = 0.17, sy = 0.17}, "out-quad")

    end

    if math.abs(mx - self.logoCircle.x) < self.logoCircle.radius and math.abs(my - self.logoCircle.y) < self.logoCircle.radius then
        if Input:pressed("menuClickLeft") then
            Timer.tween(2, self.logoCircle, {rotation = self.logoCircle.rotation + 30}, "out-quad")
        end
    end
    local bubbleBeatTimers = {}
    self.logoCircleFill.rotation = self.logoCircle.rotation -- why do the calculations twice?
    for i, Bubble in ipairs(self.bubbles) do
        Bubble:update(dt)
                Bubble.rotation = Bubble.rotation + math.cos(love.timer.getTime() * 0.5 + i) * 30 * dt

        Bubble.x, Bubble.y = Bubble.x + math.sin(love.timer.getTime() * 0.5 + i) * 30 * dt, Bubble.y - 10 * dt

        if self.bpmHandler:wasBeatHit() then
            self.bubbleTimerBooleanIdk = self.bubbleTimerBooleanIdk or false
            if bubbleBeatTimers[i] then Timer.cancel(bubbleBeatTimers[i]) end

                bubbleBeatTimers[i] = Timer.tween(0.5, Bubble, {y = Bubble.y - 30}, "out-quad")

        end
        Bubble.y = Bubble.y + math.cos(love.timer.getTime() * 0.5 + i) * 30 * dt
        if Bubble.x > baseScreenRatio.x + Bubble.radius+10 then Bubble.x = -Bubble.radius+10
        elseif Bubble.x < -Bubble.radius+10 then Bubble.x = baseScreenRatio.x + Bubble.radius+10 end
        
        if Bubble.y < -Bubble.radius+10 then Bubble.y = baseScreenRatio.y + Bubble.radius+10 end
    end

    local totalSongListHeight = #songButtons * (songButtonHeight + songButtonSpacing)
    local minHoveredSong = -totalSongListHeight + songButtonHeight + songButtonSpacing * 2
    local maxHoveredSong = songButtonSpacing * 2
  --  hoveredSong = math.max(math.min(hoveredSong, maxHoveredSong), minHoveredSong)



    if self.window then self.window:update(dt) end

    if self.previousSong then self.previousSong:setVolume(self.previousAudioVolume or 0) end
    if self.currentAudio then self.currentAudio:setVolume(self.currentAudioVolume or 0) end
end

function songSelect:checkForSongLoop()
    if not self.currentLoopPoint then return end
    if not self.currentAudio then return end


    if self.currentAudio:tell("seconds")*1000 < tonumber(self.currentLoopPoint) then -- we need to seek to the loop point 
        self.currentAudio:seek(self.currentLoopPoint/1000)
        MusicTime = self.currentAudio:tell()
        -- this is where that one bug happens,,, idk what to try to fix this really..
        if not (self.currentAudio:tell("seconds")*1000 < tonumber(self.currentLoopPoint)) then-- we just check the same conditions again and if it still is true we dont set the bpm
            self:resetBpmShit(self.currentSongInfo.bpm or 100)
        else
           -- self:loadAudio(self.currentSongInfo.path .. "/" .. self.currentSongInfo.audioFile)       -- oh my god my fucking ears do NOT uncomment this line 😭😭😭
        end
    end
end

function songSelect:mousemoved()
    local _, _, _, dy = cursor:getPosition()
    if cursor:isMouseDown() then
        hoveredSong = hoveredSong + dy
        self.ignoreInterpolation = true
    end
end

function songSelect:scroll(s)
    hoveredSong = hoveredSong + (songButtonHeight + songButtonSpacing) * s
end

function songSelect:updateSongButtons(dt)
    local function getBezierCurveEvalForSongButtonPosition(songButton)
        -- get the eval thingy for the center of the song button by doing stuff idfk
        local centerY = songButton.y+songButton.height/2
        -- check where that value is on the window Y axis
        local uhh = centerY/baseScreenRatio.y
        if uhh <0 then uhh = 0 end
        if uhh >1 then uhh = 1 end
        local ummX, ummY = self.buttonBezierCurve:evaluate(uhh)
        return ummX-baseScreenRatio.x
    end
    local speed = 10

    for i, SongButton in ipairs(songButtons) do
        if SongButton.image and SongButton.typeOf and SongButton:typeOf("GIF") then
            SongButton.cacheDirty = true
        end
        local targetY = (i * (songButtonHeight + songButtonSpacing)) + hoveredSong
        local targetX = (self.menuState == "song" and songButtonX) or baseScreenRatio.x + songButtonSpacing
        targetX = targetX + getBezierCurveEvalForSongButtonPosition(SongButton)
        if i == selectedSong and self.menuState ~= "difficulty" then targetX = targetX - 50 end
        if self.ignoreInterpolation then
            SongButton.y = targetY
        else
            SongButton.y = SongButton.y + (targetY - SongButton.y) * speed * dt
        end
        SongButton.x = SongButton.x + (targetX - SongButton.x) * speed * dt

        SongButton:update(dt)
    end
end

local BGFade
function songSelect:updateBGImage()
    local function fadeBG()
        BGAlpha = {0}
        if BGFade then Timer.cancel(BGFade) end
        BGFade = Timer.tween(0.25, BGAlpha, {1})
    end

    for i, SongButton in ipairs(songButtons) do
        if i == selectedSong then
            if SongButton.imageLoaded then
                if currentDisplayedBG ~= SongButton.image then -- its not the right image so we change it
                    previousBG = currentDisplayedBG
                    currentDisplayedBG = SongButton.image
                    -- hell, just select the current song
                    selectedSong = i     -- for what tho  
                    self.currentSongInfo = SongButton:returnInfo()
                    fadeBG()
                end
            end
        end
    end
end


function songSelect:loadAudio(path)  -- this needs to be threaded but im stupid 
    self.currentAudioVolume = 1
    self.previousAudioVolume = 1   
    self.currentPlayingSong = selectedSong
    local audio
    

    -- first we clone the current song, with its time and everything

    self.previousSong = self.currentAudio
    if self.previousSong then self.previousSong:seek(self.currentAudio:tell("seconds")) end
    --if self.currentAudio and self.currentAudio:isPlaying() then self.currentAudio:stop() end

    self.currentAudio = nil
    if not path then GlobalNotificationsHandler("no path passed into loadAudio!", "error") end
    if not love.filesystem.getInfo(path, "file") then GlobalNotificationsHandler:addNotification(self.currentSongInfo.name .. " audio file not found!", "error");  love.audio.stop(); goto skipNewAudio end
     audio = love.audio.newSource(path, "stream")
    ::skipNewAudio::

    self.currentAudio = audio

    --self.currentAudio:setVolume(0)
    if self.previousSong then self.previousSong:setVolume(1) end
    if self.currentAudio then self.currentAudio:play() else GlobalNotificationsHandler:addNotification("something broke,, idk what", "error"); return end
    if self.previousSong then self.previousSong:play() end
   -- self:resetBpmShit(self.currentSongInfo.bpm)
    MusicTime = self.currentAudio:tell()
    -- now we fade the previus one out, and fade the current one in 


    -- there is a massive bug here but we just ignore it lmao   switching songs faster than the tween finishes makes the previous song never stop (oopsies)
    if self.previousSongFade then Timer.cancel(self.previousSongFade) end
    self.previousSongFade = Timer.tween(0.1, self, {previousAudioVolume = 0, currentAudioVolume = 1}, "linear", function() if self.previousSong then self.previousSong:stop(); self.previousSong = nil end end)

    -- this is sorta hacky, but itll work 
    -- we set the song to loop, and just check if its before the preview time, if it does, we seek to the preview time, itll play till the end, loop, then seek again
    self.currentAudio:setLooping(true)
end



function songSelect:updateDifficultyButtons(dt)
    local speed = 10
    for _, DifficultyButton in ipairs(difficultyButtons) do
        local targetX = (self.menuState == "difficulty" and songButtonX) or (baseScreenRatio.x + songButtonSpacing)
        DifficultyButton.x = DifficultyButton.x + (targetX - DifficultyButton.x) * speed * dt
    end
end

function songSelect:tweenSongInfo()
    self.songInfoY = -50
    if self.songInfoTween then Timer.cancel(self.songInfoTween) end
    self.songInfoTween = Timer.tween(0.15, self, {songInfoY = 20}, "out-back")
end

function songSelect:checkForSongButtonClicks(requireClick)
    local buttonInfo = false
    if self.menuState == "difficulty" then return end
    for i, SongButton in ipairs(songButtons) do
        local thething = function()
                self.currentSongInfo = SongButton:returnInfo()
                self:tweenSongInfo()
                if not self.currentSongInfo.bpm then 
                    selectedSong = i
                    self.currentSongInfo = SongButton:returnInfo()
                end
                self:resetBpmShit(self.currentSongInfo.bpm or 100)
                buttonInfo = SongButton:onClick()
                local uhhhOtherStuffIdk = SongButton:returnInfo()
                if self.currentPlayingSong ~= i then self:loadAudio(self.currentSongInfo.path .. "/" .. self.currentSongInfo.audioFile) end
                self.currentPlayingSong = i

                self.currentLoopPoint = uhhhOtherStuffIdk.songPreviewTime
                if selectedSong ~= i then selectedSong = i return end
                if AchievementHandler then AchievementHandler:unlock("select song") end
                self.menuState = "difficulty"
                self.uglyDiffButtonIssueFix = true    -- this is gross
                self:setupDifficultyList(buttonInfo.path,buttonInfo.color)
        end
        if requireClick then
            if mouseOver(SongButton) then
                if Input:pressed("menuClickLeft") then

                    thething()
                end
            end
        else
            thething()
        end
    end
end

function songSelect:checkForDifficultyButtonClicks() 
    local buttonInfo = false
    if self.uglyDiffButtonIssueFix then self.uglyDiffButtonIssueFix = false; return end  -- fucking disgusting fix 
    for _, SongButton in ipairs(difficultyButtons) do
        if mouseOver(SongButton) then
            if Input:pressed("menuClickLeft") then
                --selectedSong = i
                buttonInfo = SongButton:onClick()
                    local switchStateFunc = function()
                        if songButtons[selectedSong].isNew then songButtons[selectedSong].isNew = false end
                        self:switchToPlaystate(buttonInfo)
                    end

                if switchingState then return end


                -- first we check for warnings
                if buttonInfo.warnings then



                    -- then we make the warning window if any were found
                    local warnings = {}
                    local finalString = ""

                    for i, Warning in ipairs(buttonInfo.warnings) do  -- get all the warnings and find their strings in the loaded locale
                        local warningStr =LocaleHandler:getText("Warnings", "Warning " .. Warning.warning) .. "\n"
                        table.insert(warnings,warningStr)
                    end
                    -- now we create the finalized message for the window
                    for i = 1,#warnings do
                        if i == 1 then -- this is the start, so we gotta add the main message thingy
                            finalString = finalString .. LocaleHandler:getText("Warnings", "Content") .. "\n\n"
                        end
                        -- now we add the warnings themselves
                        finalString = finalString .. warnings[i] -- no need to add a \n cuz we already added it to the string in the warnings table

                        -- check if its the last one, if it is, we add the end part 
                        if i == #warnings then 
                            finalString = finalString .. "\n" .. LocaleHandler:getText("Warnings", "Still Wanna Play")
                        end
                    end
                    -- now we make the window
                    self.window = window(self,LocaleHandler:getText("Warnings","Hold Up"), 
                        finalString,  
                        {
                            {text = LocaleHandler:getText("UI", "Yes"), func = function () switchStateFunc(); self.window:killYourself() end},
                            {text = LocaleHandler:getText("UI", "No"), func = function() self.window:killYourself() end}
                        },
                        false,false,"Don't Show Again"
                    )
                else -- no warnings so just play the song
                    switchStateFunc()
                end
                

            end
            -- why go through the rest? we already have a match so just break
            break
        end
    end
end

function songSelect:switchToPlaystate(buttonInfo)
    local time = 0.4
    local mods = self.modifiersMenu:returnMods()
    Timer.tween(time,self.logoH, {x = baseScreenRatio.x/2, y = baseScreenRatio.y/2}, "out-quad")
    Timer.tween(time, self, {currentAudioVolume = 0.25})

    Timer.tween(time,self.coverBG, {alpha = 1}, "out-quad", function() 
        State.switch(States.menu.gameTransition, buttonInfo.mode, buttonInfo.path, 
        currentDisplayedBG, self.logoH, BGDarkness, 
        {audio = self.currentAudio, volume = self.currentAudio:getVolume(), time = self.currentAudio:tell("seconds")},mods)
    end)

    switchingState = true
end


function songSelect:draw(dt)
    -- draw background from selected song button
    if not dontShowBG then
        if previousBG then love.graphics.draw(previousBG,0,0, nil, baseScreenRatio.x/previousBG:getWidth(), baseScreenRatio.y/previousBG:getHeight()) end 
        love.graphics.setColor(1,1,1,BGAlpha[1])
        if currentDisplayedBG then love.graphics.draw(currentDisplayedBG,0,0, nil, baseScreenRatio.x/currentDisplayedBG:getWidth(), baseScreenRatio.y/currentDisplayedBG:getHeight()) end
    end

    love.graphics.setColor(0,0,0,BGDarkness or 0)

    if not switchingState then love.graphics.rectangle("fill", 0,0,baseScreenRatio.x,baseScreenRatio.y) end
        love.graphics.setColor(11,1,1)
    for _, Bubble in ipairs(self.bubbles) do
        Bubble:draw()
    end

    love.graphics.setColor(1,1,1,0.05)
    for _, squiglyLine in ipairs(self.squiglyLines) do
        squiglyLine:draw(dt)
    end

    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(5)
   -- love.graphics.line(songButtonX-songButtonSpacing, songButtonSpacing*2, songButtonX-songButtonSpacing, baseScreenRatio.y-songButtonSpacing*2)

    for _, SongButton in ipairs(songButtons) do
        SongButton:draw()
    end



    if songSelect.difficultyListDraw then songSelect:difficultyListDraw() end
    self:drawSongInfo(20,self.songInfoY,15)

    self:drawCircleWithContents()
    self.modifiersMenu:draw()

    -- this is a sorta ugly hack but it works 
    if switchingState then
        love.graphics.setColor(1,1,1,self.coverBG.alpha)
        if currentDisplayedBG then love.graphics.draw(currentDisplayedBG,0,0, nil, baseScreenRatio.x/currentDisplayedBG:getWidth(), baseScreenRatio.y/currentDisplayedBG:getHeight()) end
        love.graphics.setColor(0,0,0,BGDarkness or 0)
        love.graphics.rectangle("fill", 0,0,baseScreenRatio.x,baseScreenRatio.y)
        love.graphics.setColor(1,1,1)
    end
    self.logoH:draw()

    if self.window then self.window:draw() end


    menuSongButton:resetCounts()
end

function songSelect:drawSongInfo(x, y, spacing)
    --[[
    love.graphics.setColor(0,0,0)

    local originalX, originalY = x,y
    love.graphics.setFont(SkinHandler:getFont("Menu", 75))
    love.graphics.printf(self.currentSongInfo.name or (LocaleHandler:getText("GeneralErrors", "No Song Name")), x, y, 2000, "left")
    y = y + SkinHandler:getFont("Menu", 75):getHeight() + spacing

    love.graphics.setFont(SkinHandler:getFont("Menu", 30))
    love.graphics.printf(LocaleHandler:getText("Menu","Song By").. (self.currentSongInfo.artist or (LocaleHandler:getText("GeneralErrors", "No Artist Name"))), x, y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 30):getHeight() + spacing

    love.graphics.printf(LocaleHandler:getText("Menu","Charted By").. (self.currentSongInfo.charter or LocaleHandler:getText("GeneralErrors", "No Charter Name")), x,y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 30):getHeight() + spacing

    love.graphics.setFont(SkinHandler:getFont("Menu", 20))
    love.graphics.printf(LocaleHandler:getText("Menu", "Length") .. LocaleHandler:getText("Misc", "Placeholder"), x, y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 30):getHeight() + spacing

    love.graphics.printf(LocaleHandler:getText("Menu","BPM") .. (self.currentSongInfo.bpm or LocaleHandler:getText("GeneralErrors", "unknown")), x, y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 30):getHeight() + spacing

    love.graphics.printf(LocaleHandler:getText("Menu","LN%") .. LocaleHandler:getText("Misc", "Placeholder"), x, y, 1000, "left")
    --]]

    -- now we do all that shit again but slightly different yay !!!!!1!!!!!!!!!

    love.graphics.setColor(1,1,1)

   -- local x,y = originalX,originalY-1
    love.graphics.setFont(SkinHandler:getFont("Menu", 75))
    printFOutline({0,0,0}, 3, self.currentSongInfo.name or (LocaleHandler:getText("GeneralErrors", "No Song Name")), x, y, 2000, "left")
    y = y + SkinHandler:getFont("Menu", 76):getHeight() + spacing

    love.graphics.setFont(SkinHandler:getFont("Menu", 30))
    printFOutline({0,0,0}, 3,LocaleHandler:getText("Menu","Song By").. (self.currentSongInfo.artist or (LocaleHandler:getText("GeneralErrors", "No Artist Name"))), x, y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 31):getHeight() + spacing

    printFOutline({0,0,0}, 3,LocaleHandler:getText("Menu","Charted By").. (self.currentSongInfo.charter or LocaleHandler:getText("GeneralErrors", "No Charter Name")), x,y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 31):getHeight() + spacing

    love.graphics.setFont(SkinHandler:getFont("Menu", 20))
    printFOutline({0,0,0}, 3,LocaleHandler:getText("Menu", "Length") .. LocaleHandler:getText("Misc", "Placeholder"), x, y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 31):getHeight() + spacing

   printFOutline({0,0,0}, 3,LocaleHandler:getText("Menu","BPM") .. (self.currentSongInfo.bpm or LocaleHandler:getText("GeneralErrors", "unknown")), x, y, 1000, "left")
    y = y + SkinHandler:getFont("Menu", 31):getHeight() + spacing

    printFOutline({0,0,0}, 3,LocaleHandler:getText("Menu","LN%") .. LocaleHandler:getText("Misc", "Placeholder"), x, y, 1000, "left")

end


function songSelect:drawCircleWithContents()
    self.logoCircleFill:draw()
    self.logoCircle:draw()
    local logoHsx, logoHsy = 0.17,0.17
    local logoHoffset = 80
    local timeOffset = 150

    local timeStr = CHETime.session.."\n"..CHETime.real

    --love.graphics.draw(self.logoH, self.logoCircle.x+100, self.logoCircle.y-logoHoffset-70, 0, logoHsx, logoHsy, self.logoH:getWidth()/2, self.logoH:getHeight()/2)
    love.graphics.setFont(SkinHandler:getFontLegacy("Menu Large"))
    love.graphics.setColor(1,1,1)
    love.graphics.printf(timeStr, self.logoCircle.x+200, self.logoCircle.y-100, 150, "left")
end

function songSelect:exit()
    self:clearBanners()
end

return songSelect
