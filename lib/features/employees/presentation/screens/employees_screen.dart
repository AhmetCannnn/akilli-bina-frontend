import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/features/employees/presentation/providers/employees_provider.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/widgets/modals/employee_modals.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/providers/building_provider.dart';
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool? _isActiveFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    await ref
        .read(employeesProvider.notifier)
        .applyFilters(search: _searchController.text.trim());
  }

  Future<void> _handleAddEmployee() async {
    final theme = FluentTheme.of(context);
    try {
      final buildings = await ref.read(buildingControllerProvider.future);
      if (buildings.isEmpty) {
        if (context.mounted) {
          displayInfoBar(
            context,
            alignment: Alignment.topCenter,
            builder: (c, close) => const InfoBar(
              title: Text('Uyarı'),
              content: Text('Önce bir bina oluşturmanız gerekiyor.'),
              severity: InfoBarSeverity.warning,
            ),
          );
        }
        return;
      }

      // Bina seçimi için dialog göster
      int? selectedBuildingId;
      await showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('Bina Seçin'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Çalışanı hangi binaya eklemek istersiniz?'),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: buildings.length,
                    itemBuilder: (context, index) {
                      final building = buildings[index];
                      return ListTile(
                        title: Text(building['name'] ?? 'İsimsiz Bina'),
                        subtitle: Text(
                          '${building['city'] ?? ''} - ${building['district'] ?? ''}',
                        ),
                        onPressed: () {
                          selectedBuildingId = building['id'] as int;
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Button(
              child: const Text('İptal'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );

      if (selectedBuildingId != null && context.mounted) {
        showAddEmployeeModal(
          context: context,
          theme: theme,
          buildingId: selectedBuildingId!,
          onSuccess: (newEmployee) {
            // Yeni çalışan eklendiğinde listeyi yenile
            ref.read(employeesProvider.notifier).refresh();
          },
        );
      }
    } catch (error) {
      if (context.mounted) {
        displayInfoBar(
          context,
          alignment: Alignment.topCenter,
          builder: (c, close) => InfoBar(
            title: const Text('Hata'),
            content: Text(humanizeError(error)),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final employeesState = ref.watch(employeesProvider);
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.valueOrNull?.userData?['role']
        ?.toString()
        .toLowerCase();
    final canManageEmployees = userRole == 'manager';
    final totalCount = employeesState.maybeWhen(
      data: (employees) => employees.length,
      orElse: () => null,
    );

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Row(
          children: [
            const Icon(FluentIcons.people),
            const SizedBox(width: 8),
            Text(
              'Çalışanlar',
              style: theme.typography.title,
            ),
          ],
        ),
        commandBar: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              child: TextBox(
                controller: _searchController,
                placeholder: 'Ad, soyad veya e-posta',
                prefix: const Icon(FluentIcons.search),
                onSubmitted: (_) => _handleSearch(),
              ),
            ),
            const SizedBox(width: 8),
            ComboBox<bool?>(
              value: _isActiveFilter,
              items: const [
                ComboBoxItem<bool?>(
                  value: null,
                  child: Text('Tümü'),
                ),
                ComboBoxItem<bool?>(
                  value: true,
                  child: Text('Aktif'),
                ),
                ComboBoxItem<bool?>(
                  value: false,
                  child: Text('Pasif'),
                ),
              ],
              onChanged: (value) {
                setState(() => _isActiveFilter = value);
                ref.read(employeesProvider.notifier).applyFilters(
                      search: _searchController.text.trim(),
                      isActive: value,
                    );
              },
            ),
            const SizedBox(width: 8),
            if (canManageEmployees)
              FilledButton(
                child: const Text('Yeni Çalışan'),
                onPressed: _handleAddEmployee,
              ),
            if (totalCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.accentColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.contact,
                      size: 14,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalCount',
                      style: theme.typography.caption?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      children: [
        employeesState.when(
          data: (employees) {
            if (employees.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        // Sidebar'daki \"Çalışanlar\" ikonu ile aynı
                        FluentIcons.people,
                        size: 56,
                        color: theme.accentColor.withOpacity(0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz çalışan kaydı bulunamadı',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bina detayından veya bu ekrandan yeni çalışan ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: theme.typography.caption?.copyWith(
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: employees.length,
                separatorBuilder: (_, __) => const Divider(size: 1),
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  final fullName =
                      '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
                          .trim();
                  final buildingId = employee['building_id']?.toString() ?? '-';
                  final buildingName =
                      (employee['building_name'] ?? '').toString().trim();
                  final isActive = employee['is_active'] == true;

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        FluentIcons.contact,
                        color: theme.accentColor,
                        size: 16,
                      ),
                    ),
                    title: Text(fullName.isNotEmpty ? fullName : 'İsimsiz'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.accentColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                buildingName.isNotEmpty
                                    ? buildingName
                                    : 'Bina #$buildingId',
                                style: theme.typography.caption?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: (isActive
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              child: Text(
                                isActive ? 'Aktif' : 'Pasif',
                                style: theme.typography.caption?.copyWith(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Detay',
                          child: IconButton(
                            icon: const Icon(FluentIcons.view),
                            onPressed: () => showEmployeeDetailModal(
                              context: context,
                              theme: theme,
                              employee: employee,
                              onEdit: () {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: ProgressRing(),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Çalışanlar yüklenirken bir hata oluştu',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText.rich(
                    TextSpan(
                      text: error.toString(),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Button(
                    child: const Text('Tekrar dene'),
                    onPressed: () =>
                        ref.read(employeesProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

