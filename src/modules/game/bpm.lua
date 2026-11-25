local bpmHandler = {}

function bpmHandler:init()
    self.bpm = 0
    self.beatInterval = 0

    self.currentMusicTime = 0
    self.nextBeatTime = 0

    self.currentBeat = 0
    self.fullBeatTime = 0

    self.beatHitOnFrame = false
end

function bpmHandler:setBpm(bpm)
    self.bpm = tonumber(bpm) or 0
    self.beatInterval = 60 / self.bpm
    self.nextBeatTime = 0
    self.currentBeat = 0
end

function bpmHandler:getBpmInterval()
    return self.beatInterval
end

function bpmHandler:getTimeToNextBeat()
    return self.nextBeatTime - self.currentMusicTime
end

function bpmHandler:update(dt)
    if not self.bpm or self.bpm <= 0 then return end

    self.currentMusicTime = (MusicTime or 0) / 1000
    self.fullBeatTime = self.currentMusicTime / self.beatInterval

    self.beatHitOnFrame = false

    if self.currentMusicTime >= self.nextBeatTime then
        self.beatHitOnFrame = true
        --print("beat handler beat hit")
        self.currentBeat = self.currentBeat + 1
        self.nextBeatTime = self.currentBeat * self.beatInterval
    end
end

function bpmHandler:wasBeatHit()
    return self.beatHitOnFrame
end

return bpmHandler