import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/core/widgets/primary_button.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/locations/providers/location_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class AddLocationScreen extends StatefulWidget {
  final int projectId;

  const AddLocationScreen({super.key, required this.projectId});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  LocationSetting _setting = LocationSetting.interior;
  SceneTime _timeOfDay = SceneTime.day;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Bối Cảnh'),
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
            // Moodboard Upload
            Container(
              height: 200,
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
                  Text('Tải Moodboard', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location Name
            Text(
              'TÊN BỐI CẢNH',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Nhập tên bối cảnh...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tên bối cảnh không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Setting (INT/EXT)
            Text(
              'LOẠI BỐI CẢNH',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<LocationSetting>(
              segments: LocationSetting.values
                  .map(
                    (s) => ButtonSegment(
                      value: s,
                      label: Text(s.fullLabel),
                      icon: Icon(
                        s == LocationSetting.interior
                            ? Icons.home_outlined
                            : Icons.wb_sunny_outlined,
                      ),
                    ),
                  )
                  .toList(),
              selected: {_setting},
              onSelectionChanged: (s) => setState(() => _setting = s.first),
            ),
            const SizedBox(height: 16),

            // Time of Day
            Text(
              'THỜI GI AN',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SceneTime>(
              segments: SceneTime.values
                  .map(
                    (t) => ButtonSegment(
                      value: t,
                      label: Text(t.fullLabel),
                      icon: Icon(
                        t == SceneTime.day
                            ? Icons.wb_sunny
                            : Icons.nightlight_round,
                      ),
                    ),
                  )
                  .toList(),
              selected: {_timeOfDay},
              onSelectionChanged: (t) => setState(() => _timeOfDay = t.first),
            ),
            const SizedBox(height: 16),

            // Notes
            Text(
              'GHI CHÚ KỸ THUẬT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText: 'Yêu cầu về ánh sáng, âm thanh, v.v...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 32),

            // Submit
            PrimaryButton(
              label: 'Xác nhận bối cảnh',
              icon: Icons.check,
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

    final location = Location(
      projectId: widget.projectId,
      name: _nameCtrl.text.trim(),
      setting: _setting,
      timeOfDay: _timeOfDay,
      notes: _notesCtrl.text.trim(),
    );

    final provider = context.read<LocationProvider>();
    final ok = await provider.addLocation(location);

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppSnackbar.success(context, 'Bối cảnh đã được thêm');
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.error ?? 'Có lỗi xảy ra');
    }
  }
}
