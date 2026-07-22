import 'package:cinex_application/core/utils/date_only.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes a local calendar date without shifting to UTC', () {
    final selected = DateTime(2026, 7, 22);
    expect(dateOnlyToApi(selected), '2026-07-22T00:00:00');
  });

  test('parses the calendar portion without timezone conversion', () {
    expect(parseDateOnly('2026-07-22T00:00:00Z'), DateTime(2026, 7, 22));
    expect(parseDateOnly('2026-07-22T17:00:00'), DateTime(2026, 7, 22));
  });

  test('rejects invalid calendar dates', () {
    expect(parseDateOnly('2026-02-30'), isNull);
    expect(parseDateOnly('not-a-date'), isNull);
  });
}
