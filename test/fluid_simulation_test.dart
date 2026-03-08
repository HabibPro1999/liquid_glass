import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass/src/fluid_simulation.dart';

void main() {
  group('FluidSimulation', () {
    test('fresh sim has zero velocity everywhere', () {
      final sim = FluidSimulation(gridSize: 16);
      final bytes = sim.getDisplacementBytes();
      // All R and G channels should be 128 (midpoint for zero velocity)
      for (int i = 0; i < 16 * 16; i++) {
        expect(bytes[i * 4 + 0], 128, reason: 'R channel at pixel $i');
        expect(bytes[i * 4 + 1], 128, reason: 'G channel at pixel $i');
      }
    });

    test('injectForce creates non-zero velocity at injection point', () {
      final sim = FluidSimulation(gridSize: 32);
      sim.injectForce(0.5, 0.5, 1.0, 0.0, 0.1);
      final bytes = sim.getDisplacementBytes();
      // Center pixel should have R > 128 (positive vx)
      final cx = 16;
      final cy = 16;
      final idx = cy * 32 + cx;
      expect(bytes[idx * 4 + 0], greaterThan(128));
    });

    test('step() moves velocity (advection works)', () {
      final sim = FluidSimulation(gridSize: 32);
      // Inject a rightward force at the center
      sim.injectForce(0.5, 0.5, 1.0, 0.0, 0.05);

      // Record center velocity before step
      final bytesBefore = sim.getDisplacementBytes();
      final cx = 16;
      final cy = 16;
      final centerIdxBefore = (cy * 32 + cx) * 4;
      final rBefore = bytesBefore[centerIdxBefore];

      sim.step(0.016);

      final bytesAfter = sim.getDisplacementBytes();

      // After advection + damping, the field changes
      bool changed = false;
      for (int i = 0; i < 32 * 32 * 4; i++) {
        if (bytesBefore[i] != bytesAfter[i]) {
          changed = true;
          break;
        }
      }
      expect(changed, isTrue,
          reason: 'Velocity field should change after a step');
      // Suppress unused warning
      expect(rBefore, isNotNull);
    });

    test('damping reduces velocity toward zero over multiple steps', () {
      final sim = FluidSimulation(gridSize: 16, damping: 0.5);
      sim.injectForce(0.5, 0.5, 1.0, 0.0, 0.2);

      // Run many steps with no new forces
      for (int i = 0; i < 50; i++) {
        sim.step(0.016);
      }

      final bytes = sim.getDisplacementBytes();
      // All R channels should be close to 128 (near-zero velocity)
      for (int i = 0; i < 16 * 16; i++) {
        expect(bytes[i * 4 + 0], closeTo(128, 5),
            reason: 'R channel at pixel $i should be near 128 after heavy damping');
      }
    });

    test('getDisplacementBytes() returns correct size (gridSize^2 * 4)', () {
      final sim16 = FluidSimulation(gridSize: 16);
      expect(sim16.getDisplacementBytes().length, 16 * 16 * 4);

      final sim64 = FluidSimulation(gridSize: 64);
      expect(sim64.getDisplacementBytes().length, 64 * 64 * 4);

      final sim32 = FluidSimulation(gridSize: 32);
      expect(sim32.getDisplacementBytes().length, 32 * 32 * 4);
    });

    test('getDisplacementBytes() encodes zero velocity as (128, 128, 0, 255)', () {
      final sim = FluidSimulation(gridSize: 8);
      final bytes = sim.getDisplacementBytes();
      for (int i = 0; i < 8 * 8; i++) {
        expect(bytes[i * 4 + 0], 128, reason: 'R at pixel $i');
        expect(bytes[i * 4 + 1], 128, reason: 'G at pixel $i');
        expect(bytes[i * 4 + 2], 0, reason: 'B at pixel $i');
        expect(bytes[i * 4 + 3], 255, reason: 'A at pixel $i');
      }
    });

    test('reset() zeroes all velocity', () {
      final sim = FluidSimulation(gridSize: 16);
      sim.injectForce(0.5, 0.5, 1.0, 1.0, 0.3);

      // Confirm velocity is non-zero before reset
      final before = sim.getDisplacementBytes();
      final cx = 8;
      final cy = 8;
      final centerIdx = (cy * 16 + cx) * 4;
      expect(before[centerIdx], greaterThan(128));

      sim.reset();

      final after = sim.getDisplacementBytes();
      for (int i = 0; i < 16 * 16; i++) {
        expect(after[i * 4 + 0], 128, reason: 'R at pixel $i after reset');
        expect(after[i * 4 + 1], 128, reason: 'G at pixel $i after reset');
      }
    });
  });
}
