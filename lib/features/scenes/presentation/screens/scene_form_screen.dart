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
  final int actId;
  final int projectId;
  final Scene? scene;
  const SceneFormScreen({
    super.key,
    required this.actId,
    required this.projectId,
    this.scene,
  });

  @override
  State<SceneFormScreen> createState() => _SceneFormScreenState();
}

class _SceneFormScreenState extends State<SceneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberCtrl;
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
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _numberCtrl,
              decoration: const InputDecoration(labelText: 'Số thứ tự cảnh *'),
              keyboardType: TextInputType.number,
              validator: (v) => AppValidators.positiveInt(v, field: 'Số cảnh'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _selectedLocationId,
              decoration: const InputDecoration(labelText: 'Bối cảnh'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Chưa chọn —')),
                ...locationProvider.locations.map((l) =>
                    DropdownMenuItem(value: l.id, child: Text(l.sceneLabel))),
              ],
              onChanged: (v) => setState(() => _selectedLocationId = v),
            ),
            const SizedBox(height: 16),
            const Text('Nhân vật tham gia'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: characterProvider.characters.map((c) {
                final selected = _selectedCharacterIds.contains(c.id);
                return FilterChip(
                  label: Text(c.name),
                  selected: selected,
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
    final taken = await sceneProvider.isSceneNumberTaken(
      widget.actId,
      sceneNumber,
      excludeId: widget.scene?.id,
    );
    if (taken) {
      if (mounted) {
        AppSnackbar.error(context, 'Số cảnh $sceneNumber đã tồn tại trong hồi này');
      }
      return;
    }
    setState(() => _saving = true);
    final scene = Scene(
      id: widget.scene?.id,
      actId: widget.actId,
      locationId: _selectedLocationId,
      sceneNumber: sceneNumber,
      summary: _summaryCtrl.text.trim().isEmpty ? null : _summaryCtrl.text.trim(),
      status: _status,
    );
    if (_isEditing) {
      await sceneProvider.editScene(scene, _selectedCharacterIds.toList());
      if (mounted) AppSnackbar.success(context, 'Đã cập nhật cảnh');
    } else {
      await sceneProvider.addScene(scene, _selectedCharacterIds.toList());
      if (mounted) AppSnackbar.success(context, 'Đã thêm cảnh');
    }
    if (mounted) Navigator.pop(context);
  }
}
