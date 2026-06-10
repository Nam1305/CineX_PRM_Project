import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class CharacterFormScreen extends StatefulWidget {
  final int projectId;
  final Character? character;
  const CharacterFormScreen({
    super.key,
    required this.projectId,
    this.character,
  });

  @override
  State<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends State<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  RoleType _roleType = RoleType.main;
  String? _imagePath;
  bool _saving = false;

  bool get _isEditing => widget.character != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.character?.name);
    _descCtrl = TextEditingController(text: widget.character?.description);
    _roleType = widget.character?.roleType ?? RoleType.main;
    _imagePath = widget.character?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineX Production'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Thêm Nhân Vật Mới',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            _ImageUploadSection(
              imagePath: _imagePath,
              onTap: _pickImage,
              theme: theme,
            ),
            const SizedBox(height: 24),
            Text(
              'TÊN NHÂN VẬT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Nhập tên nhân vật...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF393939)),
                ),
              ),
              validator: (v) =>
                  AppValidators.required(v, field: 'Tên nhân vật'),
            ),
            const SizedBox(height: 24),
            Text(
              'VAI TRÒ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RoleType>(
              initialValue: _roleType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF393939)),
                ),
              ),
              items: RoleType.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => setState(() => _roleType = v!),
            ),
            const SizedBox(height: 24),
            Text(
              'MÔ TẢ CHI TIẾT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: 'Mô tả về tâm lý, nền tảng và các nét nhân vật...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF393939)),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Cập nhật' : 'Lưu nhân vật'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CharacterProvider>();
    final character = Character(
      id: widget.character?.id,
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      roleType: _roleType,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      imagePath: _imagePath,
    );
    if (_isEditing) {
      await provider.editCharacter(character);
      if (mounted) AppSnackbar.success(context, 'Đã cập nhật nhân vật');
    } else {
      await provider.addCharacter(character);
      if (mounted) AppSnackbar.success(context, 'Đã thêm nhân vật');
    }
    if (mounted) Navigator.pop(context);
  }
}

class _ImageUploadSection extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ImageUploadSection({
    required this.imagePath,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF393939),
            style: BorderStyle.solid,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _UploadPlaceholder(theme: theme),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : _UploadPlaceholder(theme: theme),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  final ThemeData theme;

  const _UploadPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt,
          size: 48,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'TẢI ẢNH',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
