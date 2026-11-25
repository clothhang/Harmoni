local UILayerWave = Class:extend("UILayerWave")

local tpi = math.pi * 2

function UILayerWave:new(x,y,width,height,layerCount,segments,amplitude,layerSpacing,layerColors)
    if not type(layerColors) == "table" then error("Bad argument #9 (layerColors) to UILayerWave! Table expected, got " .. type(layerColors)) end 

    self.layers = {}
    segments = segments or 20
    amplitude = amplitude or 20
    self.thatOneValue = 0
    layerSpacing = layerSpacing or 0

    self.amplitude = amplitude

    for i = 1, layerCount do
        self:createLayer(
            x, y, width, height,
            segments, amplitude, i,
            layerSpacing,
            layerColors[i] or {1, 1, 1}
        )
    end
end

function UILayerWave:createLayer(x, y, width, height, segments, amplitude, index, spacing, color)
    local layer = {
        x = x,
        y = y,
        width = width,
        height = height,
        color = color,
        segments = segments,
        amplitude = amplitude,
        spacing = spacing * index,
        phaseOffset = love.math.random() * tpi,
        freqMultiplier = 1 + (love.math.random() - 0.5) * 0.5,
        speed = 1 + love.math.random(),
        points = {}
    }

    local pts = layer.points
    local count = segments + 1
    local p = 1

    for i = 0, segments do
        local t = i / segments
        pts[p] = x + t * width
        p = p + 1
        pts[p] = y + math.sin(t * tpi * layer.freqMultiplier + layer.phaseOffset) * amplitude - layer.spacing
        p = p + 1
    end

    pts[p] = x + width
    p = p + 1
    pts[p] = y + height
    p = p + 1

    pts[p] = x
    p = p + 1
    pts[p] = y + height

    table.insert(self.layers, layer)
end

function UILayerWave:update(dt)

    self.time = love.timer.getTime()+self.thatOneValue

    for _, layer in ipairs(self.layers) do
        layer.amplitude = self.amplitude
        local pts = layer.points
        local x = layer.x
        local y = layer.y
        local width = layer.width
        local freq = layer.freqMultiplier
        local amp = layer.amplitude
        local seg = layer.segments
        local spacing = layer.spacing
        local basePhase = layer.phaseOffset + self.time * layer.speed

        local p = 1

        for i = 0, seg do
            local t = i / seg
            pts[p] = x + t * width; p = p + 1
            pts[p] = y + math.sin(t * tpi * freq + basePhase) * amp - spacing
            p = p + 1
        end

        pts[p] = x + width
        p = p + 1
        pts[p] = y + layer.height
        p = p + 1

        pts[p] = x
        pts[p + 1] = y + layer.height
    end
end

function UILayerWave:draw()
    for _, layer in ipairs(self.layers) do
        love.graphics.setColor(layer.color)
        love.graphics.polygon("fill", layer.points)
    end
    love.graphics.setColor(1, 1, 1)
end

return UILayerWave