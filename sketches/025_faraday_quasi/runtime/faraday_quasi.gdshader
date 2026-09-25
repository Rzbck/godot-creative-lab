shader_type canvas_item;
render_mode unshaded;

uniform vec4 u_amps = vec4(0.1);
uniform vec4 u_phases = vec4(0.0);
uniform float u_drive = 0.9;
uniform float u_damping = 0.3;
uniform float u_capillarity = 0.7;
uniform float u_depth = 0.8;
uniform float u_mode_coupling = 0.7;
uniform float u_touch_energy = 0.0;

float mode_wave(vec2 p, vec2 dir, float k, float phase, float amplitude) {
    float primary = cos(dot(p, dir) * k + phase);
    // Non-integer harmonic phases are safe because controller phases are now
    // unwrapped. They add capillary detail without any phase-reset seam.
    float capillary = cos(dot(p, dir) * k * 2.07 + phase * 1.37 + 0.73);
    return amplitude * (primary + capillary * 0.105 * u_capillarity);
}

float surface_height(vec2 p) {
    float k0 = mix(13.0, 29.0, clamp(u_capillarity / 1.5, 0.0, 1.0));
    float depth_scale = mix(0.72, 1.18, clamp(u_depth / 1.5, 0.0, 1.0));

    vec2 d0 = vec2(1.0, 0.0);
    vec2 d1 = vec2(0.0, 1.0);
    vec2 d2 = normalize(vec2(1.0, 1.0));
    vec2 d3 = normalize(vec2(1.0, -0.6180339));

    float w0 = mode_wave(p, d0, k0 * depth_scale, u_phases.x, u_amps.x);
    float w1 = mode_wave(p, d1, k0 * 1.03 * depth_scale, u_phases.y, u_amps.y);
    float w2 = mode_wave(p, d2, k0 * 0.88 * depth_scale, u_phases.z, u_amps.z);
    float w3 = mode_wave(p, d3, k0 * 1.17 * depth_scale, u_phases.w, u_amps.w);

    float h = w0 + w1 + w2 + w3;
    h += (w0 * w1 + w2 * w3) * u_mode_coupling * 0.64;
    h += (w0 * w2 - w1 * w3) * u_mode_coupling * 0.13;
    return h;
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = UV;
    vec2 aspect = vec2(1.7777778, 1.0);
    vec2 p = (uv - 0.5) * aspect;

    float h = surface_height(p);
    float eps = 0.0026;
    float hx = surface_height(p + vec2(eps, 0.0));
    float hy = surface_height(p + vec2(0.0, eps));

    vec3 normal = normalize(vec3((h - hx) / eps * 0.030, (h - hy) / eps * 0.030, 1.0));
    vec3 light = normalize(vec3(-0.46, -0.38, 0.80));
    vec3 rim_light = normalize(vec3(0.62, 0.18, 0.76));
    float diffuse = clamp(dot(normal, light) * 0.5 + 0.5, 0.0, 1.0);
    float rim = pow(clamp(1.0 - normal.z, 0.0, 1.0), 2.4);
    float secondary = pow(max(dot(normal, rim_light), 0.0), 9.0);

    float crest = smoothstep(0.08, 0.96, abs(h));
    float nodes = 1.0 - smoothstep(0.0, 0.075 + u_damping * 0.065, abs(h));
    float micro = hash21(FRAGCOORD.xy * 0.41) - 0.5;
    float energy = clamp(dot(u_amps, vec4(0.25)), 0.0, 1.0);

    vec3 abyss = vec3(0.004, 0.013, 0.030);
    vec3 deep = vec3(0.018, 0.080, 0.125);
    vec3 teal = vec3(0.045, 0.43, 0.51);
    vec3 spectral = vec3(0.20, 0.88, 0.82);
    vec3 pearl = vec3(0.96, 0.86, 0.62);

    vec3 color = mix(abyss, deep, 0.28 + diffuse * 0.54);
    color = mix(color, teal, crest * (0.28 + u_drive * 0.17));
    color = mix(color, spectral, rim * (0.30 + energy * 0.26));
    color = mix(color, pearl, nodes * (0.18 + secondary * 0.34));
    color += pearl * secondary * 0.24;

    // Touch energy changes the modal simulation upstream. Here it only adjusts
    // material response smoothly; there is no direct click-local height patch.
    color = mix(color, color * vec3(1.05, 1.015, 0.94), u_touch_energy * 0.11);
    color += micro * 0.012 * (0.25 + crest);

    float vignette = smoothstep(1.08, 0.18, length(p * vec2(0.61, 1.0)));
    color *= 0.69 + vignette * 0.37;
    COLOR = vec4(max(color, vec3(0.0)), 1.0);
}
