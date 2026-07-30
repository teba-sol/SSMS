import 'package:flutter/material.dart';
import 'core/theme/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/realtime_sync.dart';
import 'supabase/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: AppSupabase.url,
    anonKey: AppSupabase.anonKey, // ignore: deprecated_member_use
  );

  // Initialize local notifications
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: SSCSApp(),
    ),
  );
}

class SSCSApp extends ConsumerWidget {
  const SSCSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeSyncProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SSCS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeProvider),
      routerConfig: router,
    );
  }
}
