import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/core/utils/enums.dart';
import 'package:cinex_application/data/mock_data.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:cinex_application/features/notifications/data/models/notification_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const ApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => message;
}

class _TimeoutClient extends http.BaseClient {
  final http.Client _inner;
  final Duration timeout;

  _TimeoutClient(this._inner, {required this.timeout});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Yêu cầu quá thời gian chờ. Vui lòng thử lại.');
    }
  }

  @override
  void close() => _inner.close();
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cinex-api.onrender.com/odata',
  );
  static String? token;
  static final http.Client _client = _TimeoutClient(
    http.Client(),
    timeout: requestTimeout,
  );
  static final http.Client _uploadClient = http.Client();

  static Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (token != null) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const Set<String> _allowedImageTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static String get _apiBaseUrl => baseUrl.replaceAll('/odata', '');

  Future<T> _withTimeout<T>(
    Future<T> future,
    String operation, {
    Duration timeout = requestTimeout,
  }) async {
    try {
      return await future.timeout(timeout);
    } on TimeoutException {
      throw ApiException('$operation quá thời gian chờ. Vui lòng thử lại.');
    }
  }

  ApiException _responseError(int statusCode, String body, String operation) {
    var detail = body.trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        detail =
            (decoded['Message'] ??
                    decoded['message'] ??
                    decoded['title'] ??
                    decoded['error'])
                ?.toString() ??
            detail;
      }
        final validationErrors = decoded['errors'];
        if (validationErrors is List && validationErrors.isNotEmpty) {
          detail = validationErrors.first.toString();
        } else if (validationErrors is Map && validationErrors.isNotEmpty) {
          final firstValue = validationErrors.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            detail = firstValue.first.toString();
          }
        }
    } catch (_) {
      // Non-JSON response: retain the short response text below.
    }
    if (detail.length > 240) detail = detail.substring(0, 240);
    final suffix = detail.isEmpty ? '' : ': $detail';
    return ApiException(
      '$operation thất bại (HTTP $statusCode)$suffix',
      statusCode: statusCode,
    );
  }

  Never _rethrowAsApiException(Object error, String operation) {
    if (error is ApiException) throw error;
    throw ApiException('$operation thất bại. Vui lòng thử lại.', cause: error);
  }

  String _imageContentType(XFile file) {
    var contentType = file.mimeType?.split(';').first.trim().toLowerCase();
    if (contentType == 'image/jpg') contentType = 'image/jpeg';
    if (contentType == null || !_allowedImageTypes.contains(contentType)) {
      final name = file.name.toLowerCase();
      if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (name.endsWith('.png')) {
        contentType = 'image/png';
      } else if (name.endsWith('.webp')) {
        contentType = 'image/webp';
      }
    }
    if (contentType == null || !_allowedImageTypes.contains(contentType)) {
      throw const ApiException('Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP.');
    }
    return contentType;
  }

  // ─── PROJECTS ─────────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả dự án từ server
  Future<List<Project>> getProjects() async {
    final url = Uri.parse('$baseUrl/Projects');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final projects = values
            .map((e) => Project.fromMap(e as Map<String, dynamic>))
            .toList();
        return projects.isNotEmpty ? projects : MockData.projectsCopy();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getProjects error: $e');
      return MockData.projectsCopy();
    }
  }

  /// Tạo dự án mới, trả về Project đã được server gán Id
  Future<Project?> createProject(Project project) async {
    final url = Uri.parse('$baseUrl/Projects');
    try {
      final body = jsonEncode({
        'Title': project.title,
        'Genre': project.genre,
        'Description': project.description,
        'Director': project.director,
        'StartDate': project.startDate,
        'EndDate': project.endDate,
        'PosterUrl': project.posterUrl,
        'Progress': project.progress,
        'Status': project.status,
        'CrewCount': project.crewCount,
      });
      final response = await _client.post(url, headers: _headers, body: body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Project.fromMap(data as Map<String, dynamic>);
      } else {
        throw _responseError(response.statusCode, response.body, 'Tạo dự án');
      }
    } catch (e) {
      _rethrowAsApiException(e, 'Tạo dự án');
    }
  }

  /// Cập nhật dự án theo id (Sử dụng PATCH để tương thích OData)
  Future<Project?> updateProject(Project project) async {
    if (project.id == null) return null;
    final url = Uri.parse('$baseUrl/Projects(${project.id})');
    try {
      final body = jsonEncode({
        'Title': project.title,
        'Genre': project.genre,
        'Description': project.description,
        'Director': project.director,
        'StartDate': project.startDate,
        'EndDate': project.endDate,
        'PosterUrl': project.posterUrl,
        'Progress': project.progress,
        'Status': project.status,
        'CrewCount': project.crewCount,
      });
      final response = await _client.patch(url, headers: _headers, body: body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isEmpty) {
          return project;
        }
        final data = jsonDecode(response.body);
        return Project.fromMap(data as Map<String, dynamic>);
      } else {
        throw _responseError(
          response.statusCode,
          response.body,
          'Cập nhật dự án',
        );
      }
    } catch (e) {
      _rethrowAsApiException(e, 'Cập nhật dự án');
    }
  }

  /// Validate ảnh, lấy presigned URL rồi stream trực tiếp từ thiết bị lên R2.
  Future<String> uploadImage(
    XFile file,
    String prefix, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileSize = await file.length();
      if (fileSize <= 0) {
        throw const ApiException('Ảnh đã chọn không có dữ liệu.');
      }
      if (fileSize > maxImageBytes) {
        throw const ApiException('Ảnh không được vượt quá 5 MB.');
      }
      final contentType = _imageContentType(file);
      final presignUrl = Uri.parse('$_apiBaseUrl/api/FileUpload/presign');
      final presignResponse = await _withTimeout(
        _client.post(
          presignUrl,
          headers: _headers,
          body: jsonEncode({
            'fileName': file.name,
            'contentType': contentType,
            'fileSize': fileSize,
            'prefix': prefix,
          }),
        ),
        'Chuẩn bị tải ảnh',
      );
      if (presignResponse.statusCode < 200 ||
          presignResponse.statusCode >= 300) {
        throw _responseError(
          presignResponse.statusCode,
          presignResponse.body,
          'Chuẩn bị tải ảnh',
        );
      }

      final data = jsonDecode(presignResponse.body) as Map<String, dynamic>;
      final uploadUrl = (data['uploadUrl'] ?? data['UploadUrl'])?.toString();
      final publicUrl = (data['publicUrl'] ?? data['PublicUrl'])?.toString();
      if (uploadUrl == null ||
          uploadUrl.isEmpty ||
          publicUrl == null ||
          publicUrl.isEmpty) {
        throw const ApiException(
          'Máy chủ trả về thông tin upload không hợp lệ.',
        );
      }

      await _withTimeout(
        _streamFileToR2(
          file,
          Uri.parse(uploadUrl),
          contentType,
          fileSize,
          onProgress,
        ),
        'Tải ảnh lên R2',
        timeout: uploadTimeout,
      );
      onProgress?.call(1);
      return publicUrl;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Không thể tải ảnh lên. Vui lòng thử lại.', cause: e);
    }
  }

  Future<void> _streamFileToR2(
    XFile file,
    Uri uploadUrl,
    String contentType,
    int fileSize,
    void Function(double progress)? onProgress,
  ) async {
    final request = http.StreamedRequest('PUT', uploadUrl)
      ..headers['Content-Type'] = contentType
      ..contentLength = fileSize;
    final responseFuture = _uploadClient.send(request);
    var sentBytes = 0;

    try {
      await for (final chunk in file.openRead()) {
        request.sink.add(chunk);
        sentBytes += chunk.length;
        onProgress?.call(sentBytes / fileSize);
      }
    } finally {
      await request.sink.close();
    }

    final response = await responseFuture;
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseError(response.statusCode, body, 'Tải ảnh lên R2');
    }
  }

  /// Xóa dự án theo id
  Future<bool> deleteProject(int id) async {
    final url = Uri.parse('$baseUrl/Projects($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteProject error: $e');
      return false;
    }
  }

  // ─── ACTS ─────────────────────────────────────────────────────────────────
  // Lưu ý: backend KHÔNG hỗ trợ PUT cho Acts (405) — phải dùng PATCH để cập nhật.

  /// Lấy danh sách Hồi (Acts) theo projectId, sắp xếp theo thứ tự
  Future<List<Act>> getActsForProject(int projectId) async {
    final url = Uri.parse(
      '$baseUrl/Acts?\$filter=ProjectId eq $projectId&\$orderby=SequenceOrder',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final acts = values
            .map((e) => Act.fromMap(e as Map<String, dynamic>))
            .toList();
        return acts.isNotEmpty ? acts : MockData.actsForProject(projectId);
      } else {
        throw Exception('Failed to load acts: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getActsForProject error: $e');
      return MockData.actsForProject(projectId);
    }
  }

  Future<Act?> createAct(Act act) async {
    final url = Uri.parse('$baseUrl/Acts');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(act.toMap()),
      );
      if (response.statusCode == 201) {
        return Act.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw _responseError(response.statusCode, response.body, 'Tạo hồi');
    } catch (e) {
      _rethrowAsApiException(e, 'Tạo hồi');
    }
  }

  Future<bool> updateAct(Act act) async {
    if (act.id == null) return false;
    final url = Uri.parse('$baseUrl/Acts(${act.id})');
    try {
      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(act.toMap()),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      throw _responseError(response.statusCode, response.body, 'Cập nhật hồi');
    } catch (e) {
      _rethrowAsApiException(e, 'Cập nhật hồi');
    }
  }

  Future<bool> deleteAct(int id) async {
    final url = Uri.parse('$baseUrl/Acts($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteAct error: $e');
      return false;
    }
  }

  // ─── LOCATIONS ────────────────────────────────────────────────────────────

  Future<List<Location>> getLocations(int projectId) async {
    final url = Uri.parse(
      '$baseUrl/Locations?\$filter=ProjectId eq $projectId',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final locations = values
            .map((e) => Location.fromMap(e as Map<String, dynamic>))
            .toList();
        return locations.isNotEmpty
            ? locations
            : MockData.locationsForProject(projectId);
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getLocations error: $e');
      return MockData.locationsForProject(projectId);
    }
  }

  Future<Location?> createLocation(Location location) async {
    final url = Uri.parse('$baseUrl/Locations');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(location.toMap()),
      );
      if (response.statusCode == 201) {
        return Location.fromMap(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw _responseError(response.statusCode, response.body, 'Tạo bối cảnh');
    } catch (e) {
      _rethrowAsApiException(e, 'Tạo bối cảnh');
    }
  }

  Future<bool> updateLocation(Location location) async {
    if (location.id == null) return false;
    final url = Uri.parse('$baseUrl/Locations(${location.id})');
    try {
      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(location.toMap()),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      throw _responseError(
        response.statusCode,
        response.body,
        'Cập nhật bối cảnh',
      );
    } catch (e) {
      _rethrowAsApiException(e, 'Cập nhật bối cảnh');
    }
  }

  Future<bool> deleteLocation(int id) async {
    final url = Uri.parse('$baseUrl/Locations($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteLocation error: $e');
      return false;
    }
  }

  // ─── CHARACTERS ───────────────────────────────────────────────────────────
  // Character là entity dùng chung toàn hệ thống trên backend (không có ProjectId).

  Future<List<Character>> getCharacters({int? projectId}) async {
    final filter = projectId != null ? '?\$filter=ProjectId eq $projectId' : '';
    final url = Uri.parse('$baseUrl/Characters$filter');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final characters = values
            .map((e) => Character.fromMap(e as Map<String, dynamic>))
            .toList();
        return characters.isNotEmpty
            ? characters
            : MockData.charactersForProject(projectId);
      } else {
        throw Exception('Failed to load characters: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getCharacters error: $e');
      return MockData.charactersForProject(projectId);
    }
  }

  Future<Character?> createCharacter(Character character) async {
    final url = Uri.parse('$baseUrl/Characters');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(character.toMap()),
      );
      if (response.statusCode == 201) {
        return Character.fromMap(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw _responseError(response.statusCode, response.body, 'Tạo nhân vật');
    } catch (e) {
      _rethrowAsApiException(e, 'Tạo nhân vật');
    }
  }

  Future<bool> updateCharacter(Character character) async {
    if (character.id == null) return false;
    final url = Uri.parse('$baseUrl/Characters(${character.id})');
    try {
      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode(character.toMap()),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      throw _responseError(
        response.statusCode,
        response.body,
        'Cập nhật nhân vật',
      );
    } catch (e) {
      _rethrowAsApiException(e, 'Cập nhật nhân vật');
    }
  }

  Future<bool> deleteCharacter(int id) async {
    final url = Uri.parse('$baseUrl/Characters($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteCharacter error: $e');
      return false;
    }
  }

  // ─── SCENES ───────────────────────────────────────────────────────────────
  // Lưu ý: backend không hỗ trợ PUT cho Scenes (405), phải dùng PATCH.
  // Lưu ý: trường `sceneCharacters` lồng trong body POST/PATCH chỉ CỘNG THÊM
  // liên kết nhân vật, KHÔNG thay thế/xoá liên kết cũ (đã verify trực tiếp
  // với server) — vì backend không có endpoint xoá SceneCharacter, muốn đổi
  // toàn bộ danh sách nhân vật của 1 cảnh phải xoá cảnh cũ và tạo cảnh mới.

  Scene _sceneFromJson(Map<String, dynamic> e) {
    Location? loc;
    if (e['Location'] != null) {
      loc = Location.fromMap(e['Location'] as Map<String, dynamic>);
    }

    final List<Character> chars = [];
    if (e['SceneCharacters'] != null) {
      for (var sc in e['SceneCharacters']) {
        if (sc['Character'] != null) {
          chars.add(Character.fromMap(sc['Character'] as Map<String, dynamic>));
        }
      }
    }

    final sNum = (e['SceneNumber']?.toString() ?? '').trim().toUpperCase();

    final String dbSetting =
        e['Setting'] as String? ?? loc?.setting.dbValue ?? 'INT';
    final String dbTime =
        e['Time'] as String? ?? loc?.timeOfDay.dbValue ?? 'DAY';
    final setting = LocationSettingExt.fromDb(dbSetting);
    final timeOfDay = SceneTimeExt.fromDb(dbTime);

    return Scene(
      id: e['Id'],
      actId: e['ActId'],
      locationId: e['LocationId'],
      sceneNumber: sNum,
      title: e['Title'] as String? ?? '',
      summary: e['Summary'] as String?,
      status: SceneStatusExt.fromDb(e['Status'] as String? ?? 'TODO'),
      setting: setting,
      timeOfDay: timeOfDay,
      location: loc,
      characters: chars,
    );
  }

  /// Lấy danh sách cảnh quay theo projectId (dùng cho Production Planner & Detail screens)
  Future<List<Scene>> getScenesForProject(int projectId) async {
    final url = Uri.parse(
      '$baseUrl/Scenes?\$expand=Location,SceneCharacters(\$expand=Character)&\$filter=Act/ProjectId eq $projectId',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final scenes = values
            .map((e) => _sceneFromJson(e as Map<String, dynamic>))
            .toList();
        return scenes.isNotEmpty
            ? scenes
            : MockData.scenesForProject(projectId);
      } else {
        throw Exception('Failed to load scenes: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getScenesForProject error: $e');
      return MockData.scenesForProject(projectId);
    }
  }

  /// Lấy danh sách cảnh quay theo actId (dùng cho Storyboard)
  Future<List<Scene>> getScenesForAct(int actId) async {
    final url = Uri.parse(
      '$baseUrl/Scenes?\$expand=Location,SceneCharacters(\$expand=Character)&\$filter=ActId eq $actId&\$orderby=SceneNumber',
    );
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final scenes = values
            .map((e) => _sceneFromJson(e as Map<String, dynamic>))
            .toList();
        return scenes.isNotEmpty ? scenes : MockData.scenesForAct(actId);
      } else {
        throw Exception('Failed to load scenes: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getScenesForAct error: $e');
      return MockData.scenesForAct(actId);
    }
  }

  Map<String, dynamic> _sceneBody(Scene scene, List<int> characterIds) => {
    'ActId': scene.actId,
    'LocationId': scene.locationId,
    'SceneNumber': scene.sceneNumber.toString(),
    'Title': scene.title,
    'Summary': scene.summary,
    'Status': scene.status.dbValue,
    'Setting': scene.setting.dbValue,
    'Time': scene.timeOfDay.dbValue,
    'SceneCharacters': characterIds.map((id) => {'CharacterId': id}).toList(),
  };

  Future<Scene?> createScene(Scene scene, List<int> characterIds) async {
    final url = Uri.parse('$baseUrl/Scenes');
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(_sceneBody(scene, characterIds)),
      );
      if (response.statusCode == 201) {
        final createdJson = jsonDecode(response.body) as Map<String, dynamic>;
        final createdId = createdJson['Id'] ?? createdJson['id'];
        return scene.copyWith(
          id: createdId is int ? createdId : int.tryParse(createdId.toString()),
        );
      }
      throw _responseError(response.statusCode, response.body, 'Tạo cảnh');
    } catch (e) {
      _rethrowAsApiException(e, 'Tạo cảnh');
    }
  }

  Future<Scene?> updateScene(
    Scene scene,
    List<int> characterIds, {
    required List<int> previousCharacterIds,
  }) async {
    if (scene.id == null) return null;
    final url = Uri.parse('$baseUrl/Scenes(${scene.id})');
    try {
      final response = await _client.patch(
        url,
        headers: _headers,
        body: jsonEncode({
          'actId': scene.actId,
          'locationId': scene.locationId,
          'sceneNumber': scene.sceneNumber.toString(),
          'title': scene.title,
          'summary': scene.summary,
          'status': scene.status.dbValue,
          'setting': scene.setting.dbValue,
          'time': scene.timeOfDay.dbValue,
          'sceneCharacters': characterIds
              .map((id) => {'characterId': id})
              .toList(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        final getUrl = Uri.parse(
          '$baseUrl/Scenes(${scene.id})?\$expand=Location,SceneCharacters(\$expand=Character)',
        );
        final getRes = await _client.get(getUrl, headers: _headers);
        if (getRes.statusCode == 200) {
          return _sceneFromJson(
            jsonDecode(getRes.body) as Map<String, dynamic>,
          );
        }
        return scene;
      }
      throw _responseError(response.statusCode, response.body, 'Cập nhật cảnh');
    } catch (e) {
      _rethrowAsApiException(e, 'Cập nhật cảnh');
    }
  }

  Future<bool> deleteScene(int id) async {
    final url = Uri.parse('$baseUrl/Scenes($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteScene error: $e');
      return false;
    }
  }

  Future<List<Act>> getDeletedActs(int projectId) async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse('$apiBaseUrl/api/Acts/Deleted/$projectId');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final acts = list.map((e) => Act.fromMap(e)).toList();
        return acts.isNotEmpty
            ? acts
            : MockData.deletedActsForProject(projectId);
      }
      return MockData.deletedActsForProject(projectId);
    } catch (e) {
      print('ApiService.getDeletedActs error: $e');
      return MockData.deletedActsForProject(projectId);
    }
  }

  Future<List<Scene>> getDeletedScenes(int projectId) async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse('$apiBaseUrl/api/Scenes/Deleted/$projectId');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final scenes = list.map((e) => _sceneFromJson(e)).toList();
        return scenes.isNotEmpty
            ? scenes
            : MockData.deletedScenesForProject(projectId);
      }
      return MockData.deletedScenesForProject(projectId);
    } catch (e) {
      print('ApiService.getDeletedScenes error: $e');
      return MockData.deletedScenesForProject(projectId);
    }
  }

  Future<bool> restoreAct(int id) async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse('$apiBaseUrl/api/Acts/Restore/$id');
    try {
      final response = await _client.post(url, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService.restoreAct error: $e');
      return false;
    }
  }

  Future<bool> restoreScene(int id) async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse('$apiBaseUrl/api/Scenes/Restore/$id');
    try {
      final response = await _client.post(url, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService.restoreScene error: $e');
      return false;
    }
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả thông báo từ database
  Future<List<NotificationModel>> getNotifications() async {
    final url = Uri.parse('$baseUrl/Notifications?\$orderby=Timestamp desc');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];
        final notifications = values
            .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
            .toList();
        return notifications.isNotEmpty
            ? notifications
            : MockData.notificationsCopy();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getNotifications error: $e');
      return MockData.notificationsCopy();
    }
  }

  /// Tạo thông báo mới và lưu vào database
  Future<NotificationModel?> createNotification(
    NotificationModel notification,
  ) async {
    final url = Uri.parse('$baseUrl/Notifications');
    try {
      final body = jsonEncode(notification.toMap());
      final response = await _client.post(url, headers: _headers, body: body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return NotificationModel.fromMap(data);
      } else {
        print(
          'ApiService.createNotification failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('ApiService.createNotification error: $e');
      return null;
    }
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<bool> markNotificationAsRead(int id) async {
    final url = Uri.parse('$baseUrl/Notifications($id)');
    try {
      final body = jsonEncode({'IsRead': true});
      final response = await _client.patch(url, headers: _headers, body: body);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('ApiService.markNotificationAsRead error: $e');
      return false;
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  Future<bool> markAllNotificationsAsRead() async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse('$apiBaseUrl/api/Notifications/MarkAllAsRead');
    try {
      final response = await _client.post(url, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService.markAllNotificationsAsRead error: $e');
      return false;
    }
  }

  /// Đánh dấu thông báo của một dự án là đã đọc
  Future<bool> markProjectNotificationsAsRead(int projectId) async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse(
      '$apiBaseUrl/api/Notifications/MarkProjectAsRead/$projectId',
    );
    try {
      final response = await _client.post(url, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      print('ApiService.markProjectNotificationsAsRead error: $e');
      return false;
    }
  }
}
