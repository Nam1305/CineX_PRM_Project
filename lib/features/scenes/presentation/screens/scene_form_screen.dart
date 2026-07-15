import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/scenes/providers/scene_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class SceneFormScreen extends StatefulWidget {
  final int projectId;
  final int actId;
  final Scene? scene;
  const SceneFormScreen({
    super.key,
    required this.projectId,
    required this.actId,
    this.scene,
  });

  @override
  State<SceneFormScreen> createState() => _SceneFormScreenState();
}

class _SceneFormScreenState extends State<SceneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  int? _selectedLocationId;
  SceneStatus _status = SceneStatus.todo;
  final Set<int> _selectedCharacterIds = {};
  bool _saving = false;

  bool get _isEditing => widget.scene != null;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(
        text: widget.scene?.sceneNumber.toString());
    _titleCtrl = TextEditingController(text: widget.scene?.title);
    _summaryCtrl = TextEditingController(text: widget.scene?.summary);
    _selectedLocationId = widget.scene?.locationId;
    _status = widget.scene?.status ?? SceneStatus.todo;
    if (widget.scene != null) {
      _selectedCharacterIds.addAll(
        widget.scene!.characters.map((c) => c.id!),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations(widget.projectId);
      context.read<CharacterProvider>().loadCharacters(widget.projectId);
    });
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = context.watch<LocationProvider>();
    final characterProvider = context.watch<CharacterProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa cảnh' : 'Cảnh mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tiêu đề cảnh *'),
              validator: (v) => AppValidators.required(v, field: 'Tiêu đề cảnh'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberCtrl,
              decoration: const InputDecoration(labelText: 'Số thứ tự cảnh *'),
              keyboardType: TextInputType.number,
              validator: (v) => AppValidators.positiveInt(v, field: 'Số cảnh'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _selectedLocationId,
              decoration: const InputDecoration(labelText: 'Bối cảnh *'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Chọn bối cảnh —')),
                ...locationProvider.locations.map((l) =>
                    DropdownMenuItem(value: l.id, child: Text(l.sceneLabel))),
              ],
              validator: (v) => v == null ? 'Vui lòng chọn bối cảnh' : null,
              onChanged: (v) => setState(() => _selectedLocationId = v),
            ),
            const SizedBox(height: 16),
            const Text('Nhân vật tham gia', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: characterProvider.characters.map((c) {
                final selected = _selectedCharacterIds.contains(c.id);
                return FilterChip(
                  label: Text(c.name),
                  selected: selected,
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? theme.colorScheme.primary : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? theme.colorScheme.primary : const Color(0xFF393939),
                    width: selected ? 1.5 : 1,
                  ),
                  onSelected: (v) => setState(() {
                    v ? _selectedCharacterIds.add(c.id!) : _selectedCharacterIds.remove(c.id);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SceneStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: SceneStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _summaryCtrl,
              decoration: const InputDecoration(labelText: 'Tóm tắt hành động'),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Cập nhật' : 'Thêm cảnh'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final sceneProvider = context.read<SceneProvider>();
    final sceneNumber = int.parse(_numberCtrl.text.trim());
    final taken = sceneProvider.isSceneNumberTaken(
      widget.actId,
      sceneNumber,
      excludeId: widget.scene?.id,
    );
    if (taken) {
      AppSnackbar.error(context, 'Số cảnh $sceneNumber đã tồn tại trong hồi này');
      return;
    }
    setState(() => _saving = true);
    final scene = Scene(
      id: widget.scene?.id,
      actId: widget.actId,
      locationId: _selectedLocationId,
      sceneNumber: sceneNumber,
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim().isEmpty ? null : _summaryCtrl.text.trim(),
      status: _status,
    );
    final ok = _isEditing
        ? await sceneProvider.editScene(
            scene,
            _selectedCharacterIds.toList(),
            previousCharacterIds:
                widget.scene!.characters.map((c) => c.id!).toList(),
          )
        : await sceneProvider.addScene(scene, _selectedCharacterIds.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppSnackbar.success(context, _isEditing ? 'Đã cập nhật cảnh' : 'Đã thêm cảnh');
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, sceneProvider.error ?? 'Có lỗi xảy ra');
    }
  }
}
