import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import '../widgets/int_ext_pie_chart.dart';
import '../widgets/character_frequency_chart.dart';
import '../widgets/scene_filter_bar.dart';
import '../widgets/shooting_day_group.dart';

class ProductionTab extends StatefulWidget {
  final int projectId;
  const ProductionTab({super.key, required this.projectId});

  @override
  State<ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<ProductionTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().loadForProject(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: IntExtPieChart(scenes: provider.allScenes)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CharacterFrequencyChart(scenes: provider.allScenes),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SceneFilterBar(
                projectId: widget.projectId,
                provider: provider,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry =
                        provider.groupedByLocation.entries.elementAt(i);
                    return ShootingDayGroup(
                      locationLabel: entry.key,
                      scenes: entry.value,
                    );
                  },
                  childCount: provider.groupedByLocation.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
