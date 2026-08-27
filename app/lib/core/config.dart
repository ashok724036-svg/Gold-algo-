import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static bool isSupabaseConfigured = false;

  static Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anonKey.isEmpty) return;

    await Supabase.initialize(url: url, anonKey: anonKey);
    isSupabaseConfigured = true;
  }

  static SupabaseClient? get supabase =>
      isSupabaseConfigured ? Supabase.instance.client : null;
}