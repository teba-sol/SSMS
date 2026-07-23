import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase/supabase_client.dart';

/// Generic base for all Supabase data access
class SupabaseService {
  SupabaseClient get client => AppSupabase.client;
  String? get currentUserId => AppSupabase.currentUser?.id;
}
