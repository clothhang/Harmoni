local LyricsRenderer = Class:extend("LyricsRenderer")

local function clamp(n, a, b)
    return n < a and a or (n > b and b or n)
end

local function assHexToRGBA(ass)
    if not ass then return 1,1,1,1 end
    local s = tostring(ass):gsub("^&H",""):gsub("&$","")
    if #s == 6 then s = "00"..s end
    if #s ~= 8 then return 1,1,1,1 end
    local aa = tonumber(s:sub(1,2),16) or 0
    local bb = tonumber(s:sub(3,4),16) or 0
    local gg = tonumber(s:sub(5,6),16) or 0
    local rr = tonumber(s:sub(7,8),16) or 0
    local alpha = 1 - (aa / 255)
    return rr/255, gg/255, bb/255, alpha
end

local function hexToRGBA(hex)
    if not hex then return 1,1,1,1 end
    local s = tostring(hex):gsub("#","")
    if #s == 3 then
        s = s:sub(1,1)..s:sub(1,1)..s:sub(2,2)..s:sub(2,2)..s:sub(3,3)..s:sub(3,3)
    end
    if #s ~= 6 then return 1,1,1,1 end
    local r = tonumber(s:sub(1,2),16)/255
    local g = tonumber(s:sub(3,4),16)/255
    local b = tonumber(s:sub(5,6),16)/255
    return r,g,b,1
end

local function parseColourRuns(text, defaultColour)
    text = tostring(text or "")

    local runs = {}
    local plain = {}
    local colourStack = {}
    local activeColour = defaultColour or {1, 1, 1, 1}

    local function addRun(value)
        if value == "" then return end

        table.insert(plain, value)

        local last = runs[#runs]
        if last and last.color == activeColour then
            last.text = last.text .. value
        else
            table.insert(runs, {
                text = value,
                color = activeColour
            })
        end
    end

    local position = 1

    while position <= #text do
        local curlyStart = text:find("{", position, true)

        if curlyStart then
            local curlyEnd = text:find("}", curlyStart + 1, true)

            if curlyEnd and (not startPos or curlyStart < startPos) then
                addRun(text:sub(position, curlyStart - 1))
                position = curlyEnd + 1
            end
        end
        local startPos, endPos, tag = text:find("<([^>]+)>", position)

        if not startPos then
            addRun(text:sub(position))
            break
        end

        addRun(text:sub(position, startPos - 1))

        local hex = tag:match("^c=(#%x%x%x%x%x%x)$")

        if hex then
            table.insert(colourStack, activeColour)

            local r, g, b, a = hexToRGBA(hex)
            activeColour = {r, g, b, a}
        elseif tag == "/c" then
            activeColour = table.remove(colourStack) or defaultColour or {1, 1, 1, 1}
        else
            addRun(text:sub(startPos, endPos))
        end

        position = endPos + 1
    end

    return runs, table.concat(plain)
end

local function measurePlainText(font, text)
    local maxWidth = 0
    local lineCount = 0

    for line in (text .. "\n"):gmatch("(.-)\n") do
        maxWidth = math.max(maxWidth, font:getWidth(line))
        lineCount = lineCount + 1
    end

    return maxWidth, lineCount * font:getHeight()
end

local function stripRich(s)
    if not s then return "" end
    return (s:gsub("{[^}]-}", ""):gsub("<[^>]->", ""))
end

local function overrideBlockIter(evt)
    local s = evt.assRaw or evt.text or ""
    return coroutine.wrap(function()
        local i = 1
        while i <= #s do
            local curlyStart = s:find("{", i, true)
            local angleStart = s:find("<", i, true)
            local nextStart, ttype
            if curlyStart and angleStart then
                if curlyStart < angleStart then nextStart, ttype = curlyStart, "curly" else nextStart, ttype = angleStart, "angle" end
            elseif curlyStart then nextStart, ttype = curlyStart, "curly"
            elseif angleStart then nextStart, ttype = angleStart, "angle"
            else break end
            if ttype == "curly" then
                local close = s:find("}", nextStart+1, true)
                if close then
                    coroutine.yield(s:sub(nextStart+1, close-1))
                    i = close + 1
                else
                    break
                end
            else
                local close = s:find(">", nextStart+1, true)
                if close then
                    coroutine.yield("<"..s:sub(nextStart+1, close-1)..">")
                    i = close + 1
                else
                    break
                end
            end
        end
    end)
end

local function parseNumberList(s)
    local out = {}
    if not s then return out end
    for num in s:gmatch("([%d%.%-]+)") do
        table.insert(out, tonumber(num))
    end
    return out
end

function LyricsRenderer:buildTimeline(evt)
    local static = {
        color = {1,1,1,1},
        font = nil,
        size = evt.fontSize or 40,
        align = tonumber(evt.align) or 2,
        x = nil,
        y = nil,
        margin = {10,10,10,10},
        rotation = 0,
        scaleX = 1,
        scaleY = 1,
        orgX = nil,
        orgY = nil,
        bord = 0,
        shad = 0,
        bold = false,
        italic = false,
        underline = false,
        strike = false,
        verticalText = false,
        shake = false,
    }

    local animated = {}

    for block in overrideBlockIter(evt) do
        if block:match("<b>") or block:match("\\b1") or block:match("\\b") then static.bold = true end
        if block:match("</b>") or block:match("\\b0") then static.bold = false end
        if block:match("<i>") or block:match("\\i1") then static.italic = true end
        if block:match("</i>") or block:match("\\i0") then static.italic = false end
        if block:match("<u>") or block:match("\\u1") then static.underline = true end
        if block:match("</u>") or block:match("\\u0") then static.underline = false end
        if block:match("<s>") or block:match("\\s1") then static.strike = true end
        if block:match("</s>") or block:match("\\s0") then static.strike = false end

        local assCol = block:match("&H[%x]+&") or block:match("H[%x]+&")

        if assCol then
            local hex = assCol

            if not hex:match("^&H") then
                hex = "&H" .. hex
            end

            local r, g, b, a = assHexToRGBA(hex)
            static.color = {r, g, b, a}
        end

        local fname = block:match("<fontName=(.-)>")
        if fname then static.font = fname end
        local fsize = block:match("<fontSize=(%d+)>")
        if fsize then static.size = tonumber(fsize) end

        local an = block:match("<an=(%d)>")
        if an then static.align = tonumber(an) end

        local px, py = block:match("<pos%(([%d%.%-]+),([%d%.%-]+)%)>")
        if px and py then static.x = tonumber(px); static.y = tonumber(py) end

        local x1, y1, x2, y2 = block:match("<move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)>")
        if x1 and y1 and x2 and y2 then
            animated.move = {tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2)}
        end

        local f1, f2 = block:match("<fade%(([%d%.%-]+),([%d%.%-]+)%)>")
        if f1 and f2 then animated.fade = {tonumber(f1), tonumber(f2)} end

        local frx = block:match("<frx=([%d%.%-]+)>"); if frx then static.rotation = tonumber(frx) end
        local fry = block:match("<fry=([%d%.%-]+)>"); if fry then static.rotation = tonumber(fry) end
        local frz = block:match("<frz=([%d%.%-]+)>"); if frz then static.rotation = tonumber(frz) end
        local sx = block:match("<fax=([%d%.%-]+)>"); if sx then static.scaleX = tonumber(sx) end
        local sy = block:match("<fay=([%d%.%-]+)>"); if sy then static.scaleY = tonumber(sy) end

        local ox, oy = block:match("<org%(([%d%.%-]+),([%d%.%-]+)%)>")
        if ox and oy then static.orgX = tonumber(ox); static.orgY = tonumber(oy) end

        local bord = block:match("<bord=([%d%.%-]+)>"); if bord then static.bord = tonumber(bord) end
        local shad = block:match("<shad=([%d%.%-]+)>"); if shad then static.shad = tonumber(shad) end

        if block:match("<verticalText>") then static.verticalText = true end
        if block:match("<shake>") then static.shake = true end
    end

    local timeline = {
        static = static,
        animated = animated,
    }

    local karaSegments = {}
    local s = evt.assRaw or ""
    local pos = 1
    local cumulative = 0
    while true do
        local kstart, kend, kdur = s:find("{\\k([%d]+)}()", pos)
        if not kstart then break end
        local nextOverrideStart = s:find("{", kend, true) or (#s + 1)
        local sylText = s:sub(kend, nextOverrideStart - 1)
        sylText = sylText:gsub("^%s+", ""):gsub("%s+$", "")
        local seg = {text = sylText, dur = tonumber(kdur), start = cumulative}
        table.insert(karaSegments, seg)
        cumulative = cumulative + (tonumber(kdur) or 0)
        pos = nextOverrideStart
    end
    if #karaSegments > 0 then
        timeline.karaokeSegments = karaSegments
    end

    return timeline
end

function LyricsRenderer:evaluateTimeline(evt, audioTime)
    local tl = evt.timeline
    local out = {}
    for k,v in pairs(tl.static) do out[k] = v end

    local alpha = 1
    if tl.animated.fade and evt.time and evt.endTime then
        local fin = (tl.animated.fade[1] or 0) / 1000
        local fout = (tl.animated.fade[2] or 0) / 1000
        local life = audioTime - evt.time
        local remain = evt.endTime - audioTime
        if life < 0 then
            alpha = 0
        elseif life < fin then
            alpha = clamp(life / math.max(fin, 1e-6), 0, 1)
        elseif remain < fout then
            alpha = clamp(remain / math.max(fout, 1e-6), 0, 1)
        else
            alpha = 1
        end
    end
    out.alpha = alpha

    if tl.animated.move and evt.time and evt.endTime then
        local m = tl.animated.move
        local total = evt.endTime - evt.time
        if total <= 0 then
            out.x = m[3]; out.y = m[4]
        else
            local t = clamp((audioTime - evt.time) / total, 0, 1)
            out.x = m[1] + (m[3] - m[1]) * t
            out.y = m[2] + (m[4] - m[2]) * t
        end
    end

    if out.color then
        if #out.color == 3 then out.color[4] = 1 end
    else
        out.color = {1,1,1,1}
    end

    out.fontObj = nil
    out.plain = evt.plain or stripRich(evt.assRaw)
    out.width = evt.cachedWidth
    out.height = evt.cachedHeight

    return out
end

function LyricsRenderer:new(x, y, width, height, events)
    self.x, self.y, self.width, self.height = x or 0, y or 0, width or 0, height or 0
    self.events = table.clone(events or {}, true)
    self.currentLine = 0
    self.lastAudioTime = 0
    self.defaultFont = SkinHandler and SkinHandler.getFont and SkinHandler:getFont("Menu", 40) or love.graphics.getFont()
    self.defaultSize = 40
    self:prepareEvents()
end

function LyricsRenderer:prepareEvents()
    local df = self.defaultFont

    for _, evt in ipairs(self.events) do
        if not evt.time and evt.start then evt.time = evt.start end
        if not evt.endTime and evt["end"] then evt.endTime = evt["end"] end
        if not evt.endTime and evt["end_"] then evt.endTime = evt["end_"] end

        evt.assRaw = evt.assRaw or evt.raw or evt.orig or evt.text or ""
        evt.plain = stripRich(evt.assRaw)
        evt.alpha = 1
        evt.override = {}

        evt.timeline = self:buildTimeline(evt)
        evt.colourRuns = parseColourRuns(evt.assRaw, evt.timeline.static.color)

        local font = df
        local size = evt.timeline.static.size or self.defaultSize
        if SkinHandler and SkinHandler.getFont and evt.timeline.static.font then
            font = SkinHandler:getFont(evt.timeline.static.font, size) or font
        end
        evt._cachedFont = font
        local text = evt.plain or ""
        local w, h = measurePlainText(font, text)
        evt.cachedWidth = w
        evt.cachedHeight = h
        if evt.timeline.karaokeSegments and #evt.timeline.karaokeSegments > 0 then
            for i, seg in ipairs(evt.timeline.karaokeSegments) do
                seg._width = font:getWidth(seg.text or "")
                seg._startSec = (seg.start or 0) / 100
                seg._durSec = (seg.dur or 0) / 100
            end
        end
        evt.runtime = {}
    end
end

function LyricsRenderer:update(dt, audioTime)
    audioTime = audioTime or 0
    local backward = audioTime < (self.lastAudioTime or 0)
    self.lastAudioTime = audioTime
    if backward then
        for _, ev in ipairs(self.events) do ev.alpha = 1 end
    end
    local active = nil
    for i, ev in ipairs(self.events) do
        if ev.time and ev.endTime then
            if audioTime >= ev.time and audioTime <= ev.endTime then
                active = i
                break
            end
        end
    end
    self.currentLine = active or 0
end

function LyricsRenderer:draw(audioTime)
    local screenW = (baseScreenRatio and baseScreenRatio.x) or love.graphics.getWidth()
    local screenH = (baseScreenRatio and baseScreenRatio.y) or love.graphics.getHeight()
    if #self.events == 0 then return end
    if self.currentLine == 0 then return end
    local evt = self.events[self.currentLine]
    if not evt or not evt.time or not evt.endTime then return end
    audioTime = audioTime or self.lastAudioTime or 0
    local runtime = self:evaluateTimeline(evt, audioTime)
    local font = evt._cachedFont or self.defaultFont
    love.graphics.setFont(font)
    local text = runtime.plain or ""
    local w = evt.cachedWidth or font:getWidth(text)
    local h = evt.cachedHeight or font:getHeight()
    runtime.width = w
    runtime.height = h
    local drawX = runtime.x or (screenW/2)
    local drawY = runtime.y or (screenH - h - 80)
    local an = runtime.align or 2
    if an >= 4 and an <= 6 then drawY = drawY - (screenH/2) end
    if an >= 7 then drawY = drawY - screenH end
    if an % 3 == 2 then
        drawX = drawX - (w/2)
    elseif an % 3 == 0 then
        drawX = drawX - w
    end
    local m = runtime.margin or {10,10,10,10}
    if drawX < m[1] then drawX = m[1] end
    if drawX + w > screenW - m[2] then drawX = screenW - m[2] - w end
    if drawY < m[3] then drawY = m[3] end
    if drawY + h > screenH - m[4] then drawY = screenH - m[4] - h end
    if runtime.shake then
        local shakeAmount = 2
        drawX = drawX + love.math.random(-shakeAmount, shakeAmount)
        drawY = drawY + love.math.random(-shakeAmount, shakeAmount)
    end
    local r,g,b,a = runtime.color[1] or 1, runtime.color[2] or 1, runtime.color[3] or 1, (runtime.color[4] or 1) * (runtime.alpha or 1)
    local shadowOffset = runtime.shad or 0
    local border = runtime.bord or 0
    local ox = runtime.orgX or (drawX + w/2)
    local oy = runtime.orgY or (drawY + h/2)
    local function drawTextWithEffectsInternal(txt, x, y)
        love.graphics.push()
        love.graphics.translate(ox, oy)
        love.graphics.rotate(math.rad(runtime.rotation or 0))
        love.graphics.scale(runtime.scaleX or 1, runtime.scaleY or 1)
        love.graphics.translate(-ox, -oy)
        if shadowOffset > 0 then
            love.graphics.setColor(0,0,0,a)
            love.graphics.print(txt, x + shadowOffset, y + shadowOffset)
        end
        if border > 0 then
            love.graphics.setColor(0,0,0,a)
            for dx=-border,border do
                for dy=-border,border do
                    if dx ~= 0 or dy ~= 0 then
                        love.graphics.print(txt, x + dx, y + dy)
                    end
                end
            end
        end
        love.graphics.setColor(r, g, b, a)
        love.graphics.print(txt, x, y)
        love.graphics.pop()
    end
    local function drawColourRuns(runs, x, y, mode)
        local cursorX = x
        local cursorY = y
        local lineHeight = font:getHeight()

        for _, run in ipairs(runs) do
            love.graphics.setColor(run.color[1], run.color[2], run.color[3], run.color[4] * a)

            for line in (run.text .. "\n"):gmatch("(.-)\n") do
                if line ~= "" then
                    if mode == "shadow" or mode == "border" then
                        love.graphics.setColor(0, 0, 0, a)
                    else
                        love.graphics.setColor(run.color[1], run.color[2], run.color[3], run.color[4] * a)
                    end

                    love.graphics.print(line, cursorX, cursorY)
                    cursorX = cursorX + font:getWidth(line)
                end

                if run.text:find("\n", 1, true) then
                    cursorX = x
                    cursorY = cursorY + lineHeight
                end
            end
        end
    end
    local function drawColourRunsWithEffects(runs, x, y)
        love.graphics.push()

        love.graphics.translate(ox, oy)
        love.graphics.rotate(math.rad(runtime.rotation or 0))
        love.graphics.scale(runtime.scaleX or 1, runtime.scaleY or 1)
        love.graphics.translate(-ox, -oy)

        if shadowOffset > 0 then
            love.graphics.setColor(0, 0, 0, a)
            drawColourRuns(runs, x + shadowOffset, y + shadowOffset, "shadow")
        end

        if border > 0 then
            for dx = -border, border do
                for dy = -border, border do
                    if dx ~= 0 or dy ~= 0 then
                        drawColourRuns(runs, x + dx, y + dy, "border")
                    end
                end
            end
        end

        drawColourRuns(runs, x, y, "normal")

        love.graphics.pop()
    end

    local padx = 10
    local pady = 4
    love.graphics.setColor(0, 0, 0, 0.7 * a)
    local txtW = w
    local _, newlineCount = text:gsub("\n","")
    local txtH = h * (newlineCount + 1)
    love.graphics.rectangle("fill", drawX - padx, drawY - pady, txtW + 2*padx, txtH + 2*pady, 5, 5)
    if evt.timeline.karaokeSegments and #evt.timeline.karaokeSegments > 0 and evt.time and evt.endTime then
        local baseTime = evt.time
        local cx = drawX
        for i, seg in ipairs(evt.timeline.karaokeSegments) do
            local segText = seg.text or ""
            local segDur = seg._durSec or ((seg.dur or 0) / 100)
            local segStart = baseTime + (seg._startSec or 0)
            local segEnd = segStart + segDur
            local progress = clamp((audioTime - segStart) / math.max(1e-6, segEnd - segStart), 0, 1)
            local segW = seg._width or font:getWidth(segText)
            drawTextWithEffectsInternal(segText, cx, drawY)
            local fillW = segW * progress
            if fillW > 0 then
                local sx = math.floor(cx)
                local sy = math.floor(drawY)
                local sw = math.ceil(fillW)
                local sh = math.ceil(h)
                love.graphics.setScissor(sx, sy, sw, sh)
                drawTextWithEffectsInternal(segText, cx, drawY)
                love.graphics.setScissor()
            end
            cx = cx + segW
        end
    else
        drawColourRunsWithEffects(evt.colourRuns, drawX, drawY)
    end
    if runtime.underline then
        love.graphics.setColor(r, g, b, a)
        love.graphics.setLineWidth(2)
        love.graphics.line(drawX, drawY + h - 4, drawX + w, drawY + h - 4)
    end
    if runtime.strike then
        love.graphics.setColor(r, g, b, a)
        love.graphics.setLineWidth(2)
        love.graphics.line(drawX, drawY + h/2, drawX + w, drawY + h/2)
    end
    love.graphics.setColor(1,1,1,1)
end

return LyricsRenderer
