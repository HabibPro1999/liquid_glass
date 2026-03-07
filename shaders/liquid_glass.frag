#version 460 core
#include <flutter/runtime_effect.glsl>

// ---------------------------------------------------------------------------
// Uniforms — float indices [0..25], sampler index [0]
//
// When used via ImageFilter.shader (BackdropFilter), the engine auto-sets:
//   float indices 0, 1 → backdrop texture width/height
//   sampler index 0    → captured backdrop content
// Do NOT call shader.setFloat(0, ...) or setFloat(1, ...) from Dart.
// Custom uniforms start at float index 2.
// ---------------------------------------------------------------------------

uniform float u_width;               // 0: auto-set by engine (backdrop width)
uniform float u_height;              // 1: auto-set by engine (backdrop height)
uniform float u_blur_sigma;          // 2: blur radius
uniform float u_refractive_index;    // 3: glass refractive index
uniform float u_refract_strength;    // 4: refraction UV offset magnitude
uniform float u_distort_falloff;     // 5: pixels from edge for refraction fade
uniform float u_distort_exponent;    // 6: falloff curve sharpness
uniform float u_saturation;          // 7: backdrop saturation multiplier
uniform float u_chromatic_aberration;// 8: per-channel UV offset
uniform float u_light_angle;         // 9: virtual light source angle (radians)
uniform float u_light_intensity;     // 10: specular brightness
uniform float u_spec_power;          // 11: primary Phong shininess
uniform float u_spec_kick_power;     // 12: back-surface kick shininess
uniform float u_spec_kick_intensity; // 13: kick light contribution
uniform float u_lightband_offset;    // 14: inner glow offset from edge
uniform float u_lightband_width;     // 15: inner glow width
uniform float u_lightband_strength;  // 16: inner glow brightness
uniform float u_grain_intensity;     // 17: film grain strength
uniform float u_tint_r;              // 18: tint red component
uniform float u_tint_g;              // 19: tint green component
uniform float u_tint_b;              // 20: tint blue component
uniform float u_tint_a;              // 21: tint alpha (0 = no tint)
uniform float u_shape_type;          // 22: SDF shape selector (0-4)
uniform float u_shape_radius;        // 23: shape corner radius
uniform float u_variant;             // 24: 0=regular, 1=clear, 2=identity
uniform float u_merge_distance;      // 25: merge softness in pixels (from group spacing)
uniform sampler2D u_backdrop;        // sampler 0: backdrop texture

out vec4 fragColor;

// ---------------------------------------------------------------------------
// SDF Shape Functions
// ---------------------------------------------------------------------------

// Inigo Quilez rounded rectangle SDF.
float sdRoundedRect(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

// Superellipse (iOS squircle) SDF — n=4 gives the characteristic iOS corner.
float sdSuperellipse(vec2 p, vec2 halfSize, float radius, float n) {
    vec2 q = abs(p) - halfSize + radius;
    vec2 q2 = max(q, 0.0);
    float ln = pow(pow(q2.x, n) + pow(q2.y, n), 1.0 / n);
    return ln + min(max(q.x, q.y), 0.0) - radius;
}

// Circle SDF.
float sdCircle(vec2 p, float radius) {
    return length(p) - radius;
}

// Capsule SDF.
float sdCapsule(vec2 p, vec2 a, vec2 b, float radius) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * t) - radius;
}

// Ellipse SDF (fast approximation, accurate to ~1px for typical UI ratios).
float sdEllipse(vec2 p, vec2 radii) {
    p = abs(p);
    vec2 q = p / radii;
    float k1 = length(q);
    return (k1 - 1.0) * min(radii.x, radii.y);
}

// ---------------------------------------------------------------------------
// Helper Functions
// ---------------------------------------------------------------------------

// Pseudo-random hash for film grain.
float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

// Evaluate SDF for the current shape type at position p (relative to center).
float evalSDF(vec2 p, vec2 halfSize, float radius) {
    int shape = int(u_shape_type);
    if (shape == 0) {
        // Rounded rectangle
        return sdRoundedRect(p, halfSize, radius);
    } else if (shape == 1) {
        // Superellipse / iOS squircle
        return sdSuperellipse(p, halfSize, radius, 4.0);
    } else if (shape == 2) {
        // Circle
        return sdCircle(p, min(halfSize.x, halfSize.y));
    } else if (shape == 3) {
        // Capsule (horizontal)
        float capLen = max(halfSize.x - halfSize.y, 0.0);
        return sdCapsule(p, vec2(-capLen, 0.0), vec2(capLen, 0.0), halfSize.y);
    } else if (shape == 4) {
        // Ellipse
        return sdEllipse(p, halfSize);
    } else {
        // Default: superellipse
        return sdSuperellipse(p, halfSize, radius, 4.0);
    }
}

// Compute SDF gradient (outward normal) via finite differences.
// Returns a normalized 2D normal vector.
vec2 sdfNormal(vec2 p, vec2 halfSize, float radius) {
    float eps = 0.5;
    float dx = evalSDF(p + vec2(eps, 0.0), halfSize, radius)
             - evalSDF(p - vec2(eps, 0.0), halfSize, radius);
    float dy = evalSDF(p + vec2(0.0, eps), halfSize, radius)
             - evalSDF(p - vec2(0.0, eps), halfSize, radius);
    vec2 grad = vec2(dx, dy);
    float len = length(grad);
    return (len > 0.0001) ? grad / len : vec2(0.0, 1.0);
}

// Schlick Fresnel approximation.
float fresnel(float cosTheta, float r0) {
    float c = clamp(1.0 - cosTheta, 0.0, 1.0);
    float c2 = c * c;
    return r0 + (1.0 - r0) * c2 * c2 * c;
}

// ---------------------------------------------------------------------------
// main()
// ---------------------------------------------------------------------------

void main() {
    // --- Coordinate setup ---
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / vec2(u_width, u_height);

    // Y-flip for OpenGL ES backends (Impeller on OpenGLES flips the texture).
#ifdef IMPELLER_TARGET_OPENGLES
    uv.y = 1.0 - uv.y;
#endif

    // --- Shape geometry ---
    vec2 halfSize = vec2(u_width, u_height) * 0.5;
    vec2 center   = halfSize;
    vec2 localP   = fragCoord - center;

    // --- SDF evaluation ---
    float d = evalSDF(localP, halfSize, u_shape_radius);

    // Anti-aliased mask: 1 inside, 0 outside.
    // When merge_distance > 0, extend the mask softness zone outward.
    // This makes edges softer, causing adjacent elements to visually blend
    // when their soft zones overlap.
    float maskWidth = 1.5; // default anti-alias width
    if (u_merge_distance > 0.0) {
        maskWidth = max(maskWidth, u_merge_distance);
    }
    float mask = 1.0 - smoothstep(-maskWidth, maskWidth, d);

    // Early exit for fully transparent fragments.
    if (mask < 0.001) {
        fragColor = texture(u_backdrop, uv);
        return;
    }

    // --- Surface normal from SDF gradient ---
    vec2 N2 = sdfNormal(localP, halfSize, u_shape_radius);

    // --- Edge falloff for refraction modulation ---
    // d < 0 inside; clamp inner region to [0, u_distort_falloff] and normalize.
    float innerDist = clamp(-d, 0.0, u_distort_falloff);
    float falloff = pow(innerDist / max(u_distort_falloff, 0.001), u_distort_exponent);

    // --- Refraction UV offset ---
    vec2 refractOffset = N2 * u_refract_strength * falloff / vec2(u_width, u_height);
    vec2 refractedUV   = clamp(uv + refractOffset, 0.0, 1.0);

    // --- Chromatic aberration (per-channel UV offset) ---
    vec2 caOffset = N2 * u_chromatic_aberration * falloff / vec2(u_width, u_height);
    vec2 uvR = clamp(refractedUV + caOffset, 0.0, 1.0);
    vec2 uvB = clamp(refractedUV - caOffset, 0.0, 1.0);

    float r = texture(u_backdrop, uvR).r;
    float g = texture(u_backdrop, refractedUV).g;
    float b = texture(u_backdrop, uvB).b;
    float a = texture(u_backdrop, refractedUV).a;

    vec4 baseColor = vec4(r, g, b, a);

    // --- Saturation adjustment ---
    float luma = dot(baseColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    baseColor.rgb = mix(vec3(luma), baseColor.rgb, u_saturation);

    // --- Specular lighting ---
    // Light direction from angle (screen-space: y increases downward so flip y).
    vec2 lightDir = vec2(cos(u_light_angle), -sin(u_light_angle));

    // Primary specular: NdotL raised to shininess power.
    float NdotL = max(dot(N2, lightDir), 0.0);
    float spec  = pow(NdotL, u_spec_power) * u_light_intensity;

    // Kick specular: light from back side of surface.
    float NdotL_back = max(dot(-N2, lightDir), 0.0);
    float specKick   = pow(NdotL_back, u_spec_kick_power) * u_spec_kick_intensity;

    float totalSpec = spec + specKick;
    baseColor.rgb  += vec3(totalSpec);

    // --- Light band (inner glow) ---
    // Glow at distance u_lightband_offset from the SDF boundary, with width u_lightband_width.
    float bandCenter = -(u_lightband_offset);
    float halfBand   = u_lightband_width * 0.5;
    float bandDist   = abs(d - bandCenter);
    float band       = smoothstep(halfBand, 0.0, bandDist) * u_lightband_strength;
    baseColor.rgb   += vec3(band);

    // --- Tint compositing ---
    if (u_tint_a > 0.0) {
        baseColor.rgb += vec3(u_tint_r, u_tint_g, u_tint_b) * u_tint_a;
    }

    // --- Film grain ---
    float grain     = hash(fragCoord) * u_grain_intensity;
    baseColor.rgb  += vec3(grain);

    // --- Apply shape mask to alpha ---
    baseColor.a = mask;

    // --- Blend with unmodified backdrop at anti-aliased edge ---
    vec4 backdropColor = texture(u_backdrop, uv);
    fragColor = mix(backdropColor, baseColor, mask);
}
