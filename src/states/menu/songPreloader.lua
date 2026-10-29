local songPreloader = State("songPreloader") -- idk i just felt like spliting it into its own file was better 
local msg
function songPreloader:enter()
    self.songList = SongListManager.getSongList(musicPath)
    self.currentIndex = 1
    for i, song in ipairs(self.songList) do
        if not song then
            table.remove(self.songList, i)
            break
        end
        local diffList = SongListManager.getDifficultyList(musicPath .. song)
        if not diffList[1] then
            table.remove(self.songList, i)
            break
        end
        if not love.filesystem.getInfo(musicPath .. song .. "/" .. diffList[1], "file") then
            table.remove(self.songList, i)
            break
        end
    end


    self.images = {
        ["H"] = {image = SkinHandler:getImage("Menu", "H"), sizeX  = 1, sizeY = 1, x = 0, y = 0},
        ["logo"] = {image = SkinHandler:getImage("Menu", "Main Logo"), sizeX  = 1, sizeY = 1, x = 0, y = 0},
    }

    self.alpha = 0 
    self.squiglyLine = UIsquiglyLine(0,100,baseScreenRatio.x,100,4,5,50,1,self.width)
    self.throbbert = throbbert({{1,1,1,1}, {1,1,1,1}, {1,1,1,1}})
    
end

function songPreloader:update(dt)
    if self.songDifficultiesDone  then  return end
    local i = self.currentIndex
    local song = self.songList[i]
    local diffList = SongListManager.getDifficultyList(musicPath .. song)


    -- we check for a difficuly file, if there is one, then we dont do anything, if there isnt, we create it
    for i = 1,#diffList do
        -- first we check for the version number
        if love.filesystem.getInfo(musicPath .. song .."/".. diffList[i] .. ".harmd", "file") then
            local file = musicPath .. song .."/".. diffList[i] .. ".harmd"
            local filecontents = love.filesystem.read(file)
            if not filecontents then GlobalNotificationsHandler:addNotification("couldn't get difficulty file for " .. file, "error") end
            local diff,version = filecontents:match("(%d+%.?%d*)%s*:%s*(%d+)") -- still magic to me,, WHAT does this mean???
            if tonumber(version) < difficultyCalculatorVersionNumber then
                love.filesystem.remove(file)
                GlobalNotificationsHandler:addNotification(song .. diffList[i] .." Difficulty file was outdated and has been removed.", "info")
            end
        end
        if not love.filesystem.getInfo(musicPath .. song .."/".. diffList[i] .. ".harmd", "file") then
            -- we need to parse this chart and gets its difficulty rating
            local chart = ChartParse.harmc(musicPath .. song .."/" .. diffList[i], "generate")
            
            if chart.meta.difficulty then
                love.filesystem.createDirectory(musicPath .. song)
                local luaString = chart.meta.difficulty .. ":" .. difficultyCalculatorVersionNumber

                local ok = love.filesystem.write(musicPath .. song .."/".. diffList[i] .. ".harmd", luaString)
                if not ok then GlobalNotificationsHandler:addNotification("Failed to create diff file for " ..song " " .. diffList[i], "error") end
                
            end
        end
    end

    self.currentIndex = self.currentIndex + 1
    if self.currentIndex > #self.songList then
        self.songDifficultiesDone = true
    end
    --love.timer.sleep(0.03)
    if self.songDifficultiesDone then
        self:done()
    end
end

function songPreloader:done()
    msg = "Loaded! :3"
    local stateToSwitchTo = aprilFools and States.aprilfools.loading or States.menu.splash
    local alpha = aprilFools and 0 or 1
    Timer.tween(1, self, {alpha = alpha}, "linear", function() State.switch(stateToSwitchTo)end)
end

function songPreloader:draw()
    
    local w, h = baseScreenRatio.x, baseScreenRatio.y
    love.graphics.setColor(1,1,1,1)
        
    love.graphics.setFont(SkinHandler:getFontLegacy("Menu Extra Large"))

    if not self.songDifficultiesDone then msg = math.ceil(self.currentIndex/#self.songList*100) .. "%" end
    if  aprilFools then msg = "0%" end -- we gotta fake this number (obviously)

    love.graphics.printf(msg, 0, h*0.5, w, "center")



    love.graphics.setLineWidth(15)
    love.graphics.setColor(1,1,1,0.10)

    


    love.graphics.setColor(1,1,1,0.85)
    

    love.graphics.setColor(1,1,1,1)

    States.menu.titleScreen.drawLogo(self)

    love.graphics.setColor(0,0,0,self.alpha)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setColor(1,1,1,1)
    
end

return songPreloader