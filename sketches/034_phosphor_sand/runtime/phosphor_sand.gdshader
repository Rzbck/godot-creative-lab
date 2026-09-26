shader_type canvas_item;
render_mode unshaded;

uniform sampler2D u_memory : filter_linear, repeat_disable;
uniform vec2 u_texel = vec2(0.0078125, 0.0138889);
uniform float u_relief = 1.08;
uniform float u_grain = 0.42;
uniform float u_chroma = 0.31;
uniform float u_feedback = 0.92;
uniform float u_threshold = 0.34;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
    vec2 uv = UV;
    vec3 center = texture(u_memory, uv).rgb;
    float l = texture(u_memory, uv - vec2(u_texel.x, 0.0)).r;
    float r = texture(u_memory, uv + vec2(u_texel.x, 0.0)).r;
    float t = texture(u_memory, uv - vec2(0.0, u_texel.y)).r;
    float b = texture(u_memory, uv + vec2(0.0, u_texel.y)).r;
    vec2 grad = vec2(r - l, b - t) * 0.5;
    float edge = clamp(length(grad) * 6.2, 0.0, 1.0);
    float lap = l + r + t + b - center.r * 4.0;

    vec2 warp = grad * (0.010 + u_relief * 0.020);
    float mem_r = texture(u_memory, clamp(uv + warp * (0.55 + u_chroma), vec2(0.0), vec2(1.0))).r;
    float mem_g = texture(u_memory, clamp(uv - warp * 0.28, vec2(0.0), vec2(1.0))).g;
    float mem_b = texture(u_memory, clamp(uv - warp * (0.55 + u_chroma), vec2(0.0), vec2(1.0))).r;

    float micro = hash21(FRAGCOORD.xy * 0.73);
    float micro2 = hash22(FRAGCOORD.xy * 0.217 + floor(uv * vec2(91.0, 53.0)));
    float material_grain = (micro - 0.5) * u_grain;
    float particulate = smoothstep(0.72 - center.r * 0.34, 0.92, micro2) * smoothstep(0.06, 0.58, center.r + abs(lap));

    vec3 black_resin = vec3(0.0035, 0.0048, 0.0065);
    vec3 graphite = vec3(0.028, 0.035, 0.038);
    vec3 bronze = vec3(0.40, 0.205, 0.075);
    vec3 gold = vec3(0.96, 0.67, 0.20);
    vec3 ice = vec3(0.32, 0.86, 0.88);

    float body = smoothstep(0.015, 0.72, center.r);
    float echo = smoothstep(0.035, 0.70, center.g);
    float phase = smoothstep(u_threshold * 0.45, min(1.0, u_threshold + 0.42), center.r + center.g * 0.26);
    float ridge = smoothstep(0.06, 0.62, edge + abs(lap) * 1.4);

    vec3 color = mix(black_resin, graphite, 0.16 + body * 0.56);
    color = mix(color, bronze, body * (0.26 + phase * 0.32));
    color = mix(color, gold, ridge * (0.30 + u_feedback * 0.13));

    vec3 spectral_state = vec3(mem_r, mem_g, mem_b);
    vec3 spectral_color = mix(gold, ice, clamp(spectral_state.b - spectral_state.r + 0.5, 0.0, 1.0));
    color = mix(color, spectral_color, u_chroma * ridge * 0.44);
    color += gold * particulate * (0.08 + center.b * 0.18);
    color += ice * echo * edge * u_chroma * 0.13;
    color += material_grain * (0.016 + body * 0.026);

    // High-resolution directional grazing response derived from the state-field
    // gradient. The 128x72 simulation is only hidden behaviour; final material
    // detail comes from full-resolution FRAGCOORD microstructure and normals.
    vec3 n = normalize(vec3(-grad.x * u_relief * 18.0, -grad.y * u_relief * 18.0, 1.0));
    vec3 light = normalize(vec3(-0.52, -0.38, 0.76));
    float grazing = pow(max(dot(n, light), 0.0), 7.0);
    color += vec3(0.92, 0.78, 0.55) * grazing * body * 0.17;

    vec2 p = (uv - 0.5) * vec2(1.7777778, 1.0);
    float vignette = 1.0 - smoothstep(0.36, 1.08, length(p * vec2(0.62, 1.0)));
    color *= 0.72 + vignette * 0.34;
    COLOR = vec4(max(color, vec3(0.0)), 1.0);
}
