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
  static const String baseUrl = 'https://cinex-api.onrender.com/odata'; // production

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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
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

  /// Lấy danh sách Hồi (Acts) theo projectId, sắp xếp theo thứ tự
  Future<List<Act>> getActsForProject(int projectId) async {
    final url = Uri.parse(
        '$baseUrl/Acts?\$filter=ProjectId eq $projectId&\$orderby=SequenceOrder');
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

  // ─── SCENES ───────────────────────────────────────────────────────────────

  /// Lấy danh sách cảnh quay theo projectId
  Future<List<Scene>> getScenesForProject(int projectId) async {
    final url = Uri.parse(
        '$baseUrl/Scenes?\$expand=Location,SceneCharacters(\$expand=Character)&\$filter=Act/ProjectId eq $projectId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> values = data['value'] ?? [];

        return values.map((e) {
          // Parse Location
          Location? loc;
          if (e['Location'] != null) {
            loc = Location.fromMap({
              'id': e['Location']['Id'],
              'project_id': projectId,
              'name': e['Location']['Name'],
              'setting': e['Location']['Setting'],
              'time_of_day': e['Location']['Time'],
              'notes': e['Location']['Notes'],
            });
          }

          // Parse Characters
          final List<Character> chars = [];
          if (e['SceneCharacters'] != null) {
            for (var sc in e['SceneCharacters']) {
              if (sc['Character'] != null) {
                final c = sc['Character'];
                chars.add(Character.fromMap({
                  'id': c['Id'],
                  'project_id': projectId,
                  'name': c['Name'],
                  'role_type': c['Role'],
                  'description': c['Description'],
                  'image_path': c['ImageUrl'],
                }));
              }
            }
          }

          // Parse SceneNumber: backend dùng String, flutter dùng int
          int sNum = 0;
          if (e['SceneNumber'] != null) {
            sNum = int.tryParse(
                    e['SceneNumber'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
          }

          return Scene(
            id: e['Id'],
            actId: e['ActId'],
            locationId: e['LocationId'],
            sceneNumber: sNum,
            summary: e['Summary'] ?? e['Title'],
            status: SceneStatusExt.fromDb(e['Status'] ?? 'TODO'),
            location: loc,
            characters: chars,
          );
        }).toList();
      } else {
        throw Exception('Failed to load scenes: ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService.getScenesForProject error: $e');
      return [];
    }
  }
}
