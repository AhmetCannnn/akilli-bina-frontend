import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/features/employees/presentation/providers/employees_provider.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/widgets/modals/employee_modals.dart';
import 'package:belediye_otomasyon/features/buildings/presentation/providers/building_provider.dart';
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/core/widgets/app_entity_row_actions.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final EmployeeApiService _employeeApiService = EmployeeApiService();
  String _activeFilter = 'all';

  bool? get _isActiveFilterValue {
    switch (_activeFilter) {
      case 'active':
        return true;
      case 'inactive':
        return false;
      case 'all':
      default:
        return null;
    }
  }

  ({String label, Color color}) _statusMeta(Map<String, dynamic> employee) {
    final status = (employee['account_status'] ?? '').toString().toUpperCase();
    switch (status) {
      case 'FORMER_EMPLOYEE':
        return (label: 'Eski Çalışan', color: Colors.grey);
      case 'ACTIVE_USER':
        return (label: 'Aktif Kullanıcı', color: Colors.green);
      case 'LOCKED':
        return (label: 'Hesap Kilitli', color: Colors.orange);
      case 'INVITE_SENT':
        return (label: 'Davet Gönderildi', color: Colors.blue);
      case 'INVITE_EXPIRED':
        return (label: 'Davet Süresi Doldu', color: Colors.red);
      case 'NO_ACCESS':
      default:
        return (label: 'Giriş Yetkisi Yok', color: Colors.grey);
    }
  }

  Widget _buildStatusLegend(FluentThemeData theme) {
    final legendItems = <({String label, Color color})>[
      (label: 'Aktif Kullanıcı', color: Colors.green),
      (label: 'Davet Gönderildi', color: Colors.blue),
      (label: 'Davet Süresi Doldu', color: Colors.red),
      (label: 'Giriş Yetkisi Yok', color: Colors.grey),
      (label: 'Hesap Kilitli', color: Colors.orange),
      (label: 'Eski Çalışan', color: Colors.purple),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.iconTheme.color?.withOpacity(0.15) ?? Colors.grey),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          for (final item in legendItems)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: theme.typography.caption,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInlineStatusLegend(FluentThemeData theme) {
    final legendItems = <({String label, Color color})>[
      (label: 'Aktif Kullanıcı', color: Colors.green),
      (label: 'Davet Gönderildi', color: Colors.blue),
      (label: 'Davet Süresi Doldu', color: Colors.red),
      (label: 'Giriş Yetkisi Yok', color: Colors.grey),
      (label: 'Hesap Kilitli', color: Colors.orange),
      (label: 'Eski Çalışan', color: Colors.purple),
    ];

    final legendTextStyle = theme.typography.body?.copyWith(
          fontSize: 13.5,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(
          fontSize: 13.5,
          height: 1.2,
          fontWeight: FontWeight.w500,
          color: theme.typography.body?.color,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiTokens.space12,
        vertical: AppUiTokens.space6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < legendItems.length; i++) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: legendItems[i].color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppUiTokens.space6),
                  Text(
                    legendItems[i].label,
                    style: legendTextStyle,
                  ),
                ],
              ),
              if (i != legendItems.length - 1)
                const SizedBox(width: AppUiTokens.space12),
            ],
          ],
        ),
      ),
    );
  }

  String _inviteActionLabel(Map<String, dynamic> employee) {
    final status = (employee['account_status'] ?? '').toString().toUpperCase();
    if (status == 'INVITE_SENT' || status == 'INVITE_EXPIRED') {
      return 'Tekrar Gönder';
    }
    return 'Davet Gönder';
  }

  bool _canInvite(Map<String, dynamic> employee) {
    final status = (employee['account_status'] ?? '').toString().toUpperCase();
    return status == 'NO_ACCESS' ||
        status == 'INVITE_SENT' ||
        status == 'INVITE_EXPIRED';
  }

  Future<void> _sendInvite(String employeeId) async {
    try {
      await _employeeApiService.createInvite(employeeId);
      if (!mounted) return;
      displayInfoBar(
        context,
        alignment: Alignment.topCenter,
        builder: (c, close) => InfoBar(
          title: const Text('Başarılı'),
          content: const Text('Davet linki oluşturuldu.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
      await ref.read(employeesProvider.notifier).refresh();
    } catch (error) {
      if (!mounted) return;
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
    try {
      final buildings = await ref.read(buildingControllerProvider.future);
      if (!mounted) return;
      final theme = FluentTheme.of(context);

      if (buildings.isEmpty) {
        displayInfoBar(
          context,
          alignment: Alignment.topCenter,
          builder: (c, close) => const InfoBar(
            title: Text('Uyarı'),
            content: Text('Önce bir bina oluşturmanız gerekiyor.'),
            severity: InfoBarSeverity.warning,
          ),
        );
        return;
      }

      showAddEmployeeModal(
        context: context,
        theme: theme,
        buildings: buildings,
        onSuccess: (newEmployee) {
          // Yeni çalışan eklendiğinde listeyi yenile
          ref.read(employeesProvider.notifier).refresh();
        },
      );
    } catch (error) {
      if (mounted) {
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

    final horizontalPad = PageHeader.horizontalPadding(context);
    return AppScaffoldPage(
      content: Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.only(
          left: horizontalPad,
          right: horizontalPad,
          top: AppUiTokens.space8,
          bottom: AppUiTokens.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUiTokens.space12,
                    vertical: AppUiTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(AppUiTokens.radius12),
                    border: Border.all(
                      color: theme.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.people,
                        size: AppUiTokens.iconMd,
                        color: theme.accentColor,
                      ),
                      const SizedBox(width: AppUiTokens.space4),
                      Text(
                        totalCount != null ? '$totalCount' : '–',
                        style: theme.typography.caption?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppUiTokens.space8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: _buildInlineStatusLegend(theme),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 220,
                              child: TextBox(
                                controller: _searchController,
                                placeholder: 'Ad, soyad veya e-posta',
                                prefix: Icon(
                                  FluentIcons.search,
                                  size: AppUiTokens.iconMd,
                                ),
                                onSubmitted: (_) => _handleSearch(),
                              ),
                            ),
                            const SizedBox(width: AppUiTokens.space8),
                            ComboBox<String>(
                              value: _activeFilter,
                              items: const [
                                ComboBoxItem<String>(
                                  value: 'all',
                                  child: Text('Tümü'),
                                ),
                                ComboBoxItem<String>(
                                  value: 'active',
                                  child: Text('Aktif'),
                                ),
                                ComboBoxItem<String>(
                                  value: 'inactive',
                                  child: Text('Pasif'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _activeFilter = value);
                                ref.read(employeesProvider.notifier).applyFilters(
                                      search: _searchController.text.trim(),
                                      isActive: _isActiveFilterValue,
                                    );
                              },
                            ),
                            const SizedBox(width: AppUiTokens.space8),
                            if (canManageEmployees)
                              EntityAddButton(
                                label: 'Yeni Çalışan',
                                onPressed: _handleAddEmployee,
                                size: AppControlSize.sm,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiTokens.space12),
            Expanded(
              child: employeesState.when(
                data: (employees) {
                  if (employees.isEmpty) {
                    return Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
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
                      ),
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: employees.length,
                      separatorBuilder: (_, __) => const Divider(size: 1),
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final fullName =
                            '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
                                .trim();
                        final statusMeta = _statusMeta(employee);
                        final employeeId = employee['id']?.toString() ?? '';
                        final canInvite =
                            canManageEmployees && _canInvite(employee) && employeeId.isNotEmpty;

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(AppUiTokens.space8),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppUiTokens.space6),
                            ),
                            child: Icon(
                              FluentIcons.contact,
                              color: theme.accentColor,
                              size: AppUiTokens.iconLg,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName.isNotEmpty ? fullName : 'İsimsiz',
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppEntityRowActions(
                                primaryLabel:
                                    canInvite ? _inviteActionLabel(employee) : null,
                                onPrimary:
                                    canInvite ? () => _sendInvite(employeeId) : null,
                                onEdit: canManageEmployees
                                    ? () => showEditEmployeeModal(
                                          context: context,
                                          theme: theme,
                                          employee: employee,
                                          onSuccess: (updatedEmployee) {
                                            ref
                                                .read(employeesProvider.notifier)
                                                .refresh();
                                          },
                                        )
                                    : null,
                                onDelete: canManageEmployees
                                    ? () => showDeleteEmployeeDialog(
                                          context: context,
                                          theme: theme,
                                          employee: employee,
                                          onSuccess: (_) {
                                            ref
                                                .read(employeesProvider.notifier)
                                                .refresh();
                                          },
                                        )
                                    : null,
                                onDetail: () => showEmployeeDetailModal(
                                  context: context,
                                  theme: theme,
                                  employee: employee,
                                  onEdit: () {},
                                ),
                              ),
                              const SizedBox(width: AppUiTokens.space8),
                              Container(
                                width: AppUiTokens.space12,
                                height: AppUiTokens.space12,
                                decoration: BoxDecoration(
                                  color: statusMeta.color,
                                  shape: BoxShape.circle,
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
            ),
          ],
        ),
      ),
    );
  }
}

