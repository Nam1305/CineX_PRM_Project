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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Character Filter
            Expanded(
              child: _buildFilterDropdown(
                label: 'NHÂN VẬT',
                value: provider.filterCharacterId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả nhân vật')),
                  ...characters.map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => provider.setFilter(
                  characterId: v,
                  timeOfDay: provider.filterTimeOfDay,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Time filter
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
            fontFamily: 'JetBrains Mono',
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
