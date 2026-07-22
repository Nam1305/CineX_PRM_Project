import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'production_schedule_view.dart';
import 'production_analytics_view.dart';

class ProductionTab extends StatefulWidget {
  final int projectId;
  final int initialTab;
  final String? projectStartDate;
  final String? projectEndDate;

  const ProductionTab({
    super.key,
    required this.projectId,
    this.initialTab = 0,
    this.projectStartDate,
    this.projectEndDate,
  });

  @override
  State<ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<ProductionTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductionProvider>().loadForProject(
        widget.projectId,
        canMigrateLegacy: context.read<AuthProvider>().isProducer,
      );
      context.read<CharacterProvider>().loadCharacters(widget.projectId);
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
                    child: CircularProgressIndicator(color: Color(0xFFFF571A)),
                  );
                }
                // Luôn hiển thị TabBarView, empty state nằm trong từng view
                return TabBarView(
                  children: [
                    ProductionScheduleView(
                      provider: provider,
                      projectId: widget.projectId,
                      projectStartDate: widget.projectStartDate,
                      projectEndDate: widget.projectEndDate,
                    ),
                    ProductionAnalyticsView(
                      provider: provider,
                      projectId: widget.projectId,
                      projectStartDate: widget.projectStartDate,
                      projectEndDate: widget.projectEndDate,
                    ),
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
