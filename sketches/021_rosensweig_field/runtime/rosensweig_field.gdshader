shader_type canvas_item;
render_mode unshaded;

uniform float u_field_strength = 0.9;
uniform vec2 u_magnet_pos = vec2(0.5);
uniform float u_magnet_radius = 0.15;
uniform float u_surface_tension = 0.5;
uniform float u_viscosity = 0.5;
uniform float u_peak_sharpness = 2.4;
uniform float u_mode_coupling = 0.7;
uniform float u_hysteresis = 0.5;
uniform float u_instability = 0.0;
uniform float u_memory = 0.0;

float gauss(float x, float sigma) {
    return exp(-(x * x) / max(0.0001, 2.0 * sigma * sigma));
}

void fragment() {
    vec2 uv = UV;
    vec2 aspect = vec2(1.7777778, 1.0);
    vec2 p = (uv - 0.5) * aspect;
    vec2 mp = (u_magnet_pos - 0.5) * aspect;

    float d = length(p - mp);
    float magnetic = gauss(d, max(0.025, u_magnet_radius * 1.9));
    float vessel_bias = gauss(length(p * vec2(0.82, 1.0)), 0.62) * 0.07;
    float field = (magnetic * 0.96 + vessel_bias) * u_field_strength;

    float k = mix(22.0, 38.0, u_surface_tension);
    vec2 d0 = vec2(1.0, 0.0);
    vec2 d1 = vec2(0.5, 0.8660254);
    vec2 d2 = vec2(-0.5, 0.8660254);

    // The lattice is spatial structure. Temporal behavior now comes from the
    // moving magnetic source + hysteretic CPU state, not shader clock wobble.
    float w0 = cos(dot(p, d0) * k);
    float w1 = cos(dot(p, d1) * k + 0.73);
    float w2 = cos(dot(p, d2) * k - 0.41);
    float lattice = (w0 + w1 + w2) / 3.0;
    float coupled = cos((w0 - w1) * 2.2 + (w2 * u_mode_coupling));
    float signal = lattice * (0.55 + u_mode_coupling * 0.12) + coupled * 0.12 * u_mode_coupling + field * 0.95;

    float threshold = mix(0.68, 0.06, clamp(u_instability + field * 0.30, 0.0, 1.0));
    float softness = mix(0.22, 0.035, clamp(u_peak_sharpness / 5.0, 0.0, 1.0));
    float peaks = smoothstep(threshold - softness, threshold + softness, signal);
    peaks = pow(peaks, mix(1.8, 0.55, clamp(u_peak_sharpness / 5.0, 0.0, 1.0)));

    float ring = abs(signal - threshold);
    float ridge = 1.0 - smoothstep(0.0, 0.07 + u_viscosity * 0.04, ring);
    float memory_glow = u_memory * magnetic * (0.3 + 0.7 * ridge);

    vec3 base = vec3(0.008, 0.012, 0.014);
    vec3 ferro = vec3(0.045, 0.065, 0.072);
    vec3 steel = vec3(0.56, 0.70, 0.72);
    vec3 cold = vec3(0.18, 0.52, 0.58);

    vec3 color = mix(base, ferro, 0.62 + field * 0.22);
    color = mix(color, steel, peaks * (0.44 + field * 0.22));
    color += ridge * vec3(0.08, 0.14, 0.15) * (0.25 + u_instability * 0.75);
    color = mix(color, cold, clamp(memory_glow * 0.34 + u_hysteresis * ridge * 0.08, 0.0, 0.28));

    float vignette = smoothstep(1.12, 0.28, length(p * vec2(0.72, 1.0)));
    color *= 0.72 + vignette * 0.38;

    COLOR = vec4(color, 1.0);
}
