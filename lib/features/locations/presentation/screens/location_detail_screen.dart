import 'package:flutter/material.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/core/widgets/section_card.dart';

class LocationDetailScreen extends StatelessWidget {
  final Location location;

  const LocationDetailScreen({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  children: [
                    _TagChip(label: location.setting.label),
                    _TagChip(label: location.timeOfDay.label),
                  ],
                ),
                const SizedBox(height: 24),

                // Technical Info
                SectionCard(
                  title: 'Thông Tin Kỹ Thuật',
                  child: Column(
                    children: [
                      _TechInfoItem(
                        icon: Icons.lightbulb_outline,
                        label: 'Ánh sáng',
                        value: location.timeOfDay.label,
                      ),
                      const SizedBox(height: 12),
                      _TechInfoItem(
                        icon: Icons.volume_up,
                        label: 'Âm thanh',
                        value: 'Yên tĩnh',
                      ),
                      const SizedBox(height: 12),
                      _TechInfoItem(
                        icon: Icons.power_outlined,
                        label: 'Điện',
                        value: 'Có',
                      ),
                      const SizedBox(height: 12),
                      _TechInfoItem(
                        icon: Icons.straighten,
                        label: 'Không gian',
                        value: 'Rộng',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                if (location.notes != null)
                  SectionCard(
                    title: 'Ghi Chú',
                    child: Text(
                      location.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 16),

                // Associated Scenes
                SectionCard(
                  title: 'Các Cảnh Liên Quan',
                  child: Column(
                    children: [
                      _SceneItem(
                        sceneNumber: '01',
                        title: 'Gặp gỡ đầu tiên',
                        duration: '3:45',
                        pages: 5,
                      ),
                      const SizedBox(height: 12),
                      _SceneItem(
                        sceneNumber: '03',
                        title: 'Cuộc gặp bí mật',
                        duration: '2:15',
                        pages: 3,
                      ),
                      const SizedBox(height: 12),
                      _SceneItem(
                        sceneNumber: '05',
                        title: 'Xung đột cao trào',
                        duration: '5:30',
                        pages: 7,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Management Info
                SectionCard(
                  title: 'Thông Tin Quản Lý',
                  child: Column(
                    children: [
                      _ManagementItem(
                        label: 'Người liên hệ',
                        value: 'Nguyễn Văn A',
                      ),
                      const SizedBox(height: 12),
                      _ManagementItem(
                        label: 'Điện thoại',
                        value: '0123 456 789',
                      ),
                      const SizedBox(height: 12),
                      _ManagementItem(
                        label: 'Chi phí thuê',
                        value: '5.000.000 VNĐ',
                      ),
                      const SizedBox(height: 12),
                      _ManagementItem(
                        label: 'Tình trạng',
                        value: 'Sẵn sàng',
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
  final String duration;
  final int pages;

  const _SceneItem({
    required this.sceneNumber,
    required this.title,
    required this.duration,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              sceneNumber,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(height: 4),
              Text(
                '$duration • $pages trang',
                style: theme.textTheme.labelSmall,
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
