import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

/// Çalışan sayısını getir
Future<int> _getEmployeeCount(int buildingId) async {
  try {
    final employees = await EmployeeApiService().getEmployeesByBuildingId(buildingId);
    return employees.length;
  } catch (e) {
    return 0;
  }
}

class InfoTab extends StatelessWidget {
  const InfoTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Açıklama bölümü (eğer varsa)
          if (building['description'] != null && building['description'].toString().trim().isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppUiTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.text_document,
                          size: 18,
                          color: theme.accentColor,
                        ),
                        const SizedBox(width: AppUiTokens.space8),
                        Text(
                          'Hakkında',
                          style: theme.typography.subtitle?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppUiTokens.space12),
                    Text(
                      building['description'].toString().trim(),
                      style: theme.typography.body,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppUiTokens.space12),
          ],
          _BuildingInfoCard(building: building),
        ],
      ),
    );
  }
}

class _BuildingInfoCard extends StatelessWidget {
  const _BuildingInfoCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppUiTokens.space16),
        child: Column(
          children: [
            _BuildingInfoItem(
              icon: FluentIcons.square_shape,
              title: 'Bina Alanı',
              value: '${building['building_area'] ?? 0} m²',
              color: Colors.blue,
            ),
            const SizedBox(height: AppUiTokens.space16),
            _BuildingInfoItem(
              icon: FluentIcons.stack,
              title: 'Kat Sayısı',
              value: '${building['floor_count'] ?? 0} Kat',
              color: Colors.purple,
            ),
            const SizedBox(height: AppUiTokens.space16),
            _BuildingInfoItem(
              icon: FluentIcons.calendar,
              title: 'Yapım Yılı',
              value: '${building['construction_year'] ?? 0}',
              color: Colors.teal,
            ),
            const SizedBox(height: AppUiTokens.space16),
            FutureBuilder<int>(
              future: _getEmployeeCount(building['id'] as int),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _BuildingInfoItem(
                  icon: FluentIcons.people,
                  title: 'Çalışan Sayısı',
                  value: '$count',
                  color: Colors.orange,
                );
              },
            ),
            const SizedBox(height: AppUiTokens.space16),
            _BuildingInfoItem(
              icon: FluentIcons.product_catalog,
              title: 'Demirbaş Sayısı',
              value: '${building['asset_count'] ?? 0}',
              color: Colors.green,
            ),
            const SizedBox(height: AppUiTokens.space16),
            _BuildingInfoItem(
              icon: FluentIcons.car,
              title: 'Otopark Kapasitesi',
              value: '${building['parking_capacity'] ?? 0} Araç',
              color: Colors.magenta,
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingInfoItem extends StatelessWidget {
  const _BuildingInfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppUiTokens.space8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppUiTokens.radius8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: AppUiTokens.space12),
        Text(
          title,
          style: theme.typography.body?.copyWith(
            color: theme.typography.body?.color?.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.typography.bodyStrong,
        ),
      ],
    );
  }
}
