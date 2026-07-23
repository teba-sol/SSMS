import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eiojnxxfzgrgnupaguwf.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpb2pueHhmemdyZ251cGFndXdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyMjIwMDcsImV4cCI6MjA5OTc5ODAwN30.Hc6I0Q2PS5m7JPaHzqPbBHtII4e6_K2UAoUx-dDUFjI',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static Session? get currentSession => auth.currentSession;
}
