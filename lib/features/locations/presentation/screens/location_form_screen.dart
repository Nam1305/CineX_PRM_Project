import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

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
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa bối cảnh' : 'Bối cảnh mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên địa điểm *'),
              validator: (v) => AppValidators.required(v, field: 'Tên địa điểm'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<LocationSetting>(
              segments: LocationSetting.values
                  .map((s) => ButtonSegment(
                      value: s,
                      label: Text(s.fullLabel),
                      icon: Icon(s == LocationSetting.interior
                          ? Icons.home_outlined
                          : Icons.wb_sunny_outlined)))
                  .toList(),
              selected: {_setting},
              onSelectionChanged: (s) => setState(() => _setting = s.first),
            ),
            const SizedBox(height: 16),
            SegmentedButton<SceneTime>(
              segments: SceneTime.values
                  .map((t) => ButtonSegment(
                      value: t,
                      label: Text(t.fullLabel),
                      icon: Icon(t == SceneTime.day
                          ? Icons.wb_sunny
                          : Icons.nightlight_round)))
                  .toList(),
              selected: {_timeOfDay},
              onSelectionChanged: (t) => setState(() => _timeOfDay = t.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Ghi chú đạo cụ'),
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
    final location = Location(
      id: widget.location?.id,
      projectId: widget.location?.projectId ?? widget.projectId,
      name: _nameCtrl.text.trim(),
      setting: _setting,
      timeOfDay: _timeOfDay,
      address: widget.location?.address,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    final ok = _isEditing
        ? await provider.editLocation(location)
        : await provider.addLocation(location);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
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
