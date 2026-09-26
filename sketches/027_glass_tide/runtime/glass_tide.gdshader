shader_type canvas_item;
render_mode unshaded;

uniform vec4 u_lens0 = vec4(0.28, 0.35, 0.11, 1.0);
uniform vec4 u_lens1 = vec4(0.68, 0.32, 0.10, 1.0);
uniform vec4 u_lens2 = vec4(0.38, 0.70, 0.13, 1.0);
uniform vec4 u_lens3 = vec4(0.76, 0.68, 0.12, 0.0);
uniform vec4 u_wave0 = vec4(0.28, 0.35, 0.0, 0.0);
uniform vec4 u_wave1 = vec4(0.68, 0.32, 0.0, 0.0);
uniform vec4 u_wave2 = vec4(0.38, 0.70, 0.0, 0.0);
uniform vec4 u_wave3 = vec4(0.76, 0.68, 0.0, 0.0);
uniform float u_threshold = 0.42;
uniform float u_displacement = 1.16;
uniform float u_refraction = 1.05;
uniform float u_regime = 0.25;
uniform float u_memory = 0.0;

float lens_sdf(vec2 uv, vec4 lens, float aspect) {
    vec2 p = uv - lens.xy;
    p.x *= aspect;
    float d = length(p) / aspect - lens.z;
    return mix(0.9, d, lens.w);
}

float wave_band(vec2 uv, vec4 wave, float aspect) {
    vec2 p = uv - wave.xy;
    p.x *= aspect;
    float d = length(p) / aspect;
    float width = 0.010 + 0.012 / max(0.25, u_displacement);
    return exp(-abs(d - wave.z) / width) * wave.w;
}

void fragment() {
    vec2 uv = UV;
    float aspect = max(0.2, SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x);

    float d0 = lens_sdf(uv, u_lens0, aspect);
    float d1 = lens_sdf(uv, u_lens1, aspect);
    float d2 = lens_sdf(uv, u_lens2, aspect);
    float d3 = lens_sdf(uv, u_lens3, aspect);

    float union_a = min(d0, d1);
    float union_b = min(d2, d3);
    float field = min(union_a, union_b);
    float split_field = max(union_a, -union_b * (0.65 + u_regime * 0.75));
    field = mix(field, split_field, smoothstep(0.58, 0.92, u_regime));

    float edge_width = mix(0.030, 0.008, u_threshold);
    float shell = exp(-abs(field) / edge_width);
    float interior = smoothstep(0.035, -0.030, field);

    float waves = wave_band(uv, u_wave0, aspect)
        + wave_band(uv, u_wave1, aspect)
        + wave_band(uv, u_wave2, aspect)
        + wave_band(uv, u_wave3, aspect);
    waves = clamp(waves, 0.0, 2.4);

    vec2 grad = vec2(dFdx(field), dFdy(field));
    float slope = clamp(length(grad) * 90.0 * u_refraction, 0.0, 1.0);
    float caustic = clamp(shell * (0.35 + slope * 1.4) + waves * (0.25 + u_displacement * 0.22), 0.0, 1.0);

    vec3 bg = vec3(0.018, 0.024, 0.032);
    vec3 glass_dark = vec3(0.055, 0.13, 0.16);
    vec3 glass_light = vec3(0.54, 0.82, 0.78);
    vec3 warm = vec3(0.94, 0.73, 0.43);

    vec3 color = mix(bg, glass_dark, interior * (0.62 + u_memory * 0.25));
    color = mix(color, glass_light, caustic * 0.72);
    color = mix(color, warm, clamp(waves * 0.42 + shell * u_regime * 0.22, 0.0, 0.55));

    float vignette = smoothstep(1.15, 0.18, distance(uv, vec2(0.5)));
    color *= 0.86 + vignette * 0.18;
    COLOR = vec4(color, 1.0);
}
