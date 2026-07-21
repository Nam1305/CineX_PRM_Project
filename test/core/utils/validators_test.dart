import 'package:cinex_application/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidators.username', () {
    test('rejects a missing username', () {
      expect(
        AppValidators.username('   '),
        'Tên đăng nhập không được để trống',
      );
    });

    test('rejects usernames outside the allowed length', () {
      expect(
        AppValidators.username('ab'),
        'Tên đăng nhập phải từ 3 đến 32 ký tự',
      );
      expect(
        AppValidators.username('a' * 33),
        'Tên đăng nhập phải từ 3 đến 32 ký tự',
      );
    });

    test('rejects characters outside the permitted set', () {
      expect(
        AppValidators.username('user name!'),
        'Tên đăng nhập chỉ được chứa chữ cái, số, dấu gạch dưới (_) và dấu chấm (.)',
      );
    });

    test('accepts usernames with letters, numbers, underscores, and dots', () {
      expect(AppValidators.username('  cinex.user_01  '), isNull);
    });

    test('uses the supplied field name in errors', () {
      expect(
        AppValidators.username(null, field: 'Username'),
        'Username không được để trống',
      );
    });
  });
}
