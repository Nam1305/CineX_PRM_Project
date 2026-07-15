import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';

class LocationTile extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isWritable;

  const LocationTile({
    super.key,
    required this.location,
    required this.onTap,
    required this.onDelete,
    this.isWritable = true,
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
            label: Text(
              location.setting.fullLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: location.setting == LocationSetting.interior
                    ? Colors.blue.shade200
                    : Colors.orange.shade200,
              ),
            ),
            backgroundColor: location.setting == LocationSetting.interior
                ? Colors.blue.shade900.withValues(alpha: 0.3)
                : Colors.orange.shade900.withValues(alpha: 0.3),
            side: BorderSide(
              color: location.setting == LocationSetting.interior
                  ? Colors.blue.shade700
                  : Colors.orange.shade700,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          if (isWritable)
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
      onTap: isWritable ? onTap : null,
    );
  }
}
