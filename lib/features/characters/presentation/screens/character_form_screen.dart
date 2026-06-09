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
  const CharacterFormScreen(
      {super.key, required this.projectId, this.character});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa nhân vật' : 'Nhân vật mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên nhân vật *'),
              validator: (v) => AppValidators.required(v, field: 'Tên nhân vật'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RoleType>(
              initialValue: _roleType,
              decoration: const InputDecoration(labelText: 'Vai trò'),
              items: RoleType.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => setState(() => _roleType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả tâm lý'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_imagePath == null ? 'Chọn ảnh' : 'Đổi ảnh'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Cập nhật' : 'Thêm nhân vật'),
            ),
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
