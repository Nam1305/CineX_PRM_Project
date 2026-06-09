import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';

class SceneFilterBar extends StatelessWidget {
  final int projectId;
  final ProductionProvider provider;

  const SceneFilterBar({
    super.key,
    required this.projectId,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final characters = context.watch<CharacterProvider>().characters;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          // Time filter
          ...SceneTime.values.map((t) => FilterChip(
                label: Text(t.fullLabel),
                selected: provider.filterTimeOfDay == t,
                onSelected: (v) => provider.setFilter(
                  characterId: provider.filterCharacterId,
                  timeOfDay: v ? t : null,
                ),
              )),
          // Character filter
          DropdownButton<int?>(
            hint: const Text('Nhân vật'),
            value: provider.filterCharacterId,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả')),
              ...characters.map((c) =>
                  DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            onChanged: (v) => provider.setFilter(
              characterId: v,
              timeOfDay: provider.filterTimeOfDay,
            ),
          ),
          if (provider.filterCharacterId != null || provider.filterTimeOfDay != null)
            ActionChip(
              label: const Text('Xóa bộ lọc'),
              avatar: const Icon(Icons.close, size: 16),
              onPressed: provider.clearFilters,
            ),
        ],
      ),
    );
  }
}
