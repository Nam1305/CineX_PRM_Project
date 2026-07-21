import 'package:flutter/material.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';

import 'package:cinex_application/core/utils/enums.dart';

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
    final isDay = location.timeOfDay == SceneTime.day;
    final isInterior = location.setting == LocationSetting.interior;

    final icon = isDay ? Icons.wb_sunny : Icons.nightlight_round;
    final iconColor = isDay ? Colors.amber : Colors.indigoAccent;
    final avatarBg = iconColor.withValues(alpha: 0.2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarBg,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                location.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isInterior ? Colors.blue.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isInterior ? Colors.blue.shade400 : Colors.orange.shade400,
                  width: 0.8,
                ),
              ),
              child: Text(
                '${location.setting.label} · ${location.timeOfDay.label}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isInterior ? Colors.blue.shade200 : Colors.orange.shade200,
                ),
              ),
            ),
          ],
        ),
        subtitle: (location.notes != null && location.notes!.isNotEmpty)
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Ghi chú đạo cụ: ${location.notes!}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: isWritable
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: onDelete,
              )
            : null,
        onTap: isWritable ? onTap : null,
      ),
    );
  }
}
