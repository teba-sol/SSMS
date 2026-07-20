import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static Session? get currentSession => auth.currentSession;
}
