import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cinex_application/core/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String? _fullName;
  String? _role; // SCREENWRITER or PRODUCER
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get isScreenwriter => _role == 'SCREENWRITER';
  bool get isProducer => _role == 'PRODUCER';

  /// Khôi phục phiên đăng nhập khi khởi động ứng dụng
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    _username = prefs.getString('username');
    _fullName = prefs.getString('fullName');
    _role = prefs.getString('role');

    // Đăng ký token với ApiService (để đính kèm vào mọi header)
    if (_token != null) {
      ApiService.token = _token;
    }
    notifyListeners();
  }

  /// Đăng nhập bằng tên đăng nhập và mật khẩu
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final base = ApiService.baseUrl.replaceAll('/odata', '');
      final url = Uri.parse('$base/api/Auth/login');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(ApiService.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['Token'] ?? data['token'];
        _username = data['Username'] ?? data['username'];
        _fullName = data['FullName'] ?? data['fullName'];
        _role = data['Role'] ?? data['role'];

        // Đăng ký token với ApiService
        ApiService.token = _token;

        // Lưu cục bộ vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('username', _username!);
        await prefs.setString('fullName', _fullName!);
        await prefs.setString('role', _role!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['Message'] ?? data['message'] ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException {
      _error = 'Đăng nhập quá thời gian chờ. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Kết nối server thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký tài khoản mới
  Future<bool> register(
    String username,
    String password,
    String fullName,
    String role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final base = ApiService.baseUrl.replaceAll('/odata', '');
      final url = Uri.parse('$base/api/Auth/register');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'fullName': fullName,
              'role': role, // SCREENWRITER or PRODUCER
            }),
          )
          .timeout(ApiService.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['Message'] ?? data['message'] ?? 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException {
      _error = 'Đăng ký quá thời gian chờ. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Kết nối server thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> logout() async {
    _token = null;
    _username = null;
    _fullName = null;
    _role = null;
    ApiService.token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    await prefs.remove('fullName');
    await prefs.remove('role');

    notifyListeners();
  }
}
