// Dummy data import removed - now using backend data
import 'package:belediye_otomasyon/features/issues/presentation/screens/active_issues_screen.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/screens/building_detail_screen.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/screens/buildings_screen.dart';
import 'package:belediye_otomasyon/features/home/presentation/screens/home_screen.dart';
import 'package:belediye_otomasyon/features/auth/presentation/screens/login_screen.dart';
import 'package:belediye_otomasyon/features/auth/presentation/screens/register_screen.dart';
import 'package:belediye_otomasyon/features/maintenance/presentation/screens/maintenance_suggestions_screen.dart';
import 'package:belediye_otomasyon/features/reports/presentation/screens/reports_screen.dart';
import 'package:belediye_otomasyon/features/settings/presentation/screens/settings_screen.dart';
import 'package:belediye_otomasyon/features/employees/presentation/screens/employees_screen.dart';
import 'package:belediye_otomasyon/features/navigation/presentation/widgets/app_shell.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return AppShell(shellContext: context, child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/building-detail/:id',
          builder: (BuildContext context, GoRouterState state) {
            final buildingId = int.parse(state.pathParameters['id']!);
            return BuildingDetailScreen(buildingId: buildingId);
          },
        ),
        GoRoute(
          path: '/buildings',
          builder: (BuildContext context, GoRouterState state) {
            return const BuildingsScreen();
          },
        ),
        GoRoute(
          path: '/active-issues',
          builder: (BuildContext context, GoRouterState state) {
            return const ActiveIssuesScreen();
          },
        ),
        GoRoute(
          path: '/employees',
          builder: (BuildContext context, GoRouterState state) {
            return const EmployeesScreen();
          },
        ),
        GoRoute(
          path: '/reports',
          builder: (BuildContext context, GoRouterState state) {
            return const ReportsScreen();
          },
        ),
        GoRoute(
          path: '/maintenance-suggestions',
          builder: (BuildContext context, GoRouterState state) {
            return const MaintenanceSuggestionsScreen();
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
      ],
    ),
  ],
);

