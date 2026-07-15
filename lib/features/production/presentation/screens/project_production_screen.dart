import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/production/providers/production_provider.dart';
import 'package:cinex_application/features/production/presentation/screens/production_tab.dart';

/// Màn hình full-screen bọc ProductionTab để dùng từ nút trong ProjectDetailScreen
class ProjectProductionScreen extends StatelessWidget {
  final int projectId;
  final String projectTitle;
  final String? projectStartDate;
  final String? projectEndDate;
  final int initialTab; // 0 = Lịch Quay, 1 = Thống kê / Phân tích

  const ProjectProductionScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    this.projectStartDate,
    this.projectEndDate,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductionProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(projectTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ProductionTab(
          projectId: projectId,
          initialTab: initialTab,
          projectStartDate: projectStartDate,
          projectEndDate: projectEndDate,
        ),
      ),
    );
  }
}
