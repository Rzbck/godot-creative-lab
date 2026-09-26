shader_type canvas_item;
render_mode unshaded;

const float DESIGN_ASPECT = 1.7777778;

uniform sampler2D u_state : filter_linear, repeat_disable;
uniform vec2 u_texel = vec2(0.0104167, 0.0185185);
uniform float u_tint = 0.36;
uniform float u_relief = 1.12;
uniform float u_caustic = 0.92;

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

vec4 sample_state(vec2 uv) {
    vec4 c = texture(u_state, uv) * 0.34;
    c += texture(u_state, clamp(uv + vec2(u_texel.x, 0.0), vec2(0.0), vec2(1.0))) * 0.11;
    c += texture(u_state, clamp(uv - vec2(u_texel.x, 0.0), vec2(0.0), vec2(1.0))) * 0.11;
    c += texture(u_state, clamp(uv + vec2(0.0, u_texel.y), vec2(0.0), vec2(1.0))) * 0.11;
    c += texture(u_state, clamp(uv - vec2(0.0, u_texel.y), vec2(0.0), vec2(1.0))) * 0.11;
    c += texture(u_state, clamp(uv + u_texel, vec2(0.0), vec2(1.0))) * 0.055;
    c += texture(u_state, clamp(uv - u_texel, vec2(0.0), vec2(1.0))) * 0.055;
    c += texture(u_state, clamp(uv + vec2(u_texel.x, -u_texel.y), vec2(0.0), vec2(1.0))) * 0.055;
    c += texture(u_state, clamp(uv + vec2(-u_texel.x, u_texel.y), vec2(0.0), vec2(1.0))) * 0.055;
    return c;
}

void fragment() {
    vec4 s = sample_state(UV);
    float e = s.r;
    float r = s.g;
    float age = s.b;

    float el = sample_state(UV - vec2(u_texel.x * 0.72, 0.0)).r;
    float er = sample_state(UV + vec2(u_texel.x * 0.72, 0.0)).r;
    float eu = sample_state(UV - vec2(0.0, u_texel.y * 0.72)).r;
    float ed = sample_state(UV + vec2(0.0, u_texel.y * 0.72)).r;
    vec2 grad = vec2(er - el, ed - eu);
    float front = smoothstep(0.018, 0.16, length(grad));

    vec3 n = normalize(vec3(-grad.x * u_relief * 7.0, -grad.y * u_relief * 7.0, 0.72));
    vec3 light_a = normalize(vec3(-0.55, -0.38, 0.74));
    vec3 light_b = normalize(vec3(0.72, 0.22, 0.66));
    float diffuse = max(0.0, dot(n, light_a));
    float counter = max(0.0, dot(n, light_b));
    float rim = pow(1.0 - max(0.0, n.z), 2.4);

    float band = 0.5 + 0.5 * cos((e * 6.7 + r * 3.3 + age * 1.7) * 6.2831853);
    float grain = hash21(floor(FRAGCOORD.xy * 0.42));

    vec3 deep = mix(vec3(0.018, 0.035, 0.050), vec3(0.050, 0.020, 0.075), u_tint);
    vec3 glass = mix(vec3(0.26, 0.86, 0.83), vec3(0.78, 0.42, 0.96), u_tint);
    vec3 hot = mix(vec3(1.0, 0.74, 0.30), vec3(0.54, 0.92, 1.0), u_tint * 0.65);

    float body = clamp(e * 0.74 + r * 0.36 + age * 0.18, 0.0, 1.0);
    vec3 color = deep * (0.52 + 0.48 * diffuse);
    color += glass * body * (0.16 + 0.58 * diffuse + 0.25 * counter);
    color += hot * front * u_caustic * (0.45 + 0.55 * band);
    color += glass * rim * body * 0.42;
    color += (grain - 0.5) * 0.035 * (0.20 + body * 0.80);

    vec2 p = UV - 0.5;
    p.x *= DESIGN_ASPECT;
    float vignette = smoothstep(1.08, 0.34, length(p));
    color *= mix(0.42, 1.0, vignette);
    color = vec3(1.0) - exp(-color * 1.58);
    COLOR = vec4(color, 1.0);
}
