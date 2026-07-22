import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';

class LocationFormScreen extends StatefulWidget {
  final Location? location;
  final int? projectId;
  const LocationFormScreen({super.key, this.location, this.projectId});

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  LocationSetting _setting = LocationSetting.interior;
  SceneTime _timeOfDay = SceneTime.day;
  bool _saving = false;

  bool get _isEditing => widget.location != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.location?.name);
    _notesCtrl = TextEditingController(text: widget.location?.notes);
    _setting = widget.location?.setting ?? LocationSetting.interior;
    _timeOfDay = widget.location?.timeOfDay ?? SceneTime.day;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa bối cảnh' : 'Bối cảnh mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên địa điểm / Bối cảnh *',
                hintText: 'Ví dụ: Cà phê Sài Gòn, Nhà Hát Lớn...',
              ),
              validator: (v) => AppValidators.text(
                v,
                field: 'Tên địa điểm',
                min: 2,
                max: 200,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<LocationSetting>(
                    value: _setting,
                    decoration: const InputDecoration(
                      labelText: 'Vị trí (Trong nhà / Ngoài trời)',
                    ),
                    items: LocationSetting.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.fullLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _setting = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SceneTime>(
                    value: _timeOfDay,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian (Ngày / Đêm)',
                    ),
                    items: SceneTime.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.fullLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _timeOfDay = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú chuẩn bị đạo cụ & kỹ thuật *',
                hintText: 'Ghi chú về đạo cụ, ánh sáng, máy quay, tiếng ồn...',
              ),
              validator: (v) => AppValidators.text(
                v,
                field: 'Ghi chú đạo cụ',
                min: 2,
                max: 5000,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Cập nhật' : 'Thêm bối cảnh'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<LocationProvider>();
    final name = _nameCtrl.text.trim();
    final effectiveProjectId = widget.location?.projectId ?? widget.projectId;

    // Refresh locations from server first so the duplicate check below isn't
    // fooled by a stale local cache if another user just added a location.
    if (effectiveProjectId != null) {
      await provider.loadLocations(effectiveProjectId);
    }
    if (!mounted) return;

    // Check trùng bối cảnh: Tên trùng + Setting trùng + TimeOfDay trùng
    final isDuplicate = provider.locations.any((loc) {
      if (_isEditing && loc.id == widget.location?.id) return false;
      return loc.name.trim().toLowerCase() == name.toLowerCase() &&
          loc.setting == _setting &&
          loc.timeOfDay == _timeOfDay;
    });

    if (isDuplicate) {
      setState(() => _saving = false);
      AppSnackbar.error(
        context,
        'Bối cảnh "$name" (${_setting.fullLabel} - ${_timeOfDay.fullLabel}) đã tồn tại!',
      );
      return;
    }

    final location = Location(
      id: widget.location?.id,
      projectId: effectiveProjectId,
      name: name,
      setting: _setting,
      timeOfDay: _timeOfDay,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final ok = _isEditing
        ? await provider.editLocation(location)
        : await provider.addLocation(location);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      context.read<NotificationProvider>().addNotification(
        projectId: location.projectId,
        title: _isEditing
            ? 'Cập nhật bối cảnh: $name'
            : 'Thêm bối cảnh mới: $name',
        body:
            '${_setting.fullLabel} · ${_timeOfDay.fullLabel}${_notesCtrl.text.trim().isNotEmpty ? " - ${_notesCtrl.text.trim()}" : ""}',
        actionType: _isEditing
            ? NotificationActionType.update
            : NotificationActionType.create,
      );
      AppSnackbar.success(
        context,
        _isEditing ? 'Đã cập nhật bối cảnh' : 'Đã thêm bối cảnh',
      );
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.error ?? 'Có lỗi xảy ra');
    }
  }
}
