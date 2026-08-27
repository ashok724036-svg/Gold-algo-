import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static bool isSupabaseConfigured = false;
  static String? initializationError;

  static Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anonKey.isEmpty) return;

    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      isSupabaseConfigured = true;
    } catch (_) {
      initializationError = 'Supabase configuration is invalid.';
    }
  }

  static SupabaseClient? get supabase =>
      isSupabaseConfigured ? Supabase.instance.client : null;
}