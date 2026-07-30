import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_client.dart';
import '../../supabase/supabase_tables.dart';

final realtimeSyncProvider = NotifierProvider<RealtimeSyncNotifier, int>(
  RealtimeSyncNotifier.new,
);

class RealtimeSyncNotifier extends Notifier<int> {
  static const _tables = [
    AppTables.academicYears,
    AppTables.classes,
    AppTables.subjects,
    AppTables.teachers,
    AppTables.students,
    AppTables.teacherAssignments,
    AppTables.studentEnrollments,
    AppTables.parentStudents,
    AppTables.attendance,
    AppTables.results,
    AppTables.activities,
    AppTables.announcements,
    AppTables.announcementReads,
    AppTables.conversations,
    AppTables.messages,
    AppTables.notifications,
  ];

  @override
  int build() {
    final channels = <RealtimeChannel>[];

    for (final table in _tables) {
      final channel = AppSupabase.client.channel('sync:public:$table')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (_) => state++,
        )
        ..subscribe();
      channels.add(channel);
    }

    ref.onDispose(() {
      for (final channel in channels) {
        AppSupabase.client.removeChannel(channel);
      }
    });

    return 0;
  }
}
