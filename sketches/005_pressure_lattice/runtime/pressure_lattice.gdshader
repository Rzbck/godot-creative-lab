shader_type canvas_item;
render_mode unshaded;

uniform float u_time = 0.0;
uniform float u_grain : hint_range(0.0, 1.0) = 0.28;
uniform float u_grid_presence : hint_range(0.0, 1.0) = 0.34;
uniform float u_registration : hint_range(0.0, 1.0) = 0.5;
uniform float u_palette_mix : hint_range(0.0, 1.0) = 0.08;

// x = anchor x in normalized design space
// y/z = gesture direction
// w = spring energy
uniform vec4 u_row0 = vec4(0.5, 1.0, 0.0, 0.0);
uniform vec4 u_row1 = vec4(0.5, 1.0, 0.0, 0.0);
uniform vec4 u_row2 = vec4(0.5, 1.0, 0.0, 0.0);

const vec2 DESIGN = vec2(1280.0, 720.0);
const float SAFE_LEFT = 86.0;
const float SAFE_RIGHT = 1194.0;
const float GRID_WIDTH = SAFE_RIGHT - SAFE_LEFT;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float line_mask(float value, float center, float width) {
    return 1.0 - smoothstep(width, width + 1.25, abs(value - center));
}

float row_field(vec2 p, vec4 row, float center_y, float half_height) {
    float anchor_x = row.x * DESIGN.x;
    float dx = (p.x - anchor_x) / 255.0;
    float dy = (p.y - center_y) / half_height;
    return exp(-(dx * dx * 1.7 + dy * dy * 2.4)) * row.w;
}

float halftone(vec2 p, float scale, float radius) {
    vec2 cell = fract(p / scale) - 0.5;
    return 1.0 - smoothstep(radius, radius + 0.08, length(cell));
}

void fragment() {
    vec2 p = UV * DESIGN;

    vec3 paper_a = vec3(0.945, 0.915, 0.845);
    vec3 paper_b = vec3(0.905, 0.925, 0.935);
    vec3 paper = mix(paper_a, paper_b, u_palette_mix);
    vec3 ink = vec3(0.035, 0.045, 0.065);
    vec3 vermilion = mix(vec3(0.97, 0.16, 0.08), vec3(0.42, 0.18, 0.76), u_palette_mix);
    vec3 cyan = mix(vec3(0.00, 0.55, 0.78), vec3(0.97, 0.16, 0.08), u_palette_mix);

    float paper_noise = (hash21(floor(p * 0.72)) - 0.5) * 0.055 * u_grain;
    vec3 color = paper + vec3(paper_noise);

    float grid = 0.0;
    if (p.x >= SAFE_LEFT && p.x <= SAFE_RIGHT && p.y >= 64.0 && p.y <= 656.0) {
        for (int i = 0; i <= 6; i++) {
            float x = SAFE_LEFT + GRID_WIDTH * float(i) / 6.0;
            grid = max(grid, line_mask(p.x, x, 0.45));
        }
        grid = max(grid, line_mask(p.y, 205.0, 0.45));
        grid = max(grid, line_mask(p.y, 410.0, 0.45));
        grid = max(grid, line_mask(p.y, 592.0, 0.45));
    }
    color = mix(color, ink, grid * (0.025 + 0.07 * u_grid_presence));

    float f0 = row_field(p, u_row0, 170.0, 92.0);
    float f1 = row_field(p, u_row1, 345.0, 128.0);
    float f2 = row_field(p, u_row2, 554.0, 96.0);

    vec2 d0 = vec2(u_row0.y, u_row0.z);
    vec2 d1 = vec2(u_row1.y, u_row1.z);
    vec2 d2 = vec2(u_row2.y, u_row2.z);

    vec2 shift0 = d0 * (10.0 + 24.0 * u_registration) * u_row0.w;
    vec2 shift1 = d1 * (12.0 + 32.0 * u_registration) * u_row1.w;
    vec2 shift2 = d2 * (10.0 + 24.0 * u_registration) * u_row2.w;

    float dots_a = 0.0;
    float dots_b = 0.0;

    dots_a += halftone(p + shift0, 12.0, 0.28) * f0;
    dots_b += halftone(p - shift0 * 0.75 + vec2(4.0, 2.0), 12.0, 0.24) * f0;

    dots_a += halftone(p + shift1, 15.0, 0.31) * f1;
    dots_b += halftone(p - shift1 * 0.72 + vec2(5.0, 3.0), 15.0, 0.27) * f1;

    dots_a += halftone(p + shift2, 11.0, 0.27) * f2;
    dots_b += halftone(p - shift2 * 0.78 + vec2(3.0, 5.0), 11.0, 0.23) * f2;

    dots_a = clamp(dots_a, 0.0, 1.0);
    dots_b = clamp(dots_b, 0.0, 1.0);

    color = mix(color, vermilion, dots_a * 0.34);
    color = mix(color, cyan, dots_b * 0.27);

    // Registration bars are part of the print language, not a debug overlay.
    float registration_marks = 0.0;
    registration_marks = max(registration_marks, line_mask(p.x, 66.0, 0.8) * line_mask(p.y, 205.0, 11.0));
    registration_marks = max(registration_marks, line_mask(p.x, 1214.0, 0.8) * line_mask(p.y, 410.0, 11.0));
    registration_marks = max(registration_marks, line_mask(p.x, 66.0, 0.8) * line_mask(p.y, 592.0, 11.0));
    color = mix(color, ink, registration_marks * 0.25);

    // Keep the outside frame quieter so the typographic safe area reads clearly.
    float edge_x = smoothstep(22.0, 62.0, min(p.x, DESIGN.x - p.x));
    float edge_y = smoothstep(22.0, 58.0, min(p.y, DESIGN.y - p.y));
    float frame = edge_x * edge_y;
    color = mix(paper * 0.985, color, frame);

    COLOR = vec4(color, 1.0);
}
