shader_type canvas_item;
render_mode unshaded;

uniform float u_time = 0.0;
uniform float u_grid_columns : hint_range(5.0, 14.0) = 7.0;
uniform float u_field_strength : hint_range(0.0, 2.0) = 0.9;
uniform float u_line_density : hint_range(8.0, 36.0) = 19.0;
uniform float u_contrast : hint_range(0.4, 1.8) = 1.05;
uniform float u_pulse : hint_range(0.0, 1.0) = 0.32;
uniform float u_palette_mix : hint_range(0.0, 1.0) = 0.18;

uniform vec4 u_mark0 = vec4(-2.0, -2.0, 0.0, 0.0);
uniform vec4 u_mark1 = vec4(-2.0, -2.0, 0.0, 0.0);
uniform vec4 u_mark2 = vec4(-2.0, -2.0, 0.0, 0.0);
uniform vec4 u_mark3 = vec4(-2.0, -2.0, 0.0, 0.0);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 mark_flow(vec2 uv, vec4 mark) {
    if (mark.z <= 0.0001) {
        return vec2(0.0);
    }

    vec2 delta = (uv - mark.xy) * vec2(1.7777778, 1.0);
    float radius = length(delta);
    float influence = exp(-radius * radius * 11.0) * mark.z;
    vec2 tangent = vec2(-delta.y, delta.x) / (radius + 0.001);
    vec2 radial = delta / (radius + 0.001);
    float age_twist = sin(mark.w * 4.0 + radius * 17.0);
    return (tangent * (0.064 + 0.024 * age_twist) - radial * 0.018) * influence;
}

float mark_energy(vec2 uv, vec4 mark) {
    if (mark.z <= 0.0001) {
        return 0.0;
    }
    vec2 delta = (uv - mark.xy) * vec2(1.7777778, 1.0);
    float radius = length(delta);
    return exp(-radius * radius * 15.0) * mark.z;
}

void fragment() {
    vec2 uv = UV;
    float columns = max(5.0, floor(u_grid_columns + 0.5));
    vec2 grid = vec2(columns, max(3.0, floor(columns * 0.56 + 0.5)));
    vec2 cell_id = floor(uv * grid);
    vec2 cell_uv = fract(uv * grid) - 0.5;
    float role = hash21(cell_id + vec2(3.1, 7.9));
    float role_state = floor(role * 4.0) / 3.0;

    vec2 warped_uv = uv;
    vec2 base_field = vec2(
        sin((uv.y * 3.0 + uv.x * 0.75) * 6.2831853 + u_time * 0.34),
        cos((uv.x * 2.4 - uv.y * 0.55) * 6.2831853 - u_time * 0.27)
    ) * 0.008;

    vec2 gesture_field = vec2(0.0);
    gesture_field += mark_flow(uv, u_mark0);
    gesture_field += mark_flow(uv, u_mark1);
    gesture_field += mark_flow(uv, u_mark2);
    gesture_field += mark_flow(uv, u_mark3);
    warped_uv += (base_field + gesture_field) * u_field_strength;

    float hierarchy_phase = role_state * 2.35 + cell_id.x * 0.11 - cell_id.y * 0.17;
    float line_phase = (
        warped_uv.y * u_line_density
        + warped_uv.x * (2.1 + role_state * 1.3)
        + sin(warped_uv.x * 12.0 + u_time * 0.21) * (0.35 + role_state * 0.25)
    ) * 6.2831853 + hierarchy_phase;

    float cross_phase = (
        warped_uv.x * (u_line_density * 0.54)
        - warped_uv.y * (1.4 + role_state * 1.6)
    ) * 6.2831853 - u_time * 0.19 + role * 5.0;

    float primary = abs(sin(line_phase));
    float secondary = abs(sin(cross_phase));
    float signal = max(primary, secondary * (0.38 + role_state * 0.28));
    float threshold = mix(0.91, 0.70, clamp(u_contrast / 1.8, 0.0, 1.0));
    float ink_mask = smoothstep(threshold, min(0.999, threshold + 0.09), signal);

    float cell_edge = max(abs(cell_uv.x), abs(cell_uv.y));
    float grid_line = smoothstep(0.465, 0.497, cell_edge);
    grid_line *= 0.12 + role_state * 0.12;

    float memory = 0.0;
    memory += mark_energy(uv, u_mark0);
    memory += mark_energy(uv, u_mark1);
    memory += mark_energy(uv, u_mark2);
    memory += mark_energy(uv, u_mark3);
    memory = clamp(memory, 0.0, 1.0);

    float pulse = 0.5 + 0.5 * sin(u_time * 0.55 + role * 6.2831853);
    float pulse_gain = mix(1.0, 0.78 + pulse * 0.42, u_pulse);
    ink_mask *= pulse_gain;

    vec3 bg_a = vec3(0.012, 0.015, 0.022);
    vec3 bg_b = vec3(0.026, 0.014, 0.028);
    vec3 paper = vec3(0.94, 0.90, 0.80);
    vec3 accent_a = vec3(1.0, 0.36, 0.08);
    vec3 accent_b = vec3(0.08, 0.72, 1.0);
    vec3 bg = mix(bg_a, bg_b, u_palette_mix);
    vec3 accent = mix(accent_a, accent_b, u_palette_mix);

    float accent_mask = smoothstep(0.22, 0.78, memory) * (0.55 + role_state * 0.45);
    accent_mask += grid_line * (0.16 + memory * 0.2);
    accent_mask = clamp(accent_mask, 0.0, 1.0);

    vec3 color = mix(bg, paper, ink_mask * (0.42 + role_state * 0.52));
    color = mix(color, accent, accent_mask * (0.48 + ink_mask * 0.28));

    float margin_x = smoothstep(0.035, 0.078, min(uv.x, 1.0 - uv.x));
    float margin_y = smoothstep(0.055, 0.105, min(uv.y, 1.0 - uv.y));
    float safe_frame = margin_x * margin_y;
    color = mix(bg, color, safe_frame);

    COLOR = vec4(color, 1.0);
}
