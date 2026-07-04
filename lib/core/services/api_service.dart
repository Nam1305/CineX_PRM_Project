import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cinex_application/features/acts/data/models/act.dart';
import 'package:cinex_application/features/projects/data/models/project.dart';
import 'package:cinex_application/features/scenes/data/models/scene.dart';
import 'package:cinex_application/features/locations/data/models/location.dart';
import 'package:cinex_application/features/characters/data/models/character.dart';
import 'package:cinex_application/core/utils/enums.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:5274/odata'; // local test
  static const String baseUrl =
      'https://cinex-api.onrender.com/odata'; // production

  static const _headers = {'Content-Type': 'application/json'};

  // ─── PROJECTS ─────────────────────────────────────────────────────────────

  /// Lấy danh sách tất cả dự án từ server
  Future<List<Project>> getProjects() async {
    final url = Uri.parse('$baseUrl/Projects');
    try {
      final response = await http.get(url);
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
      print('ApiService.getProjects error: $e');
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
        'StartDate': project.startDate,
        'PosterUrl': project.posterUrl,
      });
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Project.fromMap(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create project: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.createProject error: $e');
      return null;
    }
  }

  /// Cập nhật dự án theo id
  Future<Project?> updateProject(Project project) async {
    if (project.id == null) return null;
    final url = Uri.parse('$baseUrl/Projects(${project.id})');
    try {
      final body = jsonEncode({
        'Title': project.title,
        'Genre': project.genre,
        'Description': project.description,
        'StartDate': project.startDate,
        'PosterUrl': project.posterUrl,
      });
      final response = await http.put(url, headers: _headers, body: body);
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
      print('ApiService.updateProject error: $e');
      return null;
    }
  }

  /// Xóa dự án theo id
  Future<bool> deleteProject(int id) async {
    final url = Uri.parse('$baseUrl/Projects($id)');
    try {
      final response = await http.delete(url);
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
      final response = await http.get(url);
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
      print('ApiService.getActsForProject error: $e');
      return [];
    }
  }

  Future<Act?> createAct(Act act) async {
    final url = Uri.parse('$baseUrl/Acts');
    try {
      final response =
          await http.post(url, headers: _headers, body: jsonEncode(act.toMap()));
      if (response.statusCode == 201) {
        return Act.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to create act: ${response.statusCode}');
    } catch (e) {
      print('ApiService.createAct error: $e');
      return null;
    }
  }

  Future<bool> updateAct(Act act) async {
    if (act.id == null) return false;
    final url = Uri.parse('$baseUrl/Acts(${act.id})');
    try {
      final response =
          await http.patch(url, headers: _headers, body: jsonEncode(act.toMap()));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ApiService.updateAct error: $e');
      return false;
    }
  }

  Future<bool> deleteAct(int id) async {
    final url = Uri.parse('$baseUrl/Acts($id)');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteAct error: $e');
      return false;
    }
  }

  // ─── LOCATIONS ────────────────────────────────────────────────────────────
  // Location là entity dùng chung toàn hệ thống trên backend (không có ProjectId).

  Future<List<Location>> getLocations() async {
    final url = Uri.parse('$baseUrl/Locations');
    try {
      final response = await http.get(url);
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
      print('ApiService.getLocations error: $e');
      return [];
    }
  }

  Future<Location?> createLocation(Location location) async {
    final url = Uri.parse('$baseUrl/Locations');
    try {
      final response = await http.post(url,
          headers: _headers, body: jsonEncode(location.toMap()));
      if (response.statusCode == 201) {
        return Location.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to create location: ${response.statusCode}');
    } catch (e) {
      print('ApiService.createLocation error: $e');
      return null;
    }
  }

  Future<bool> updateLocation(Location location) async {
    if (location.id == null) return false;
    final url = Uri.parse('$baseUrl/Locations(${location.id})');
    try {
      final response = await http.patch(url,
          headers: _headers, body: jsonEncode(location.toMap()));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ApiService.updateLocation error: $e');
      return false;
    }
  }

  Future<bool> deleteLocation(int id) async {
    final url = Uri.parse('$baseUrl/Locations($id)');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteLocation error: $e');
      return false;
    }
  }

  // ─── CHARACTERS ───────────────────────────────────────────────────────────
  // Character là entity dùng chung toàn hệ thống trên backend (không có ProjectId).

  Future<List<Character>> getCharacters() async {
    final url = Uri.parse('$baseUrl/Characters');
    try {
      final response = await http.get(url);
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
      print('ApiService.getCharacters error: $e');
      return [];
    }
  }

  Future<Character?> createCharacter(Character character) async {
    final url = Uri.parse('$baseUrl/Characters');
    try {
      final response = await http.post(url,
          headers: _headers, body: jsonEncode(character.toMap()));
      if (response.statusCode == 201) {
        return Character.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to create character: ${response.statusCode}');
    } catch (e) {
      print('ApiService.createCharacter error: $e');
      return null;
    }
  }

  Future<bool> updateCharacter(Character character) async {
    if (character.id == null) return false;
    final url = Uri.parse('$baseUrl/Characters(${character.id})');
    try {
      final response = await http.patch(url,
          headers: _headers, body: jsonEncode(character.toMap()));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ApiService.updateCharacter error: $e');
      return false;
    }
  }

  Future<bool> deleteCharacter(int id) async {
    final url = Uri.parse('$baseUrl/Characters($id)');
    try {
      final response = await http.delete(url);
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

    int sNum = 0;
    if (e['SceneNumber'] != null) {
      sNum = int.tryParse(
            e['SceneNumber'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }

    return Scene(
      id: e['Id'],
      actId: e['ActId'],
      locationId: e['LocationId'],
      sceneNumber: sNum,
      title: e['Title'] as String? ?? '',
      summary: e['Summary'] as String?,
      status: SceneStatusExt.fromDb(e['Status'] as String? ?? 'TODO'),
      location: loc,
      characters: chars,
    );
  }

  /// Lấy danh sách cảnh quay theo projectId (dùng cho Production Planner)
  Future<List<Scene>> getScenesForProject(int projectId) async {
    final url = Uri.parse(
      '$baseUrl/Scenes?\$expand=Location,SceneCharacters(\$expand=Character)&\$filter=Act/ProjectId eq $projectId',
    );
    try {
      final response = await http.get(url);
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
      print('ApiService.getScenesForProject error: $e');
      return [];
    }
  }

  /// Lấy danh sách cảnh quay theo actId (dùng cho Storyboard)
  Future<List<Scene>> getScenesForAct(int actId) async {
    final url = Uri.parse(
      '$baseUrl/Scenes?\$expand=Location,SceneCharacters(\$expand=Character)&\$filter=ActId eq $actId&\$orderby=SceneNumber',
    );
    try {
      final response = await http.get(url);
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
      print('ApiService.getScenesForAct error: $e');
      return [];
    }
  }

  Map<String, dynamic> _sceneBody(Scene scene, List<int> characterIds) => {
        'actId': scene.actId,
        'locationId': scene.locationId,
        'sceneNumber': scene.sceneNumber.toString(),
        'title': scene.title,
        'summary': scene.summary,
        'status': scene.status.dbValue,
        'sceneCharacters': characterIds.map((id) => {'characterId': id}).toList(),
      };

  Future<Scene?> createScene(Scene scene, List<int> characterIds) async {
    final url = Uri.parse('$baseUrl/Scenes');
    try {
      final response = await http.post(url,
          headers: _headers, body: jsonEncode(_sceneBody(scene, characterIds)));
      if (response.statusCode == 201) {
        return _sceneFromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to create scene: ${response.statusCode}');
    } catch (e) {
      print('ApiService.createScene error: $e');
      return null;
    }
  }

  /// Cập nhật cảnh quay. Vì backend chỉ hỗ trợ CỘNG THÊM sceneCharacters (không
  /// xoá được), nếu danh sách nhân vật mong muốn khác danh sách hiện có thì
  /// phải xoá cảnh cũ và tạo lại cảnh mới với đầy đủ nhân vật (sẽ có Id mới).
  Future<Scene?> updateScene(
    Scene scene,
    List<int> characterIds, {
    required List<int> previousCharacterIds,
  }) async {
    final sameCharacters = Set<int>.from(characterIds).length == previousCharacterIds.length &&
        Set<int>.from(characterIds).containsAll(previousCharacterIds);

    if (!sameCharacters) {
      if (scene.id != null) await deleteScene(scene.id!);
      return createScene(scene, characterIds);
    }

    if (scene.id == null) return null;
    final url = Uri.parse('$baseUrl/Scenes(${scene.id})');
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({
          'actId': scene.actId,
          'locationId': scene.locationId,
          'sceneNumber': scene.sceneNumber.toString(),
          'title': scene.title,
          'summary': scene.summary,
          'status': scene.status.dbValue,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
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
      final response = await http.delete(url);
      return response.statusCode == 204;
    } catch (e) {
      print('ApiService.deleteScene error: $e');
      return false;
    }
  }
}
