extern vec3 iResolution;
extern number iTime;
extern number fade;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 q = 7.0 * (fragCoord.xy - 0.5 * iResolution.xy) / max(iResolution.x, iResolution.y);

    for(number i = 1.0; i < 40.0; i *= 1.1) {
        vec2 o = q;
        o.x += (0.5 / i) * cos(i * q.y + iTime * 0.297 + 0.03 * i) + 1.3;
        o.y += (0.5 / i) * cos(i * q.x + iTime * 0.414 + 0.03 * (i + 10.0)) + 1.9;
        q = o;
    }

    vec3 col = vec3(0.5 * sin(3.0 * q.x) + 0.5, 0.5 * sin(3.0 * q.y) + 0.5, sin(1.3 * q.x + 1.7 * q.y));

    number f = 0.43 * (col.x + col.y + col.z);

    fragColor = vec4(f + 0.6, 0.2 + 0.75 * f, 0.2, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 fragCoord = screen_coords;
    fragCoord.y = love_ScreenSize.y - fragCoord.y;

    vec4 fragColor = vec4(0.0);
    mainImage(fragColor, fragCoord);

    vec4 original = Texel(texture, texture_coords) * color;

    vec3 finalColor = mix(original.rgb, fragColor.rgb, fade);

    return vec4(finalColor, original.a);
}
