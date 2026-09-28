local drums = Class:extend("drums")

function drums:new(chart, parent, fullChart, mods)
    self.mods = mods
    self.chartPath = getDirectory(chart)
    self.chart = self:setUpChart(chart,fullChart)

    self.judgements = require("modules.gamemodes.drums.drumsJudgements")

     -- cursor is pretty important for this mode lol, cant have it randomly dissapearing 

    self.parent = parent

    self.parent:initializeSong()

        self.song = love.audio.newSource(self.chartPath .. "/" .. self.chart.meta.audioFile, "static")
    self.song:setLooping(false)
    
        self:setUpObjects()


    self.keyboardInputs = {  -- used for keyboard only modifier
        "drumsLeftKey",
        "drumsDownKey",
        "drumsCenterKey",
        "drumsUpKey",
        "drumsRightKey"
    }
end

function drums:setUpObjects()
    
    local fieldWidth,fieldHeight  = 790,514
    local fieldX, fieldY = 624, 316
        self.inputField = drumsInputField(self,fieldX, fieldY, fieldWidth, fieldHeight)

        local backgroundPath = self.chartPath .. self.chart.meta.backgroundFile
    self.background = sharedBackground(backgroundPath, gameplayBackgroundDim, 1)
        self.bpmHandler = require("modules.game.bpm")
    self:resetBpmShit(0)
    self.lane = drumsLane(self, self.chart)


    self.countdownBar = countdownBar(baseScreenRatio.x/2, baseScreenRatio.y/2-50, 500, 20, 1.5)

        local songLength = self.song and self.song:getDuration("seconds") or 0
    self.timeRemaingBar = UITimeRemaing(
        0, songLength,
        0, baseScreenRatio.y - 50,
        baseScreenRatio.x,
        self,
        5, -5, 5, 30
    )
end

function drums:checkInput()
    -- all we do is check every frame for a left mouse click and if there is one then we trigger click in inputField
    if Input:pressed("drumsClick") then
        print("drums:checkInput()")
        self.inputField:onClick()
    end
end

function drums:checkKeyboardInput()  -- only used when the keyboard modifier is active 
    for i = 1,#self.keyboardInputs do
        if Input:pressed(self.keyboardInputs[i]) then self.inputField:onClick(i) end
    end
end

function drums:startSong(countdown)
    self.songStarted = true
    self.parent:startSong(countdown)
end

function drums:resetBpmShit(newBpm)
    self.bpmHandler:init()
    self.bpmHandler:setBpm(newBpm or 100)
end

function drums:setUpChart(chartpath, chart)
    local songPath = getDirectory(chartpath)
    local parsed = chart
    self.totalNotes = #parsed.hitObjects

    local drumsChart = {
        meta = parsed.meta,
        bpm = {},
        hitObjects = {},
        scrollVelocities = {}
    }

    -- Setup video background if valid
    if parsed.meta.backgroundVideo then
        self.videoBackground = video(
            songPath .. "/" .. parsed.meta.backgroundVideo,
            baseScreenRatio.x / 2,
            baseScreenRatio.y / 2,
            nil,
            nil,
            gameplayBackgroundDim
        )
        if not self.videoBackground.image then
            self.videoBackground = nil
        else
            self.videoBackground.scaleX = baseScreenRatio.x / self.videoBackground.image:getWidth()
            self.videoBackground.scaleY = baseScreenRatio.y / self.videoBackground.image:getHeight()
        end
    end

    for _, BpmChange in ipairs(parsed.bpm) do
        table.insert(drumsChart.bpm, {startTime = BpmChange.startTime, bpm = BpmChange.bpm})
    end

    --[[
    for _, SliderVelocity in ipairs(parsed.sliderVelocities) do
        table.insert(drumsChart.scrollVelocities, {
            startTime = SliderVelocity.startTime,
            multiplier = SliderVelocity.multiplier
        })
    end

    --]
    if self.mods["NSV"] then drumsChart.scrollVelocities = {} end
    --]]
    for _, obj in ipairs(parsed.hitObjects) do
        --if self.mods["NLN"] then obj.endTime = nil end
        table.insert(drumsChart.hitObjects, {
            type = obj.type,
            lane = obj.lane,
            startTime = obj.startTime,
        })
    end

    print("note count:",#drumsChart.hitObjects)
    

    drumsChart.scrollSpeedFactors = parsed.scrollSpeedFactors or {}

    --if self.mods["NVB"] then
     --   self.videoBackground = nil
    --end


        -- look for the lyrics file

    local validTypes = {
        "srt",
        "vtt",
        "sbv",
        "stl",
        "ass",
        "lua"
    }

    local type = ""
    local path = songPath .. "/lyrics."
    for _, t in ipairs(validTypes) do
        if love.filesystem.getInfo(path .. t, "file") then
            type = t
            break
        end
    end

    local lyrics
    if type ~= "lua" and type ~= "" then
        lyrics = CaptionParser.parse(love.filesystem.read(path .. type), type)
    elseif type == "lua" then
        lyrics = CaptionParser.parse(path .. type, type)
    end
    self.lyricsRenderer = lyricsRenderer(baseScreenRatio.x-570,30,540,baseScreenRatio.y-200, lyrics)

    return drumsChart

end

function drums:update(dt)
    cursor.fadeOutWhenIdle = false
    self:updateObjects(dt)
    
    if self.mods["NLN"] then self:checkKeyboardInput()  -- temp until i make Drums modifiers
    else self:checkInput() end

    if self.song and MusicTime >= 0 and not self.song:isPlaying() and not played and not self.paused then
        self.song:play()
        self:resetBpmShit(self.chart.meta.bpm or 100)

        if self.videoBackground then self.videoBackground:play() end
        played = true
    elseif not self.paused then
        if self.videoBackground and played then
            videoFade = math.min(videoFade + dt*5, 1)
        end
    end

end

function drums:updateObjects(dt)
    self.lane:update(dt)
    self.inputField:update(dt)
    if self.videoBackground then self.videoBackground:update(dt) end
    self.background:update(dt)
    self.countdownBar:update(dt)
    if self.countdownBar.complete and not self.songStarted then self:startSong(1) end
end

function drums:draw()
    self.background:draw()
    self.countdownBar:draw()
    self.lane:draw()
    self.inputField:draw()
    love.graphics.print(MusicTime)
end

return drums