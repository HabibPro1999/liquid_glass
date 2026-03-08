import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show StandardMessageCodec;
import 'package:liquid_glass/liquid_glass.dart';

import 'showcase_screen.dart';

void main() => runApp(const LiquidGlassDemo());

class LiquidGlassDemo extends StatelessWidget {
  const LiquidGlassDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassTheme(
      data: const GlassThemeData.light(),
      child: MaterialApp(
        title: 'Liquid Glass Demo',
        theme: ThemeData(brightness: Brightness.light),
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: const DemoScreen(),
      ),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  LiquidGlassVariant _variant = LiquidGlassVariant.regular;

  static const _shapes = <String, LiquidGlassShape>{
    'Squircle': Squircle(radius: 20),
    'RoundedRect': RoundedRect(radius: 12),
    'Circle': Circle(),
    'Capsule': Capsule(),
    'Ellipse': Ellipse(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Rich multi-layer background — creates light and dark regions so
          // the Fresnel rim brightening is clearly visible at glass edges.
          const _RichBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Liquid Glass',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      LiquidGlass(
                        shape: const Squircle(radius: 12),
                        showShadow: false,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShowcaseScreen(),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Apple-style glass rendering for Flutter',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _TierDebugLabel(),
                  const SizedBox(height: 28),

                  // ── Variant switcher ─────────────────────────────────────
                  const _SectionHeader(title: 'Variant'),
                  const SizedBox(height: 10),
                  _VariantSwitcher(
                    current: _variant,
                    onChanged: (v) => setState(() => _variant = v),
                  ),
                  const SizedBox(height: 28),

                  // ── Frosted Glass — hero demo ─────────────────────────────
                  const _SectionHeader(title: 'Frosted Glass'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: LiquidGlass(
                      settings: LiquidGlassSettings(variant: _variant),
                      shape: const Squircle(radius: 24),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Frosted Glass Card',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'The background beneath is blurred and tinted '
                              'through the glass surface. Fresnel rim '
                              'brightening is visible at the edges.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Variants — side-by-side comparison ───────────────────
                  const _SectionHeader(title: 'Variants'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _VariantCard(
                          label: 'Regular (tinted)',
                          description:
                              'Visible tint adapts to the background colour.',
                          variant: LiquidGlassVariant.regular,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VariantCard(
                          label: 'Clear (transparent)',
                          description:
                              'No tint — pure blur and specular chrome.',
                          variant: LiquidGlassVariant.clear,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Shapes showcase ──────────────────────────────────────
                  const _SectionHeader(title: 'Shapes'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _shapes.entries.map((entry) {
                      return SizedBox(
                        width: 100,
                        height: 80,
                        child: LiquidGlass(
                          settings: LiquidGlassSettings(variant: _variant),
                          shape: entry.value,
                          child: Center(
                            child: Text(
                              entry.key,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Glass Group ──────────────────────────────────────────
                  const _SectionHeader(title: 'Glass Group'),
                  const SizedBox(height: 10),
                  LiquidGlassGroup(
                    spacing: 8.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
                          child: LiquidGlass(
                            settings: LiquidGlassSettings(variant: _variant),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Text(
                                'Item ${i + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Buttons ──────────────────────────────────────────────
                  const _SectionHeader(title: 'Buttons'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      LiquidGlassButton(
                        style: LiquidGlassButtonStyle.primary,
                        onPressed: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Primary',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      LiquidGlassButton(
                        style: LiquidGlassButtonStyle.secondary,
                        onPressed: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Text(
                            'Secondary',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Interactive ──────────────────────────────────────────
                  const _SectionHeader(title: 'Interactive'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlass(
                          settings: const LiquidGlassSettings(isInteractive: true),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Touch me',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Interactive',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidGlass(
                          settings: const LiquidGlassSettings(isInteractive: false),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Static',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Non-interactive',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap the button — watch the spring bounce and shimmer:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  LiquidGlassButton(
                    style: LiquidGlassButtonStyle.primary,
                    onPressed: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Text(
                        'Spring + Shimmer',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Native vs Flutter ────────────────────────────────────
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const _SectionHeader(title: 'Native vs Flutter'),
                    const SizedBox(height: 10),
                    // Card comparison
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 90,
                                child: UiKitView(
                                  viewType: 'native-glass-view',
                                  creationParams: const <String, dynamic>{
                                    'label': 'Native',
                                    'subtitle': 'UIGlassEffect',
                                  },
                                  creationParamsCodec:
                                      const StandardMessageCodec(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Native iOS 26',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 90,
                                child: LiquidGlass(
                                  settings:
                                      LiquidGlassSettings(variant: _variant),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Flutter',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'LiquidGlass',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Flutter Package',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Button comparison
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 52,
                                child: UiKitView(
                                  viewType: 'native-glass-view',
                                  creationParams: const <String, dynamic>{
                                    'label': 'Tap Me',
                                    'isButton': true,
                                  },
                                  creationParamsCodec:
                                      const StandardMessageCodec(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Native Button',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              LiquidGlassButton(
                                style: LiquidGlassButtonStyle.primary,
                                onPressed: () {},
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Tap Me',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Flutter Button',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Deep Rendering ───────────────────────────────────────
                  const _SectionHeader(title: 'Deep Rendering'),
                  const SizedBox(height: 8),
                  LiquidGlass(
                    settings: const LiquidGlassSettings(
                      enableGyroscope: true,
                      gyroscopeSensitivity: 1.5,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Tilt your phone',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gyroscope parallax',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlass(
                          settings: const LiquidGlassSettings(
                            enableFluid: true,
                            fluidStrength: 0.5,
                            isInteractive: true,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Touch and drag',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fluid distortion',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidGlass(
                          settings: const LiquidGlassSettings(
                            isInteractive: false,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Static',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No fluid',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tier debug label ─────────────────────────────────────────────────────────

class _TierDebugLabel extends StatefulWidget {
  const _TierDebugLabel();

  @override
  State<_TierDebugLabel> createState() => _TierDebugLabelState();
}

class _TierDebugLabelState extends State<_TierDebugLabel> {
  RenderingTier? _tier;

  @override
  void initState() {
    super.initState();
    DeviceCapabilities.query().then((info) {
      if (!mounted) return;
      setState(() {
        _tier = TierResolver.resolve(info, LiquidGlassMode.auto);
      });
    });
  }

  static String _tierLabel(RenderingTier tier) {
    return switch (tier) {
      RenderingTier.tier0Native => 'Tier 0: Native Glass',
      RenderingTier.tier1Shader => 'Tier 1: Impeller Shader',
      RenderingTier.tier2Fallback => 'Tier 2: Blur + Specular',
      RenderingTier.tier3PureFlutter => 'Tier 3: Pure Flutter',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _tier == null ? 'Detecting...' : _tierLabel(_tier!),
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white54,
      ),
    );
  }
}

// ── Rich background ─────────────────────────────────────────────────────────

/// A visually complex, widget-only background that creates both light and dark
/// regions. No external assets or packages are required.
class _RichBackground extends StatelessWidget {
  const _RichBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient: deep navy → violet
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B4B),
                Color(0xFF2D1464),
                Color(0xFF1A0A3C),
              ],
            ),
          ),
        ),

        // Top-left bright blob — creates a light region for Fresnel contrast
        Positioned(
          left: -80,
          top: -60,
          child: _GlowBlob(
            size: 340,
            color: const Color(0xFF4A9EFF).withValues(alpha: 0.55),
          ),
        ),

        // Top-right warm coral blob
        Positioned(
          right: -60,
          top: 40,
          child: _GlowBlob(
            size: 260,
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.45),
          ),
        ),

        // Centre-left teal accent
        Positioned(
          left: 20,
          top: 260,
          child: _GlowBlob(
            size: 200,
            color: const Color(0xFF00D4AA).withValues(alpha: 0.40),
          ),
        ),

        // Centre bright yellow highlight — sharp contrast for rim test
        Positioned(
          left: 140,
          top: 150,
          child: _GlowBlob(
            size: 160,
            color: const Color(0xFFFFE066).withValues(alpha: 0.35),
          ),
        ),

        // Lower-right deep magenta blob — dark side
        Positioned(
          right: -40,
          bottom: 100,
          child: _GlowBlob(
            size: 300,
            color: const Color(0xFFB03AFF).withValues(alpha: 0.50),
          ),
        ),

        // Bottom-left cobalt blob
        Positioned(
          left: -30,
          bottom: 60,
          child: _GlowBlob(
            size: 220,
            color: const Color(0xFF1E6FFF).withValues(alpha: 0.40),
          ),
        ),

        // Bright white sunspot — creates the highest-contrast light region
        Positioned(
          right: 60,
          top: 200,
          child: _GlowBlob(
            size: 120,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),

        // Thin diagonal stripe — adds geometric interest and horizontal banding
        Positioned.fill(
          child: CustomPaint(
            painter: _DiagonalStripePainter(),
          ),
        ),
      ],
    );
  }
}

/// Soft circular gradient blob used for the layered background.
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

/// Paints a few soft diagonal bands to add horizontal contrast variation.
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Subtle semi-transparent light band across the upper third
    final rect1 = Rect.fromLTWH(0, size.height * 0.08, size.width, 60);
    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.07),
        Colors.white.withValues(alpha: 0),
      ],
    ).createShader(rect1);
    canvas.drawRect(rect1, paint);

    // Dark band in the lower half — creates shadow region
    final rect2 = Rect.fromLTWH(0, size.height * 0.55, size.width, 80);
    paint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.black.withValues(alpha: 0),
        Colors.black.withValues(alpha: 0.18),
        Colors.black.withValues(alpha: 0),
      ],
    ).createShader(rect2);
    canvas.drawRect(rect2, paint);
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter oldDelegate) => false;
}

// ── Variant comparison card ─────────────────────────────────────────────────

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.label,
    required this.description,
    required this.variant,
  });

  final String label;
  final String description;
  final LiquidGlassVariant variant;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      settings: LiquidGlassSettings(variant: variant),
      shape: const Squircle(radius: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared UI components ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white54,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _VariantSwitcher extends StatelessWidget {
  const _VariantSwitcher({
    required this.current,
    required this.onChanged,
  });

  final LiquidGlassVariant current;
  final ValueChanged<LiquidGlassVariant> onChanged;

  static String _label(LiquidGlassVariant v) {
    return switch (v) {
      LiquidGlassVariant.regular => 'Regular (tinted)',
      LiquidGlassVariant.clear => 'Clear (transparent)',
      LiquidGlassVariant.identity => 'Identity (off)',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LiquidGlassVariant.values.map((v) {
        final selected = v == current;
        return TextButton(
          onPressed: () => onChanged(v),
          style: TextButton.styleFrom(
            backgroundColor: selected
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selected ? Colors.white : Colors.white38,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: Text(
            _label(v),
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}
