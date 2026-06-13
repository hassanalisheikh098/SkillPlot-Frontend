import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  static String get apiBaseUrl {
    if (isProduction) {
      return const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://skillpilot-api.onrender.com/api/v1');
    }
    // Android emulator default on mobile, localhost on web
    return kIsWeb ? 'http://localhost:8000/api/v1' : 'http://10.0.2.2:8000/api/v1';
  }

  static String get supabaseUrl {
    return const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://gmrayhnwhivcdvzhixdj.supabase.co');
  }

  static String get supabaseAnonKey {
    return const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdtcmF5aG53aGl2Y2R2emhpeGRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2NzI4OTgsImV4cCI6MjA5NjI0ODg5OH0.z8Ktu87dqGfXLDLKb6NauOpFHLN6bKoELLjVg1k6wog');
  }
}