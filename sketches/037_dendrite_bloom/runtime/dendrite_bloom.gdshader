shader_type canvas_item;
render_mode unshaded;

const float DESIGN_ASPECT = 1.7777778;

uniform sampler2D u_state : filter_linear, repeat_disable;
uniform vec2 u_texel = vec2(0.0104167, 0.0185185);
uniform float u_tint = 0.58;
uniform float u_relief = 1.22;
uniform float u_micro = 1.08;

float hash21(vec2 p) {
    p = fract(p * vec2(443.8975, 397.2973));
    p += dot(p, p.yx + 19.19);
    return fract(p.x * p.y);
}

float crystal_noise(vec2 p) {
    float a = hash21(floor(p));
    float b = hash21(floor(p * 2.03 + 17.0));
    float c = hash21(floor(p * 4.07 + 51.0));
    return a * 0.57 + b * 0.29 + c * 0.14;
}

vec4 smooth_state(vec2 uv) {
    vec2 o = u_texel * 0.72;
    vec4 s = texture(u_state, uv) * 4.0;
    s += texture(u_state, uv + vec2(o.x, 0.0)) * 2.0;
    s += texture(u_state, uv - vec2(o.x, 0.0)) * 2.0;
    s += texture(u_state, uv + vec2(0.0, o.y)) * 2.0;
    s += texture(u_state, uv - vec2(0.0, o.y)) * 2.0;
    s += texture(u_state, uv + vec2(o.x, o.y));
    s += texture(u_state, uv + vec2(o.x, -o.y));
    s += texture(u_state, uv + vec2(-o.x, o.y));
    s += texture(u_state, uv - o);
    return s / 16.0;
}

void fragment() {
    vec4 state = smooth_state(UV);
    float phase = state.r;
    float nutrient = state.g;
    float age = state.b;

    vec2 grad_step = u_texel * 0.82;
    float pl = smooth_state(UV - vec2(grad_step.x, 0.0)).r;
    float pr = smooth_state(UV + vec2(grad_step.x, 0.0)).r;
    float pu = smooth_state(UV - vec2(0.0, grad_step.y)).r;
    float pd = smooth_state(UV + vec2(0.0, grad_step.y)).r;
    vec2 grad = vec2(pr - pl, pd - pu);
    float front = clamp(length(grad) * 3.8, 0.0, 1.0);

    vec3 n = normalize(vec3(-grad.x * u_relief * 6.2, -grad.y * u_relief * 6.2, 0.82));
    vec3 light_a = normalize(vec3(-0.46, -0.31, 0.83));
    vec3 light_b = normalize(vec3(0.68, 0.18, 0.71));
    float lambert = max(0.0, dot(n, light_a));
    float rim = pow(1.0 - max(0.0, n.z), 2.0);
    float counter = max(0.0, dot(n, light_b));

    vec2 pixel = floor(FRAGCOORD.xy);
    float micro = crystal_noise(pixel * (0.085 + u_micro * 0.055));
    float facet = 0.5 + 0.5 * sin((n.x * 19.0 + n.y * 23.0 + micro * 5.0) * 2.1);
    facet = smoothstep(0.37, 0.78, facet);

    vec3 cold = mix(vec3(0.08, 0.28, 0.36), vec3(0.24, 0.12, 0.40), u_tint);
    vec3 mineral = mix(vec3(0.54, 0.90, 0.92), vec3(0.88, 0.58, 0.96), u_tint);
    vec3 hot_edge = mix(vec3(0.82, 1.0, 0.96), vec3(1.0, 0.72, 0.42), u_tint * 0.55);
    vec3 background = vec3(0.008, 0.012, 0.018);

    float body = smoothstep(0.035, 0.74, phase);
    float translucency = clamp((1.0 - age) * 0.45 + nutrient * 0.18, 0.0, 0.6);
    vec3 crystal = cold * (0.20 + 0.72 * lambert);
    crystal += mineral * (0.16 + 0.52 * counter) * (0.45 + facet * 0.55);
    crystal += hot_edge * front * (0.55 + 0.65 * (1.0 - age));
    crystal += mineral * rim * 0.48;
    crystal += (micro - 0.5) * 0.075 * u_micro;
    crystal += hot_edge * translucency * 0.22;

    float halo = smoothstep(0.16, 0.018, abs(phase - 0.10)) * (0.12 + nutrient * 0.16);
    vec3 color = mix(background, crystal, body);
    color += hot_edge * halo;

    vec2 p = UV - 0.5;
    p.x *= DESIGN_ASPECT;
    float vignette = smoothstep(1.05, 0.30, length(p));
    color *= mix(0.46, 1.0, vignette);
    color = vec3(1.0) - exp(-color * 1.45);
    COLOR = vec4(color, 1.0);
}
