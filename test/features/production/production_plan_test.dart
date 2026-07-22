import 'package:cinex_application/features/production/data/models/production_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductionPlan', () {
    test('parses backend maps with numeric JSON keys', () {
      final plan = ProductionPlan.fromMap({
        'projectId': 12,
        'locationDates': {'4': '2026-08-01'},
        'sceneStatuses': {'30': 'DONE'},
        'version': 3,
        'updatedAt': '2026-07-22T03:00:00Z',
      });

      expect(plan.projectId, 12);
      expect(plan.locationDates, {4: '2026-08-01'});
      expect(plan.sceneStatuses, {30: 'DONE'});
      expect(plan.version, 3);
      expect(plan.updatedAt?.isUtc, isTrue);
    });

    test('serializes update payload without local-only fields', () {
      const plan = ProductionPlan(
        projectId: 12,
        locationDates: {4: '2026-08-01'},
        sceneStatuses: {30: 'IN_PROGRESS'},
        version: 2,
      );

      expect(plan.toUpdateMap(), {
        'locationDates': {'4': '2026-08-01'},
        'sceneStatuses': {'30': 'IN_PROGRESS'},
        'version': 2,
      });
    });
  });
}
