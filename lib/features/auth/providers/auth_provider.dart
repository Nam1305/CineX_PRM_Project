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

  /// Lấy danh sách người dùng cục bộ từ SharedPreferences, khởi tạo nếu chưa có
  Future<List<Map<String, dynamic>>> _getOrCreateLocalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final localUsersJson = prefs.getString('local_users_list');
    
    List<Map<String, dynamic>> usersList = [];
    if (localUsersJson != null) {
      try {
        final decoded = jsonDecode(localUsersJson) as List<dynamic>;
        usersList = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        print('Error decoding local users list: $e');
      }
    }
    
    // Nếu chưa có hoặc danh sách rỗng, khởi tạo với user mặc định tương thích DB Seed
    if (usersList.isEmpty) {
      usersList = [
        {
          'username': 'writer',
          'password': 'writer123',
          'fullName': 'Biên Kịch Chính',
          'role': 'SCREENWRITER',
        },
        {
          'username': 'producer',
          'password': 'producer123',
          'fullName': 'Nhà Sản Xuất Trưởng',
          'role': 'PRODUCER',
        }
      ];
      await prefs.setString('local_users_list', jsonEncode(usersList));
    }
    
    return usersList;
  }

  /// Lưu/Cập nhật thông tin đăng nhập vào dữ liệu cục bộ
  Future<void> _saveUserLocally(String username, String password, String fullName, String role) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _getOrCreateLocalUsers();
    
    final index = users.indexWhere((u) => u['username'] == username);
    final userMap = {
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
    };
    
    if (index != -1) {
      users[index] = userMap;
    } else {
      users.add(userMap);
    }
    
    await prefs.setString('local_users_list', jsonEncode(users));
  }

  /// Đăng nhập offline bằng dữ liệu cục bộ
  Future<bool> _tryOfflineLogin(String username, String password) async {
    final users = await _getOrCreateLocalUsers();
    final matchedUser = users.firstWhere(
      (u) => u['username'] == username && u['password'] == password,
      orElse: () => {},
    );
    
    if (matchedUser.isNotEmpty) {
      _token = 'offline_token_${matchedUser['username']}';
      _username = matchedUser['username'];
      _fullName = matchedUser['fullName'];
      _role = matchedUser['role'];
      
      // Đăng ký token với ApiService
      ApiService.token = _token;

      // Lưu cục bộ vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('username', _username!);
      await prefs.setString('fullName', _fullName!);
      await prefs.setString('role', _role!);
      return true;
    }
    return false;
  }

  /// Đăng ký offline bằng dữ liệu cục bộ
  Future<bool> _tryOfflineRegister(String username, String password, String fullName, String role) async {
    final users = await _getOrCreateLocalUsers();
    final exists = users.any((u) => u['username'] == username);
    if (exists) {
      _error = 'Tên đăng nhập đã tồn tại trong dữ liệu cục bộ';
      return false;
    }
    await _saveUserLocally(username, password, fullName, role);
    return true;
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

        // Cập nhật lưu trữ offline
        await _saveUserLocally(username, password, _fullName!, _role!);

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
      // Đăng nhập thất bại do kết nối -> Thử đăng nhập offline
      final offlineSuccess = await _tryOfflineLogin(username, password);
      if (offlineSuccess) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
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
        // Lưu thông tin đăng ký vào local để có thể đăng nhập offline
        await _saveUserLocally(username, password, fullName, role);
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
      // Đăng ký thất bại do kết nối -> Thử đăng ký offline
      final offlineSuccess = await _tryOfflineRegister(username, password, fullName, role);
      if (offlineSuccess) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
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
