local bullshit = State()

local shaderTemplate = [[
#pragma language glsl3
vec2 iResolution = vec2(2560, 1440);
extern number iTime;

#define METABALL_COUNT 50
#define MIX_COLORS 0

#define SPREAD 0.85
#define SIZE_MULTIPLIER 2
#define THRESHOLD_MULTIPLIER 1.

int hash(int seed) {
    seed ^= 2747636419;
    seed *= 2654435769;
    seed ^= seed >> 16;
    seed *= 2654435769;
    seed ^= seed >> 16;
    seed *= 2654435769;
    return seed;
}

int pcg_hash(int seed) {
    int state = seed * 747796405 + 2891336453;
    int word = ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
    return (word >> 22u) ^ word;
}

int random_range(int seed, int minVal, int maxVal) {
    int raw_rand = pcg_hash(seed);
    int range = int(maxVal - minVal + 1);
    return minVal + int(raw_rand % range);
}

number random_number(int seed) {
    return number(hash(seed)) / 4294967295.0;
}

extern vec3 colors[REPLACE_ME] = vec3[REPLACE_ME](
REPLACE_ME_LOOP
);

struct MetaBall {
    number r;
    vec2 pos;
    vec3 col;
};

vec3 renderMetaBall(vec2 uv) {
    number totalAlpha = 0.0;
    vec3 rgbTotal = vec3(0.0);
    vec3 col = vec3(0.0);
    number strongestField = 0.0;
    number t = iTime;
    int columns = int(ceil(sqrt(number(METABALL_COUNT) * iResolution.x / iResolution.y)));
    int rows = (METABALL_COUNT + columns - 1) / columns;

    for (int i = 0; i < METABALL_COUNT; i++) {
        number fi = number(i);
        int seed = (i + 1) * 1973 + 9277 + 26699;
        number phase = fi * 2.39996;
        number gridX = mod(fi, number(columns));
        number gridY = floor(fi / number(columns));
        number offsetX = random_number(seed + 101);
        number offsetY = random_number(seed + 202);

        vec2 basePos = vec2(
            ((gridX + offsetX) / number(columns) * 2.0 - 1.0) * (iResolution.x / iResolution.y),
            1.0 - (gridY + offsetY) / number(rows) * 2.0 - 0.300
        );

        number speed = 0.10 + random_number(seed + 303) * 0.12;
        vec2 drift = vec2(
            sin(t * speed + phase) * 0.12 + sin(t * 0.17 + phase * 1.7) * 0.06,
            cos(t * speed * 0.8 + phase) * 0.09 + cos(t * 0.13 + phase * 1.3) * 0.04
        );

        vec2 pos = basePos * SPREAD + drift;
        number radius = mix(0.35, 0.70, random_number(seed)) * SIZE_MULTIPLIER;
        vec3 ballCol = colors[random_range(seed + 12345, 0, REPLACE_ME_NEG1)];
        number dist = max(length(uv - pos), 0.0001);
        number field = radius / dist;

        totalAlpha += field;
        rgbTotal += ballCol * field;

        if (field > strongestField) {
            strongestField = field;
            col = ballCol;
        }
    }

    number threshold = THRESHOLD_MULTIPLIER * number(METABALL_COUNT);
    number mask = step(threshold, totalAlpha);

#if MIX_COLORS
    col = rgbTotal / max(totalAlpha, 0.0001);
#endif

    return col * mask;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
    vec3 col = renderMetaBall(uv);
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
    vec2 fragCoord = texture_coords * iResolution.xy;
    mainImage(color, fragCoord);
    return color;
}
]]

function bullshit:enter()
    local arrayCode = ""
    self.canvas = love.graphics.newCanvas(baseScreenRatio.x, baseScreenRatio.y)

    if SkinHandler.__data.Skin.RandomColors then
        local colors = SkinHandler.__data.Skin.RandomColors
        for i = 1, #colors do
            arrayCode = arrayCode .. "\tvec3(" .. (tostring(colors[i][1] or 1)) .. ", " .. tostring(colors[i][2] or 1) .. ", " .. tostring(colors[i][3] or 1) .. ")"
            if i ~= #colors then
                arrayCode = arrayCode .. ",\n"
            else
                arrayCode = arrayCode .. "\n"
            end
        end
        local shader = shaderTemplate:gsub("REPLACE_ME_LOOP", arrayCode)
        shader = shader:gsub("REPLACE_ME_NEG1", #colors-1)
        shader = shader:gsub("REPLACE_ME", #colors)
        
        self.bullshitShader = love.graphics.newShader(shader)
    end
end

function bullshit:update(dt)
    self.bullshitShader:send("iTime", love.timer.getTime()*10)
end

function bullshit:draw()
    local lastShader = love.graphics.getShader()
    local lastCanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, baseScreenRatio.x, baseScreenRatio.y)
    love.graphics.setShader(self.bullshitShader)
    love.graphics.setCanvas(lastCanvas)
    love.graphics.draw(self.canvas)
    love.graphics.setShader(lastShader)
end

return bullshit