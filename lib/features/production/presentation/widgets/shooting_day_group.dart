import 'package:flutter/material.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';

class ShootingDayGroup extends StatelessWidget {
  final String locationLabel;
  final List<Scene> scenes;

  const ShootingDayGroup({
    super.key,
    required this.locationLabel,
    required this.scenes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(locationLabel,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary)),
        subtitle: Text('${scenes.length} cảnh'),
        children: scenes
            .map((s) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                      radius: 14,
                      child: Text('${s.sceneNumber}',
                          style: const TextStyle(fontSize: 11))),
                  title: Text(s.summary ?? '(Chưa có tóm tắt)',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      s.characters.map((c) => c.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
      ),
    );
  }
}
