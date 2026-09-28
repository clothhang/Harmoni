local gameModeManager = State()

function gameModeManager:enter(s,mode,chart,fullchart,mods)
    self.gameMode = nil

    self.s,self.mode,self.chart,self.fullchart,self.mods = s,mode,chart,fullchart,mods

    print("Game Mode Manager Entered with mode: " .. mode)
    if mode == "mania" then
        self.gameMode = mania(self.chart, self, self.fullchart, self.mods)
    elseif mode == "slider" then
        self.gameMode = slider(chart, self, fullchart)
    elseif mode == "drums" then
        self.gameMode = drums(self.chart, self, self.fullchart, self.mods)
    end



    self.gameOver = false

    cursor.fadeOutWhenIdle = true    -- why dont we just add a check to the cursor to see if we are in gamemodemanager
                                     -- because its not like the cursor will only ever fade out in gamemodemanager

    gameModeManager:initializeSong()
    if mode == "mania" then SongScript:load(self.gameMode.chartPath .. "mod/script.lua") end -- TEMP cuz i wanna add scripts to drums (and fucking slider if it ever doesnt suck)
    self.inSong = true  

   if mode == "mania" then  SongScript:call("OnStart") end
end

function gameModeManager:restart()
    self:enter(self.s,self.mode,self.chart,self.fullchart,self.mods)
end

function gameModeManager:initializeSong()
    MusicTime = -100000 -- we set this to something wild just so that it wont somehow reach 0 before we want
end

function gameModeManager:startSong(countdown)
    MusicTime = 0 - (countdown or 0)*1000
end

function gameModeManager:update(dt)
    if not self.gameOver and not self.gameMode.paused then
        MusicTime = MusicTimeManager.updateMusicTime(MusicTime, dt)
        if MusicTimeManager.needsResync(self.gameMode.song) then
            MusicTime = MusicTimeManager.resyncMusicTime(self.gameMode.song)
        end
    end

    if States.game.gameModeManager.gameMode.ableToModscript then
        SongScript:update(dt)
    end
    self.gameMode:update(dt)
end

function gameModeManager:draw()
    self.gameMode:draw()
end

function gameModeManager:exit()
    cursor.fadeOutWhenIdle = false
    cursor.fadeOutAlpha = 1
    self.inSong = false
end

return gameModeManager