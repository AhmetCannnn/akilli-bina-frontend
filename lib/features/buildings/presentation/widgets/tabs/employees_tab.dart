import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/core/widgets/app_entity_row_actions.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import '../modals/employee_modals.dart';

class EmployeesTab extends ConsumerStatefulWidget {
  const EmployeesTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  ConsumerState<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<EmployeesTab> {
  List<Map<String, dynamic>> _employees = [];
  final EmployeeApiService _employeeApiService = EmployeeApiService();

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
                    width: AppUiTokens.space10,
                    height: AppUiTokens.space10,
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

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() async {
    try {
      final employees = await _employeeApiService.getEmployeesByBuildingId(
        widget.building['id'] as int,
      );
      if (mounted) {
        setState(() {
          _employees = employees;
        });
      }
    } catch (_) {}
  }

  /// Yeni çalışanı direkt listeye ekler (API'ye tekrar istek atmaz)
  void _addEmployee(Map<String, dynamic> newEmployee) {
    if (mounted) {
      setState(() {
        _employees = [newEmployee, ..._employees]; // Yeni çalışanı başa ekle
      });
    }
  }

  /// Güncellenmiş çalışanı direkt listeye günceller (API'ye tekrar istek atmaz)
  void _updateEmployee(Map<String, dynamic> updatedEmployee) {
    if (mounted) {
      setState(() {
        _employees = _employees.map((e) {
          if (e['id'] == updatedEmployee['id']) {
            return updatedEmployee; // Güncellenmiş çalışanı değiştir
          }
          return e;
        }).toList();
      });
    }
  }

  /// Silinen çalışanı direkt listeden kaldırır (API'ye tekrar istek atmaz)
  void _removeEmployee(String employeeId) {
    if (mounted) {
      setState(() {
        _employees = _employees.where((e) => e['id'].toString() != employeeId).toList();
      });
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

  bool _canInvite(Map<String, dynamic> employee) {
    final status = (employee['account_status'] ?? '').toString().toUpperCase();
    return status == 'NO_ACCESS' ||
        status == 'INVITE_SENT' ||
        status == 'INVITE_EXPIRED';
  }

  String _inviteActionLabel(Map<String, dynamic> employee) {
    final status = (employee['account_status'] ?? '').toString().toUpperCase();
    if (status == 'INVITE_SENT' || status == 'INVITE_EXPIRED') {
      return 'Tekrar Gönder';
    }
    return 'Davet Gönder';
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
      _loadEmployees();
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
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.valueOrNull?.userData?['role']
        ?.toString()
        .toLowerCase();
    final canManageEmployees = userRole == 'manager';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
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
                  borderRadius: BorderRadius.circular(AppUiTokens.radius12),
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
                      '${_employees.length}',
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
                          if (canManageEmployees)
                            EntityAddButton(
                              label: 'Yeni Çalışan',
                              onPressed: () => showAddEmployeeModal(
                                context: context,
                                theme: theme,
                                buildingId: widget.building['id'] as int,
                                onSuccess: _addEmployee,
                              ),
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
          Card(
            child: _employees.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppUiTokens.space24),
                    child: Column(
                      children: [
                        Icon(
                          FluentIcons.people,
                          size: 48,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppUiTokens.space12),
                        Text(
                          'Henüz çalışan bilgisi bulunmuyor',
                          style: theme.typography.body?.copyWith(
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _employees.length,
                    separatorBuilder: (_, __) => const Divider(size: 1),
                    itemBuilder: (context, index) {
                      final e = _employees[index];
                      final fullName = '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
                      final statusMeta = _statusMeta(e);
                      final employeeId = e['id']?.toString() ?? '';
                      return Container(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(AppUiTokens.space8),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppUiTokens.radius6),
                            ),
                            child: Icon(FluentIcons.contact, color: theme.accentColor, size: 16),
                          ),
                          title: Text(fullName.isNotEmpty ? fullName : 'İsimsiz Çalışan'),
                          trailing: canManageEmployees
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppEntityRowActions(
                                      width: _canInvite(e) && employeeId.isNotEmpty
                                          ? 260
                                          : 150,
                                      primaryLabel: _canInvite(e) && employeeId.isNotEmpty
                                          ? _inviteActionLabel(e)
                                          : null,
                                      onPrimary: _canInvite(e) && employeeId.isNotEmpty
                                          ? () => _sendInvite(employeeId)
                                          : null,
                                      onEdit: () => showEditEmployeeModal(
                                        context: context,
                                        theme: theme,
                                        employee: e,
                                        onSuccess: _updateEmployee,
                                      ),
                                      onDelete: () => showDeleteEmployeeDialog(
                                        context: context,
                                        theme: theme,
                                        employee: e,
                                        onSuccess: _removeEmployee,
                                      ),
                                      onDetail: () => showEmployeeDetailModal(
                                        context: context,
                                        theme: theme,
                                        employee: e,
                                        onEdit: () => showEditEmployeeModal(
                                          context: context,
                                          theme: theme,
                                          employee: e,
                                          onSuccess: _updateEmployee,
                                        ),
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
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppEntityRowActions(
                                      width: 80,
                                      onDetail: () => showEmployeeDetailModal(
                                        context: context,
                                        theme: theme,
                                        employee: e,
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
                          onPressed: () => showEmployeeDetailModal(
                            context: context,
                            theme: theme,
                            employee: e,
                            onEdit: () => showEditEmployeeModal(
                              context: context,
                              theme: theme,
                              employee: e,
                              onSuccess: _updateEmployee,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

