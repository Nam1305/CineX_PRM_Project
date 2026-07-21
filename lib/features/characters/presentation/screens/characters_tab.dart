import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import '../widgets/cinematic_character_card.dart';
import 'character_form_screen.dart';
import 'character_detail_screen.dart';

import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/shared/widgets/pagination_bar.dart';

class CharactersTab extends StatefulWidget {
  final int projectId;
  const CharactersTab({super.key, required this.projectId});

  @override
  State<CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends State<CharactersTab> {
  RoleType? _selectedRole;
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 5;
  Map<int, int> _characterSceneCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterProvider>().loadCharacters(widget.projectId);
      _loadSceneCounts();
    });
  }

  Future<void> _loadSceneCounts() async {
    try {
      final scenes = await ApiService().getScenesForProject(widget.projectId);
      final Map<int, int> counts = {};
      for (final scene in scenes) {
        for (final char in scene.characters) {
          if (char.id != null) {
            counts[char.id!] = (counts[char.id!] ?? 0) + 1;
          }
        }
      }
      if (mounted) {
        setState(() {
          _characterSceneCounts = counts;
        });
      }
    } catch (_) {}
  }

  List<dynamic> _getFilteredCharacters(List<dynamic> characters) {
    var list = characters;
    if (_selectedRole != null) {
      list = list.where((c) => c.roleType == _selectedRole).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWritable = auth.isScreenwriter;

    return Scaffold(
      body: Consumer<CharacterProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.characters.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.person_outline,
              message: isWritable
                  ? 'Chưa có nhân vật nào.\nBấm nút + để thêm nhân vật đầu tiên.'
                  : 'Chưa có nhân vật nào trong hệ thống.',
              actionLabel: isWritable ? 'Thêm nhân vật' : null,
              onAction: isWritable ? () => _openForm(context) : null,
            );
          }

          final filtered = _getFilteredCharacters(provider.characters);

          // Phân trang
          final totalItems = filtered.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();

          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          }

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage > totalItems ? totalItems : startIndex + _itemsPerPage;
          final paginated = filtered.sublist(startIndex, endIndex);

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2C2C2C)),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value.trim();
                                    _currentPage = 1;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Tìm kiếm nhân vật...',
                                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(
                                    label: 'TẤT CẢ',
                                    isSelected: _selectedRole == null,
                                    onPressed: () =>
                                        setState(() {
                                          _selectedRole = null;
                                          _currentPage = 1;
                                        }),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'MAIN',
                                    isSelected: _selectedRole == RoleType.main,
                                    onPressed: () =>
                                        setState(() {
                                          _selectedRole = RoleType.main;
                                          _currentPage = 1;
                                        }),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'SUPPORT',
                                    isSelected: _selectedRole == RoleType.support,
                                    onPressed: () =>
                                        setState(() {
                                          _selectedRole = RoleType.support;
                                          _currentPage = 1;
                                        }),
                                  ),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                    label: 'CROWD',
                                    isSelected: _selectedRole == RoleType.crowd,
                                    onPressed: () =>
                                        setState(() {
                                          _selectedRole = RoleType.crowd;
                                          _currentPage = 1;
                                        }),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final char = paginated[i];
                            final sceneCount = _characterSceneCounts[char.id] ?? 0;
                            final status = char.castingStatus ?? 'Đang tuyển';
                            final isGreen = status == 'Đã duyệt' || status == 'APPROVED' || status == 'Approved';

                            return CinematicCharacterCard(
                              character: char,
                              sceneCount: sceneCount,
                              status: status,
                              statusGreen: isGreen,
                              isWritable: isWritable,
                              onTap: () => _openDetail(context, char),
                              onEdit: () => _openForm(context, character: char),
                              onDelete: () async {
                                final ok = await context
                                    .read<CharacterProvider>()
                                    .removeCharacter(char.id!);
                                if (ok && context.mounted) {
                                  context.read<NotificationProvider>().addNotification(
                                        projectId: widget.projectId,
                                        projectTitle: 'Dự án CineX #${widget.projectId}',
                                        title: 'Xóa nhân vật: ${char.name}',
                                        body: 'Nhân vật "${char.name}" (${char.roleType.label}) đã bị xóa khỏi dự án.',
                                        actionType: NotificationActionType.delete,
                                      );
                                  AppSnackbar.success(context, 'Đã xóa nhân vật thành công');
                                  _loadSceneCounts();
                                }
                              },
                            );
                          },
                          childCount: paginated.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                totalItems: totalItems,
                itemsPerPage: _itemsPerPage,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: isWritable
          ? FloatingActionButton(
              heroTag: 'add_character_fab',
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _openForm(BuildContext context, {Character? character}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterFormScreen(
          projectId: widget.projectId,
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
