import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/acts/providers/act_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';

class ActFormScreen extends StatefulWidget {
  final int projectId;
  final Act? act;
  const ActFormScreen({super.key, required this.projectId, this.act});

  @override
  State<ActFormScreen> createState() => _ActFormScreenState();
}

class _ActFormScreenState extends State<ActFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  bool _saving = false;

  bool get _isEditing => widget.act != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.act?.title);
    _summaryCtrl = TextEditingController(text: widget.act?.summary);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa hồi' : 'Hồi mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tên hồi *'),
              validator: (v) => AppValidators.required(v, field: 'Tên hồi'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _summaryCtrl,
              decoration: const InputDecoration(labelText: 'Tóm tắt'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_isEditing ? 'Cập nhật' : 'Thêm hồi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ActProvider>();
    final act = Act(
      id: widget.act?.id,
      projectId: widget.projectId,
      title: _titleCtrl.text.trim(),
      sequenceOrder: widget.act?.sequenceOrder ?? provider.acts.length + 1,
      summary: _summaryCtrl.text.trim().isEmpty ? null : _summaryCtrl.text.trim(),
      status: widget.act?.status ?? 'WAITING',
    );
    final ok = _isEditing ? await provider.editAct(act) : await provider.addAct(act);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppSnackbar.success(context, _isEditing ? 'Đã cập nhật hồi' : 'Đã thêm hồi');
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, provider.error ?? 'Có lỗi xảy ra');
    }
  }
}
