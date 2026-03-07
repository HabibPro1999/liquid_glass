#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform float u_width;
uniform float u_height;
uniform float u_spec_power;
uniform float u_spec_kick_power;
uniform float u_spec_kick_intensity;
uniform float u_light_angle;
uniform float u_light_intensity;
uniform float u_lightband_offset;
uniform float u_lightband_width;
uniform float u_lightband_strength;
uniform float u_shape_radius;

out vec4 fragColor;

float sdRoundedRect(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 halfSize  = vec2(u_width, u_height) * 0.5;
    vec2 localP    = fragCoord - halfSize;

    float d    = sdRoundedRect(localP, halfSize, u_shape_radius);
    float mask = 1.0 - smoothstep(-1.0, 1.0, d);

    vec2 N2;
    {
        float eps = 0.5;
        float dx  = sdRoundedRect(localP + vec2(eps, 0.0), halfSize, u_shape_radius)
                  - sdRoundedRect(localP - vec2(eps, 0.0), halfSize, u_shape_radius);
        float dy  = sdRoundedRect(localP + vec2(0.0, eps), halfSize, u_shape_radius)
                  - sdRoundedRect(localP - vec2(0.0, eps), halfSize, u_shape_radius);
        float len = length(vec2(dx, dy));
        N2 = (len > 0.0001) ? vec2(dx, dy) / len : vec2(0.0, 1.0);
    }

    vec2  lightDir  = vec2(cos(u_light_angle), -sin(u_light_angle));
    float NdotL     = max(dot(N2, lightDir), 0.0);
    float spec      = pow(NdotL, u_spec_power) * u_light_intensity;
    float NdotLBack = max(dot(-N2, lightDir), 0.0);
    float specKick  = pow(NdotLBack, u_spec_kick_power) * u_spec_kick_intensity;
    float totalSpec = spec + specKick;

    float bandCenter = -(u_lightband_offset);
    float halfBand   = u_lightband_width * 0.5;
    float band       = smoothstep(halfBand, 0.0, abs(d - bandCenter)) * u_lightband_strength;

    vec3 chrome = vec3(totalSpec + band);
    fragColor   = vec4(chrome * mask, mask);
}
