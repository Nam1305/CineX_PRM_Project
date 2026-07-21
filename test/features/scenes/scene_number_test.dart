import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scene number contract', () {
    test('accepts numeric and cinematic suffix formats', () {
      expect(AppValidators.sceneNumber('1'), isNull);
      expect(AppValidators.sceneNumber('12A'), isNull);
      expect(AppValidators.sceneNumber(' 12b '), isNull);
    });

    test('rejects ambiguous or unsafe values', () {
      expect(AppValidators.sceneNumber(''), isNotNull);
      expect(AppValidators.sceneNumber('A12'), isNotNull);
      expect(AppValidators.sceneNumber('12-AA'), isNotNull);
      expect(AppValidators.sceneNumber('12345'), isNotNull);
    });

    test('sorts numeric bases before letter suffixes', () {
      final values = ['10', '2B', '2', '1', '2A'];
      values.sort(Scene.compareNumbers);
      expect(values, ['1', '2', '2A', '2B', '10']);
    });
  });

  group('Bounded validators', () {
    test('enforces text length and control characters', () {
      expect(AppValidators.text('A', field: 'Tên', min: 2, max: 10), isNotNull);
      expect(
        AppValidators.text('Tên hợp lệ', field: 'Tên', min: 2, max: 20),
        isNull,
      );
      expect(
        AppValidators.text('Tên\u0001', field: 'Tên', min: 2, max: 20),
        isNotNull,
      );
    });

    test('enforces integer bounds', () {
      expect(
        AppValidators.boundedInt('0', field: 'Số người', min: 0, max: 100),
        isNull,
      );
      expect(
        AppValidators.boundedInt('101', field: 'Số người', min: 0, max: 100),
        isNotNull,
      );
    });
  });
}
