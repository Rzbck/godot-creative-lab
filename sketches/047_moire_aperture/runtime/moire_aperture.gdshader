shader_type canvas_item;
render_mode unshaded;

const float ASPECT = 1.7777778;

uniform vec2 u_anchor0 = vec2(0.28, 0.36);
uniform vec2 u_anchor1 = vec2(0.72, 0.32);
uniform vec2 u_anchor2 = vec2(0.56, 0.72);
uniform float u_density = 34.0;
uniform float u_angle = 0.48;
uniform float u_shear = 0.28;
uniform float u_lens = 0.86;
uniform float u_aperture = 0.29;
uniform float u_contrast = 0.82;
uniform float u_chroma = 0.20;
uniform float u_handle = 0.18;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 rot(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(vec2(c, -s), vec2(s, c)) * p;
}

vec2 aspect_point(vec2 uv) {
    vec2 p = uv - 0.5;
    p.x *= ASPECT;
    return p;
}

vec2 anchor_point(vec2 a) {
    vec2 p = a - 0.5;
    p.x *= ASPECT;
    return p;
}

vec2 warp_anchor(vec2 p, vec2 a, float polarity) {
    vec2 d = p - a;
    float r2 = dot(d, d);
    float radius = max(0.045, u_aperture);
    float falloff = exp(-r2 / (radius * radius));
    float safe_r = sqrt(r2 + 0.0015);
    vec2 tangent = vec2(-d.y, d.x) / safe_r;
    return d * (-u_lens * 0.18 * falloff) + tangent * polarity * u_shear * 0.055 * falloff;
}

float line_mask(float coordinate, float width) {
    float f = fract(coordinate);
    float d = min(f, 1.0 - f);
    float aa = fwidth(coordinate) * 0.72 + 0.0005;
    return 1.0 - smoothstep(width, width + aa, d);
}

float aperture_ring(vec2 p, vec2 a) {
    float r = length(p - a);
    float target = max(0.038, u_aperture * 0.39);
    float aa = 0.0035;
    return 1.0 - smoothstep(aa, aa * 2.2, abs(r - target));
}

void fragment() {
    vec2 p = aspect_point(UV);
    vec2 a0 = anchor_point(u_anchor0);
    vec2 a1 = anchor_point(u_anchor1);
    vec2 a2 = anchor_point(u_anchor2);

    vec2 q = p;
    q += warp_anchor(p, a0, 1.0);
    q += warp_anchor(p, a1, -1.0);
    q += warp_anchor(p, a2, 1.0);

    float density = max(8.0, u_density);
    float angle = u_angle;
    float shear_term = (q.y * q.y - q.x * 0.13) * u_shear;

    vec2 p0 = rot(q + vec2(shear_term * 0.055, 0.0), angle);
    vec2 p1 = rot(q + vec2(0.0, -shear_term * 0.040), -angle * 0.72 + 0.31);
    vec2 p2 = rot(q + vec2(shear_term * 0.025, shear_term * 0.022), angle * 0.37 - 0.76);

    float l0 = line_mask(p0.x * density, 0.060);
    float l1 = line_mask(p1.x * density * 1.013, 0.052);
    float l2 = line_mask(p2.x * density * 0.987, 0.047);

    float pair = l0 * l1 + l1 * l2 + l2 * l0;
    float triple = l0 * l1 * l2;
    float line_union = clamp(l0 + l1 * 0.82 + l2 * 0.64, 0.0, 1.0);

    float basin0 = exp(-dot(p - a0, p - a0) / max(0.012, u_aperture * u_aperture * 2.8));
    float basin1 = exp(-dot(p - a1, p - a1) / max(0.012, u_aperture * u_aperture * 2.8));
    float basin2 = exp(-dot(p - a2, p - a2) / max(0.012, u_aperture * u_aperture * 2.8));
    float basin = clamp(basin0 + basin1 + basin2, 0.0, 1.0);

    vec3 paper = vec3(0.915, 0.902, 0.866);
    vec3 ink = vec3(0.018, 0.022, 0.026);
    float grain = hash21(floor(FRAGCOORD.xy * 0.55));
    paper += (grain - 0.5) * 0.035;

    float density_field = clamp(line_union * (0.62 + u_contrast * 0.48) + pair * 0.22 * u_contrast + triple * 0.28, 0.0, 1.0);
    density_field *= mix(0.72, 1.08, basin);
    vec3 color = mix(paper, ink, clamp(density_field, 0.0, 1.0));

    float registration = clamp(pair * 0.60 + triple, 0.0, 1.0) * u_chroma;
    color.r += registration * (l0 - l2) * 0.32;
    color.b += registration * (l2 - l1) * 0.36;

    float handles = max(aperture_ring(p, a0), max(aperture_ring(p, a1), aperture_ring(p, a2)));
    vec3 handle_color = vec3(0.94, 0.42, 0.16);
    color = mix(color, handle_color, handles * u_handle);

    float vignette = smoothstep(1.07, 0.44, length(p * vec2(0.72, 1.0)));
    color *= mix(0.82, 1.0, vignette);
    COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
