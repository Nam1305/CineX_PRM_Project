import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/core/widgets/primary_button.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _directorCtrl = TextEditingController();
  final _genreCtrl = TextEditingController();
  final _loglineCtrl = TextEditingController();
  String _selectedGenre = 'Drama';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _directorCtrl.dispose();
    _genreCtrl.dispose();
    _loglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Dự Án Mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Poster Upload
            Container(
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text('Tải Poster (2:3)', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Project Name
            Text(
              'TÊN DỰ ÁN',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Nhập tên dự án...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tên dự án không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Director
            Text(
              'ĐẠO DIỄN',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _directorCtrl,
              decoration: InputDecoration(
                hintText: 'Tên đạo diễn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Genre
            Text(
              'THỂ LOẠI',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedGenre,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Drama', child: Text('Drama')),
                DropdownMenuItem(value: 'Action', child: Text('Action')),
                DropdownMenuItem(value: 'Horror', child: Text('Horror')),
                DropdownMenuItem(value: 'Comedy', child: Text('Comedy')),
              ],
              onChanged: (value) {
                setState(() => _selectedGenre = value ?? 'Drama');
              },
            ),
            const SizedBox(height: 16),

            // Logline
            Text(
              'SYN OP',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loglineCtrl,
              decoration: InputDecoration(
                hintText: 'Mô tả cốt truyện...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              label: 'Tạo dự án',
              icon: Icons.add,
              isLoading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final project = Project(
      title: _titleCtrl.text.trim(),
      director: _directorCtrl.text.trim(),
      genre: _selectedGenre,
      description: _loglineCtrl.text.trim(),
      progress: 0.0,
      status: 'PLANNING',
    );

    final createdId = await context.read<ProjectProvider>().addProject(project);

    if (mounted) {
      setState(() => _saving = false);
      if (createdId != null) {
        context.read<NotificationProvider>().addNotification(
          projectId: createdId,
          projectTitle: project.title,
          title: 'Tạo dự án mới: ${project.title}',
          body:
              'Trạng thái: ${project.status} · Thể loại: ${project.genre ?? "N/A"} · Đạo diễn: ${project.director ?? "N/A"}',
          actionType: NotificationActionType.create,
        );
        AppSnackbar.success(context, 'Dự án đã được tạo');
        Navigator.pop(context);
      } else {
        AppSnackbar.error(context, 'Tạo dự án thất bại. Vui lòng thử lại.');
      }
    }
  }
}
