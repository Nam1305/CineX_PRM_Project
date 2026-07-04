import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import 'package:cinex_application/data/mock_data.dart';
import '../widgets/cinematic_character_card.dart';
import 'character_form_screen.dart';
import 'character_detail_screen.dart';

class CharactersTab extends StatefulWidget {
  const CharactersTab({super.key});

  @override
  State<CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends State<CharactersTab> {
  RoleType? _selectedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterProvider>().loadCharacters();
    });
  }

  List<dynamic> _getFilteredCharacters(List<dynamic> characters) {
    if (_selectedRole == null) return characters;
    return characters.where((c) => c.roleType == _selectedRole).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineX Production'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<CharacterProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.characters.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.person_outline,
              message: 'Chưa có nhân vật nào.\nBấm nút + để thêm nhân vật đầu tiên.',
            );
          }

          final filtered = _getFilteredCharacters(provider.characters);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'TẤT CẢ',
                          isSelected: _selectedRole == null,
                          onPressed: () =>
                              setState(() => _selectedRole = null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'MAIN',
                          isSelected: _selectedRole == RoleType.main,
                          onPressed: () =>
                              setState(() => _selectedRole = RoleType.main),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'SUPPORT',
                          isSelected: _selectedRole == RoleType.support,
                          onPressed: () =>
                              setState(() => _selectedRole = RoleType.support),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'CROWD',
                          isSelected: _selectedRole == RoleType.crowd,
                          onPressed: () =>
                              setState(() => _selectedRole = RoleType.crowd),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final char = filtered[i];
                      final sceneCount = MockData.characterSceneCount[char.id] ?? 0;
                      final status = MockData.characterStatus[char.id] ?? '';
                      final isGreen = MockData.characterStatusGreen[char.id] ?? false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CinematicCharacterCard(
                          character: char,
                          sceneCount: sceneCount,
                          status: status,
                          statusGreen: isGreen,
                          onTap: () => _openDetail(context, char),
                          onEdit: () => _openForm(context, character: char),
                          onDelete: () async {
                            await context
                                .read<CharacterProvider>()
                                .removeCharacter(char.id!);
                          },
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_character_fab',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {character}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterFormScreen(
          character: character,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterDetailScreen(character: character),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : const Color(0xFF393939),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
