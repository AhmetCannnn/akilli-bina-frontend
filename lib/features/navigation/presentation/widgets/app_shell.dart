import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:belediye_otomasyon/features/home/presentation/widgets/ai_assistant_modal.dart';
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import 'package:belediye_otomasyon/core/realtime/realtime_ws_client.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child, required this.shellContext});

  final Widget child;
  final BuildContext? shellContext;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final authAsync = ref.read(authControllerProvider);
      if (!authAsync.isLoading && !authAsync.hasError) {
        RealtimeWsClient.syncAuth(ref, authAsync.valueOrNull);
      }
    });
  }

  String _roleLabel(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'manager':
        return 'Yonetici';
      case 'user':
        return 'Kullanici';
      default:
        return 'Kullanici';
    }
  }

  String _displayName(Map<String, dynamic>? userData) {
    final fullName = userData?['full_name']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) return fullName;

    final email = userData?['email']?.toString().trim() ?? '';
    if (email.contains('@')) return email.split('@').first;
    if (email.isNotEmpty) return email;

    return 'Kullanici';
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/buildings') ||
        location.startsWith('/building-detail')) return 1;
    if (location.startsWith('/active-issues')) return 2;
    if (location.startsWith('/maintenance-suggestions')) return 3;
    if (location.startsWith('/reports')) return 4;
    if (location.startsWith('/employees')) return 5;
    if (location.startsWith('/settings')) return 8; // footer index
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState?>>(authControllerProvider, (prev, next) {
      if (next.isLoading) {
        return;
      }
      if (next.hasError) {
        RealtimeWsClient.disconnect();
        return;
      }
      RealtimeWsClient.syncAuth(ref, next.valueOrNull);
    });

    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final theme = FluentTheme.of(context);
    final authState = ref.watch(authControllerProvider);
    final userData = authState.valueOrNull?.userData;
    final displayName = _displayName(userData);
    final roleText = _roleLabel(userData?['role']?.toString());
    final selectedIndex = _calculateSelectedIndex(context);

    return NavigationView(
      // GoRouter child tek örnek; tüm PaneItem.body'ye aynı widget vermek PageView'da
      // aynı alt ağacı birden çok kez bağlar ve GlobalKey çakışmasına yol açar.
      paneBodyBuilder: (item, body) {
        return FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: widget.child,
        );
      },
      pane: NavigationPane(
        selected: selectedIndex,
        onChanged: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/buildings');
              break;
            case 2:
              context.go('/active-issues');
              break;
            case 3:
              context.go('/maintenance-suggestions');
              break;
            case 4:
              context.go('/reports');
              break;
            case 5:
              context.go('/employees');
              break;
          }
        },
        displayMode: PaneDisplayMode.auto,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Ana Sayfa'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.city_next),
            title: const Text('Binalar'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.warning),
            title: const Text('Arızalar'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.build_definition),
            title: const Text('Bakımlar'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.analytics_report),
            title: const Text('Raporlar'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.people),
            title: const Text('Çalışanlar'),
            body: const SizedBox.shrink(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                FluentIcons.contact,
                size: 12,
                color: theme.accentColor,
              ),
            ),
            title: Text(
              '$displayName - $roleText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.bodyStrong,
            ),
            body: const SizedBox.shrink(),
            onTap: () {},
          ),
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.robot),
            title: const Text('AI Asistan'),
            body: const SizedBox.shrink(),
            onTap: () {
              AIAssistantModal.show(context);
            },
          ),
          PaneItem(
            icon: Icon(
              isDarkMode ? FluentIcons.brightness : FluentIcons.sunny,
            ),
            title: Text(isDarkMode ? 'Açık Tema' : 'Koyu Tema'),
            body: const SizedBox.shrink(),
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Ayarlar'),
            body: const SizedBox.shrink(),
            onTap: () => context.go('/settings'),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.sign_out),
            title: const Text('Çıkış Yap'),
            body: const SizedBox.shrink(),
            onTap: () {
              // Global auth standardı: tokenları temizle + backend logout çağır
              ref.read(authControllerProvider.notifier).logout();
              context.go('/');
            },
          ),
        ],
      ),
    );
  }
}


