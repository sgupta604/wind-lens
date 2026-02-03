import 'package:flutter_test/flutter_test.dart';
import 'package:wind_lens/models/view_mode.dart';

void main() {
  group('ViewMode', () {
    group('enum values', () {
      test('has dots value', () {
        expect(ViewMode.dots, isNotNull);
        expect(ViewMode.dots.name, 'dots');
      });

      test('has streamlines value', () {
        expect(ViewMode.streamlines, isNotNull);
        expect(ViewMode.streamlines.name, 'streamlines');
      });

      test('has exactly two values', () {
        expect(ViewMode.values.length, 2);
      });

      test('values are in order: dots, streamlines', () {
        expect(ViewMode.values[0], ViewMode.dots);
        expect(ViewMode.values[1], ViewMode.streamlines);
      });
    });

    group('displayName', () {
      test('dots has displayName "Dots"', () {
        expect(ViewMode.dots.displayName, 'Dots');
      });

      test('streamlines has displayName "Streamlines"', () {
        expect(ViewMode.streamlines.displayName, 'Streamlines');
      });
    });

    group('defaultMode', () {
      test('ViewModeExtension.defaultMode returns dots', () {
        expect(ViewModeExtension.defaultMode, ViewMode.dots);
      });
    });

    group('toggle', () {
      test('toggling from dots returns streamlines', () {
        expect(ViewMode.dots.toggle(), ViewMode.streamlines);
      });

      test('toggling from streamlines returns dots', () {
        expect(ViewMode.streamlines.toggle(), ViewMode.dots);
      });
    });
  });
}
