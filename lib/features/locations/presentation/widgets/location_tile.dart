import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';

class LocationTile extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LocationTile({
    super.key,
    required this.location,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          location.timeOfDay == SceneTime.day
              ? Icons.wb_sunny
              : Icons.nightlight_round,
          color: location.timeOfDay == SceneTime.day
              ? Colors.amber
              : Colors.indigo.shade200,
        ),
      ),
      title: Text(location.name),
      subtitle: Text(location.sceneLabel,
          style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(location.setting.fullLabel,
                style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'Xoá bối cảnh',
                content: 'Xoá "${location.name}"? Các cảnh liên kết sẽ mất bối cảnh.',
              );
              if (confirmed) onDelete();
            },
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
