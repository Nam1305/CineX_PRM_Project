import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/core/utils/date_only.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
import 'package:cinex_application/core/theme/app_colors.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/projects/providers/project_provider.dart';
import 'package:cinex_application/shared/widgets/app_snackbar.dart';
import 'package:cinex_application/features/notifications/providers/notification_provider.dart';
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';
import 'package:cinex_application/core/services/api_service.dart';

class ProjectFormScreen extends StatefulWidget {
  final Project? project;
  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _directorCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _crewCountCtrl;

  String _selectedGenre = 'Drama';
  String _selectedStatus = 'PLANNING';

  DateTime? _startDate;
  DateTime? _endDate;

  String? _posterPath; // Can be a local path or network URL
  XFile? _pendingPoster;
  String? _uploadedPosterUrl;
  bool _uploadingPoster = false;
  double _posterUploadProgress = 0;
  String? _posterUploadError;
  bool _saving = false;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.project?.title);
    _directorCtrl = TextEditingController(text: widget.project?.director);
    _descCtrl = TextEditingController(text: widget.project?.description);
    _crewCountCtrl = TextEditingController(
      text: widget.project?.crewCount.toString() ?? '0',
    );
    _selectedGenre = widget.project?.genre ?? 'Drama';
    _selectedStatus = widget.project?.status ?? 'PLANNING';
    _posterPath = widget.project?.posterUrl;

    if (widget.project?.startDate != null) {
      _startDate = parseDateOnly(widget.project!.startDate!);
    }
    if (widget.project?.endDate != null) {
      _endDate = parseDateOnly(widget.project!.endDate!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _directorCtrl.dispose();
    _descCtrl.dispose();
    _crewCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPoster() async {
    if (_uploadingPoster) {
      AppSnackbar.error(context, 'Ảnh hiện tại đang được tải lên.');
      return;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1800,
        imageQuality: 75,
      );
      if (file == null || !mounted) return;
      setState(() {
        _posterPath = file.path;
        _pendingPoster = file;
        _uploadedPosterUrl = null;
        _posterUploadError = null;
        _posterUploadProgress = 0;
      });
      await _uploadPoster(file);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    }
  }

  Future<void> _uploadPoster(XFile file) async {
    setState(() {
      _uploadingPoster = true;
      _posterUploadError = null;
      _posterUploadProgress = 0;
    });
    try {
      final url = await _api.uploadImage(
        file,
        'poster',
        onProgress: (progress) {
          if (mounted && identical(_pendingPoster, file)) {
            setState(() => _posterUploadProgress = progress);
          }
        },
      );
      if (!mounted || !identical(_pendingPoster, file)) return;
      setState(() {
        _uploadedPosterUrl = url;
        _posterUploadProgress = 1;
      });
    } catch (e) {
      if (!mounted || !identical(_pendingPoster, file)) return;
      setState(() => _posterUploadError = e.toString());
      AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted && identical(_pendingPoster, file)) {
        setState(() => _uploadingPoster = false);
      }
    }
  }

  Future<void> _retryPosterUpload() async {
    final file = _pendingPoster;
    if (file != null && !_uploadingPoster) await _uploadPoster(file);
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final firstAllowed = _isEditing ? DateTime(1900) : todayMidnight;

    final preferred =
        _startDate ?? (_isEditing ? DateTime.now() : todayMidnight);
    final lastYear = preferred.year > now.year + 20
        ? preferred.year + 20
        : now.year + 20;
    final lastAllowed = DateTime(lastYear, 12, 31);
    final initialDate = preferred.isBefore(firstAllowed)
        ? firstAllowed
        : preferred;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      AppSnackbar.error(context, 'Hãy chọn ngày bắt đầu trước');
      return;
    }
    final now = DateTime.now();
    final preferred = _endDate ?? _startDate!.add(const Duration(days: 30));
    final lastYear = preferred.year > now.year + 20
        ? preferred.year + 20
        : now.year + 20;
    final lastAllowed = DateTime(lastYear, 12, 31);
    final initialDate = preferred.isBefore(_startDate!)
        ? _startDate!
        : preferred;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate!,
      lastDate: lastAllowed,
      helpText: 'Chọn ngày hoàn thành',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final List<String> genreOptions = [
      'Drama',
      'Action',
      'Horror',
      'Comedy',
      'Sci-Fi',
      'Romance',
    ];
    if (_selectedGenre.isNotEmpty && !genreOptions.contains(_selectedGenre)) {
      genreOptions.add(_selectedGenre);
    }

    final List<String> statusOptions = [
      'PLANNING',
      'SHOOTING',
      'POST_PRODUCTION',
      'COMPLETED',
    ];
    if (_selectedStatus.isNotEmpty &&
        !statusOptions.contains(_selectedStatus)) {
      statusOptions.add(_selectedStatus);
    }

    String getStatusLabel(String status) {
      switch (status) {
        case 'PLANNING':
          return 'Lập kế hoạch';
        case 'SHOOTING':
          return 'Đang quay';
        case 'POST_PRODUCTION':
          return 'Hậu kỳ';
        case 'COMPLETED':
          return 'Hoàn tất';
        default:
          return status;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thông tin dự án' : 'Tạo dự án mới'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Poster Picker Section
                GestureDetector(
                  onTap: _pickPoster,
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: _posterPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AdaptiveImage(
                              source: _posterPath!,
                              placeholderBuilder: (_) =>
                                  _buildUploadPlaceholder(theme),
                            ),
                          )
                        : _buildUploadPlaceholder(theme),
                  ),
                ),
                if (_pendingPoster != null) ...[
                  const SizedBox(height: 8),
                  _buildPosterUploadStatus(theme),
                ],
                const SizedBox(height: 24),

                // Project Title
                _fieldLabel(theme, 'TÊN DỰ ÁN *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tên dự án...',
                  ),
                  validator: (v) => AppValidators.text(
                    v,
                    field: 'Tên dự án',
                    min: 2,
                    max: 200,
                  ),
                ),
                const SizedBox(height: 16),

                // Director
                _fieldLabel(theme, 'ĐẠO DIỄN *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _directorCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tên đạo diễn...',
                  ),
                  validator: (v) => AppValidators.text(
                    v,
                    field: 'Tên đạo diễn',
                    min: 2,
                    max: 200,
                  ),
                ),
                const SizedBox(height: 16),

                // Genre & Status Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(theme, 'THỂ LOẠI'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedGenre,
                            items: genreOptions
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _selectedGenre = value ?? 'Drama',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(theme, 'TRẠNG THÁI'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(getStatusLabel(s)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _selectedStatus = value ?? 'PLANNING',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Pickers Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(theme, 'NGÀY BẮT ĐẦU'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectStartDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startDate != null
                                        ? dateFormat.format(_startDate!)
                                        : 'Chọn ngày',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: context.appColors.textFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel(theme, 'NGÀY KẾT THÚC'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectEndDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endDate != null
                                        ? dateFormat.format(_endDate!)
                                        : 'Chọn ngày',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  Icon(
                                    Icons.event,
                                    size: 16,
                                    color: context.appColors.textFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Crew Count
                _fieldLabel(theme, 'SỐ THÀNH VIÊN ĐOÀN PHIM'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _crewCountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Số lượng người...',
                  ),
                  validator: (v) => AppValidators.boundedInt(
                    v,
                    field: 'Số đoàn viên',
                    min: 0,
                    max: 100000,
                  ),
                ),
                const SizedBox(height: 16),

                // Description / Logline
                _fieldLabel(theme, 'MÔ TẢ KỊCH BẢN (SYNOP/LOGLINE) *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Mô tả cốt truyện chi tiết...',
                  ),
                  validator: (v) => AppValidators.text(
                    v,
                    field: 'Mô tả kịch bản',
                    min: 2,
                    max: 5000,
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton.icon(
                  onPressed: (_saving || _uploadingPoster) ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'LƯU THAY ĐỔI' : 'TẠO DỰ ÁN'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
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

  Widget _buildPosterUploadStatus(ThemeData theme) {
    if (_uploadingPoster) {
      final percent = (_posterUploadProgress * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: _posterUploadProgress),
          const SizedBox(height: 4),
          Text(
            'Đang tải ảnh lên: $percent%',
            style: theme.textTheme.labelSmall,
          ),
        ],
      );
    }
    if (_posterUploadError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _posterUploadError!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.appColors.danger,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _retryPosterUpload,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: context.appColors.success),
        const SizedBox(width: 6),
        Text(
          'Ảnh đã được tải lên',
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.appColors.success,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(ThemeData theme, String label) => Text(
    label,
    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
  );

  Widget _buildUploadPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 48,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'TẢI ẢNH POSTER (2:3)',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_uploadingPoster) {
      AppSnackbar.error(context, 'Vui lòng chờ ảnh tải lên hoàn tất.');
      return;
    }
    if (_pendingPoster != null && _uploadedPosterUrl == null) {
      AppSnackbar.error(context, 'Ảnh chưa tải lên được. Hãy bấm Thử lại.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      AppSnackbar.error(context, 'Vui lòng chọn ngày bắt đầu dự án');
      return;
    }
    if (_endDate == null) {
      AppSnackbar.error(context, 'Vui lòng chọn ngày kết thúc dự án');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      AppSnackbar.error(context, 'Ngày kết thúc không được trước ngày bắt đầu');
      return;
    }
    if (!_isEditing) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final startMidnight = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      if (startMidnight.isBefore(todayMidnight)) {
        AppSnackbar.error(
          context,
          'Ngày bắt đầu dự án mới không được ở trong quá khứ',
        );
        return;
      }
    }
    setState(() => _saving = true);

    final finalPosterUrl = _uploadedPosterUrl ?? widget.project?.posterUrl;

    final project = Project(
      id: widget.project?.id,
      title: _titleCtrl.text.trim(),
      director: _directorCtrl.text.trim().isEmpty
          ? null
          : _directorCtrl.text.trim(),
      genre: _selectedGenre,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      startDate: _startDate == null ? null : dateOnlyToApi(_startDate!),
      endDate: _endDate == null ? null : dateOnlyToApi(_endDate!),
      posterUrl: finalPosterUrl,
      progress: widget.project?.progress ?? 0.0,
      status: _selectedStatus,
      crewCount: int.tryParse(_crewCountCtrl.text) ?? 0,
      createdAt:
          widget.project?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
    );

    final provider = context.read<ProjectProvider>();
    bool success;
    int? savedProjectId = project.id;
    if (_isEditing) {
      success = await provider.editProject(project);
    } else {
      final newId = await provider.addProject(project);
      savedProjectId = newId;
      success = newId != null;
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.read<NotificationProvider>().addNotification(
          projectId: savedProjectId,
          projectTitle: project.title,
          title: _isEditing
              ? 'Cập nhật dự án: ${project.title}'
              : 'Tạo dự án mới: ${project.title}',
          body:
              'Trạng thái: ${project.status} · Thể loại: ${project.genre ?? "N/A"} · Đạo diễn: ${project.director ?? "N/A"}',
          actionType: _isEditing
              ? NotificationActionType.update
              : NotificationActionType.create,
        );
        AppSnackbar.success(
          context,
          _isEditing ? 'Cập nhật dự án thành công' : 'Đã tạo dự án thành công',
        );
        Navigator.pop(context);
      } else {
        AppSnackbar.error(context, provider.error ?? 'Có lỗi xảy ra');
      }
    }
  }
}
