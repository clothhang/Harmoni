local mania = Class:extend("mania")
local videoFade = 0
local played = false

function mania:new(chart, parent, fullChart, mods)
    videoFade = 0
    played = false
    self.mods = mods


    print(fullChart.meta.difficulty)
    self.parent = parent
    self.videoBackground = nil
    self.chartPath = getDirectory(chart)

    self.debug = false
    self.songStarted = false

    self.chart = self:setUpChart(chart, fullChart)
    self.scoreHandler = ScoreHandler

    self.endSongTimer = 0

    self.paused = false
    --score shit 
    self.scoreHandler:resetScore({difficulty = (fullChart.meta.difficulty) or 0})
    --ScoreHandler:setupPerformanceRating()

    self.scoresPerJudgements = self.scoreHandler:getScorePerJudgment(self.totalNotes)

    self.HUDBeatSize = 1
    print("FJIDFJOFI",self.scoresPerJudgements.perfect)
    print(self.chart)
    self.laneSpacing = 30
    self.laneYOffset = 30
    self.song = love.audio.newSource(self.chartPath .. "/" .. self.chart.meta.audioFile, "static")
    self.song:setLooping(false)
    self.playField = {maniaPlayField(self.chart, self)}

    mania.judgements = require("modules.gamemodes.mania.maniaJudgements")

    self.inputsPerSecond = {}
    self.notesPerSecond = {}

    self.ableToModscript = false

    self:setUpObjects()
    self.pauseButtonWidth = 800
    self.pauseButtonHeight = 200

    self.pauseButtons = {
        {text = "Resume", subtext = "Don't quit!", func = function() self:unpause() end, width = self.pauseButtonWidth, height = self.pauseButtonHeight, x = baseScreenRatio.x/2, y = baseScreenRatio.y/2-300, color = rgb({79,240,141}), liquidAssX = 0, liquidAssY = 0},   -- old harmoni ahh code 🥀
        {text = "Restart", subtext = "Try again?", func = function() self:restart() end, width = self.pauseButtonWidth, height = self.pauseButtonHeight, x = baseScreenRatio.x/2, y = baseScreenRatio.y/2, color = rgb({240,219,91}), liquidAssX = 0, liquidAssY = 0},
        {text = "Quit", subtext = "Giving up?", func = function()  self:endSong() end, width = self.pauseButtonWidth, height = self.pauseButtonHeight, x = baseScreenRatio.x/2,y = baseScreenRatio.y/2+300, color = rgb({237,102,92}), liquidAssX = 0, liquidAssY = 0},
    }
end


function mania:countdownhandler()

end

function mania:liquidAssPauseButtons(button,what,liquidAssTime)
    if what == "clicked" then
        self.dontAllowPauseClicks = true
        button.clicked = true
        button.liquidAssX = 100
        button.liquidAssY = -20
        Timer.tween(liquidAssTime, button, {liquidAssX = 10, liquidAssY = 10}, "out-elastic", function() self.dontAllowPauseClicks = false end)
    elseif what == "mouseover" then
        button.isMousingOver = true
        Timer.tween(liquidAssTime, button, {liquidAssX = 110}, "out-elastic")
    else
        button.isMousingOver = false
        Timer.tween(liquidAssTime, button, {liquidAssX = 0}, "out-elastic")
    end
    button.clicked = false
end

function mania:pause(showMenu)  -- i wanna implement pausing into gamemodemanager instead,,,, but im lazy and this seems easier lol
    showMenu = (showMenu == nil) and true or false
    self.song:pause()

    self.unpausing = false -- i hate this whole game genuienly and shit like this pisses me off more than it should

    self.paused = true  -- dont toggle since this only pauses, it will never be called to unpause
    self.showMenu = showMenu
    if self.videoBackground then self.videoBackground:pause() end
end

function mania:restart()
    self.parent:restart()
end

function mania:unpause()
    self.unpausing = true --kill myself 

    self.unpauseBar = countdownBar(baseScreenRatio.x/2, baseScreenRatio.y/2-50, 500, 20, 1.5)  -- we dont call this self.timeBar since we arent going to use the timebar.complete thingy, because im a lazy piece of shit and wanna do it incorrectly instead
    Timer.after(1.5, function()
        self.song:play()
        self.paused = false
        if self.videoBackground then self.videoBackground:play() end
        MusicTime = MusicTimeManager.resyncMusicTime(self.song)
    end)
end

function mania:startSong(countdown)
    self.songStarted = true
    self.parent:startSong(countdown)
end

function mania:resetBpmShit(newBpm)
    self.bpmHandler:init()
    self.bpmHandler:setBpm(newBpm or 100)
end

function mania:setUpObjects()
    local backgroundPath = self.chartPath .. self.chart.meta.backgroundFile
    self.background = sharedBackground(backgroundPath, gameplayBackgroundDim, 1)
    self.HUD = maniaHUD(self)
    self.bpmHandler = require("modules.game.bpm")
    self:resetBpmShit(0)

    self.comboAlert = maniaComboAlert()

    self.HUD:sendScoreHandlerScores(self.scoreHandler.Scores)

    self.judgementCount = maniaJudgmentCount()
    self.judgementCount:sendJudgements(self.judgements)

    self.countdownBar = countdownBar(baseScreenRatio.x/2, baseScreenRatio.y/2-50, 500, 20, 1.5)

    local songLength = self.song and self.song:getDuration("seconds") or 0
    self.timeRemaingBar = UITimeRemaing(
        0, songLength,
        0, baseScreenRatio.y - 50,
        baseScreenRatio.x,
        self,
        5, -5, 5, 30
    )

    self.judgementObject = maniaJudgement(
        SkinHandler:getParam("Judgement X Offset"),
        SkinHandler:getParam("Judgement Y Offset"),
        SkinHandler:getParam("Judgement Size"),
        self.judgements,
        self
    )

    self.comboCount = maniaComboCount(
        SkinHandler:getParam("Combo X Offset"),
        SkinHandler:getParam("Combo Y Offset")
    )

    self.healthBar = maniaHealthBar(
        SkinHandler:getParam("Health Bar X Offset"),
        SkinHandler:getParam("Health Bar Y Offset"),
        SkinHandler:getParam("Health Bar Width"),
        SkinHandler:getParam("Health Bar Height")
    )
end

function mania:setUpChart(chartpath, chart)
    local songPath = getDirectory(chartpath)
    local parsed = chart
    self.totalNotes = #parsed.hitObjects

    local maniaChart = {
        meta = parsed.meta,
        bpm = {},
        hitObjects = {},
        scrollVelocities = {}
    }

    -- Setup video background if valid
    if parsed.meta.backgroundVideo and self.mods["NVB"] then
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
        table.insert(maniaChart.bpm, {startTime = BpmChange.startTime, bpm = BpmChange.bpm})
    end

    for _, SliderVelocity in ipairs(parsed.sliderVelocities) do
        table.insert(maniaChart.scrollVelocities, {
            startTime = SliderVelocity.startTime,
            multiplier = SliderVelocity.multiplier
        })
    end
    if self.mods["NSV"] then maniaChart.scrollVelocities = {} end
    for _, obj in ipairs(parsed.hitObjects) do
        if self.mods["NLN"] then obj.endTime = nil end
        table.insert(maniaChart.hitObjects, {
            type = obj.type,
            startTime = obj.startTime,
            endTime = obj.endTime,
            lane = obj.lane
        })
    end

    maniaChart.scrollSpeedFactors = parsed.scrollSpeedFactors or {}

    if self.mods["NVB"] then
        self.videoBackground = nil
    end


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

    return maniaChart
end

function mania:update(dt)
    Profiler:start("GAMEMODE:UPDATE")
    self:updateObjects(dt)

    
    for _, playField in ipairs(self.playField) do
        playField:update(dt)
    end
    -- should only ever update the FIRST playfield
    --[[ self.playField[1]:update(dt) ]]

    if self.song and self.playField[1].finished then
        print("SONG END 1")
        if not self.song:isPlaying() then
            print("SONG END 2")
            if AchievementHandler then AchievementHandler:unlock("finished song") end
            self:endSong()
        end
    end

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

    if thething then
        thething = false
        self:endSong()
    end

    for i = 1,#self.inputsPerSecond do
        self.inputsPerSecond[i] = self.inputsPerSecond[i]-1000*dt
        if self.inputsPerSecond[i] <= 0 then table.remove(self.inputsPerSecond, i) break end
    end

    for i = 1,#self.notesPerSecond do
        self.notesPerSecond[i] = self.notesPerSecond[i]-1000*dt
        if self.notesPerSecond[i] <= 0 then table.remove(self.notesPerSecond, i) break end
    end
    
    self.endSongTimer = math.max(self.endSongTimer + (Input:down("menuBack") and not self.paused and 1200 or -3000) * dt,0)
    if self.endSongTimer>=230 then self.endSongTimer =0 self:pause() end

    if self.paused then
        local liquidAssTime = 0.5
        local mx,my = cursor:getPosition()
        if self.dontAllowPauseClicks then goto continue end
        for i, Button in ipairs(self.pauseButtons) do
            local bx,by = Button.x-Button.width/2, Button.y-Button.height/2
            local bw, bh = bx+Button.width, by+Button.height
            if mx >= bx and mx <= bw and my >= by and my <= bh then

                if not Button.isMousingOver and not Button.clicked then self:liquidAssPauseButtons(Button, "mouseover", liquidAssTime) end
                if Button.isMousingOver and not Button.clicked and Input:pressed("menuClickLeft") then 
                    self:liquidAssPauseButtons(Button, "clicked", liquidAssTime) 
                Timer.after(liquidAssTime, function() Button.func() end) 
               -- Button.func()
                end
            else
                if Button.isMousingOver and not Button.clicked then self:liquidAssPauseButtons(Button, nil, liquidAssTime) end
            end
        end
        ::continue::
    end


    -- counts the current beat based off of music time and bpm changes
    if self.chart and self.chart.bpm then
        for i, BpmChange in ipairs(self.chart.bpm) do
            if MusicTime >= BpmChange.startTime and not BpmChange.wasHit then
                self:resetBpmShit(BpmChange.bpm or 100)
                BpmChange.wasHit = true
            end
        end
    end
    Profiler:stop("GAMEMODE:UPDATE")

    --local avg, last = Profiler:getAverage("GAMEMODE:UPDATE"), Profiler:getLastTime("GAMEMODE:UPDATE")
    --print("Time to update MANIA GAMEMODE: ", last, "\nAverage: ", avg)
end

function mania:endSong()
    print("mania:endSong()")
    if self.song then self.song:stop();print("SONG END 3") end
  --  love.audio.stop()
    self.song = nil
    self.chart = nil
    self.playField = {}
    State.switch(States.game.resultsState, self)
end


function mania:updateObjects(dt)
    if self.videoBackground then self.videoBackground:update(dt) end
    self.background:update(dt)
    self.countdownBar:update(dt)
    if self.unpauseBar then self.unpauseBar:update(dt) end
    if self.countdownBar.complete and not self.songStarted then self:startSong(1) end
    self.judgementObject:update(dt)
    if self.song then self.timeRemaingBar:update(dt, self.song:tell()/self.song:getDuration()) end
    self.comboCount:update(dt)
    self.healthBar:update(dt)
    self.HUD:sendScoreHandlerScores(self.scoreHandler.Scores)
    self.bpmHandler:update(dt)

    if self.lyricsRenderer then
        self.lyricsRenderer:update(dt, MusicTime/1000)
    end

    self.HUD:update(dt) -- we also gotta send values to the hud
    self.HUD:sendValues(self.scoreHandler:getScore("printable"), self.scoreHandler:getAccuracy("printable"))

    --[[ if self.healthBar.health <= 0 and not self.mods["NF"] then
        if AchievementHandler then AchievementHandler:unlock("failed song") end
        self:gameOver()
    end ]]

    if self.bpmHandler:wasBeatHit() then
        self:onBeat()
    end
end

local HUD_BEAT_SIZE_MULT = 1.0065
function mania:onBeat()
    if self.beatFuckThingyIdk == nil then self.beatFuckThingyIdk = false end
            self.beatFuckThingyIdk = not self.beatFuckThingyIdk
    if self.timeBarBeatTween then Timer.cancel(self.timeBarBeatTween) end
    local timeBarTime = 1
    local timeBarAmplitude = 5
    if self.beatFuckThingyIdk then 
        self.timeRemaingBar.squiglyLine.amplitude = timeBarAmplitude
        self.timeBarBeatTween = Timer.tween(0.5, self.timeRemaingBar.squiglyLine, {time = self.timeRemaingBar.squiglyLine.time-1, amplitude = 0}, "out-quad")
    end
    if self.healthBarBeatTween then Timer.cancel(self.healthBarBeatTween) end
    self.healthBar.line.amplitude = 5
    self.healthBarBeatTween = Timer.tween(0.5, self.healthBar.line, {time = self.healthBar.line.time-5, amplitude = 0}, "out-quad")    -- FAKE liquid ass!!

    self.HUDBeatSize = 1 * HUD_BEAT_SIZE_MULT
    if self.HUDSizeTween then Timer.cancel(self.HUDSizeTween) end   -- OOH EMM GEE ITS EFF ENN EFF !!!!!
    self.HUDSizeTween = Timer.tween(0.5, self, {HUDBeatSize = 1}, "out-quad")

end

function mania:gameOver()
    self:endSong()  -- remove this to see the gameover, but youll be softlocked

    if self.parent.gameOver then return end
    self.parent.gameOver = true
    for _, playField in ipairs(self.playField) do
        playField:gameOver()
    end

end


function mania:draw()
    Profiler:start("GAMEMODE:DRAW")
    self.background:draw()
    if self.videoBackground then
        self.videoBackground.alpha = videoFade
        self.videoBackground:draw()
    end

    local coverAlpha = 1 - (Settings:getValue("Gameplay", "Mania", "Background Brightness") / 100)
    love.graphics.setColor(0, 0, 0, coverAlpha)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1,1,1)

    -- Prepare batches
    local arrowBatch = SkinHandler:getBatch("Arrows")
    local receptorBatch = SkinHandler:getBatch("Receptors")
    local noteBatch = SkinHandler:getBatch("Notes")
    local judgementBatch = SkinHandler:getBatch("Judgements")

    if arrowBatch then arrowBatch:clear() end
    if receptorBatch then receptorBatch:clear() end
    if noteBatch then noteBatch:clear() end
    if judgementBatch then judgementBatch:clear() end

    for _, playField in ipairs(self.playField) do
        playField:draw()
    end

    if arrowBatch then love.graphics.draw(arrowBatch) end
    if receptorBatch then love.graphics.draw(receptorBatch) end
    if noteBatch then love.graphics.draw(noteBatch) end

    self.judgementObject:draw()
    if judgementBatch then love.graphics.draw(judgementBatch) end

    self.comboCount:draw()
    self.timeRemaingBar:draw()
    self.healthBar:draw()

    self.countdownBar:draw()
    if self.unpauseBar then self.unpauseBar:draw() end
    love.graphics.translate(baseScreenRatio.x/2, baseScreenRatio.y/2)
    love.graphics.scale(self.HUDBeatSize)
    love.graphics.translate(-baseScreenRatio.x/2, -baseScreenRatio.y/2)

    self.HUD:draw()

    self.comboAlert:draw()
    --love.graphics.scale(-self.HUDBeatSize)


    self.judgementCount:draw()

    if self.lyricsRenderer then
        self.lyricsRenderer:draw(self.song:tell())
    end

    local target = (self.paused and not self.unpausing and self.showMenu) and 0.8 or 0
    if not self.pauseAlpha then self.pauseAlpha = 0 end
    self.pauseAlpha = lerp(self.pauseAlpha, target, 0.5)
    love.graphics.setColor(0,0,0,self.pauseAlpha)

    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1,1,1)

    if self.paused and not self.unpausing and self.showMenu then
        for i,Button in ipairs(self.pauseButtons) do -- this shit look like old harmoni 
            love.graphics.setColor(Button.color)
            love.graphics.rectangle("fill", Button.x-Button.width/2-Button.liquidAssX/2, Button.y-Button.height/2-Button.liquidAssY/2, Button.width+Button.liquidAssX, Button.height+Button.liquidAssY, 10, 10)
            love.graphics.setFont(SkinHandler:getFont("Menu", 80))
            love.graphics.setColor(0,0,0)
            love.graphics.printf(Button.text, Button.x-Button.width/2, Button.y-love.graphics.getFont():getHeight()/2-25, Button.width, "center")
            love.graphics.setFont(SkinHandler:getFont("Menu", 30))
            love.graphics.setColor(0,0,0)
            love.graphics.printf(Button.subtext, Button.x-Button.width/2, Button.y-love.graphics.getFont():getHeight()/2+30, Button.width, "center")
            love.graphics.setColor(1,1,1)
        end
    end

    -- draw the pause fade over everything else
    love.graphics.setColor(0,0,0,(self.endSongTimer/1000)*0.8)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)

    love.graphics.setColor(1,1,1,1)

    if self.debug then 
        love.graphics.print(MusicTime, 250, 400)
    end

    Profiler:stop("GAMEMODE:DRAW")
    --[[ local avg, last = Profiler:getAverage("GAMEMODE:DRAW"), Profiler:getLastTime("GAMEMODE:DRAW")
    print("Time to draw MANIA GAMEMODE: ", last, "\nAverage: ", avg) ]]
end

return mania
