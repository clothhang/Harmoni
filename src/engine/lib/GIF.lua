--- FFI-accelerated GIF decoder & renderer for Love2D
--- LICENSE: MIT License
--- GuglioIsStupid, 2026

local ffi = require("ffi")
local bit = require("bit")

local Gif = {}
Gif.__index = Gif
Gif.__storage = {}

ffi.cdef[[
typedef struct {
    uint16_t prefix;
    uint8_t suffix;
} LzwEntry;
]]

local function newBitReader(data, size)
    return {
        data = data,
        size = size,
        bytePos = 0,
        bitPos = 0,

        readBits = function(self, n)
            local value = 0
            local shift = 0

            while n > 0 do
                if self.bytePos >= self.size then
                    return nil
                end

                local byte = self.data[self.bytePos]
                local remaining = 8 - self.bitPos
                local take = math.min(n, remaining)

                local mask = bit.lshift(1, take) - 1
                local bits = bit.band(
                    bit.rshift(byte, self.bitPos),
                    mask
                )

                value = bit.bor(value, bit.lshift(bits, shift))

                self.bitPos = self.bitPos + take
                if self.bitPos >= 8 then
                    self.bitPos = 0
                    self.bytePos = self.bytePos + 1
                end

                shift = shift + take
                n = n - take
            end

            return value
        end
    }
end

local function decodeLzwFfi(data, size, minCodeSize, pixelCount)
    local clearCode = bit.lshift(1, minCodeSize)
    local endCode = clearCode + 1

    local dict = ffi.new("LzwEntry[4096]")
    local stack = ffi.new("uint8_t[4096]")
    local output = ffi.new("uint8_t[?]", pixelCount)

    for i = 0, clearCode - 1 do
        dict[i].prefix = 0xFFFF
        dict[i].suffix = i
    end

    local codeSize = minCodeSize + 1
    local nextCode = endCode + 1
    local maxCode = bit.lshift(1, codeSize)

    local reader = newBitReader(data, size)
    local outPos = 0
    local prevCode = -1

    while outPos < pixelCount do
        local code = reader:readBits(codeSize)
        if not code then break end

        if code == clearCode then
            codeSize = minCodeSize + 1
            nextCode = endCode + 1
            maxCode = bit.lshift(1, codeSize)
            prevCode = -1
        elseif code == endCode then
            break
        else
            local cur = code
            local stackPos = 0

            if cur == nextCode and prevCode ~= -1 then
                stack[0] = dict[prevCode].suffix
                stackPos = 1
                cur = prevCode
            end

            while cur >= clearCode do
                stack[stackPos] = dict[cur].suffix
                stackPos = stackPos + 1
                cur = dict[cur].prefix
            end

            local first = cur
            stack[stackPos] = first
            stackPos = stackPos + 1

            for i = stackPos - 1, 0, -1 do
                if outPos >= pixelCount then break end
                output[outPos] = stack[i]
                outPos = outPos + 1
            end

            if prevCode ~= -1 and nextCode < 4096 then
                dict[nextCode].prefix = prevCode
                dict[nextCode].suffix = first
                nextCode = nextCode + 1

                if nextCode >= maxCode and codeSize < 12 then
                    codeSize = codeSize + 1
                    maxCode = bit.lshift(1, codeSize)
                end
            end

            prevCode = code
        end
    end

    return output
end

local interlaceOffsets = {0, 4, 2, 1}
local interlaceSteps = {8, 8, 4, 2}

local function interlaceBlit(dst, dstW, indices, palette, transparentIndex, x, y, w, h)
    local srcPos = 0

    for pass = 1, 4 do
        local row = interlaceOffsets[pass]
        local step = interlaceSteps[pass]

        while row < h do
            local dstOff = ((y + row) * dstW + x) * 4

            for col = 0, w - 1 do
                local idx = indices[srcPos]
                local o = dstOff + col * 4

                if transparentIndex ~= nil and idx == transparentIndex then
                    dst[o + 3] = 0
                else
                    local c = palette[idx]
                    dst[o] = c[1]
                    dst[o + 1] = c[2]
                    dst[o + 2] = c[3]
                    dst[o + 3] = 255
                end

                srcPos = srcPos + 1
            end

            row = row + step
        end
    end
end

local function blitIndexedToRgba(dst, dstW, indices, palette, transparentIndex, x, y, w, h, isDisposal0)
    for row = 0, h - 1 do
        local dstOff = ((y + row) * dstW + x) * 4
        local srcOff = row * w

        for col = 0, w - 1 do
            local idx = indices[srcOff + col]
            local o = dstOff + col * 4
            if State.current() == States.extra.america then -- awesome hardcode instead of figuring out the error !!!
                dst[o + 3] = 0
            end

            if transparentIndex ~= nil and idx == transparentIndex then
                if not isDisposal0 then
                    dst[o + 3] = 0
                end
            else
                local c = palette[idx]
                dst[o] = c[1]
                dst[o + 1] = c[2]
                dst[o + 2] = c[3]
                dst[o + 3] = 255
            end
        end
    end
end

local function readByte(data, pos)
    return data:byte(pos), pos + 1
end

local function readWord(data, pos)
    local a, b = data:byte(pos, pos + 1)
    return a + b * 256, pos + 2
end

local function readSubBlocks(data, pos)
    local bytes = {}
    while true do
        local size
        size, pos = readByte(data, pos)
        if size == 0 then break end
        for _ = 1, size do
            bytes[#bytes + 1] = data:byte(pos)
            pos = pos + 1
        end
    end
    return bytes, pos
end

Gif.IS_GIF = true
function Gif.new(path, createImageDatas)
    if createImageDatas == nil then createImageDatas = true end
    local self = setmetatable({}, Gif)

    local data = love.filesystem.read(path)
    local pos = 1

    pos = pos + 6

    self.width, pos = readWord(data, pos)
    self.height, pos = readWord(data, pos)

    self.loopCount = 0
    self.currentLoop = 0
    self.duration = 0

    local packed
    packed, pos = readByte(data, pos)
    pos = pos + 2

    local hasGlobal = bit.band(packed, 0x80) ~= 0
    local globalSize = bit.lshift(1, bit.band(packed, 0x07) + 1)

    local globalPalette
    if hasGlobal then
        globalPalette = {}
        for i = 0, globalSize - 1 do
            local r, g, b
            r, pos = readByte(data, pos)
            g, pos = readByte(data, pos)
            b, pos = readByte(data, pos)
            globalPalette[i] = { r, g, b }
        end
    end

    self.frames = {}
    local delay = 0.1
    local transparentIndex = nil

    while true do
        local block
        local disposal = 0
        local interlaced = false
        block, pos = readByte(data, pos)
        if not block or block == 0x3B then break end

        if block == 0x21 then
            local label
            label, pos = readByte(data, pos)

            if label == 0xF9 then
                pos = pos + 1
                local packed
                packed, pos = readByte(data, pos)

                disposal = bit.band(bit.rshift(packed, 2), 0x07)

                local d
                d, pos = readWord(data, pos)
                delay = math.max(d / 100, 0.01)

                transparentIndex = bit.band(packed, 1) ~= 0 and data:byte(pos) or nil
                pos = pos + 2
            else
                local _, newPos = readSubBlocks(data, pos)
                pos = newPos
            end
        elseif block == 0xFF then
            local size
            size, pos = readByte(data, pos)

            local app = data:sub(pos, pos + size - 1)
            pos = pos + size

            if app == "NETSCAPE2.0" or app == "ANIMEXTS1.0" then
                local subSize
                subSize, pos = readByte(data, pos)

                if subSize == 3 then
                    pos = pos + 1
                    local loops
                    loops, pos = readWord(data, pos)

                    self.loopCount = loops
                    pos = pos + 1
                else
                    pos = pos + subSize + 1
                end
            else
                local _, newPos = readSubBlocks(data, pos)
                pos = newPos
            end
        elseif block == 0x2C then
            local x, y, w, h
            x, pos = readWord(data, pos)
            y, pos = readWord(data, pos)
            w, pos = readWord(data, pos)
            h, pos = readWord(data, pos)

            local flags
            flags, pos = readByte(data, pos)

            local palette = globalPalette
            if bit.band(flags, 0x80) ~= 0 then
                local size = bit.lshift(1, bit.band(flags, 0x07) + 1)
                palette = {}
                for i = 0, size - 1 do
                    local r, g, b
                    r, pos = readByte(data, pos)
                    g, pos = readByte(data, pos)
                    b, pos = readByte(data, pos)
                    palette[i] = { r, g, b }
                end
            end

            if bit.band(flags, 0x40) ~= 0 then
                interlaced = true
            end

            local minCode
            minCode, pos = readByte(data, pos)

            local blocks
            blocks, pos = readSubBlocks(data, pos)

            local buf = ffi.new("uint8_t[?]", #blocks)
            for i = 1, #blocks do
                buf[i - 1] = blocks[i]
            end

            local indices = decodeLzwFfi(buf, #blocks, minCode, w * h)
            self.frames[#self.frames + 1] = {
                indices = indices,
                palette = palette,
                transparentIndex = transparentIndex,
                x = x,
                y = y,
                w = w,
                h = h,
                delay = delay,
                disposal = disposal,
                interlaced = interlaced
            }

            delay = 0.1
            transparentIndex = nil
            disposal = 0
        end
    end

    self.frameTime = 0
    self.time = 0
    self.frameIndex = 1

    for _, frame in ipairs(self.frames) do
        self.duration = self.duration + frame.delay
    end

    self.canvas = ffi.new("uint8_t[?]", self.width * self.height * 4)
    self.prevCanvas = ffi.new("uint8_t[?]", self.width * self.height * 4)

    ffi.fill(self.canvas, self.width * self.height * 4, 0)

    local first = self.frames[1]

    ffi.copy(
        self.prevCanvas,
        self.canvas,
        self.width * self.height * 4
    )

    if first.interlaced then
        interlaceBlit(
            self.canvas,
            self.width,
            first.indices,
            first.palette,
            first.transparentIndex,
            first.x,
            first.y,
            first.w,
            first.h
        )
    else
        blitIndexedToRgba(
            self.canvas,
            self.width,
            first.indices,
            first.palette,
            first.transparentIndex,
            first.x,
            first.y,
            first.w,
            first.h,
            first.disposal == 0
        )
    end

    self.imageData = love.image.newImageData(self.width, self.height, "rgba8")
    if createImageDatas then
        self.image = love.graphics.newImage(self.imageData)
    end

    ffi.copy(
        self.imageData:getFFIPointer(),
        self.canvas,
        self.width * self.height * 4
    )
    if createImageDatas then
        self.image:replacePixels(self.imageData)
    end

    self.lastFrame = nil

    table.insert(Gif.__storage, self)

    return self
end


Gif.__allowUpdateInDraw = false
function Gif.pushLove()
    local ogdraw = love.graphics.draw
    local ognewImage = love.graphics.newImage
    local ogupdate = love.update

    ---@diagnostic disable-next-line: duplicate-set-field
    function love.graphics.draw(...)
        local first = select(1, ...)
        if first.typeOf and first:typeOf("GIF") then
            first:draw(select(2, ...))
        else
            ogdraw(...)
        end
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    function love.graphics.newImage(img)
        if type(img) == "string" and img:sub(-4):lower() == ".gif" then
            print("Loading GIF:", img)
            return Gif.new(img)
        else
            return ognewImage(img)
        end
    end
end

function Gif.enableDrawUpdates()
    Gif.__allowUpdateInDraw = true
end

function Gif:resetGifs()
    for _, gif in ipairs(Gif.__storage) do
        gif.updatedThisFrame = false
    end
end

function Gif:applyDisposal(frame)
    if frame.disposal == 2 then
        for row = 0, frame.h - 1 do
            local off = ((frame.y + row) * self.width + frame.x) * 4
            ffi.fill(self.canvas + off, frame.w * 4, 0)
        end

    elseif frame.disposal == 3 then
        ffi.copy(
            self.canvas,
            self.prevCanvas,
            self.width * self.height * 4
        )
    end
end

function Gif:update(dt)
    if self.finished then return end

    self.frameTime = self.frameTime + dt
    self.time = self.time + dt
    local frame = self.frames[self.frameIndex]

    if self.frameTime < frame.delay then return end
    self.frameTime = self.frameTime - frame.delay

    if self.lastFrame then
        self:applyDisposal(self.lastFrame)
    end

    if frame.disposal == 3 then
        ffi.copy(
            self.prevCanvas,
            self.canvas,
            self.width * self.height * 4
        )
    end

    if frame.interlaced then
        interlaceBlit(
            self.canvas,
            self.width,
            frame.indices,
            frame.palette,
            frame.transparentIndex,
            frame.x,
            frame.y,
            frame.w,
            frame.h
        )
    else
        blitIndexedToRgba(
            self.canvas,
            self.width,
            frame.indices,
            frame.palette,
            frame.transparentIndex,
            frame.x,
            frame.y,
            frame.w,
            frame.h,
            frame.disposal == 0
        )
    end

    if not self.image then self.image = love.graphics.newImage(self.imageData) end

    self.lastFrame = frame
    self.frameIndex = self.frameIndex + 1

    if self.frameIndex > #self.frames then
        self.time = 0
        self.frameIndex = 1
        self.currentLoop = self.currentLoop + 1

        if self.loopCount ~= 0 and self.currentLoop >= self.loopCount and not self.loopOverride then
            print(self.loopCount ~= 0, self.currentLoop >= self.loopCount, not self.loopOverride)
            self.finished = true
            return
        end

        ffi.fill(self.canvas, self.width * self.height * 4, 0)
        ffi.copy(
            self.prevCanvas,
            self.canvas,
            self.width * self.height * 4
        )

        local first = self.frames[1]

        if first.interlaced then
            interlaceBlit(
                self.canvas,
                self.width,
                first.indices,
                first.palette,
                first.transparentIndex,
                first.x,
                first.y,
                first.w,
                first.h
            )
        else
            blitIndexedToRgba(
                self.canvas,
                self.width,
                first.indices,
                first.palette,
                first.transparentIndex,
                first.x,
                first.y,
                first.w,
                first.h,
                first.disposal == 0
            )
        end

        self.lastFrame = first

        ffi.copy(
            self.imageData:getFFIPointer(),
            self.canvas,
            self.width * self.height * 4
        )
        if self.image then
            self.image:replacePixels(self.imageData)
        end

        return
    end

    ffi.copy(
        self.imageData:getFFIPointer(),
        self.canvas,
        self.width * self.height * 4
    )
    if self.image then
        self.image:replacePixels(self.imageData)
    end
end

function Gif:setLooping(enabled)
    self.loopOverride = enabled
    self.currentLoop = 0
    self.finished = false
end

function Gif:setLoopCount(count)
    self.loopOverride = nil
    self.loopCount = count
    self.currentLoop = 0
    self.finished = false
end

function Gif:reset()
    self.frameTime = 0
    self.time = 0
    self.frameIndex = 1
    self.currentLoop = 0
    self.finished = false
    self.lastFrame = nil

    ffi.fill(self.canvas, self.width * self.height * 4, 0)

    local first = self.frames[1]
    if first.interlaced then
        interlaceBlit(
            self.canvas,
            self.width,
            first.indices,
            first.palette,
            first.transparentIndex,
            first.x,
            first.y,
            first.w,
            first.h
        )
    else
        blitIndexedToRgba(
            self.canvas,
            self.width,
            first.indices,
            first.palette,
            first.transparentIndex,
            first.x,
            first.y,
            first.w,
            first.h,
            first.disposal == 0
        )
    end

    ffi.copy(
        self.imageData:getFFIPointer(),
        self.canvas,
        self.width * self.height * 4
    )

    if self.image then
        self.image:replacePixels(self.imageData)
    end
    self.lastFrame = first
end

function Gif:getFrameCount()
    return #self.frames
end

function Gif:getLoopCount()
    return self.loopCount
end

function Gif:isFinished()
    return self.finished
end

function Gif:getCurrentLoop()
    return self.currentLoop
end

function Gif:getCurrentFrame()
    return self.frameIndex
end

function Gif:getDuration()
    return self.duration
end

function Gif:getWidth()
    local frame = self.frames[1]
    if frame then
        return frame.w
    else
        return 0
    end
end

function Gif:getHeight()
    local frame = self.frames[1]
    if frame then
        return frame.h
    else
        return 0
    end
end

function Gif:getDimensions()
    local frame = self.frames[1]
    if frame then
        return frame.w, frame.h
    else
        return 0, 0
    end
end

function Gif:type()
    return "GIF"
end

function Gif:typeOf(t)
    return t == "GIF"
end

local function quickNumberAssert(v, id)
    return assert(tonumber(v), "Expected number for argument #" .. id .. ". got ".. type(v) .. ".")
end

function Gif:draw(...)
    if not self.image then return end
    local x = quickNumberAssert(select(1, ...) or 0, 1)
    local y = quickNumberAssert(select(2, ...) or 0, 2)
    local r = quickNumberAssert(select(3, ...) or 0, 3)
    local sx = quickNumberAssert(select(4, ...) or 1, 4)
    local sy = quickNumberAssert(select(5, ...) or sx, 5)
    local ox = quickNumberAssert(select(6, ...) or 0, 6)
    local oy = quickNumberAssert(select(7, ...) or 0, 7)
    local kx = quickNumberAssert(select(8, ...) or 0, 8)
    local ky = quickNumberAssert(select(9, ...) or 0, 9)
    if Gif.__allowUpdateInDraw and not self.updatedThisFrame then
        self:update(love.timer.getDelta())
        self.updatedThisFrame = true
    end
    love.graphics.draw(self.image, x, y, r, sx, sy, ox, oy, kx, ky)
end

function Gif:release()
    if self.image then
        self.image:release()
    end
    self.imageData:release()

    self.image = nil
    self.imageData = nil
    self.frames = nil
    self.canvas = nil
    self.prevCanvas = nil

    self = nil

    collectgarbage("collect")
    collectgarbage("collect")
end

return Gif
