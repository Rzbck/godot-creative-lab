shader_type canvas_item;
render_mode unshaded;

uniform sampler2D u_scar : filter_linear, repeat_disable;
uniform vec2 u_anchor0 = vec2(0.31, 0.38);
uniform vec2 u_anchor1 = vec2(0.67, 0.31);
uniform vec2 u_anchor2 = vec2(0.58, 0.70);
uniform float u_volume_scale = 1.0;
uniform float u_tunnel = 0.86;
uniform float u_spectral = 0.32;
uniform float u_roughness = 0.58;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

mat2 rot2(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(vec2(c, -s), vec2(s, c));
}

float sd_torus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float smooth_min(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float map_scene(vec3 p) {
    vec3 q = p / u_volume_scale;
    vec3 c0 = vec3((u_anchor0.x - 0.5) * 1.45, (0.5 - u_anchor0.y) * 0.95, 0.10);
    vec3 c1 = vec3((u_anchor1.x - 0.5) * 1.45, (0.5 - u_anchor1.y) * 0.95, -0.12);
    vec3 c2 = vec3((u_anchor2.x - 0.5) * 1.45, (0.5 - u_anchor2.y) * 0.95, 0.02);

    vec3 a = q - c0;
    vec2 ar = rot2(0.45 + u_anchor0.x * 1.8) * a.xz;
    a.x = ar.x; a.z = ar.y;
    vec3 b = q - c1;
    vec2 br = rot2(-0.65 + u_anchor1.y * 1.6) * b.yz;
    b.y = br.x; b.z = br.y;
    vec3 c = q - c2;
    vec2 cr = rot2(0.95 + u_anchor2.x * 1.2) * c.xy;
    c.x = cr.x; c.y = cr.y;

    float tube = 0.070 + u_tunnel * 0.055;
    float d0 = sd_torus(a, vec2(0.44, tube));
    float d1 = sd_torus(b, vec2(0.39, tube * 1.04));
    float d2 = sd_torus(c, vec2(0.47, tube * 0.92));
    float d = smooth_min(d0, d1, 0.18);
    d = smooth_min(d, d2, 0.18);

    float fold = abs(q.y + 0.10 * sin(q.x * 3.7) + 0.08 * sin(q.z * 4.3)) - 0.038;
    d = smooth_min(d, fold, 0.13);

    vec2 scar_uv = clamp(vec2(q.x * 0.31 + 0.5, 0.5 - q.y * 0.46), vec2(0.0), vec2(1.0));
    float scar = texture(u_scar, scar_uv).r;
    d += scar * (0.055 + 0.12 * u_tunnel);
    d += sin((q.x + q.z) * 17.0) * 0.0026;
    return d * u_volume_scale;
}

vec3 scene_normal(vec3 p) {
    float e = 0.0035;
    vec2 h = vec2(e, 0.0);
    return normalize(vec3(
        map_scene(p + h.xyy) - map_scene(p - h.xyy),
        map_scene(p + h.yxy) - map_scene(p - h.yxy),
        map_scene(p + h.yyx) - map_scene(p - h.yyx)
    ));
}

float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 52; i++) {
        vec3 p = ro + rd * t;
        float d = map_scene(p);
        if (d < 0.0015) {
            return t;
        }
        t += max(0.006, d * 0.72);
        if (t > 5.2) {
            break;
        }
    }
    return -1.0;
}

float ambient_occlusion(vec3 p, vec3 n) {
    float occ = 0.0;
    float weight = 1.0;
    for (int i = 1; i <= 4; i++) {
        float h = 0.035 * float(i);
        float d = map_scene(p + n * h);
        occ += (h - d) * weight;
        weight *= 0.62;
    }
    return clamp(1.0 - occ * 2.8, 0.0, 1.0);
}

void fragment() {
    vec2 p = UV - 0.5;
    p.x *= 1.7777778;

    vec3 ro = vec3(0.0, 0.0, 2.75);
    vec3 rd = normalize(vec3(p.x, -p.y, -1.72));
    float t = raymarch(ro, rd);

    vec3 bg_a = vec3(0.004, 0.006, 0.009);
    vec3 bg_b = vec3(0.020, 0.012, 0.028);
    float vignette = smoothstep(1.05, 0.18, length(p));
    vec3 color = mix(bg_a, bg_b, vignette * 0.52);

    if (t > 0.0) {
        vec3 pos = ro + rd * t;
        vec3 n = scene_normal(pos);
        float ao = ambient_occlusion(pos, n);
        vec3 l1 = normalize(vec3(-0.52, 0.64, 0.56));
        vec3 l2 = normalize(vec3(0.68, -0.16, 0.72));
        float diff = max(0.0, dot(n, l1));
        float counter = max(0.0, dot(n, l2));
        vec3 half_v = normalize(l1 - rd);
        float spec_power = mix(18.0, 92.0, 1.0 - u_roughness);
        float spec = pow(max(0.0, dot(n, half_v)), spec_power);
        float rim = pow(1.0 - max(0.0, dot(n, -rd)), 2.6);

        vec2 scar_uv = clamp(vec2(pos.x * 0.31 / u_volume_scale + 0.5, 0.5 - pos.y * 0.46 / u_volume_scale), vec2(0.0), vec2(1.0));
        float scar = texture(u_scar, scar_uv).r;
        float grain = hash21(floor(FRAGCOORD.xy * 0.29));

        vec3 mineral = mix(vec3(0.12, 0.15, 0.18), vec3(0.18, 0.105, 0.24), u_spectral);
        vec3 edge = mix(vec3(0.64, 0.72, 0.76), vec3(0.94, 0.46, 0.72), u_spectral);
        color = mineral * (0.18 + 0.72 * diff + 0.25 * counter) * ao;
        color += edge * rim * (0.20 + 0.52 * u_spectral);
        color += vec3(0.92, 0.88, 0.78) * spec * (0.42 + (1.0 - u_roughness) * 0.52);
        color *= 1.0 - scar * 0.34;
        color += (grain - 0.5) * 0.028 * (0.30 + 0.70 * (1.0 - u_roughness));
        color *= mix(0.62, 1.0, vignette);
        color = vec3(1.0) - exp(-color * 1.72);
    }

    COLOR = vec4(color, 1.0);
}
