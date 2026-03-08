import 'dart:math' show exp;
import 'dart:typed_data';

class FluidSimulation {
  FluidSimulation({this.gridSize = 64, this.damping = 0.97}) {
    final size = gridSize * gridSize;
    _velocityX = Float32List(size);
    _velocityY = Float32List(size);
    _prevVelocityX = Float32List(size);
    _prevVelocityY = Float32List(size);
  }

  final int gridSize;
  final double damping;

  late Float32List _velocityX;
  late Float32List _velocityY;
  late Float32List _prevVelocityX;
  late Float32List _prevVelocityY;

  void injectForce(double x, double y, double fx, double fy, double radius) {
    final gx = x * gridSize;
    final gy = y * gridSize;
    final r = radius * gridSize;
    final r2 = r * r;

    for (int j = 0; j < gridSize; j++) {
      for (int i = 0; i < gridSize; i++) {
        final dx = i - gx;
        final dy = j - gy;
        final dist2 = dx * dx + dy * dy;
        final weight = exp(-dist2 / r2);
        final idx = j * gridSize + i;
        _velocityX[idx] += fx * weight;
        _velocityY[idx] += fy * weight;
      }
    }
  }

  void step(double dt) {
    _prevVelocityX = Float32List.fromList(_velocityX);
    _prevVelocityY = Float32List.fromList(_velocityY);

    _advect(_velocityX, _prevVelocityX, _prevVelocityX, _prevVelocityY, dt);
    _advect(_velocityY, _prevVelocityY, _prevVelocityX, _prevVelocityY, dt);

    for (int i = 0; i < _velocityX.length; i++) {
      _velocityX[i] *= damping;
      _velocityY[i] *= damping;
    }
  }

  void _advect(
    Float32List field,
    Float32List prev,
    Float32List velX,
    Float32List velY,
    double dt,
  ) {
    final tmp = Float32List(field.length);
    for (int j = 1; j < gridSize - 1; j++) {
      for (int i = 1; i < gridSize - 1; i++) {
        final idx = j * gridSize + i;
        double srcX = i - dt * gridSize * velX[idx];
        double srcY = j - dt * gridSize * velY[idx];
        srcX = srcX.clamp(0.5, gridSize - 1.5);
        srcY = srcY.clamp(0.5, gridSize - 1.5);
        final i0 = srcX.floor();
        final j0 = srcY.floor();
        final s1 = srcX - i0;
        final s0 = 1.0 - s1;
        final t1 = srcY - j0;
        final t0 = 1.0 - t1;
        tmp[idx] = s0 * (t0 * prev[j0 * gridSize + i0] + t1 * prev[(j0 + 1) * gridSize + i0]) +
            s1 * (t0 * prev[j0 * gridSize + i0 + 1] + t1 * prev[(j0 + 1) * gridSize + i0 + 1]);
      }
    }
    for (int j = 1; j < gridSize - 1; j++) {
      for (int i = 1; i < gridSize - 1; i++) {
        final idx = j * gridSize + i;
        field[idx] = tmp[idx];
      }
    }
  }

  Uint8List getDisplacementBytes() {
    final size = gridSize * gridSize;
    final bytes = Uint8List(size * 4);
    for (int i = 0; i < size; i++) {
      final vx = _velocityX[i].clamp(-1.0, 1.0);
      final vy = _velocityY[i].clamp(-1.0, 1.0);
      bytes[i * 4 + 0] = ((vx * 0.5 + 0.5) * 255).round().clamp(0, 255);
      bytes[i * 4 + 1] = ((vy * 0.5 + 0.5) * 255).round().clamp(0, 255);
      bytes[i * 4 + 2] = 0;
      bytes[i * 4 + 3] = 255;
    }
    return bytes;
  }

  void reset() {
    final size = gridSize * gridSize;
    _velocityX = Float32List(size);
    _velocityY = Float32List(size);
    _prevVelocityX = Float32List(size);
    _prevVelocityY = Float32List(size);
  }
}
