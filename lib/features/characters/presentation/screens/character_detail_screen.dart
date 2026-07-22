import 'package:flutter/material.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
import 'package:cinex_application/core/storage/local_cache_service.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

class CharacterDetailScreen extends StatefulWidget {
  final Character character;

  const CharacterDetailScreen({super.key, required this.character});

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  final _api = ApiService();
  List<Scene> _scenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacterScenes();
  }

  Future<void> _loadCharacterScenes() async {
    final projectId = widget.character.projectId;
    if (projectId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    List<Scene> cachedScenes = [];
    try {
      cachedScenes = await LocalCacheService.instance.getScenesForProject(
        projectId,
      );
      if (cachedScenes.isNotEmpty && mounted) {
        setState(() {
          _scenes = _filterCharacterScenes(cachedScenes);
          _isLoading = false;
        });
      }
    } catch (_) {}

    try {
      final serverScenes = await _api.getScenesForProject(projectId);
      try {
        await LocalCacheService.instance.replaceScenesForProject(
          projectId,
          serverScenes,
        );
      } catch (_) {}
      if (mounted) {
        setState(() {
          _scenes = _filterCharacterScenes(serverScenes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('CharacterDetailScreen._loadCharacterScenes error: $e');
      if (mounted) {
        setState(() {
          _scenes = _filterCharacterScenes(cachedScenes);
          _isLoading = false;
        });
      }
    }
  }

  List<Scene> _filterCharacterScenes(List<Scene> scenes) {
    final characterId = widget.character.id;
    final characterName = widget.character.name.trim().toLowerCase();
    return scenes.where((scene) {
      return scene.characters.any(
        (character) =>
            (characterId != null && character.id == characterId) ||
            character.name.trim().toLowerCase() == characterName,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final character = widget.character;
    final roleLabel = character.roleType.label;
    final charIdStr = character.id != null
        ? '#${character.id.toString().padLeft(3, '0')}'
        : '#001';

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
                  character.imagePath != null && character.imagePath!.isNotEmpty
                      ? AdaptiveImage(
                          source: character.imagePath!,
                          placeholderBuilder: (_) => Container(
                            color: theme.colorScheme.surface,
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 120,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surface,
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 120,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
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
                                  roleLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  'ID: $charIdStr',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color: theme.colorScheme.outline,
                                ),
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
                _ImageNotesSection(character: character, theme: theme),
                const SizedBox(height: 24),
                _PsychologySection(character: character, theme: theme),
                const SizedBox(height: 24),
                _SceneListSection(
                  scenes: _scenes,
                  isLoading: _isLoading,
                  theme: theme,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageNotesSection extends StatelessWidget {
  final Character character;
  final ThemeData theme;

  const _ImageNotesSection({required this.character, required this.theme});

  @override
  Widget build(BuildContext context) {
    final notes = [
      'Thủ vai: ${character.actorName ?? 'Chưa phân công diễn viên'}',
      'Trạng thái tuyển chọn: ${character.castingStatus ?? 'Chờ xét duyệt'}',
      'Phân loại vai diễn: ${character.roleType.label}',
      'Tạo hình: Phù hợp kịch bản sản xuất',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THÔNG TIN & GHI CHÚ NHÂN VẬT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...notes.map(
              (note) => Padding(
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
                      child: Text(note, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PsychologySection extends StatelessWidget {
  final Character character;
  final ThemeData theme;

  const _PsychologySection({required this.character, required this.theme});

  @override
  Widget build(BuildContext context) {
    final desc = character.description;
    final hasDesc = desc != null && desc.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TÂM LÝ & MÔ TẢ NHÂN VẬT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasDesc
                  ? desc
                  : 'Chưa có mô tả tâm lý chi tiết cho nhân vật này.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneListSection extends StatelessWidget {
  final List<Scene> scenes;
  final bool isLoading;
  final ThemeData theme;

  const _SceneListSection({
    required this.scenes,
    required this.isLoading,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DANH SÁCH CẢNH QUAY (${scenes.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (scenes.isNotEmpty)
              Text(
                'Tổng số: ${scenes.length} cảnh',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (scenes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.appColors.surfaceElevated),
            ),
            child: Text(
              'Chưa có cảnh quay nào phân công cho nhân vật này.',
              style: TextStyle(
                color: context.appColors.textFaint,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: scenes.length,
              itemBuilder: (context, index) {
                final scene = scenes[index];
                final sceneNum = scene.sceneNumber.toString().padLeft(2, '0');
                final settingLabel = scene.location?.setting.label ?? 'INT';
                final timeLabel = scene.location?.timeOfDay.label ?? 'DAY';

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < scenes.length - 1 ? 12 : 0,
                  ),
                  child: SizedBox(
                    width: 160,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cảnh $sceneNum',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              scene.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _buildTag(settingLabel, theme),
                                _buildTag(timeLabel, theme),
                              ],
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

  Widget _buildTag(String tag, ThemeData theme) {
    final isInt = tag.toUpperCase() == 'INT' || tag.toUpperCase() == 'NỘI';
    final isExt = tag.toUpperCase() == 'EXT' || tag.toUpperCase() == 'NGOẠI';
    final appColors = theme.extension<AppColors>()!;
    final statusColor = isInt
        ? appColors.info
        : (isExt ? appColors.warning : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor?.withValues(alpha: 0.3) ?? appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: statusColor ?? theme.colorScheme.outline,
          width: 0.5,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: statusColor ?? appColors.textMuted,
        ),
      ),
    );
  }
}
