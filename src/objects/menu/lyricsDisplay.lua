local lyricsDisplay = Class:extend("lyricsDisplay")
local utf8 = require("utf8")

local function parseDisplayColours(text)
    local runs = {}
    local activeColour = nil
    local colourStack = {}

    local function addRun(value)
        if value == "" then return end

        local last = runs[#runs]

        if last and last.colour == activeColour then
            last.text = last.text .. value
        else
            table.insert(runs, {
                text = value,
                colour = activeColour
            })
        end
    end

    local position = 1

    while position <= #text do
       local startPos, endPos, tag = text:find("<([^>]+)>", position)

        if not startPos then
            addRun(text:sub(position))
            break
        end

        addRun(text:sub(position, startPos - 1))

        local hex = tag:match("^c=(#%x%x%x%x%x%x)$")

        if hex then
            table.insert(colourStack, activeColour)

            activeColour = {tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255}
        elseif tag == "/c" then
            activeColour = table.remove(colourStack)
        end

        position = endPos + 1
    end

    return runs
end

local function getPlainLyric(text)
    return tostring(text or ""):gsub("<c=#%x%x%x%x%x%x>", ""):gsub("</c>", "")
end

function lyricsDisplay:new(x, y, width, height, lyrics)
    if type(lyrics) ~= "table" then error("are you fucking stupid or something?") end

    self.x, self.y, self.width, self.height = x, y, width, height
    self.lyrics = lyrics
    self.currentLyric = 0
    self.lyricRectWidth = self.width
    self.lineSpacing = 50
    self.timers = {}

    self:setUpLyrics()
end

function lyricsDisplay:setUpLyrics()
    local font = SkinHandler:getFont("Menu", 50)
    love.graphics.setFont(font)

    local currentY = self.y
    local lineHeight = font:getHeight()
    local wrapLimit = self.lyricRectWidth - 30

    for _, Lyric in ipairs(self.lyrics) do
        local text = getPlainLyric(Lyric.text)
        local _, wrappedLines = font:getWrap(text, wrapLimit)

        local textHeight = #wrappedLines * lineHeight

        Lyric.rectangle = {
            x = self.x,
            y = currentY,
            width = self.lyricRectWidth,
            height = textHeight
        }

        currentY = currentY + textHeight + self.lineSpacing
    end
end

function lyricsDisplay:update(dt, musicTime)
    self.lastLyricHitByTime = self.lastLyricHitByTime or 0
    self.lastMusicTime = self.lastMusicTime or 0

    if musicTime < self.lastMusicTime then
        for i, Lyric in ipairs(self.lyrics) do
            if Lyric.time > musicTime then
                Lyric.hit = false
            else
                Lyric.hit = true
                self.lastLyricHitByTime = i
            end
        end

        local latest = 0
        for i, Lyric in ipairs(self.lyrics) do
            if musicTime >= Lyric.time then
                latest = i
            else
                break
            end
        end

        if latest > 0 then
            self:hitLyric(latest)
        end

        self.lastMusicTime = musicTime
        return
    end

    for i = self.lastLyricHitByTime + 1, #self.lyrics do
        local Lyric = self.lyrics[i]
        if musicTime >= Lyric.time then
            Lyric.hit = true
            self:hitLyric(i)
            self.lastLyricHitByTime = i
        else
            break
        end
    end

    self.lastMusicTime = musicTime
end


function lyricsDisplay:clickLyric()
    local CX, CY = cursor:getPosition()
    if Input:pressed("menuClickLeft") then
        for i, Lyric in ipairs(self.lyrics) do
            local rect = Lyric.rectangle
            if CX >= rect.x and CX <= rect.x + rect.width and CY >= rect.y and CY <= rect.y + rect.height then
                self.currentLyric = i
                for j, l in ipairs(self.lyrics) do
                    if j >= i then
                        l.hit = false
                    end
                end

                self.lastLyricHitByTime = i - 1

                return {lyricClick = true, time = Lyric.time}
            end
        end
    end
end

function lyricsDisplay:hitLyric(lyricIndex)
    self.currentLyric = lyricIndex
    local clicked = self.lyrics[lyricIndex]

    local centerY = self.y + self.height / 2 - clicked.rectangle.height / 2
    local offset = centerY - clicked.rectangle.y

    local topY = math.huge
    local bottomY = -math.huge
    for _, Lyric in ipairs(self.lyrics) do
        local yAfter = Lyric.rectangle.y + offset
        if yAfter < topY then topY = yAfter end
        if yAfter + Lyric.rectangle.height > bottomY then bottomY = yAfter + Lyric.rectangle.height end
    end

    if topY > self.y then
        offset = offset - (topY - self.y)
    elseif bottomY < self.y + self.height then
        offset = offset + (self.y + self.height - bottomY)
    end

    for i, Lyric in ipairs(self.lyrics) do
        if self.timers[i] then
            Timer.cancel(self.timers[i])
        end
        self.timers[i] = Timer.tween(0.1, Lyric.rectangle, { y = Lyric.rectangle.y + offset }, "in-out-quad")
    end
end


local function drawRichText(text, x, y, wrap)
    text = tostring(text or "")

    local font = SkinHandler:getFont("Menu", 50) or love.graphics.getFont()
    local previousFont = love.graphics.getFont()
    local prevR, prevG, prevB, prevA = love.graphics.getColor()

    love.graphics.setFont(font)

    local runs = parseDisplayColours(text)
    local lines = {{}}
    local cursorX = 0
    local lineHeight = font:getHeight()

    for _, run in ipairs(runs) do
        for _, code in utf8.codes(run.text) do
            local char = utf8.char(code)

            if char == "\n" then
                table.insert(lines, {})
                cursorX = 0
            else
                local charWidth = font:getWidth(char)

                if cursorX + charWidth > wrap and cursorX > 0 then
                    table.insert(lines, {})
                    cursorX = 0
                end

                local currentLine = lines[#lines]
                local last = currentLine[#currentLine]

                if last and last.colour == run.colour then
                    last.text = last.text .. char
                else
                    table.insert(currentLine, {
                        text = char,
                        colour = run.colour
                    })
                end

                cursorX = cursorX + charWidth
            end
        end
    end

    for lineIndex, line in ipairs(lines) do
        local cursorX = x
        local cursorY = y + (lineIndex - 1) * lineHeight

        for _, run in ipairs(line) do
            if run.colour then
                local r, g, b = run.colour[1], run.colour[2], run.colour[3]

                if prevR ~= 1 or prevG ~= 1 or prevB ~= 1 then
                    r = r * 0.6
                    g = g * 0.6
                    b = b * 0.6
                end

                love.graphics.setColor(r, g, b, prevA)
            else
                love.graphics.setColor(prevR, prevG, prevB, prevA)
            end

            love.graphics.print(run.text, cursorX, cursorY)
            cursorX = cursorX + font:getWidth(run.text)
        end
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(prevR, prevG, prevB, prevA)
end


function lyricsDisplay:draw()
    -- background
    love.graphics.setColor(0.5, 0.5, 0.5, 0.75)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 50, 50)

    -- define stencil mask
    local function maskShape()
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 50, 50)
    end

    love.graphics.stencil(maskShape, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    -- draw lyrics inside mask only
    local font = SkinHandler:getFont("Menu", 50)
    love.graphics.setFont(font)

    for i, Lyric in ipairs(self.lyrics) do
        if self.currentLyric == i then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0, 0, 0, 0.5)
        end

        drawRichText(
            Lyric.text,
            Lyric.rectangle.x + 30,
            Lyric.rectangle.y,
            Lyric.rectangle.width - 30
        )
    end

    -- reset
    love.graphics.setStencilTest()
    love.graphics.setColor(1, 1, 1)
end

return lyricsDisplay
