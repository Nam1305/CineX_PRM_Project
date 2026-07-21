import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cinex_application/core/utils/validators.dart';
import 'package:cinex_application/core/widgets/adaptive_image.dart';
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
      final parsed = DateTime.tryParse(widget.project!.startDate!);
      // Convert UTC dates from server to local to prevent off-by-one day
      _startDate = parsed != null ? DateTime(parsed.year, parsed.month, parsed.day) : null;
    }
    if (widget.project?.endDate != null) {
      final parsed = DateTime.tryParse(widget.project!.endDate!);
      _endDate = parsed != null ? DateTime(parsed.year, parsed.month, parsed.day) : null;
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
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _posterPath = file.path);
    }
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    DateTime firstAllowed = todayMidnight;
    if (_startDate != null && _startDate!.isBefore(todayMidnight)) {
      firstAllowed = _startDate!;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? todayMidnight,
      firstDate: firstAllowed,
      lastDate: DateTime(2030),
      helpText: 'Chọn ngày bắt đầu',
    );
    if (picked != null) {
      final pickedMidnight = DateTime(picked.year, picked.month, picked.day);
      if (pickedMidnight.isBefore(todayMidnight)) {
        final initialStartStr = widget.project?.startDate;
        final initialStart = initialStartStr != null ? DateTime.tryParse(initialStartStr) : null;
        final origMidnight = initialStart != null ? DateTime(initialStart.year, initialStart.month, initialStart.day) : null;

        if (origMidnight == null || !pickedMidnight.isAtSameMomentAs(origMidnight)) {
          AppSnackbar.error(context, 'Ngày bắt đầu dự án không được ở trong quá khứ');
          return;
        }
      }

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 30)),
      firstDate: _startDate!,
      lastDate: DateTime(2030),
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
    if (_selectedStatus.isNotEmpty && !statusOptions.contains(_selectedStatus)) {
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
                      border: Border.all(color: const Color(0xFF393939), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: _posterPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AdaptiveImage(
                              source: _posterPath!,
                              placeholderBuilder: (_) => _buildUploadPlaceholder(theme),
                            ),
                          )
                        : _buildUploadPlaceholder(theme),
                  ),
                ),
                const SizedBox(height: 24),

                // Project Title
                _fieldLabel(theme, 'TÊN DỰ ÁN *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tên dự án...',
                  ),
                  validator: (v) => AppValidators.required(v, field: 'Tên dự án'),
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
                  validator: (v) => AppValidators.required(v, field: 'Tên đạo diễn'),
                ),
                const SizedBox(height: 16),

                // Genre & Status Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 380;
                    final genreCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(theme, 'THỂ LOẠI'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGenre,
                          items: genreOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (value) => setState(() => _selectedGenre = value ?? 'Drama'),
                        ),
                      ],
                    );
                    final statusCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(theme, 'TRẠNG THÁI'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(getStatusLabel(s)))).toList(),
                          onChanged: (value) => setState(() => _selectedStatus = value ?? 'PLANNING'),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          genreCol,
                          const SizedBox(height: 16),
                          statusCol,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: genreCol),
                        const SizedBox(width: 16),
                        Expanded(child: statusCol),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Date Pickers Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 380;
                    final startCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(theme, 'NGÀY BẮT ĐẦU'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border.all(color: const Color(0xFF393939)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _startDate != null ? dateFormat.format(_startDate!) : 'Chọn ngày',
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                    final endCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(theme, 'NGÀY KẾT THÚC'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectEndDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              border: Border.all(color: const Color(0xFF393939)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _endDate != null ? dateFormat.format(_endDate!) : 'Chọn ngày',
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.event, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          startCol,
                          const SizedBox(height: 16),
                          endCol,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: startCol),
                        const SizedBox(width: 16),
                        Expanded(child: endCol),
                      ],
                    );
                  },
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
                  validator: (v) => AppValidators.positiveInt(v, field: 'Số đoàn viên'),
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
                  validator: (v) => AppValidators.required(v, field: 'Mô tả kịch bản'),
                  maxLines: 5,
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditing ? 'LƯU THAY ĐỔI' : 'TẠO DỰ ÁN'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final startMidnight = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);

    final initialStartStr = widget.project?.startDate;
    final initialStart = initialStartStr != null ? DateTime.tryParse(initialStartStr) : null;
    final origMidnight = initialStart != null ? DateTime(initialStart.year, initialStart.month, initialStart.day) : null;

    if (startMidnight.isBefore(todayMidnight)) {
      if (origMidnight == null || !startMidnight.isAtSameMomentAs(origMidnight)) {
        AppSnackbar.error(context, 'Ngày bắt đầu dự án không được ở trong quá khứ');
        return;
      }
    }
    setState(() => _saving = true);

    String? finalPosterUrl = widget.project?.posterUrl ?? 
        'https://placehold.co/300x450/FF4D00/FFFFFF?text=Poster';

    // If a new local image is picked, upload it to R2 first
    if (_posterPath != null && !_posterPath!.startsWith('http')) {
      final uploadedUrl = await _api.uploadFile(_posterPath!, 'poster');
      if (uploadedUrl != null) {
        finalPosterUrl = uploadedUrl;
      }
    }

    final project = Project(
      id: widget.project?.id,
      title: _titleCtrl.text.trim(),
      director: _directorCtrl.text.trim().isEmpty ? null : _directorCtrl.text.trim(),
      genre: _selectedGenre,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      startDate: _startDate != null
          ? '${_startDate!.year.toString().padLeft(4, '0')}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}T00:00:00'
          : null,
      endDate: _endDate != null
          ? '${_endDate!.year.toString().padLeft(4, '0')}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}T00:00:00'
          : null,
      posterUrl: finalPosterUrl,
      progress: widget.project?.progress ?? 0.0,
      status: _selectedStatus,
      crewCount: int.tryParse(_crewCountCtrl.text) ?? 0,
      createdAt: widget.project?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
    );

    final provider = context.read<ProjectProvider>();
    bool success;
    if (_isEditing) {
      success = await provider.editProject(project);
    } else {
      final newId = await provider.addProject(project);
      success = newId != null;
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.read<NotificationProvider>().addNotification(
              projectId: project.id,
              projectTitle: project.title,
              title: _isEditing ? 'Cập nhật dự án: ${project.title}' : 'Tạo dự án mới: ${project.title}',
              body: 'Trạng thái: ${project.status} · Thể loại: ${project.genre ?? "N/A"} · Đạo diễn: ${project.director ?? "N/A"}',
              actionType: _isEditing ? NotificationActionType.update : NotificationActionType.create,
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
