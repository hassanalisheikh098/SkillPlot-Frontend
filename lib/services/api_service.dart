import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  // For local development use http://127.0.0.1:8000/api/v1
  // For Android emulator use http://10.0.2.2:8000/api/v1
  // For physical device use your machine's local IP e.g. http://192.168.1.x:8000/api/v1
  // For production use your Render URL e.g. https://skillpilot-api.onrender.com/api/v1
  static String get baseUrl => AppConfig.apiBaseUrl;

  // -- Resume Upload --------------------------------------------------------
  static Future<dynamic> uploadResume({
    File? file,
    Uint8List? bytes,
    required String filename,
    required String userId,
  }) async {
    final uri = Uri.parse("$baseUrl/resume/upload-resume");
    final req = http.MultipartRequest('POST', uri);
    if (bytes != null) {
      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    } else if (file != null) {
      req.files.add(await http.MultipartFile.fromPath('file', file.path, filename: filename));
    } else {
      throw ArgumentError('Either file or bytes must be provided');
    }
    if (userId.isNotEmpty) req.fields['user_id'] = userId;
    final streamed = await req.send().timeout(Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();
    log("UPLOAD RESUME: ${streamed.statusCode} $body");
    if (streamed.statusCode == 200) return jsonDecode(body);
    throw Exception("Resume upload failed: ${streamed.statusCode}");
  }

  // -- Job Roles List -------------------------------------------------------
  static Future<dynamic> getJobRoles() async {
    final res = await http
        .get(Uri.parse("$baseUrl/jobs/job-roles"))
        .timeout(Duration(seconds: 10));
    log("JOB ROLES: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load job roles");
  }

  // -- Skill Gap Analysis ---------------------------------------------------
  static Future<dynamic> analyzeGap(
    String targetRole,
    List<String> userSkills,
  ) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/jobs/analyze-gap"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "target_role": targetRole,
            "user_skills": userSkills,
          }),
        )
        .timeout(Duration(seconds: 15));
    log("ANALYZE GAP: ${res.statusCode} ${res.body}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gap analysis failed: ${res.statusCode}");
  }

  // -- Course Recommendations -----------------------------------------------
  static Future<dynamic> getRecommendations(List<String> missingSkills) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/jobs/recommend-courses"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"missing_skills": missingSkills}),
        )
        .timeout(Duration(seconds: 15));
    log("COURSES: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Course recommendations failed");
  }

  // -- Job Alerts -----------------------------------------------------------
  static Future<dynamic> getJobs() async {
    final uri = Uri.parse("$baseUrl/jobs/jobs");
    final res = await http.get(uri).timeout(Duration(seconds: 15));
    log("JOBS: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load jobs");
  }

  // -- Career Chatbot -------------------------------------------------------
  static Future<dynamic> sendChatMessage({
    required String message,
    String? targetRole,
    List<String>? missingSkills,
    List? userSkills,
    String? userName,
    String? experienceSummary,
    String? educationSummary,
    List<Map<String, dynamic>> history = const [],
  }) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/chat/chat"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "message": message,
            "target_role": targetRole,
            "missing_skills": missingSkills ?? [],
            "user_skills": userSkills ?? [],
            "user_name": userName,
            "experience_summary": experienceSummary,
            "education_summary": educationSummary,
            "history": history,
          }),
        )
        .timeout(Duration(seconds: 20));
    log("CHAT: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Chat request failed");
  }

  // -- Career Roadmap -------------------------------------------------------
  static Future<dynamic> generateRoadmap(
    String targetRole,
    List<String> missingSkills,
  ) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/roadmap/generate"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "target_role": targetRole,
            "missing_skills": missingSkills,
          }),
        )
        .timeout(Duration(seconds: 30));
    log("ROADMAP: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Roadmap generation failed");
  }

  // -- Award XP -------------------------------------------------------------
  static Future<dynamic> awardXP(String userId, String action) async {
    final res = await http
        .post(
          Uri.parse("$baseUrl/gamification/award-xp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId, "action": action}),
        )
        .timeout(Duration(seconds: 10));
    log("XP: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("XP award failed");
  }

  // -- Get Progress ---------------------------------------------------------
  static Future<dynamic> getProgress(String userId) async {
    final res = await http
        .get(Uri.parse("$baseUrl/gamification/progress/$userId"))
        .timeout(Duration(seconds: 10));
    log("PROGRESS: ${res.statusCode}");
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Progress load failed");
  }

  // -- Get Resume Profile ---------------------------------------------------
  static Future<dynamic> getResumeProfile(String userId) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/resume/profile/$userId"))
          .timeout(Duration(seconds: 10));
      log("GET_RESUME_PROFILE: ${res.statusCode}");
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {"status": "not_found"};
    } catch (e) {
      log("GET_RESUME_PROFILE ERROR: $e");
      return {"status": "not_found"};
    }
  }

  // -- Save User Profile ----------------------------------------------------
  static Future<bool> saveUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final res = await http
          .patch(
            Uri.parse("$baseUrl/users/profile/$userId"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: 10));
      log("SAVE_USER_PROFILE: ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      log("SAVE_USER_PROFILE ERROR: $e");
      return false;
    }
  }

  // -- Save Chat History ----------------------------------------------------
  static Future<bool> saveChatHistory(String userId, List<Map<String, dynamic>> messages) async {
    try {
      final res = await http
          .post(
            Uri.parse("$baseUrl/chat/save-history"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"user_id": userId, "messages": messages}),
          )
          .timeout(Duration(seconds: 10));
      log("SAVE_CHAT_HISTORY: ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      log("SAVE_CHAT_HISTORY ERROR: $e");
      return false;
    }
  }

  // -- Load Chat History ----------------------------------------------------
  static Future<List<Map<String, dynamic>>> loadChatHistory(String userId) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/chat/history/$userId"))
          .timeout(Duration(seconds: 10));
      log("LOAD_CHAT_HISTORY: ${res.statusCode}");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final messages = data['history'] as List? ?? [];
        return messages.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      log("LOAD_CHAT_HISTORY ERROR: $e");
      return [];
    }
  }

  // -- Get XP History -------------------------------------------------------
  static Future<dynamic> getXpHistory(String userId) async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/gamification/xp-history/$userId"))
          .timeout(Duration(seconds: 10));
      log("GET_XP_HISTORY: ${res.statusCode}");
      if (res.statusCode == 200) return jsonDecode(res.body);
      return {"history": []};
    } catch (e) {
      log("GET_XP_HISTORY ERROR: $e");
      return {"history": []};
    }
  }

  // -- Health Check ---------------------------------------------------------
  static Future<bool> isServerReachable() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(Duration(seconds: 5));
      log("SERVER_REACHABLE: ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      log("SERVER_REACHABLE ERROR: $e");
      return false;
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse("http://127.0.0.1:8000/health"))
          .timeout(Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}