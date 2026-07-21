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

  static String? compose(String? value, List<String? Function(String?)> rules) {
    for (final rule in rules) {
      final error = rule(value);
      if (error != null) return error;
    }
    return null;
  }
}
