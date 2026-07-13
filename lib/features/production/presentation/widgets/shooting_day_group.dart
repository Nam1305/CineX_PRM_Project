import 'package:flutter/material.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/utils/enums.dart';

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
    if (scenes.isEmpty) return const SizedBox.shrink();
    
    // Guess setting and time from the first scene in group if available
    final firstLoc = scenes.first.location;
    final settingStr = (firstLoc?.setting.toString() == LocationSetting.interior.toString() || firstLoc?.setting.toString() == 'LocationSetting.interior' || firstLoc?.setting.toString() == 'INT') ? 'Nội (INT)' : 'Ngoại (EXT)';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // slate-surface
        border: Border.all(color: const Color(0xFF2C2C2C)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A), // surface-container-high
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFF2C2C2C))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFF571A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  settingStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE6BEB2),
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
          ),
          
          // Scenes List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scenes.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFF2C2C2C), height: 1),
            itemBuilder: (context, index) {
              final s = scenes[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scene Number Left
                    Container(
                      width: 60,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFF2C2C2C))),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'CẢNH',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.sceneNumber.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF571A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Scene Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  s.summary ?? 'Chưa có tiêu đề',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.status == SceneStatus.done
                                      ? Colors.green.withAlpha(25)
                                      : (s.status == SceneStatus.inProgress
                                          ? Colors.amber.withAlpha(25)
                                          : Colors.grey.withAlpha(25)),
                                  border: Border.all(
                                    color: s.status == SceneStatus.done
                                        ? Colors.green.withAlpha(51)
                                        : (s.status == SceneStatus.inProgress
                                            ? Colors.amber.withAlpha(51)
                                            : Colors.grey.withAlpha(51)),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.status.dbValue,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: s.status == SceneStatus.done
                                        ? Colors.green
                                        : (s.status == SceneStatus.inProgress
                                            ? Colors.amber
                                            : Colors.grey),
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (s.characters.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.groups, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s.characters.map((e) => e.name).join(', '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
