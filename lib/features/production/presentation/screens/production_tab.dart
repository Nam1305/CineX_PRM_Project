import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'production_schedule_view.dart';
import 'production_analytics_view.dart';

class ProductionTab extends StatefulWidget {
  final int projectId;
  final int initialTab;

  const ProductionTab({
    super.key,
    required this.projectId,
    this.initialTab = 0,
  });

  @override
  State<ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<ProductionTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().loadForProject(widget.projectId);
      context.read<CharacterProvider>().loadCharacters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              indicatorColor: Color(0xFFFF571A),
              labelColor: Color(0xFFFF571A),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'LỊCH QUAY'),
                Tab(text: 'THỐNG KÊ'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ProductionProvider>(
              builder: (context, provider, _) {
                // Hiển thị loading indicator toàn màn hình chỉ khi lần đầu load
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF571A),
                    ),
                  );
                }
                // Luôn hiển thị TabBarView, empty state nằm trong từng view
                return TabBarView(
                  children: [
                    ProductionScheduleView(
                      provider: provider,
                      projectId: widget.projectId,
                    ),
                    ProductionAnalyticsView(provider: provider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
