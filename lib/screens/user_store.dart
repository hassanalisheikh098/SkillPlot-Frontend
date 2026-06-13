import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class UserStore {
  static SupabaseClient get _client => Supabase.instance.client;

  // Sign up new user via Supabase Auth
  static Future<bool> addUser(String email, String password) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      return res.user != null;
    } catch (e) {
      return false;
    }
  }

  // Login via Supabase Auth - saves user_id to SharedPrefs for other screens
  static Future<bool> validateUser(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session != null) {
        final userId = res.user?.id ?? '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('user_email', email);
        
        // Auto-load resume profile from backend
        if (userId.isNotEmpty) {
          try {
            final profile = await ApiService.getResumeProfile(userId);
            if (profile['status'] != 'not_found') {
              final skills = profile['extracted_skills'] as List? ?? [];
              await prefs.setString('extracted_skills', skills.cast<String>().join(','));
              await prefs.setString('target_role', profile['target_role'] ?? '');
              await prefs.setString('user_name', profile['full_name'] ?? '');
              await prefs.setString('experience_summary', profile['experience_summary'] ?? '');
              await prefs.setString('education_summary', profile['education_summary'] ?? '');
              await prefs.setString('resume_filename', profile['resume_filename'] ?? '');
              await prefs.setString('has_resume', 'true');
            }
          } catch (_) {
            // Network error - fail silently, user can still use app
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout and clear local data
  static Future<void> logout() async {
    await _client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    // Clear all user-related preferences
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('extracted_skills');
    await prefs.remove('target_role');
    await prefs.remove('experience_summary');
    await prefs.remove('education_summary');
    await prefs.remove('resume_filename');
    await prefs.remove('has_resume');
    await prefs.remove('missing_skills');
  }

  // Not used anymore but kept so nothing breaks
  static Future<void> updatePassword(String email, String password) async {}
  static Future<bool> userExists(String email) async => false;
  static Future<Map<String, String>> loadUsers() async => {};

  // Convenience getters
  static bool get isLoggedIn => _client.auth.currentUser != null;
  static String? get currentUserId => _client.auth.currentUser?.id;
  static String? get currentUserEmail => _client.auth.currentUser?.email;
  
  static Future<String?> get currentUserName async {
    final session = _client.auth.currentSession;
    if (session != null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name');
    }
    return null;
  }
}
