shader_type canvas_item;
render_mode unshaded;

const float DESIGN_ASPECT = 1.7777778;

uniform vec4 u_b0 = vec4(0.31,0.34,0.118,0.72);
uniform vec4 u_b1 = vec4(0.45,0.27,0.096,0.54);
uniform vec4 u_b2 = vec4(0.61,0.34,0.132,0.78);
uniform vec4 u_b3 = vec4(0.70,0.51,0.088,0.48);
uniform vec4 u_b4 = vec4(0.59,0.66,0.112,0.62);
uniform vec4 u_b5 = vec4(0.42,0.68,0.101,0.59);
uniform vec4 u_b6 = vec4(0.27,0.56,0.084,0.44);
uniform vec4 u_b7 = vec4(0.48,0.48,0.139,0.86);
uniform float u_film_width = 1.18;
uniform float u_iridescence = 0.78;
uniform float u_translucency = 0.58;
uniform float u_micro = 1.12;
uniform float u_exposure = 1.08;

float hash21(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 34.17);
    return fract(p.x * p.y);
}

vec2 ap(vec2 uv) {
    vec2 p = uv - 0.5;
    p.x *= DESIGN_ASPECT;
    return p;
}

float bubble_sd(vec2 p, vec4 b) {
    return length(p - ap(b.xy)) - b.z;
}

void fragment() {
    vec2 p = ap(UV);
    float near1 = 1000.0;
    float near2 = 1000.0;
    vec4 nearest_b = u_b0;
    float d;

    d = bubble_sd(p,u_b0); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b0; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b1); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b1; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b2); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b2; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b3); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b3; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b4); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b4; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b5); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b5; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b6); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b6; } else if (d < near2) { near2 = d; }
    d = bubble_sd(p,u_b7); if (d < near1) { near2 = near1; near1 = d; nearest_b = u_b7; } else if (d < near2) { near2 = d; }

    float body = smoothstep(0.018, -0.028, near1);
    float outer_film = exp(-abs(near1) * (155.0 / max(0.2,u_film_width)));
    float junction = exp(-abs(near2 - near1) * (115.0 / max(0.2,u_film_width))) * smoothstep(0.10,-0.02,near1);
    float film = clamp(max(outer_film, junction), 0.0, 1.0);

    vec2 center = ap(nearest_b.xy);
    vec2 local = (p - center) / max(nearest_b.z, 0.001);
    float radial = clamp(length(local), 0.0, 1.5);
    vec3 normal = normalize(vec3(local * 0.72, sqrt(max(0.04, 1.0 - min(0.98,dot(local,local))))));
    vec3 light = normalize(vec3(-0.42,-0.28,0.86));
    float diffuse = max(0.0,dot(normal,light));
    float rim = pow(1.0 - max(0.0,normal.z),2.5);

    float optical_phase = (radial * 3.7 + nearest_b.w * 1.9 + (near2-near1) * 22.0) * 6.28318;
    vec3 interference = 0.5 + 0.5*cos(vec3(1.0,1.31,1.67)*optical_phase + vec3(0.0,2.0,4.1));
    interference = pow(interference,vec3(1.25));

    vec2 pixel = floor(FRAGCOORD.xy);
    float grain = hash21(floor(pixel*(0.42+u_micro*0.16)));
    float pearly = smoothstep(0.70,0.98,grain) * u_micro;

    vec3 background = vec3(0.006,0.009,0.015);
    vec3 glass = vec3(0.035,0.075,0.105) * (0.45 + diffuse*0.9);
    glass += vec3(0.08,0.14,0.17) * rim * 0.55;
    glass += mix(vec3(0.18),interference,u_iridescence) * (0.12 + film*0.74 + rim*0.18);
    glass += interference * pearly * 0.075;
    glass += vec3(0.22,0.32,0.38) * u_translucency * (1.0-radial) * 0.18;

    vec3 color = mix(background,glass,body*0.84 + film*0.42);
    color += interference * film * (0.28 + u_iridescence*0.66);
    float vignette = smoothstep(1.05,0.26,length(p));
    color *= mix(0.42,1.0,vignette);
    color = vec3(1.0)-exp(-color*u_exposure*1.7);
    COLOR = vec4(color,1.0);
}
