local Trail = Class:extend("Trail")

function Trail:new(points, pixelsPerSecond, trailSegmentDecay, callback, despawn, width)
    self.points = points or {}
    self.pixelsPerSecond = pixelsPerSecond or 100
    self.trailSegmentDecay = trailSegmentDecay or 1
    self.callback = callback or function() end
    self.despawn = despawn ~= false

    self.width = width or 8
    self.maxSegments = 256
    self.minSegmentDistance = 2

    self.x = 0
    self.y = 0

    self.currentPoint = 1
    self.targetPoint = 2

    self.segments = {}
    self.finished = #self.points == 0
    self.CatThatSaysHi = false

    self.mesh = love.graphics.newMesh(
        self.maxSegments * 2,
        "strip",
        "dynamic"
    )

    self.shader = love.graphics.newShader([[
        vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
            return color;
        }
    ]])

    if self.finished then
        return
    end

    self.x = self.points[1].x
    self.y = self.points[1].y

    self:addSegment(self.x, self.y)

    if #self.points == 1 then
        self.finished = true
        self.callback(self.points[1], 1)
    end
end

function Trail:addSegment(x, y, force)
    local last = self.segments[#self.segments]

    if last then
        local dx = x - last.x
        local dy = y - last.y
        local distanceSq = dx * dx + dy * dy

        if distanceSq < 0.0001 then
            return
        end

        if not force and distanceSq < self.minSegmentDistance ^ 2 then
            return
        end
    end

    self.segments[#self.segments + 1] = {
        x = x,
        y = y,
        alpha = 1
    }

    if #self.segments > self.maxSegments then
        table.remove(self.segments, 1)
    end
end

function Trail:update(dt)
    for i = #self.segments, 1, -1 do
        local segment = self.segments[i]

        segment.alpha = segment.alpha - self.trailSegmentDecay * dt

        if segment.alpha <= 0 then
            table.remove(self.segments, i)
        end
    end

    if self.finished then
        return
    end

    local remainingDistance = self.pixelsPerSecond * dt

    while remainingDistance > 0 and not self.finished do
        local target = self.points[self.targetPoint]

        if not target then
            self.finished = true
            break
        end

        local dx = target.x - self.x
        local dy = target.y - self.y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance <= remainingDistance or distance == 0 then
            self.x = target.x
            self.y = target.y

            remainingDistance = remainingDistance - distance

            self:addSegment(self.x, self.y, true)
            self.currentPoint = self.targetPoint
            self.callback(target, self.currentPoint)

            if self.currentPoint == #self.points then
                if self.despawn then
                    self.finished = true
                    if self.CatThatSaysHi then
                        local c = love.audio.newSource("ahh.mp3", "static")
                        c:setVolume(0.8)
                        love.audio.play(c)
                    end
                else
                    self.targetPoint = 1
                end
            else
                self.targetPoint = self.targetPoint + 1
            end
        else
            local ratio = remainingDistance / distance

            self.x = self.x + dx * ratio
            self.y = self.y + dy * ratio

            remainingDistance = 0
        end
    end

    self:addSegment(self.x, self.y)
end

function Trail:draw()
    local count = #self.segments

    if count < 2 then
        return
    end

    local halfWidth = self.width * 0.5
    local vertices = {}

    local points = {}

    for i = 1, count do
        local point = self.segments[i]
        local last = points[#points]

        if not last then
            points[#points + 1] = point
        else
            local dx = point.x - last.x
            local dy = point.y - last.y

            if dx * dx + dy * dy > 0.0001 then
                points[#points + 1] = point
            end
        end
    end

    count = #points

    if count < 2 then
        return
    end

    local directions = {}
    local normals = {}

    for i = 1, count - 1 do
        local a = points[i]
        local b = points[i + 1]

        local dx = b.x - a.x
        local dy = b.y - a.y
        local length = math.sqrt(dx * dx + dy * dy)

        directions[i] = {
            x = dx / length,
            y = dy / length
        }

        normals[i] = {
            x = -dy / length,
            y = dx / length
        }
    end

    for i = 1, count do
        local point = points[i]

        local offsetX
        local offsetY

        if i == 1 then
            offsetX = normals[1].x * halfWidth
            offsetY = normals[1].y * halfWidth
        elseif i == count then
            offsetX = normals[count - 1].x * halfWidth
            offsetY = normals[count - 1].y * halfWidth
        else
            local n1 = normals[i - 1]
            local n2 = normals[i]

            local d1 = directions[i - 1]
            local d2 = directions[i]

            local denominator = 1 + d1.x * d2.x + d1.y * d2.y

            if denominator > 0.0001 then
                local scale = halfWidth / denominator

                offsetX = (n1.x + n2.x) * scale
                offsetY = (n1.y + n2.y) * scale
            else
                offsetX = n1.x * halfWidth
                offsetY = n1.y * halfWidth
            end
        end

        local alpha = math.max(0, math.min(1, point.alpha))

        vertices[#vertices + 1] = {
            point.x + offsetX,
            point.y + offsetY,
            0, 0,
            1, 1, 1, alpha
        }

        vertices[#vertices + 1] = {
            point.x - offsetX,
            point.y - offsetY,
            1, 0,
            1, 1, 1, alpha
        }
    end

    local mesh = love.graphics.newMesh(
        vertices,
        "strip",
        "dynamic"
    )

    love.graphics.push("all")

    love.graphics.setShader(self.shader)
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mesh)

    if self.CatThatSaysHi and self.finished then  -- im leaving this here
        love.graphics.rectangle("fill", 25, 25, 500, 300)
    end

    love.graphics.pop()

    mesh:release()
end


function Trail:destroy()
    if self.mesh then
        self.mesh:release()
        self.mesh = nil
    end
end

return Trail
