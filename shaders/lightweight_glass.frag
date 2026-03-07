#include <flutter/runtime_effect.glsl>

precision mediump float;

// ---------------------------------------------------------------------------
// Uniforms — additive specular + rim chrome overlay.
// This shader does NOT sample the backdrop — it only adds visual chrome on top.
// Intended for use with Paint.shader + BlendMode.plus in GlassFallbackPainter.
//
// iOS 26 calibration constants from liquid_glass_widgets §4.2:
//   kSpecularPowerPrimary = 14.0
//   kSpecularPowerKick    = 20.0
//   kRimBaseOpacity       = 0.4
//   kSpecKickIntensity    = 0.4
// ---------------------------------------------------------------------------

uniform float u_width;               // element width in pixels
uniform float u_height;              // element height in pixels
uniform float u_light_angle;         // virtual light source angle (radians)
uniform float u_light_intensity;     // specular brightness multiplier
uniform float u_spec_power;          // primary Phong shininess (14.0)
uniform float u_spec_kick_power;     // back-surface kick shininess (20.0)
uniform float u_spec_kick_intensity; // kick contribution (0.4)
uniform float u_rim_opacity;         // rim light opacity at edges (0.4)
uniform float u_shape_radius;        // corner radius for the SDF

out vec4 fragColor;

// Inigo Quilez rounded rectangle SDF.
float sdRoundedRect(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Y-flip for OpenGL ES backends (Impeller on OpenGLES flips the coordinate).
#ifdef IMPELLER_TARGET_OPENGLES
    fragCoord.y = u_height - fragCoord.y;
#endif

    vec2 halfSize = vec2(u_width, u_height) * 0.5;
    vec2 localP   = fragCoord - halfSize;

    float d    = sdRoundedRect(localP, halfSize, u_shape_radius);
    float mask = 1.0 - smoothstep(-1.0, 1.0, d);

    // Early exit for fully transparent fragments.
    if (mask < 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // --- Surface normal from SDF gradient (finite differences) ---
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

    // --- Dual specular: key light + back-surface kick ---
    vec2  lightDir  = vec2(cos(u_light_angle), -sin(u_light_angle));
    float NdotL     = max(dot(N2, lightDir), 0.0);
    float spec      = pow(NdotL, u_spec_power) * u_light_intensity;
    float NdotLBack = max(dot(-N2, lightDir), 0.0);
    float specKick  = pow(NdotLBack, u_spec_kick_power) * u_spec_kick_intensity;
    float totalSpec = spec + specKick;

    // --- Light band (inner glow ring near the SDF boundary) ---
    // The band center is placed at the SDF edge (d=0); glow fades inward.
    float bandHalfWidth = 15.0;
    float band = smoothstep(bandHalfWidth, 0.0, abs(d)) * 0.3;

    // --- Rim light at edges ---
    // Edge pixels (where d is close to 0) get an ambient rim boost.
    float edgeFactor = 1.0 - smoothstep(-4.0, 0.0, d);
    float rim        = edgeFactor * u_rim_opacity;

    // --- Combine chrome contributions ---
    float chrome = totalSpec + band + rim;

    // Premultiplied alpha output — additive blending (BlendMode.plus) composes
    // this on top of the blurred backdrop without modifying existing pixels.
    fragColor = vec4(vec3(chrome) * mask, mask);
}
