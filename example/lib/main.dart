import 'package:flutter/material.dart';
import 'package:liquid_glass/liquid_glass.dart';

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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A73E8),
                  Color(0xFF9C27B0),
                  Color(0xFFE91E63),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Liquid Glass Demo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Variant'),
                  const SizedBox(height: 8),
                  _VariantSwitcher(
                    current: _variant,
                    onChanged: (v) => setState(() => _variant = v),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Basic Glass Card'),
                  const SizedBox(height: 8),
                  LiquidGlass(
                    settings: LiquidGlassSettings(variant: _variant),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Text(
                        'This is a liquid glass card with the default squircle shape.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Shape Showcase'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _shapes.entries.map((entry) {
                      return SizedBox(
                        width: 80,
                        height: 60,
                        child: LiquidGlass(
                          settings: LiquidGlassSettings(variant: _variant),
                          shape: entry.value,
                          child: Center(
                            child: Text(
                              entry.key,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Buttons'),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Glass Group'),
                  const SizedBox(height: 8),
                  LiquidGlassGroup(
                    spacing: 8.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0),
                          child: LiquidGlass(
                            settings:
                                LiquidGlassSettings(variant: _variant),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Item ${i + 1}',
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.5,
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: LiquidGlassVariant.values.map((v) {
        final selected = v == current;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () => onChanged(v),
            style: TextButton.styleFrom(
              backgroundColor: selected
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: selected ? Colors.white : Colors.white54,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: Text(v.name),
          ),
        );
      }).toList(),
    );
  }
}
