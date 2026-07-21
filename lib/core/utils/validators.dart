class AppValidators {
  static String? required(String? value, {String field = 'Trường này'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    return null;
  }

  static String? maxLength(String? value, int max) {
    if (value != null && value.trim().length > max) {
      return 'Không được vượt quá $max ký tự';
    }
    return null;
  }

  static String? username(String? value, {String field = 'Tên đăng nhập'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    final v = value.trim();
    if (v.length < 3 || v.length > 32) {
      return '$field phải từ 3 đến 32 ký tự';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v)) {
      return '$field chỉ được chứa chữ cái, số, dấu gạch dưới (_) và dấu chấm (.)';
    }
    return null;
  }

  static String? positiveInt(String? value, {String field = 'Số thứ tự'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      return '$field phải là số nguyên dương';
    }
    return null;
  }

  static String? text(
    String? value, {
    required String field,
    int min = 1,
    required int max,
    bool isRequired = true,
  }) {
    final v = value?.trim() ?? '';
    if (isRequired && v.isEmpty) return '$field không được để trống';
    if (v.isEmpty) return null;
    if (v.length < min) return '$field phải có ít nhất $min ký tự';
    if (v.length > max) return '$field không được vượt quá $max ký tự';
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(v)) {
      return '$field chứa ký tự không hợp lệ';
    }
    return null;
  }

  static String? boundedInt(
    String? value, {
    required String field,
    required int min,
    required int max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$field không được để trống';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < min || n > max) {
      return '$field phải là số nguyên từ $min đến $max';
    }
    return null;
  }

  static String? sceneNumber(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'Số cảnh không được để trống';
    if (!RegExp(r'^[0-9]{1,4}[A-Z]?$').hasMatch(v)) {
      return 'Số cảnh phải có dạng 1, 12 hoặc 12A';
    }
    return null;
  }

  static String? compose(String? value, List<String? Function(String?)> rules) {
    for (final rule in rules) {
      final error = rule(value);
      if (error != null) return error;
    }
    return null;
  }
}
