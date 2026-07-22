import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class ProductionMetrics {
  final int total;
  final int todo;
  final int inProgress;
  final int done;

  const ProductionMetrics({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
  });

  double get progress => total == 0 ? 0 : done / total;

  factory ProductionMetrics.fromScenes(
    List<Scene> scenes,
    Map<int, String> shootingStatuses,
  ) {
    var todo = 0;
    var inProgress = 0;
    var done = 0;
    for (final scene in scenes) {
      final status = effectiveShootingStatus(scene, shootingStatuses);
      switch (status) {
        case SceneStatus.todo:
          todo++;
        case SceneStatus.inProgress:
          inProgress++;
        case SceneStatus.done:
          done++;
      }
    }
    return ProductionMetrics(
      total: scenes.length,
      todo: todo,
      inProgress: inProgress,
      done: done,
    );
  }
}

SceneStatus effectiveShootingStatus(
  Scene scene,
  Map<int, String> shootingStatuses,
) {
  final sceneId = scene.id;
  if (sceneId == null || scene.status != SceneStatus.done) {
    return SceneStatus.todo;
  }
  return SceneStatusExt.fromDb(shootingStatuses[sceneId] ?? 'TODO');
}
