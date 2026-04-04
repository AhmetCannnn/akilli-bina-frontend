import 'package:fluent_ui/fluent_ui.dart';
import '../../utils/building_helpers.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

class DepartmentsTab extends StatelessWidget {
  const DepartmentsTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DepartmentsCard(building: building),
        ],
      ),
    );
  }
}

class _DepartmentsCard extends StatelessWidget {
  const _DepartmentsCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      child: Padding(
          padding: const EdgeInsets.all(AppUiTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birimler',
              style: theme.typography.bodyStrong,
            ),
          const SizedBox(height: AppUiTokens.space12),
            Wrap(
              spacing: AppUiTokens.space8,
              runSpacing: AppUiTokens.space8,
              children: safeStringList(building['departments']).map((department) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUiTokens.space12,
                    vertical: AppUiTokens.space6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppUiTokens.radius4),
                  ),
                  child: Text(
                    department,
                    style: theme.typography.caption?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppUiTokens.space24),
            Text(
              'Tesisler',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: AppUiTokens.space12),
            Wrap(
              spacing: AppUiTokens.space8,
              runSpacing: AppUiTokens.space8,
              children: safeStringList(building['facilities']).map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUiTokens.space12,
                    vertical: AppUiTokens.space6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppUiTokens.radius4),
                  ),
                  child: Text(
                    facility,
                    style: theme.typography.caption?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
