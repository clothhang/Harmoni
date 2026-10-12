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

extern vec3 colors[30] = vec3[30](
    vec3(240.0, 223.0, 205.0) / 255.0,
    vec3(219.0, 213.0, 185.0) / 255.0,
    vec3(192.0, 186.0, 153.0) / 255.0,
    vec3(254.0, 235.0, 201.0) / 255.0,
    vec3(253.0, 203.0, 162.0) / 255.0,
    vec3(252.0, 169.0, 133.0) / 255.0,
    vec3(125.0, 255.0, 76.0) / 255.0,
    vec3(255.0, 250.0, 19.0) / 255.0,
    vec3(255.0, 237.0, 81.0) / 255.0,
    vec3(224.0, 243.0, 176.0) / 255.0,
    vec3(191.0, 228.0, 18.0) / 255.0,
    vec3(133.0, 202.0, 93.0) / 255.0,
    vec3(207.0, 236.0, 207.0) / 255.0,
    vec3(181.0, 235.0, 174.0) / 255.0,
    vec3(145.0, 210.0, 144.0) / 255.0,
    vec3(179.0, 226.0, 221.0) / 255.0,
    vec3(134.0, 207.0, 190.0) / 255.0,
    vec3(72.0, 181.0, 163.0) / 255.0,
    vec3(20.0, 173.0, 207.0) / 255.0,
    vec3(18.0, 225.0, 174.0) / 255.0,
    vec3(14.0, 210.0, 144.0) / 255.0,
    vec3(179.0, 226.0, 21.0) / 255.0,
    vec3(134.0, 207.0, 79.0) / 255.0,
    vec3(72.0, 181.0, 63.0) / 255.0,
    vec3(15.0, 106.0, 239.0) / 255.0,
    vec3(154.0, 206.0, 235.0) / 255.0,
    vec3(111.0, 183.0, 214.0) / 255.0,
    vec3(191.0, 213.0, 232.0) / 255.0,
    vec3(148.0, 168.0, 208.0) / 255.0,
    vec3(117.0, 137.0, 191.0) / 255.0
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
        vec3 ballCol = colors[random_range(seed + 12345, 0, 29)];
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
    vec4 texcolor = Texel(texture, texture_coords);
    vec2 fragCoord = texture_coords * iResolution.xy;
    mainImage(color, fragCoord);
    return color;
}
