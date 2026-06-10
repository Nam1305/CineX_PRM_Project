import 'package:flutter/material.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/core/utils/enums.dart';

class CharacterDetailScreen extends StatelessWidget {
  final Character character;

  const CharacterDetailScreen({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleLabel = character.roleType.label;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  character.roleType.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: const Text(
                                  'ID: #001',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(color: Color(0xFF393939)),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${character.name} ($roleLabel)',
                            style: theme.textTheme.headlineLarge,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ImageNotesSection(theme: theme),
                const SizedBox(height: 24),
                _PsychologySection(character: character, theme: theme),
                const SizedBox(height: 24),
                _SceneListSection(theme: theme),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(activeIndex: 1),
    );
  }
}

class _ImageNotesSection extends StatelessWidget {
  final ThemeData theme;

  const _ImageNotesSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    final notes = [
      'Trang phục công sở màu tối',
      'Đồng hồ cổ điển',
      'Túi hồ sơ màu đen',
      'Tóc vuốt gọn',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GHI CHÚ ẢNH',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...notes.map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _PsychologySection extends StatelessWidget {
  final Character character;
  final ThemeData theme;

  const _PsychologySection({
    required this.character,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TÂM LÝ NHÂN VẬT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              character.description ?? 'Không có mô tả',
              style: theme.textTheme.bodyMedium,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'Nhân vật này có nền tảng gia đình khó khăn, nhưng quyết tâm vươn lên. Sợ thất bại và bị lừa dối. Mục tiêu là kiếm sống ổn định và bảo vệ gia đình.',
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneListSection extends StatelessWidget {
  final ThemeData theme;

  const _SceneListSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    final scenes = [
      {'number': '01', 'title': 'Gặp gỡ đầu tiên', 'tags': ['INT', 'DAY']},
      {'number': '03', 'title': 'Cuộc gặp bí mật', 'tags': ['INT', 'NIGHT']},
      {'number': '05', 'title': 'Xung đột', 'tags': ['EXT', 'NIGHT']},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DANH SÁCH CẢNH QUAY (8)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Xem tất cả',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: scenes.length,
            itemBuilder: (context, index) {
              final scene = scenes[index];
              return Padding(
                padding: EdgeInsets.only(right: index < scenes.length - 1 ? 12 : 0),
                child: SizedBox(
                  width: 140,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cảnh ${scene['number']}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scene['title'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            children: (scene['tags'] as List<String>).map((tag) {
                              return Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 9),
                                ),
                                padding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int activeIndex;

  const _BottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: activeIndex,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Nhân vật',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          selectedIcon: Icon(Icons.location_on),
          label: 'Bối cảnh',
        ),
        NavigationDestination(
          icon: Icon(Icons.movie_filter_outlined),
          selectedIcon: Icon(Icons.movie_filter),
          label: 'Storyboard',
        ),
      ],
    );
  }
}
