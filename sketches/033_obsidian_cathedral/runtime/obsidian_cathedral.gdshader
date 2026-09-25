shader_type canvas_item;
render_mode unshaded;

uniform float u_angle = -0.32;
uniform float u_tilt = 0.18;
uniform float u_architecture = 1.02;
uniform float u_facets = 1.12;
uniform float u_roughness = 0.26;
uniform float u_spectral = 0.38;
uniform float u_camera_depth = 0.94;
uniform float u_stress_gain = 1.15;
uniform vec4 u_crack0 = vec4(0.28, 0.42, 0.0, 0.13);
uniform vec4 u_crack1 = vec4(0.71, 0.31, 0.0, 0.41);
uniform vec4 u_crack2 = vec4(0.62, 0.72, 0.0, 0.67);
uniform vec4 u_crack3 = vec4(0.38, 0.66, 0.0, 0.89);

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(vec2(c, -s), vec2(s, c));
}

float sd_box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, vec3(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sd_octa(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float map_scene(vec3 p) {
    p.xz = rot(u_angle) * p.xz;
    p.yz = rot(u_tilt) * p.yz;
    p.y += 0.04;

    float arch = mix(0.78, 1.22, clamp((u_architecture - 0.45) / 1.30, 0.0, 1.0));
    vec3 core_p = vec3(p.x, p.y * 0.67, p.z);
    float core = sd_octa(core_p, 1.02 * arch);

    float central = sd_box(p - vec3(0.0, 0.52, 0.0), vec3(0.19, 0.82 * arch, 0.19));
    central = smin(central, sd_octa(p - vec3(0.0, 1.31 * arch, 0.0), 0.42), 0.09);

    vec3 side = p;
    side.x = abs(side.x) - 0.58 * arch;
    float buttress = sd_box(side - vec3(0.0, 0.20, 0.03), vec3(0.13, 0.66 * arch, 0.22));
    float crown = sd_octa(side - vec3(0.0, 0.92 * arch, 0.01), 0.36);
    buttress = smin(buttress, crown, 0.07);

    vec3 wing = p;
    wing.x = abs(wing.x) - 0.92 * arch;
    float outer = sd_octa(vec3(wing.x, wing.y * 0.78 + 0.12, wing.z), 0.44);

    float d = smin(core, central, 0.13);
    d = smin(d, buttress, 0.085);
    d = smin(d, outer, 0.055);

    // Deep negative-space cuts turn the crystal cluster into architecture rather
    // than a generic blob. They are static geometry, not time effects.
    float nave = sd_box(p - vec3(0.0, -0.10, -0.02), vec3(0.16, 0.56, 0.72));
    float portal = sd_octa(vec3(p.x * 1.5, p.y + 0.12, p.z + 0.58), 0.46);
    d = max(d, -min(nave, portal));
    return d;
}

vec3 normal_at(vec3 p) {
    float e = 0.0018;
    vec2 h = vec2(e, 0.0);
    return normalize(vec3(
        map_scene(p + h.xyy) - map_scene(p - h.xyy),
        map_scene(p + h.yxy) - map_scene(p - h.yxy),
        map_scene(p + h.yyx) - map_scene(p - h.yyx)
    ));
}

float hash31(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float ambient_occlusion(vec3 p, vec3 n) {
    float occ = 0.0;
    float weight = 1.0;
    for (int i = 1; i <= 4; i++) {
        float d = float(i) * 0.055;
        occ += (d - map_scene(p + n * d)) * weight;
        weight *= 0.55;
    }
    return clamp(1.0 - occ * 1.7, 0.0, 1.0);
}

float crack_branch(vec2 uv, vec4 c) {
    vec2 d = uv - c.xy;
    float r = length(d);
    float a = atan(d.y, d.x);
    float arms = 4.0 + floor(c.w * 4.0);
    float branch = abs(sin(a * arms + c.w * 9.0 + r * (16.0 + c.w * 21.0)));
    float fork = abs(sin(a * (arms + 3.0) - c.w * 7.0 + r * 31.0));
    float line = (1.0 - smoothstep(0.018, 0.095, min(branch, fork))) * exp(-r * 5.3);
    float core = exp(-r * 38.0);
    return (line * 0.78 + core) * c.z;
}

void fragment() {
    vec2 uv = UV;
    vec2 p = uv * 2.0 - 1.0;
    p.x *= 1.7777778;

    float camera_scale = mix(0.78, 1.16, clamp((u_camera_depth - 0.45) / 1.20, 0.0, 1.0));
    vec3 ro = vec3(0.0, 0.02, -3.7 / camera_scale);
    vec3 rd = normalize(vec3(p.x * 0.80, -p.y * 0.80, 1.62));

    float t = 0.0;
    float hit = 0.0;
    vec3 pos = ro;
    for (int i = 0; i < 64; i++) {
        pos = ro + rd * t;
        float d = map_scene(pos);
        if (abs(d) < 0.0016) {
            hit = 1.0;
            break;
        }
        t += max(0.002, d * 0.76);
        if (t > 7.0) {
            break;
        }
    }

    vec3 background_top = vec3(0.010, 0.013, 0.022);
    vec3 background_bottom = vec3(0.0015, 0.0025, 0.006);
    vec3 color = mix(background_bottom, background_top, clamp(1.0 - uv.y, 0.0, 1.0));
    float grain = hash21(FRAGCOORD.xy * 0.37) - 0.5;
    color += grain * 0.006;

    float fracture = crack_branch(uv, u_crack0) + crack_branch(uv, u_crack1) + crack_branch(uv, u_crack2) + crack_branch(uv, u_crack3);
    fracture = clamp(fracture * u_stress_gain, 0.0, 1.0);

    if (hit > 0.5) {
        vec3 n = normal_at(pos);
        vec3 v = normalize(ro - pos);
        vec3 l0 = normalize(vec3(-0.55, 0.72, -0.42));
        vec3 l1 = normalize(vec3(0.68, -0.18, -0.58));
        float ao = ambient_occlusion(pos, n);
        float diffuse = max(dot(n, l0), 0.0);
        float back = max(dot(n, l1), 0.0);
        float fresnel = pow(1.0 - max(dot(n, v), 0.0), 3.2);

        float cells = mix(8.0, 34.0, clamp(u_facets / 2.4, 0.0, 1.0));
        float facet = hash31(floor(pos * cells));
        float micro = hash31(floor(pos * cells * 3.7 + 4.1));
        vec3 half_dir = normalize(l0 + v);
        float spec_power = mix(78.0, 8.0, u_roughness);
        float spec = pow(max(dot(n, half_dir), 0.0), spec_power);
        spec *= mix(0.65, 1.35, facet);

        vec3 obsidian = vec3(0.008, 0.012, 0.018);
        vec3 graphite = vec3(0.055, 0.072, 0.082);
        vec3 silver = vec3(0.58, 0.64, 0.63);
        vec3 cyan = vec3(0.10, 0.72, 0.78);
        vec3 amber = vec3(0.94, 0.46, 0.17);

        color = mix(obsidian, graphite, 0.18 + diffuse * 0.72) * ao;
        color += silver * spec * (0.34 + (1.0 - u_roughness) * 0.48);
        color += silver * back * 0.08;
        vec3 spectral_color = mix(cyan, amber, clamp(n.y * 0.5 + 0.5 + facet * 0.16, 0.0, 1.0));
        color += spectral_color * fresnel * u_spectral * (0.22 + facet * 0.32);
        color += (micro - 0.5) * 0.025 * (1.0 - u_roughness);
        color = mix(color, spectral_color * 0.82 + silver * 0.18, fracture * 0.30);
        color += silver * fracture * 0.20;
    } else {
        color += vec3(0.08, 0.18, 0.22) * fracture * 0.035;
    }

    float vignette = 1.0 - smoothstep(0.52, 1.24, length(p * vec2(0.56, 0.92)));
    color *= 0.68 + vignette * 0.38;
    COLOR = vec4(max(color, vec3(0.0)), 1.0);
}
