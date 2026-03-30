Modal audit - old ContentDialog pattern to review

Planned review order:
1) screens/maintenance_suggestions_screen.dart (3 dialogs)
2) screens/active_issues_screen.dart (multiple dialogs)
3) screens/building_detail/widgets/tabs/maintenance_tab.dart (detail modal)
4) screens/building_detail/modals/visitor_modals.dart
5) screens/building_detail/modals/employee_modals.dart
6) core/utils/delete_dialog.dart
7) screens/building_detail/utils/dialog_utils.dart (success/error)
8) screens/building_detail_screen.dart (>=2 dialogs)
9) screens/add_building_screen.dart (add/edit modals)
10) screens/home_screen.dart (>=2 dialogs)
11) screens/reports_screen.dart (>=2 dialogs)
12) screens/settings_screen.dart (>=1 dialog)

Target design (like AI Assistant modal):
- Use custom Dialog + ClipRRect
- Opaque background: theme.resources.solidBackgroundFillColorBase
- Keep existing content; ensure list/content overflow is clipped where needed

