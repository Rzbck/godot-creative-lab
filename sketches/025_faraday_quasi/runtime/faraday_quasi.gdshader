shader_type canvas_item;
render_mode unshaded;

uniform vec4 u_amps = vec4(0.1);
uniform vec4 u_phases = vec4(0.0);
uniform float u_drive = 0.9;
uniform float u_damping = 0.3;
uniform float u_capillarity = 0.7;
uniform float u_depth = 0.8;
uniform float u_mode_coupling = 0.7;
uniform vec2 u_touch_pos = vec2(0.5);
uniform float u_touch_impulse = 0.0;
uniform float u_forcing_phase = 0.0;

float wave(vec2 p, vec2 dir, float k, float phase) {
    return cos(dot(p, dir) * k + phase);
}

void fragment() {
    vec2 uv = UV;
    vec2 aspect = vec2(1.7777778, 1.0);
    vec2 p = (uv - 0.5) * aspect;

    float k0 = mix(13.0, 28.0, clamp(u_capillarity / 1.5, 0.0, 1.0));
    float depth_scale = mix(0.72, 1.18, clamp(u_depth / 1.5, 0.0, 1.0));
    float sub = u_forcing_phase * 0.5;

    vec2 d0 = vec2(1.0, 0.0);
    vec2 d1 = vec2(0.0, 1.0);
    vec2 d2 = normalize(vec2(1.0, 1.0));
    vec2 d3 = normalize(vec2(1.0, -0.6180339));

    float w0 = wave(p, d0, k0 * depth_scale, u_phases.x + sub) * u_amps.x;
    float w1 = wave(p, d1, k0 * 1.03 * depth_scale, u_phases.y - sub * 0.94) * u_amps.y;
    float w2 = wave(p, d2, k0 * 0.88 * depth_scale, u_phases.z + sub * 1.06) * u_amps.z;
    float w3 = wave(p, d3, k0 * 1.17 * depth_scale, u_phases.w - sub * 0.91) * u_amps.w;

    float h = w0 + w1 + w2 + w3;
    float cross = (w0 * w1 + w2 * w3) * u_mode_coupling * 0.75;
    h += cross;

    // Touch injects a local pressure impulse into modal state. It does not add
    // an unrelated clock-driven ripple on top of the physical surface.
    vec2 tp = (u_touch_pos - 0.5) * aspect;
    float td = length(p - tp);
    float touch = exp(-td * td / 0.035) * u_touch_impulse;
    h += touch * (0.34 + u_amps.x * 0.10);

    float eps = 0.004;
    float hx = 0.0;
    float hy = 0.0;
    vec2 px = p + vec2(eps, 0.0);
    vec2 py = p + vec2(0.0, eps);
    hx += wave(px, d0, k0 * depth_scale, u_phases.x + sub) * u_amps.x;
    hx += wave(px, d1, k0 * 1.03 * depth_scale, u_phases.y - sub * 0.94) * u_amps.y;
    hx += wave(px, d2, k0 * 0.88 * depth_scale, u_phases.z + sub * 1.06) * u_amps.z;
    hx += wave(px, d3, k0 * 1.17 * depth_scale, u_phases.w - sub * 0.91) * u_amps.w;
    hy += wave(py, d0, k0 * depth_scale, u_phases.x + sub) * u_amps.x;
    hy += wave(py, d1, k0 * 1.03 * depth_scale, u_phases.y - sub * 0.94) * u_amps.y;
    hy += wave(py, d2, k0 * 0.88 * depth_scale, u_phases.z + sub * 1.06) * u_amps.z;
    hy += wave(py, d3, k0 * 1.17 * depth_scale, u_phases.w - sub * 0.91) * u_amps.w;

    vec3 normal = normalize(vec3((h - hx) / eps * 0.035, (h - hy) / eps * 0.035, 1.0));
    vec3 light = normalize(vec3(-0.45, -0.35, 0.82));
    float diffuse = clamp(dot(normal, light) * 0.5 + 0.5, 0.0, 1.0);
    float crest = smoothstep(0.12, 1.05, abs(h));
    float nodes = 1.0 - smoothstep(0.0, 0.11 + u_damping * 0.08, abs(h));

    vec3 deep = vec3(0.010, 0.025, 0.055);
    vec3 water = vec3(0.055, 0.32, 0.48);
    vec3 cyan = vec3(0.18, 0.82, 0.86);
    vec3 pearl = vec3(0.92, 0.88, 0.72);
    vec3 color = mix(deep, water, diffuse * 0.72 + 0.08);
    color = mix(color, cyan, crest * (0.18 + u_drive * 0.15));
    color = mix(color, pearl, nodes * 0.26 * (1.0 - u_damping * 0.35));

    float vignette = smoothstep(1.05, 0.22, length(p * vec2(0.64, 1.0)));
    color *= 0.73 + vignette * 0.34;
    COLOR = vec4(color, 1.0);
}
