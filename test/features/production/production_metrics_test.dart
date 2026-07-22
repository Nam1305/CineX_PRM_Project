import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/production/data/production_metrics.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Scene scene(int id, SceneStatus scriptStatus) => Scene(
    id: id,
    actId: 1,
    sceneNumber: '$id',
    title: 'Scene $id',
    status: scriptStatus,
  );

  test('production progress uses persisted shooting statuses consistently', () {
    final scenes = [
      scene(1, SceneStatus.done),
      scene(2, SceneStatus.done),
      scene(3, SceneStatus.done),
      scene(4, SceneStatus.inProgress),
    ];
    final metrics = ProductionMetrics.fromScenes(scenes, {
      1: 'DONE',
      2: 'IN_PROGRESS',
      3: 'TODO',
      4: 'DONE',
    });

    expect(metrics.total, 4);
    expect(metrics.done, 1);
    expect(metrics.inProgress, 1);
    expect(metrics.todo, 2);
    expect(metrics.progress, 0.25);
  });

  test('empty production plan has zero progress', () {
    final metrics = ProductionMetrics.fromScenes(const [], const {});
    expect(metrics.progress, 0);
  });
}
