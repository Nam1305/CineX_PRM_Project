import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';

class SceneFilterBar extends StatefulWidget {
  final int projectId;
  final ProductionProvider provider;

  const SceneFilterBar({
    super.key,
    required this.projectId,
    required this.provider,
  });

  @override
  State<SceneFilterBar> createState() => _SceneFilterBarState();
}

class _SceneFilterBarState extends State<SceneFilterBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CharacterProvider>().loadCharacters(widget.projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final provider = widget.provider;

    // Tổng hợp danh sách nhân vật từ cả CharacterProvider và các cảnh hiện tại
    final charMap = <int, Character>{};
    for (final c in characterProvider.characters) {
      if (c.id != null) charMap[c.id!] = c;
    }
    for (final scene in provider.allScenes) {
      for (final c in scene.characters) {
        if (c.id != null) {
          charMap.putIfAbsent(c.id!, () => c);
        }
      }
    }

    final availableCharacters = charMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    int? effectiveCharId;
    if (provider.filterCharacterId != null &&
        availableCharacters.any((c) => c.id == provider.filterCharacterId)) {
      effectiveCharId = provider.filterCharacterId;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Bộ lọc Nhân vật
            Expanded(
              child: _buildFilterDropdown(
                label: 'NHÂN VẬT',
                value: effectiveCharId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả nhân vật')),
                  ...availableCharacters.map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => provider.setFilter(
                  characterId: v,
                  timeOfDay: provider.filterTimeOfDay,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Bộ lọc Thời gian
            Expanded(
              child: _buildFilterDropdown(
                label: 'THỜI GIAN',
                value: provider.filterTimeOfDay,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Mọi lúc')),
                  ...SceneTime.values.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.fullLabel))),
                ],
                onChanged: (v) => provider.setFilter(
                  characterId: provider.filterCharacterId,
                  timeOfDay: v,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CHẾ ĐỘ GOM NHÓM',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ProductionGroupMode>(
                segments: const [
                  ButtonSegment<ProductionGroupMode>(
                    value: ProductionGroupMode.byLocation,
                    label: Text('Gom theo Bối cảnh'),
                    icon: Icon(Icons.location_on_outlined),
                  ),
                  ButtonSegment<ProductionGroupMode>(
                    value: ProductionGroupMode.byCharacter,
                    label: Text('Gom theo Nhân vật'),
                    icon: Icon(Icons.person_outline),
                  ),
                ],
                selected: {provider.groupMode},
                onSelectionChanged: (Set<ProductionGroupMode> selection) {
                  provider.setGroupMode(selection.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        if (provider.filterCharacterId != null || provider.filterTimeOfDay != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              label: const Text(
                'Xóa bộ lọc',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required void Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: Border.all(color: const Color(0xFF2C2C2C)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              isExpanded: true,
              value: value,
              dropdownColor: const Color(0xFF1E1E1E),
              icon: const Icon(Icons.expand_more, color: Colors.grey),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
