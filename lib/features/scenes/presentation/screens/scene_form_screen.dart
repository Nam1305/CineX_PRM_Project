import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/theme/app_colors.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/scenes/providers/scene_provider.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
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
  LocationSetting _setting = LocationSetting.interior;
  SceneTime _timeOfDay = SceneTime.day;
  final Set<int> _selectedCharacterIds = {};
  bool _saving = false;

  bool get _isEditing => widget.scene != null;

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(
      text: widget.scene?.sceneNumber.toString(),
    );
    _titleCtrl = TextEditingController(text: widget.scene?.title);
    _summaryCtrl = TextEditingController(text: widget.scene?.summary);
    _selectedLocationId = widget.scene?.locationId;
    _status = widget.scene?.status ?? SceneStatus.todo;
    _setting = widget.scene?.setting ?? LocationSetting.interior;
    _timeOfDay = widget.scene?.timeOfDay ?? SceneTime.day;
    if (widget.scene != null) {
      _selectedCharacterIds.addAll(widget.scene!.characters.map((c) => c.id!));
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

  int? get _effectiveLocationId {
    final locs = context.read<LocationProvider>().locations;
    if (_selectedLocationId != null &&
        locs.any((l) => l.id == _selectedLocationId)) {
      return _selectedLocationId;
    }
    return null;
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
              validator: (v) =>
                  AppValidators.required(v, field: 'Tiêu đề cảnh'),
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
              initialValue: _effectiveLocationId,
              decoration: const InputDecoration(labelText: 'Bối cảnh địa lý *'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('— Chọn bối cảnh —'),
                ),
                ...locationProvider.locations.map(
                  (l) => DropdownMenuItem(
                    value: l.id,
                    child: Text(
                      '${l.name} (${l.setting.label} · ${l.timeOfDay.label})',
                    ),
                  ),
                ),
              ],
              validator: (v) => v == null ? 'Vui lòng chọn bối cảnh' : null,
              onChanged: (v) {
                setState(() {
                  _selectedLocationId = v;
                  if (v != null) {
                    final selectedLoc = locationProvider.locations.firstWhere(
                      (l) => l.id == v,
                    );
                    _setting = selectedLoc.setting;
                    _timeOfDay = selectedLoc.timeOfDay;
                  }
                });
              },
            ),
            if (_selectedLocationId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thuộc tính bối cảnh: ${_setting.fullLabel} · ${_timeOfDay.fullLabel}',
                      style: TextStyle(
                        color: context.appColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Nhân vật tham gia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: characterProvider.characters.map((c) {
                final selected = _selectedCharacterIds.contains(c.id);
                return FilterChip(
                  label: Text(c.name),
                  selected: selected,
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.25,
                  ),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? theme.colorScheme.primary
                        : context.appColors.textMuted,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: selected ? 1.5 : 1,
                  ),
                  onSelected: (v) => setState(() {
                    v
                        ? _selectedCharacterIds.add(c.id!)
                        : _selectedCharacterIds.remove(c.id);
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
              decoration: const InputDecoration(
                labelText: 'Tóm tắt hành động *',
              ),
              validator: (v) =>
                  AppValidators.required(v, field: 'Tóm tắt hành động'),
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
      sceneNumber.toString(),
      excludeId: widget.scene?.id,
    );
    if (taken) {
      AppSnackbar.error(
        context,
        'Số cảnh $sceneNumber đã tồn tại trong hồi này',
      );
      return;
    }
    if (_isEditing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          final dialogTheme = Theme.of(context);
          final dialogAppColors = context.appColors;
          return AlertDialog(
            backgroundColor: dialogTheme.colorScheme.surface,
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: dialogAppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cảnh báo thay đổi Lịch quay',
                  style: TextStyle(
                    color: dialogTheme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Text(
              'Việc chỉnh sửa thông tin phân cảnh (số cảnh, bối cảnh, nhân vật) sẽ làm thay đổi lịch bấm máy của toàn bộ đoàn phim.\n\nBạn có chắc chắn muốn cập nhật không?',
              style: TextStyle(color: dialogAppColors.textFaint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: dialogAppColors.textFaint),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Xác nhận lưu',
                  style: TextStyle(color: dialogTheme.colorScheme.primary),
                ),
              ),
            ],
          );
        },
      );
      if (confirm != true) return;
    }
    setState(() => _saving = true);
    final scene = Scene(
      id: widget.scene?.id,
      actId: widget.actId,
      locationId: _selectedLocationId,
      sceneNumber: sceneNumber.toString(),
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim().isEmpty
          ? null
          : _summaryCtrl.text.trim(),
      status: _status,
      setting: _setting,
      timeOfDay: _timeOfDay,
    );
    final ok = _isEditing
        ? await sceneProvider.editScene(
            scene,
            _selectedCharacterIds.toList(),
            previousCharacterIds: widget.scene!.characters
                .map((c) => c.id!)
                .toList(),
          )
        : await sceneProvider.addScene(scene, _selectedCharacterIds.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.read<NotificationProvider>().addNotification(
        projectId: widget.projectId,
        actId: widget.actId,
        sceneId: scene.id,
        title: _isEditing
            ? 'Đã cập nhật Cảnh $sceneNumber'
            : 'Đã thêm phân cảnh mới: Cảnh $sceneNumber',
        body:
            'Cảnh $sceneNumber (${_setting.label}. ${_titleCtrl.text.trim().toUpperCase()} - ${_timeOfDay.label}) đã được ${_isEditing ? "cập nhật" : "thêm mới"}.',
        actionType: _isEditing
            ? NotificationActionType.update
            : NotificationActionType.create,
      );
      AppSnackbar.success(
        context,
        _isEditing ? 'Đã cập nhật cảnh' : 'Đã thêm cảnh',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, sceneProvider.error ?? 'Có lỗi xảy ra');
    }
  }
}
