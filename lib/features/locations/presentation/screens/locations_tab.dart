import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/services/api_service.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/shared/widgets/confirm_dialog.dart';
import '../widgets/location_tile.dart';
import 'location_form_screen.dart';

import 'package:cinex_application/features/auth/providers/auth_provider.dart';
import 'package:cinex_application/shared/widgets/pagination_bar.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/theme/app_colors.dart';

class LocationsTab extends StatefulWidget {
  final int projectId;
  const LocationsTab({super.key, required this.projectId});

  @override
  State<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<LocationsTab> {
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWritable = auth.isScreenwriter;

    return Scaffold(
      body: Consumer<LocationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.locations.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.location_off_outlined,
              message: isWritable
                  ? 'Chưa có bối cảnh nào.\nBấm nút + để thêm bối cảnh đầu tiên.'
                  : 'Chưa có bối cảnh nào trong hệ thống.',
              actionLabel: isWritable ? 'Thêm bối cảnh' : null,
              onAction: isWritable ? () => _openForm(context) : null,
            );
          }

          // Phân trang
          final totalItems = provider.locations.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();

          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          }

          final startIndex = (_currentPage - 1) * _itemsPerPage;
          final endIndex = startIndex + _itemsPerPage > totalItems
              ? totalItems
              : startIndex + _itemsPerPage;
          final paginatedLocations = provider.locations.sublist(
            startIndex,
            endIndex,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: paginatedLocations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final loc = paginatedLocations[i];
                    return LocationTile(
                      location: loc,
                      isWritable: isWritable,
                      onTap: () => _openForm(context, location: loc),
                      onDelete: () async {
                        final scenes = await ApiService().getScenesForProject(
                          widget.projectId,
                        );
                        final linkedScenes = scenes
                            .where((s) => s.locationId == loc.id)
                            .toList();
                        if (!context.mounted) return;

                        if (linkedScenes.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              final dialogTheme = Theme.of(dialogContext);
                              return AlertDialog(
                                backgroundColor: dialogTheme.colorScheme.surface,
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: dialogContext.appColors.danger,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Không thể xóa bối cảnh',
                                      style: TextStyle(
                                        color: dialogTheme.colorScheme.onSurface,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  'Bối cảnh "${loc.name}" đang được sử dụng trong ${linkedScenes.length} phân cảnh kịch bản.\n\nBạn vui lòng thay đổi bối cảnh hoặc xóa các phân cảnh liên quan trước khi xóa bối cảnh địa lý này.',
                                  style: TextStyle(
                                    color: dialogContext.appColors.textFaint,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: Text(
                                      'Đóng',
                                      style: TextStyle(
                                        color: dialogTheme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          return;
                        }

                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Xoá bối cảnh',
                          content: 'Xoá bối cảnh "${loc.name}"?',
                        );
                        if (confirmed) {
                          final ok = await provider.removeLocation(loc.id!);
                          if (ok && context.mounted) {
                            context.read<NotificationProvider>().addNotification(
                              projectId: widget.projectId,
                              title: 'Xóa bối cảnh: ${loc.name}',
                              body:
                                  'Bối cảnh "${loc.name}" (${loc.setting.fullLabel} - ${loc.timeOfDay.fullLabel}) đã bị xóa.',
                              actionType: NotificationActionType.delete,
                            );
                            AppSnackbar.success(
                              context,
                              'Đã xóa bối cảnh thành công',
                            );
                          }
                        }
                      },
                    );
                  },
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
              heroTag: 'add_location_fab',
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add_location_outlined),
            )
          : null,
    );
  }

  void _openForm(BuildContext context, {location}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationFormScreen(location: location, projectId: widget.projectId),
      ),
    );
  }
}
