shader_type canvas_item;
render_mode unshaded;

const float DESIGN_ASPECT = 1.7777778;

uniform vec4 u_load0 = vec4(0.24, 0.31, 0.62, 0.13);
uniform vec4 u_load1 = vec4(0.73, 0.24, 0.48, 0.37);
uniform vec4 u_load2 = vec4(0.66, 0.74, 0.58, 0.63);
uniform vec4 u_load3 = vec4(0.34, 0.69, 0.42, 0.89);
uniform float u_load_gain = 1.18;
uniform float u_thickness = 0.92;
uniform float u_fringe_density = 8.4;
uniform float u_spectral_mix = 0.72;
uniform float u_elasticity = 0.86;
uniform float u_anisotropy = 0.58;
uniform float u_exposure = 1.16;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 aspect_space(vec2 uv) {
    vec2 p = uv - 0.5;
    p.x *= DESIGN_ASPECT;
    return p;
}

vec2 aspect_load(vec2 uv) {
    vec2 p = uv - 0.5;
    p.x *= DESIGN_ASPECT;
    return p;
}

vec3 tensor_from_load(vec2 p, vec4 load) {
    vec2 q = p - aspect_load(load.xy);
    float r2 = dot(q, q) + 0.006;
    float inv = load.z / (r2 * r2 + 0.0025);
    float sx = (q.x * q.x - 0.42 * q.y * q.y) * inv;
    float sy = (q.y * q.y - 0.42 * q.x * q.x) * inv;
    float txy = 1.38 * q.x * q.y * inv;
    float seed_wave = sin((q.x * 5.7 + q.y * 4.3) + load.w * 6.28318) * 0.08 * load.z;
    return vec3(sx + seed_wave, sy - seed_wave, txy);
}

float stress_value(vec2 p) {
    vec3 t = vec3(0.0);
    t += tensor_from_load(p, u_load0);
    t += tensor_from_load(p, u_load1);
    t += tensor_from_load(p, u_load2);
    t += tensor_from_load(p, u_load3);
    float principal = sqrt(max(0.0, (t.x - t.y) * (t.x - t.y) + 4.0 * t.z * t.z));
    float residual = 0.14 * sin(p.x * 4.7 + p.y * 7.3) + 0.09 * sin(p.x * 10.9 - p.y * 5.1);
    return max(0.0, principal * 0.036 * u_load_gain * u_elasticity + residual * u_anisotropy + 0.12);
}

void fragment() {
    vec2 p = aspect_space(UV);
    float stress = stress_value(p);

    float eps = 0.0018;
    float sx0 = stress_value(p - vec2(eps, 0.0));
    float sx1 = stress_value(p + vec2(eps, 0.0));
    float sy0 = stress_value(p - vec2(0.0, eps));
    float sy1 = stress_value(p + vec2(0.0, eps));
    vec2 grad = vec2(sx1 - sx0, sy1 - sy0) / (2.0 * eps);
    float edge = clamp(length(grad) * 0.34, 0.0, 1.0);

    float thickness = u_thickness + stress * 0.74 + dot(p, vec2(0.11, -0.07)) * u_anisotropy;
    float phase = thickness * u_fringe_density * 6.28318;
    vec3 spectral = 0.5 + 0.5 * cos(vec3(1.00, 1.27, 1.61) * phase + vec3(0.15, 2.22, 4.35));
    spectral = pow(spectral, vec3(1.35));

    float fringe = 0.5 + 0.5 * cos(phase);
    float cross_polar = pow(1.0 - abs(fringe * 2.0 - 1.0), 0.58);
    float basin = exp(-dot(p, p) * 1.18);

    vec3 deep = vec3(0.012, 0.016, 0.028);
    vec3 cold = vec3(0.055, 0.11, 0.18);
    vec3 pearl = vec3(0.72, 0.86, 0.94);
    vec3 color = mix(deep, cold, clamp(stress * 0.52 + basin * 0.16, 0.0, 1.0));
    color += pearl * edge * (0.18 + 0.42 * cross_polar);
    color += mix(vec3(cross_polar * 0.26), spectral * (0.28 + 0.92 * cross_polar), u_spectral_mix);

    vec2 pixel = floor(FRAGCOORD.xy);
    float grain = hash21(pixel + floor(stress * 37.0));
    color += (grain - 0.5) * 0.028 * (0.25 + edge);

    float vignette = smoothstep(1.12, 0.26, length(p));
    color *= mix(0.42, 1.0, vignette);
    color = vec3(1.0) - exp(-color * u_exposure * 1.55);
    COLOR = vec4(color, 1.0);
}
