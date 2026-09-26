shader_type canvas_item;
render_mode unshaded;

const float ASPECT = 1.7777778;

uniform vec4 u_spot0 = vec4(0.24, 0.33, 0.82, 0.72);
uniform vec4 u_spot1 = vec4(0.67, 0.28, 0.64, 0.46);
uniform vec4 u_spot2 = vec4(0.56, 0.70, 0.48, 0.28);
uniform vec4 u_spot3 = vec4(0.5, 0.5, 0.0, 0.0);
uniform vec4 u_spot4 = vec4(0.5, 0.5, 0.0, 0.0);
uniform vec4 u_spot5 = vec4(0.5, 0.5, 0.0, 0.0);
uniform float u_radius = 0.18;
uniform float u_conduction = 0.64;
uniform float u_buckle = 0.72;
uniform float u_oxide = 0.74;
uniform float u_furnace = 0.52;

float hash21(vec2 p) {
    p = fract(p * vec2(443.8975, 397.2973));
    p += dot(p, p.yx + 19.19);
    return fract(p.x * p.y);
}

vec4 spot_field(vec2 uv, vec4 s) {
    vec2 d = uv - s.xy;
    d.x *= ASPECT;
    float radius = max(0.025, u_radius);
    float g = exp(-dot(d, d) / (radius * radius));
    float heat = s.z * g;
    float oxide = s.w * g;
    vec2 grad = -2.0 * d / (radius * radius) * heat;
    return vec4(heat, oxide, grad.x, grad.y);
}

vec3 temper_palette(float heat, float oxide) {
    vec3 steel = vec3(0.075, 0.082, 0.090);
    vec3 straw = vec3(0.88, 0.58, 0.16);
    vec3 violet = vec3(0.42, 0.12, 0.50);
    vec3 blue = vec3(0.12, 0.34, 0.72);
    vec3 pale = vec3(0.72, 0.80, 0.84);

    float h = clamp(heat * 0.82 + oxide * 0.34, 0.0, 1.65);
    vec3 c = mix(steel, straw, smoothstep(0.12, 0.42, h));
    c = mix(c, violet, smoothstep(0.36, 0.70, h));
    c = mix(c, blue, smoothstep(0.64, 1.02, h));
    c = mix(c, pale, smoothstep(1.05, 1.50, h));
    return c;
}

void fragment() {
    vec4 f = spot_field(UV, u_spot0);
    f += spot_field(UV, u_spot1);
    f += spot_field(UV, u_spot2);
    f += spot_field(UV, u_spot3);
    f += spot_field(UV, u_spot4);
    f += spot_field(UV, u_spot5);

    float heat = f.x;
    float oxide = f.y * u_oxide;
    vec2 grad = f.zw * (0.42 + u_conduction * 0.58);

    vec3 n = normalize(vec3(-grad.x * u_buckle * 1.9, -grad.y * u_buckle * 1.9, 1.0));
    vec3 light_a = normalize(vec3(-0.62, -0.34, 0.78));
    vec3 light_b = normalize(vec3(0.72, 0.24, 0.64));
    float diffuse = max(0.0, dot(n, light_a));
    float counter = max(0.0, dot(n, light_b));
    float rim = pow(1.0 - clamp(n.z, 0.0, 1.0), 2.2);

    vec3 base = temper_palette(heat, oxide);
    float ring = smoothstep(0.015, 0.12, length(grad)) * clamp(oxide + heat * 0.45, 0.0, 1.0);
    vec3 color = base * (0.42 + diffuse * 0.72 + counter * 0.14);
    color += vec3(0.74, 0.82, 0.88) * rim * 0.28;
    color += vec3(0.94, 0.54, 0.18) * ring * 0.10;

    float brushed = 0.5 + 0.5 * sin(FRAGCOORD.x * 0.43 + hash21(vec2(floor(FRAGCOORD.y * 0.12), 3.0)) * 6.2831853);
    float scratch = step(0.985, hash21(vec2(floor(FRAGCOORD.x * 0.16), floor(FRAGCOORD.y * 0.045))));
    float grain = hash21(floor(FRAGCOORD.xy * 0.52));
    color += (brushed - 0.5) * 0.020 * (1.0 - clamp(heat, 0.0, 1.0));
    color += (grain - 0.5) * 0.026;
    color += scratch * vec3(0.10, 0.11, 0.12);

    vec2 p = UV - 0.5;
    p.x *= ASPECT;
    float plate = smoothstep(1.05, 0.76, max(abs(p.x) * 0.86, abs(p.y) * 1.55));
    float vignette = smoothstep(1.08, 0.30, length(p * vec2(0.72, 1.0)));
    color *= mix(0.46, 1.0, vignette);
    color = mix(vec3(0.012, 0.014, 0.017), color, clamp(plate + 0.10, 0.0, 1.0));
    color += u_furnace * heat * vec3(0.025, 0.010, 0.002);

    COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
