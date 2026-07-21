import 'package:flutter/foundation.dart';
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

class ApiService {
  static const String baseUrl =
      'https://cinex-api.onrender.com/odata'; // local test
  static String? token;
  static final http.Client _client = http.Client();

  static Map<String, String> get _headers {
    final map = {'Content-Type': 'application/json'};
    if (token != null) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
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
        return values
            .map((e) => Project.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getProjects error: $e');
      return [];
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
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.createProject error: $e');
      return null;
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
        throw Exception('Failed to update project: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.updateProject error: $e');
      return null;
    }
  }

  /// Tải tệp tin lên Cloudflare R2 thông qua API Upload (Hỗ trợ cả Mobile & Web)
  Future<String?> uploadFile(String filePath, String prefix) async {
    final base = baseUrl.replaceAll('/odata', '');
    final uploadUrl = Uri.parse('$base/api/FileUpload/upload');
    try {
      final bytes = await XFile(filePath).readAsBytes();
      final filename = filePath.split('/').last.split('\\').last;

      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['prefix'] = prefix
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename.isNotEmpty ? filename : 'upload.png',
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['Url'] ?? data['url']) as String?;
      } else {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.uploadFile error: $e');
      return null;
    }
  }

  /// Xóa dự án theo id
  Future<bool> deleteProject(int id) async {
    final url = Uri.parse('$baseUrl/Projects($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.deleteProject error: $e');
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
        return values
            .map((e) => Act.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load acts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getActsForProject error: $e');
      return [];
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
      throw Exception('Failed to create act: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService.createAct error: $e');
      return null;
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
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.updateAct error: $e');
      return false;
    }
  }

  Future<bool> deleteAct(int id) async {
    final url = Uri.parse('$baseUrl/Acts($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.deleteAct error: $e');
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
        return values
            .map((e) => Location.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getLocations error: $e');
      return [];
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
      throw Exception('Failed to create location: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService.createLocation error: $e');
      return null;
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
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.updateLocation error: $e');
      return false;
    }
  }

  Future<bool> deleteLocation(int id) async {
    final url = Uri.parse('$baseUrl/Locations($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.deleteLocation error: $e');
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
        return values
            .map((e) => Character.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load characters: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getCharacters error: $e');
      return [];
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
      throw Exception('Failed to create character: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService.createCharacter error: $e');
      return null;
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
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.updateCharacter error: $e');
      return false;
    }
  }

  Future<bool> deleteCharacter(int id) async {
    final url = Uri.parse('$baseUrl/Characters($id)');
    try {
      final response = await _client.delete(url, headers: _headers);
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('ApiService.deleteCharacter error: $e');
      return false;
    }
  }

  // ─── SCENES ───────────────────────────────────────────────────────────────

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

    int sNum = 0;
    if (e['SceneNumber'] != null) {
      sNum =
          int.tryParse(
            e['SceneNumber'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }

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
        return values
            .map((e) => _sceneFromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load scenes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getScenesForProject error: $e');
      return [];
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
        return values
            .map((e) => _sceneFromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load scenes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApiService.getScenesForAct error: $e');
      return [];
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
        final intId = createdId is int
            ? createdId
            : int.tryParse(createdId.toString());

        // Fetch full scene with expanded characters
        if (intId != null) {
          final getUrl = Uri.parse(
            '$baseUrl/Scenes($intId)?\$expand=Location,SceneCharacters(\$expand=Character)',
          );
          final getRes = await _client.get(getUrl, headers: _headers);
          if (getRes.statusCode == 200) {
            return _sceneFromJson(
              jsonDecode(getRes.body) as Map<String, dynamic>,
            );
          }
        }
        return scene.copyWith(id: intId);
      }
      throw Exception('Failed to create scene: ${response.statusCode}');
    } catch (e) {
      print('ApiService.createScene error: $e');
      return null;
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
        body: jsonEncode(_sceneBody(scene, characterIds)),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Fetch full scene with expanded characters after update
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
      throw Exception('Failed to update scene: ${response.statusCode}');
    } catch (e) {
      print('ApiService.updateScene error: $e');
      return null;
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
        return list.map((e) => Act.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      print('ApiService.getDeletedActs error: $e');
      return [];
    }
  }

  Future<List<Scene>> getDeletedScenes(int projectId) async {
    final apiBaseUrl = baseUrl.replaceAll('/odata', '');
    final url = Uri.parse('$apiBaseUrl/api/Scenes/Deleted/$projectId');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => _sceneFromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('ApiService.getDeletedScenes error: $e');
      return [];
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
        return values
            .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getNotifications error: $e');
      return [];
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
