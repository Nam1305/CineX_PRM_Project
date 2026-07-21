import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/core/widgets/section_card.dart';
import 'package:cinex_application/data/mock_data.dart';

class LocationDetailScreen extends StatefulWidget {
  final Location location;

  const LocationDetailScreen({
    super.key,
    required this.location,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final _api = ApiService();
  List<Scene> _scenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationScenes();
  }

  Future<void> _loadLocationScenes() async {
    final projId = widget.location.projectId ?? 1;
    try {
      final allScenes = await _api.getScenesForProject(projId);
      final locId = widget.location.id;

      final filtered = allScenes.where((s) => s.locationId == locId || (locId != null && s.location?.id == locId)).toList();

      if (mounted) {
        setState(() {
          _scenes = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('LocationDetailScreen._loadLocationScenes error: $e');
      final locId = widget.location.id;
      final mockFiltered = MockData.mockScenes.where((s) => s.locationId == locId || (locId != null && s.location?.id == locId)).toList();
      if (mounted) {
        setState(() {
          _scenes = mockFiltered;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = widget.location;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ImageCard(
                imageUrl:
                    'https://placehold.co/400x300/1C1B1B/FF4D00?text=${Uri.encodeComponent(location.name)}',
                onTap: () {},
                heroTag: 'location_${location.id}',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                Text(
                  location.name,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),

                // Quick Tags
                Wrap(
                  spacing: 8,
                  children: const [
                    _TagChip(label: 'Bối cảnh địa lý'),
                  ],
                ),
                const SizedBox(height: 24),

                // Technical Info
                SectionCard(
                  title: 'Thông Tin Kỹ Thuật',
                  child: Column(
                    children: [
                      _TechInfoItem(
                        icon: Icons.place_outlined,
                        label: 'Tên bối cảnh',
                        value: location.name,
                      ),
                      const SizedBox(height: 12),
                      _TechInfoItem(
                        icon: Icons.straighten,
                        label: 'Vị trí & Thời gian quay',
                        value: '${location.setting.fullLabel} - ${location.timeOfDay.fullLabel}',
                      ),
                      const SizedBox(height: 12),
                      _TechInfoItem(
                        icon: Icons.volume_up,
                        label: 'Âm thanh',
                        value: 'Yên tĩnh',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                if (location.notes != null && location.notes!.isNotEmpty) ...[
                  SectionCard(
                    title: 'Ghi Chú Bối Cảnh',
                    child: Text(
                      location.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Associated Scenes
                SectionCard(
                  title: 'Các Cảnh Liên Quan (${_scenes.length})',
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _scenes.isEmpty
                          ? const Text(
                              'Chưa có cảnh quay nào đăng ký tại bối cảnh này.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            )
                          : Column(
                              children: _scenes.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final scene = entry.value;
                                final sceneNum = scene.sceneNumber.toString().padLeft(2, '0');
                                final charCount = scene.characters.length;

                                return Column(
                                  children: [
                                    if (idx > 0) const SizedBox(height: 12),
                                    _SceneItem(
                                      sceneNumber: sceneNum,
                                      title: scene.title,
                                      summary: scene.summary ?? 'Chưa có tóm tắt cảnh',
                                      charCount: charCount,
                                      statusLabel: scene.status.label,
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                ),
                const SizedBox(height: 16),

                // Management Info
                SectionCard(
                  title: 'Thông Tin Quản Lý',
                  child: Column(
                    children: [
                      _ManagementItem(
                        label: 'Tên bối cảnh',
                        value: location.name,
                      ),
                      const SizedBox(height: 12),
                      const _ManagementItem(
                        label: 'Tình trạng',
                        value: 'Sẵn sàng ghi hình',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TechInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall,
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SceneItem extends StatelessWidget {
  final String sceneNumber;
  final String title;
  final String summary;
  final int charCount;
  final String statusLabel;

  const _SceneItem({
    required this.sceneNumber,
    required this.title,
    required this.summary,
    required this.charCount,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 44,
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              sceneNumber,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cảnh $sceneNumber: $title',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$summary • $charCount nhân vật • $statusLabel',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagementItem extends StatelessWidget {
  final String label;
  final String value;

  const _ManagementItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
