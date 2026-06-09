import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class ProjectFormScreen extends StatefulWidget {
  final Project? project;
  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.project?.title);
    _genreCtrl = TextEditingController(text: widget.project?.genre);
    _descCtrl = TextEditingController(text: widget.project?.description);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _genreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa dự án' : 'Dự án mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tên dự án *'),
              validator: (v) => AppValidators.required(v, field: 'Tên dự án'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _genreCtrl,
              decoration: const InputDecoration(labelText: 'Thể loại'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Cập nhật' : 'Tạo dự án'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ProjectProvider>();
    final now = DateTime.now().toIso8601String();
    if (_isEditing) {
      await provider.editProject(widget.project!.copyWith(
        title: _titleCtrl.text.trim(),
        genre: _genreCtrl.text.trim().isEmpty ? null : _genreCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
      if (mounted) AppSnackbar.success(context, 'Đã cập nhật dự án');
    } else {
      await provider.addProject(Project(
        title: _titleCtrl.text.trim(),
        genre: _genreCtrl.text.trim().isEmpty ? null : _genreCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        createdAt: now,
      ));
      if (mounted) AppSnackbar.success(context, 'Đã tạo dự án mới');
    }
    if (mounted) Navigator.pop(context);
  }
}
