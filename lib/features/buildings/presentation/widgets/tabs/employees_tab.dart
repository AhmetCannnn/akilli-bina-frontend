import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import '../modals/employee_modals.dart';

class EmployeesTab extends ConsumerStatefulWidget {
  const EmployeesTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  ConsumerState<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<EmployeesTab> {
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() async {
    final employees = await EmployeeApiService().getEmployeesByBuildingId(widget.building['id'] as int);
    if (mounted) {
      setState(() {
        _employees = employees;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final authState = ref.watch(authControllerProvider);
    final userRole = authState.valueOrNull?.userData?['role']
        ?.toString()
        .toLowerCase();
    final canManageEmployees = userRole == 'manager';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Çalışanlar',
                style: theme.typography.title?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.people, color: theme.accentColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_employees.length}',
                          style: theme.typography.body?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canManageEmployees)
                    Button(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.add, size: 16),
                          const SizedBox(width: 4),
                          Text('Ekle'),
                        ],
                      ),
                      onPressed: () => showAddEmployeeModal(
                        context: context,
                        theme: theme,
                        buildingId: widget.building['id'] as int,
                        onSuccess: _addEmployee,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: _employees.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          FluentIcons.people,
                          size: 48,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
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
                      return Container(
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(FluentIcons.contact, color: theme.accentColor, size: 16),
                          ),
                          title: Text(fullName.isNotEmpty ? fullName : 'İsimsiz Çalışan'),
                          trailing: canManageEmployees
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: 'Düzenle',
                                      child: IconButton(
                                        icon: Icon(FluentIcons.edit, size: 18),
                                        onPressed: () => showEditEmployeeModal(
                                          context: context,
                                          theme: theme,
                                          employee: e,
                                          onSuccess: _updateEmployee,
                                        ),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Sil',
                                      child: IconButton(
                                        icon: Icon(FluentIcons.delete, size: 18, color: Colors.red),
                                        onPressed: () => showDeleteEmployeeDialog(
                                          context: context,
                                          theme: theme,
                                          employee: e,
                                          onSuccess: _removeEmployee,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
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

