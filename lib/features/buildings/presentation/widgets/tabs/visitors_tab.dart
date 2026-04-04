import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/visitor_api_service.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildErrorCard;
import 'package:belediye_otomasyon/core/widgets/entity_action_buttons.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import '../modals/visitor_modals.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

class VisitorsTab extends StatefulWidget {
  const VisitorsTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  State<VisitorsTab> createState() => _VisitorsTabState();
}

class _VisitorsTabState extends State<VisitorsTab> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppUiTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Row(
                children: [
                  const Icon(FluentIcons.calendar, size: 16),
                  const SizedBox(width: AppUiTokens.space6),
                  DatePicker(
                    selected: _selectedDay,
                    onChanged: (d) {
                      setState(() => _selectedDay = d);
                    },
                  ),
                  const SizedBox(width: AppUiTokens.space16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppUiTokens.space12,
                      vertical: AppUiTokens.space6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppUiTokens.radius16),
                      border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.people, color: theme.accentColor, size: 16),
                        const SizedBox(width: AppUiTokens.space6),
                        FutureBuilder<Map<String, dynamic>>(
                          future: VisitorApiService().getDailyVisitorSummary(widget.building['id'], _selectedDay),
                          builder: (context, snapshot) {
                            final totalVisitors = snapshot.data?['total_visitors'] ?? 0;
                            return Text(
                              '$totalVisitors',
                              style: theme.typography.body?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.accentColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppUiTokens.space8),
                  EntityAddButton(
                    label: 'Ekle',
                    onPressed: () => showAddVisitorModal(
                      context: context,
                      theme: theme,
                      buildingId: widget.building['id'] as int,
                      selectedDay: _selectedDay,
                      onSuccess: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppUiTokens.space12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: VisitorApiService().getVisitorsByBuilding(widget.building['id'], visitDate: _selectedDay),
            builder: (context, visitorSnapshot) {
              if (visitorSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: ProgressRing());
              }

              if (visitorSnapshot.hasError) {
                return buildErrorCard(theme, 'Ziyaretçi listesi yüklenemedi');
              }

              final visitors = visitorSnapshot.data ?? [];

              if (visitors.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppUiTokens.space24),
                    child: Column(
                      children: [
                        Icon(FluentIcons.group, size: 48, color: theme.iconTheme.color?.withOpacity(0.5)),
                        const SizedBox(height: AppUiTokens.space12),
                        Text(
                          'Bu tarihte ziyaretçi kaydı bulunmuyor',
                          style: theme.typography.body?.copyWith(
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
                  itemCount: visitors.length,
                  separatorBuilder: (_, __) => const Divider(size: 1),
                  itemBuilder: (context, index) {
                    final visitor = visitors[index];
                    return _buildVisitorTile(theme, visitor);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorTile(FluentThemeData theme, Map<String, dynamic> visitor) {
    final entryTime = visitor['entry_time'] as String? ?? '';
    final exitTime = visitor['exit_time'] as String? ?? '';
    final isActive = exitTime.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.05) : null,
        border: isActive ? Border.all(color: Colors.green.withOpacity(0.2)) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppUiTokens.space8),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppUiTokens.radius6),
          ),
          child: Icon(
            isActive ? FluentIcons.people : FluentIcons.check_mark,
            color: isActive ? Colors.green : Colors.blue,
            size: 16,
          ),
        ),
        title: Text('${visitor['first_name']} ${visitor['last_name']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EntityActionButtons(
              width: 160,
              onEdit: () {
                final visitDate = visitor['visit_date'] != null
                    ? DateTime.tryParse(visitor['visit_date'].toString()) ??
                        _selectedDay
                    : _selectedDay;
                showAddVisitorModal(
                  context: context,
                  theme: theme,
                  buildingId: widget.building['id'] as int,
                  selectedDay: visitDate,
                  onSuccess: () => setState(() {}),
                  visitor: visitor,
                );
              },
              onDelete: () => showDeleteVisitorDialog(
                context: context,
                theme: theme,
                visitor: visitor,
                onSuccess: () => setState(() {}),
              ),
              onDetail: () => showVisitorDetail(
                context: context,
                theme: theme,
                visitor: visitor,
                onEdit: () {
                  final visitDate = visitor['visit_date'] != null
                      ? DateTime.tryParse(visitor['visit_date'].toString()) ??
                          _selectedDay
                      : _selectedDay;
                  showAddVisitorModal(
                    context: context,
                    theme: theme,
                    buildingId: widget.building['id'] as int,
                    selectedDay: visitDate,
                    onSuccess: () => setState(() {}),
                    visitor: visitor,
                  );
                },
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: AppUiTokens.space8),
              Button(
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(Colors.red),
                  foregroundColor: ButtonState.all(Colors.white),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.sign_out, size: 14),
                    const SizedBox(width: AppUiTokens.space4),
                    Text('Çıkış'),
                  ],
                ),
                onPressed: () => showCheckoutModal(
                  context: context,
                  theme: theme,
                  visitor: visitor,
                  onSuccess: () => setState(() {}),
                ),
              ),
            ],
            const SizedBox(width: AppUiTokens.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppUiTokens.space10,
                vertical: AppUiTokens.space6,
              ),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppUiTokens.radius8),
                border: Border.all(
                  color: theme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.clock,
                        size: 16,
                        color: theme.accentColor,
                      ),
                      const SizedBox(width: AppUiTokens.space6),
                      Text(
                        entryTime,
                        style: theme.typography.body?.copyWith(
                          color: theme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (exitTime.isNotEmpty) ...[
                    const SizedBox(height: AppUiTokens.space4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FluentIcons.clock,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: AppUiTokens.space6),
                        Text(
                          exitTime,
                          style: theme.typography.body?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        onPressed: () => showVisitorDetail(
          context: context,
          theme: theme,
          visitor: visitor,
          onEdit: () {
            final visitDate = visitor['visit_date'] != null
                ? DateTime.tryParse(visitor['visit_date'].toString()) ??
                    _selectedDay
                : _selectedDay;
            showAddVisitorModal(
              context: context,
              theme: theme,
              buildingId: widget.building['id'] as int,
              selectedDay: visitDate,
              onSuccess: () => setState(() {}),
              visitor: visitor,
            );
          },
        ),
      ),
    );
  }
}
