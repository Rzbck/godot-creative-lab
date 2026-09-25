shader_type canvas_item;
render_mode unshaded;

const float DESIGN_ASPECT = 1.7777778;

uniform sampler2D u_state : filter_linear, repeat_disable;
uniform vec2 u_texel = vec2(0.0125,0.0222222);
uniform float u_knife_angle = 0.34;
uniform float u_chromaticity = 0.22;
uniform float u_micro = 1.06;

float hash21(vec2 p){
    p=fract(p*vec2(123.34,456.21));
    p+=dot(p,p+45.32);
    return fract(p.x*p.y);
}

void fragment(){
    vec4 s=texture(u_state,UV);
    float d=s.r;
    float t=s.g;
    float dl=texture(u_state,UV-vec2(u_texel.x,0.0)).r;
    float dr=texture(u_state,UV+vec2(u_texel.x,0.0)).r;
    float du=texture(u_state,UV-vec2(0.0,u_texel.y)).r;
    float dd=texture(u_state,UV+vec2(0.0,u_texel.y)).r;
    vec2 grad=vec2(dr-dl,dd-du)*0.5;
    float g=length(grad);

    vec2 knife=vec2(cos(u_knife_angle),sin(u_knife_angle));
    float signed_grad=dot(grad,knife);
    float schlieren=0.5+signed_grad*7.5;
    schlieren=clamp(schlieren,0.0,1.0);
    float edge=smoothstep(0.008,0.12,g);

    vec2 pixel=floor(FRAGCOORD.xy);
    float grain=hash21(floor(pixel*(0.33+u_micro*0.18)));
    float wisps=hash21(floor(pixel*0.075)+floor(d*31.0));

    vec3 neutral=mix(vec3(0.012,0.016,0.021),vec3(0.80,0.84,0.84),schlieren);
    neutral*=0.34+d*0.78+edge*0.35;

    vec3 cold=vec3(0.20,0.48,0.70);
    vec3 warm=vec3(0.96,0.48,0.18);
    vec3 thermal=mix(cold,warm,clamp(t,0.0,1.0));
    vec3 color=mix(neutral,neutral*0.58+thermal*(0.22+d*0.48+edge*0.38),u_chromaticity);

    float filament=smoothstep(0.03,0.16,g)*(0.55+0.45*schlieren);
    color+=thermal*filament*0.18*u_chromaticity;
    color+=(grain-0.5)*0.034*u_micro*(0.25+d*0.75);
    color+=(wisps-0.5)*0.018*u_micro*d;

    vec2 p=UV-0.5;
    p.x*=DESIGN_ASPECT;
    float vignette=smoothstep(1.12,0.32,length(p));
    color*=mix(0.38,1.0,vignette);
    color=vec3(1.0)-exp(-color*1.42);
    COLOR=vec4(color,1.0);
}
