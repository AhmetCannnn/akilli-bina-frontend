import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:belediye_otomasyon/core/router/app_router.dart';
import 'package:belediye_otomasyon/theme/theme_provider.dart';
import 'package:belediye_otomasyon/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Optional: load .env if asset olarak paketlendiyse; yoksa sessizce geç
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Web veya asset yoksa: dart-define ile geliyorsa sorun değil.
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return FluentApp.router(
      title: 'Akıllı Binalar',
      theme: AppTheme.lightThemeFluent,
      darkTheme: AppTheme.darkThemeFluent,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false, // Fluent UI uygulamalarında genellikle debug banner gizlenir
    );
  }
}

