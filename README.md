# liquid_glass

A Flutter package implementing Apple's Liquid Glass effect using `ImageFilter.shader`.

## Features

- **Shader-based glass rendering** — full GLSL fragment shader pipeline driven by `ImageFilter.shader` on Impeller-backed platforms.
- **Five SDF shapes** — squircle, roundedRect, circle, capsule, and ellipse, each with a dedicated signed-distance function in the shader.
- **Two-tier rendering** — Tier 1 uses the full Impeller shader path; Tier 2 provides a `BackdropFilter` blur + additive specular fallback for platforms that do not support `ImageFilter.shader`.
- **Accessibility** — automatic detection of high contrast, reduced motion, and dark mode; glass is bypassed at zero GPU cost when transparency is disabled.
- **Theming** — `LiquidGlassSettings` bundles all visual parameters with `copyWith` and `lerp` support for animation and theming.
- **Grouping** — `LiquidGlassGroup` enables shared compositing context and shape merging across sibling glass elements.
- **Button** — `LiquidGlassButton` wraps the glass effect with a press-scale spring animation and primary/secondary style presets.

## Getting started

Add the dependency:

```yaml
dependencies:
  liquid_glass: ^1.0.0
```

Minimum Flutter SDK: **3.6.0**

## Usage

### Basic glass surface

```dart
import 'package:liquid_glass/liquid_glass.dart';

LiquidGlass(
  shape: LiquidGlassShape.squircle(radius: 24),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Hello'),
  ),
)
```

### Glass button

```dart
LiquidGlassButton(
  style: LiquidGlassButtonStyle.primary,
  onPressed: () => debugPrint('tapped'),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Text('Tap me'),
  ),
)
```

### Glass group with merging

```dart
LiquidGlassGroup(
  spacing: 8,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      LiquidGlass(child: Icon(Icons.home)),
      LiquidGlass(child: Icon(Icons.search)),
      LiquidGlass(child: Icon(Icons.settings)),
    ],
  ),
)
```

## Platform support

| Platform              | Tier | Notes                                      |
| --------------------- | ---- | ------------------------------------------ |
| iOS                   | 1    | Full shader pipeline via Impeller          |
| Android (Vulkan)      | 1    | Full shader pipeline via Impeller          |
| Android (OpenGL)      | 2    | Blur + specular fallback                   |
| Web                   | 2    | Blur + specular fallback (no shader API)   |
| Desktop (macOS/Linux/Windows) | 2 | Blur + specular fallback               |

Tier 1 delivers full refraction, chromatic aberration, grain, and light-band effects. Tier 2 approximates the look using `BackdropFilter.blur` and a lightweight specular overlay — visually similar, without shader dependency.

## Example

See the [`example/`](example/) directory for a runnable Flutter app demonstrating all shapes, variants, grouping, and button styles.
