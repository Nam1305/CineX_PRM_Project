import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/core/widgets/app_header.dart';
import 'package:cinex_application/core/widgets/status_badge.dart';
import 'package:cinex_application/core/widgets/image_card.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'add_location_screen.dart';
import 'location_detail_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  LocationSetting? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filter == null
              ? provider.locations
              : provider.locations
                  .where((l) => l.setting == _filter)
                  .toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeader(
                  title: 'Bối cảnh',
                  onSearch: () {},
                  onNotification: () {},
                ),
              ),
              // Search & Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bối cảnh...',
                          prefixIcon: const Icon(Icons.search_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Tất cả',
                              isSelected: _filter == null,
                              onTap: () => setState(() => _filter = null),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'INT',
                              isSelected: _filter == LocationSetting.interior,
                              onTap: () =>
                                  setState(() => _filter = LocationSetting.interior),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'EXT',
                              isSelected: _filter == LocationSetting.exterior,
                              onTap: () =>
                                  setState(() => _filter = LocationSetting.exterior),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Location List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final location = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LocationCard(
                        location: location,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LocationDetailScreen(location: location),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLocationScreen()),
          );
        },
        child: const Icon(Icons.add_location_outlined),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
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

class _LocationCard extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ImageCard(
                  imageUrl:
                      'https://via.placeholder.com/400x300/1C1B1B/FF4D00?text=${location.name}',
                  onTap: onTap,
                  height: 180,
                  heroTag: 'location_${location.id}',
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      _TagBadge(
                        label: location.setting.label,
                      ),
                      const SizedBox(width: 8),
                      _TagBadge(
                        label: location.timeOfDay.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.notes ?? 'Không có ghi chú',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '8 cảnh',
                        style: theme.textTheme.labelSmall,
                      ),
                      StatusBadge(
                        status: StatusType.approved,
                        label: 'ĐÃ XÁC NHẬN',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;

  const _TagBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
