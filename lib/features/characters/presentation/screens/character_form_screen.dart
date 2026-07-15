import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/core/services/api_service.dart';

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
  final _api = ApiService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _actorCtrl;
  late final TextEditingController _descCtrl;
  RoleType _roleType = RoleType.main;
  String? _imagePath;
  bool _saving = false;

  bool get _isEditing => widget.character != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.character?.name);
    _actorCtrl = TextEditingController(text: widget.character?.actorName);
    _descCtrl = TextEditingController(text: widget.character?.description);
    _roleType = widget.character?.roleType ?? RoleType.main;
    _imagePath = widget.character?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _actorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa Nhân vật' : 'Thêm Nhân Vật Mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            _ImageUploadSection(
              imagePath: _imagePath,
              castingStatus: widget.character?.castingStatus,
              onTap: _pickImage,
              theme: theme,
            ),
            const SizedBox(height: 24),
            _fieldLabel(theme, 'NHÂN VẬT (CHARACTER NAME)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Nhập tên nhân vật...',
                suffixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  AppValidators.required(v, field: 'Tên nhân vật'),
            ),
            const SizedBox(height: 24),
            _fieldLabel(theme, 'VAI TRÒ (ROLE)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<RoleType>(
              initialValue: _roleType,
              icon: const Icon(Icons.unfold_more),
              items: RoleType.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.dbValue} (${r.label})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _roleType = v!),
            ),
            const SizedBox(height: 24),
            _fieldLabel(theme, 'DIỄN VIÊN (ACTOR)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _actorCtrl,
              decoration: const InputDecoration(
                hintText: 'Nhập tên diễn viên...',
                suffixIcon: Icon(Icons.contact_page_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_actorCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Hồ sơ diễn viên đã được liên kết',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _fieldLabel(theme, 'MÔ TẢ CHI TIẾT (DETAILED DESCRIPTION)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                hintText: 'Mô tả về tâm lý, nền tảng và các nét nhân vật...',
              ),
              maxLines: 5,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _fieldLabel(theme, 'CẢNH XUẤT HIỆN (APPEARS IN)'),
              const SizedBox(height: 8),
              const _AppearsInScenesSection(),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'LƯU THAY ĐỔI' : 'LƯU NHÂN VẬT'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _fieldLabel(ThemeData theme, String label) => Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<CharacterProvider>();
    
    String? finalImageUrl = widget.character?.imagePath;

    // Upload local image to R2 if selected
    if (_imagePath != null && !_imagePath!.startsWith('http')) {
      final uploadedUrl = await _api.uploadFile(_imagePath!, 'character');
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      }
    }

    final character = Character(
      id: widget.character?.id,
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      roleType: _roleType,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      actorName: _actorCtrl.text.trim().isEmpty ? null : _actorCtrl.text.trim(),
      imagePath: finalImageUrl,
      castingStatus: widget.character?.castingStatus,
    );
    final ok = _isEditing
        ? await provider.editCharacter(character)
        : await provider.addCharacter(character);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppSnackbar.success(
        context,
        _isEditing ? 'Đã cập nhật nhân vật' : 'Đã thêm nhân vật',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.error ?? 'Có lỗi xảy ra');
    }
  }
}

class _ImageUploadSection extends StatelessWidget {
  final String? imagePath;
  final String? castingStatus;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ImageUploadSection({
    required this.imagePath,
    required this.castingStatus,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final approved = castingStatus == 'Đã duyệt';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF393939)),
          color: theme.colorScheme.surface,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imagePath != null
                ? AdaptiveImage(
                    source: imagePath!,
                    placeholderBuilder: (_) => _UploadPlaceholder(theme: theme),
                  )
                : _UploadPlaceholder(theme: theme),
            if (castingStatus != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (approved ? Colors.green : Colors.amber)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: approved ? Colors.green : Colors.amber,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: approved ? Colors.green : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        castingStatus!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: approved ? Colors.green : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 18, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'THAY ĐỔI ẢNH',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _AppearsInScene {
  final String code;
  final String title;
  final String tag;
  final SceneTime time;

  const _AppearsInScene(this.code, this.title, this.tag, this.time);
}

class _AppearsInScenesSection extends StatelessWidget {
  const _AppearsInScenesSection();

  // Chưa có endpoint tra cứu "cảnh nào có nhân vật này" trên toàn dự án
  // (Character là entity dùng chung, không gắn theo ProjectId), nên đây là
  // dữ liệu minh hoạ giống cách CharacterDetailScreen đang làm.
  static const _scenes = [
    _AppearsInScene('SCENE 12A', 'Căn hộ của Minh', 'INT / DAY', SceneTime.day),
    _AppearsInScene('SCENE 15', 'Hẻm tối Quận 4', 'EXT / NIGHT', SceneTime.night),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _scenes.map((scene) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: const Border.fromBorderSide(
                  BorderSide(color: Color(0xFF393939)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          scene.code,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Icon(
                        scene.time == SceneTime.day
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_round,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    scene.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scene.tag,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
