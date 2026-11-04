local songPreloader = State("songPreloader")
local msg

local songSelect

function songPreloader:enter()
    songSelect = States.menu.songSelect
    songSelect:enter(nil, nil, true)

    self.songList = SongListManager.getSongList(musicPath)
    self.currentIndex = 1
    self.currentDifficultyIndex = 1
    self.currentDifficultyList = nil

    self.songDifficultiesDone = false
    self.transitioning = false
    self.alpha = 0

    local validSongs = {}

    for _, song in ipairs(self.songList) do
        local diffList = SongListManager.getDifficultyList(musicPath .. song)

        if diffList[1] and love.filesystem.getInfo(musicPath .. song .. "/" .. diffList[1], "file") then
            table.insert(validSongs, song)
        end
    end

    self.songList = validSongs

    if #self.songList == 0 then
        self.songDifficultiesDone = true
    end

    self.images = {
        ["H"] = {image = SkinHandler:getImage("Menu", "H"), sizeX = 1, sizeY = 1, x = 0, y = 0},
        ["logo"] = {image = SkinHandler:getImage("Menu", "Main Logo"), sizeX = 1, sizeY = 1, x = 0, y = 0},
    }

    self.squiglyLine = UIsquiglyLine(0,100,baseScreenRatio.x,100,4,5,50,1,self.width)
    self.throbbert = throbbert({{1,1,1,1}, {1,1,1,1}, {1,1,1,1}})
end

function songPreloader:update(dt)
    if not self.songDifficultiesDone then
        local song = self.songList[self.currentIndex]

        if song then
            if not self.currentDifficultyList then
                self.currentDifficultyList = SongListManager.getDifficultyList(musicPath .. song)
            end

            local difficulty = self.currentDifficultyList[self.currentDifficultyIndex]

            if difficulty then
                local file = musicPath .. song .. "/" .. difficulty .. ".harmd"

                if love.filesystem.getInfo(file, "file") then
                    local fileContents = love.filesystem.read(file)

                    if not fileContents then
                        GlobalNotificationsHandler:addNotification("Couldn't read difficulty file for " .. file, "error")

                        love.filesystem.remove(file)
                    else
                        local _, version = fileContents:match("(%d+%.?%d*)%s*:%s*(%d+)")

                        if not version or tonumber(version) < difficultyCalculatorVersionNumber then
                            love.filesystem.remove(file)

                            GlobalNotificationsHandler:addNotification(song .. " " .. difficulty .. " difficulty file was outdated and has been removed.", "info")
                        end
                    end
                end

                if not love.filesystem.getInfo(file, "file") then
                    local chart = ChartParse.harmc(musicPath .. song .. "/" .. difficulty, "generate")

                    if chart and chart.meta and chart.meta.difficulty then
                        local luaString = chart.meta.difficulty .. ":" .. difficultyCalculatorVersionNumber

                        local ok = love.filesystem.write(file, luaString)

                        if not ok then
                            GlobalNotificationsHandler:addNotification("Failed to create difficulty file for " .. song .. " " .. difficulty, "error")
                        end
                    end
                end

                self.currentDifficultyIndex = self.currentDifficultyIndex + 1
            else
                self.currentIndex = self.currentIndex + 1
                self.currentDifficultyIndex = 1
                self.currentDifficultyList = nil

                if self.currentIndex > #self.songList then
                    self.songDifficultiesDone = true
                end
            end
        else
            self.songDifficultiesDone = true
        end
    end

    local canBeDone = songSelect:update(dt, true)

    if self.songDifficultiesDone and canBeDone and not self.transitioning then
        self:done()
    end
end

function songPreloader:done()
    if self.transitioning then
        return
    end

    self.transitioning = true

    msg = "Loaded! :3"
    local stateToSwitchTo = aprilFools and States.aprilfools.loading or States.menu.splash
    local alpha = aprilFools and 0 or 1

    Timer.tween(1, self, {alpha = alpha}, "linear", function()
        State.switch(stateToSwitchTo)
    end)
end

function songPreloader:draw()
    local w, h = baseScreenRatio.x, baseScreenRatio.y

    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(SkinHandler:getFontLegacy("Menu Extra Large"))

    local progress = 100

    if #self.songList > 0 and not self.songDifficultiesDone then
        progress = math.min(100, math.floor(((self.currentIndex - 1) / #self.songList) * 100))
    end

    msg = self.songDifficultiesDone and "Loaded! :3" or (progress .. "%")

    if aprilFools then
        msg = "0%"
    end

    love.graphics.printf(msg, 0, h * 0.5, w, "center")

    love.graphics.setLineWidth(15)
    love.graphics.setColor(1,1,1,1)

    States.menu.titleScreen:drawLogo(self)

    love.graphics.setColor(0,0,0,self.alpha)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1,1,1,1)
end

return songPreloader