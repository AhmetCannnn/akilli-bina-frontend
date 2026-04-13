import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart' show buildErrorCard, showDeleteDialog;
import 'package:belediye_otomasyon/core/utils/api_error.dart' show humanizeError;
import 'package:belediye_otomasyon/features/issues/presentation/providers/issue_provider.dart';
import 'package:belediye_otomasyon/features/issues/presentation/screens/active_issues_screen.dart';
import 'package:belediye_otomasyon/features/issues/domain/models/issue.dart';

/// Bina detayında: `issueControllerProvider` listesinden bu binaya ait kayıtlar.
class BuildingIssuesTab extends ConsumerWidget {
  const BuildingIssuesTab({required this.building, super.key});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final buildingId = building['id'] as int;
    final buildingName = (building['name'] ?? '').toString();
    final buildingAddress = (building['address'] ?? '').toString();
    final nameMap = {buildingId: buildingName};
    final addrMap = {buildingId: buildingAddress};

    final issuesAsync = ref.watch(issueControllerProvider);

    return SingleChildScrollView(
      // Web'de dikey scrollbar içerik üstüne bindiğinde sağdaki buton/kartlar kesilmesin.
      padding: const EdgeInsets.fromLTRB(
        0,
        AppUiTokens.space16,
        AppUiTokens.space12,
        AppUiTokens.space16,
      ),
      child: issuesAsync.when(
        loading: () =>
            const Center(child: Padding(padding: EdgeInsets.all(24), child: ProgressRing())),
        error: (e, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppUiTokens.space16),
            child: buildErrorCard(theme, humanizeError(e)),
          ),
        ),
        data: (raw) {
          final issues = raw
              .map((m) => Issue.fromJson(m, buildingNameMap: nameMap, buildingAddressMap: addrMap))
              .where((i) => i.buildingId == buildingId)
              .toList();

          return Column(
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
                      border: Border.all(color: theme.accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.report_hacked, size: AppUiTokens.iconMd, color: theme.accentColor),
                        const SizedBox(width: AppUiTokens.space4),
                        Text(
                          '${issues.length}',
                          style: theme.typography.caption?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  EntityAddButton(
                    label: 'Arıza Bildir',
                    onPressed: () => showReportIssueModal(
                      context,
                      ref,
                      initialBuildingId: buildingId.toString(),
                      initialBuildingName: buildingName.isNotEmpty ? buildingName : null,
                    ),
                    size: AppControlSize.sm,
                  ),
                ],
              ),
              const SizedBox(height: AppUiTokens.space12),
              if (issues.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppUiTokens.space24),
                    child: Column(
                      children: [
                        Icon(
                          FluentIcons.warning,
                          size: 48,
                          color: theme.iconTheme.color?.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppUiTokens.space12),
                        Text(
                          'Bu bina için arıza kaydı yok',
                          style: theme.typography.body?.copyWith(
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...issues.map(
                  (issue) => IssueCard(
                    issue: issue,
                    onEdit: () => openIssueEditUsingReportModal(context, ref, issue),
                    onAddIntervention: () => openInterventionModal(context, ref, issue, isEdit: true),
                    onDeleteIntervention: () {
                      showDeleteDialog(
                        context: context,
                        theme: theme,
                        title: 'Müdahaleyi Sil',
                        message:
                            '"${issue.title}" için müdahale bilgilerini silmek istediğinize emin misiniz?',
                        onDelete: () async {
                          await ref.read(issueControllerProvider.notifier).updateIssue(
                                issue.id,
                                {
                                  'status': IssueStatus.pending.apiValue,
                                  'assigned_to': null,
                                  'intervention_assignee': null,
                                  'intervention_note': null,
                                  'intervention_at': null,
                                  'estimated_cost': null,
                                  'actual_cost': null,
                                  'resolved_at': null,
                                },
                              );
                          return true;
                        },
                        successMessage: 'Müdahale bilgileri silindi.',
                        onSuccess: null,
                      );
                    },
                    onDelete: () {
                      showDeleteDialog(
                        context: context,
                        theme: theme,
                        title: 'Arızayı Sil',
                        message: '"${issue.title}" kaydını silmek istediğinize emin misiniz?',
                        onDelete: () async {
                          await ref.read(issueControllerProvider.notifier).deleteIssue(issue.id);
                          return true;
                        },
                        successMessage: '"${issue.title}" başarıyla silindi.',
                        onSuccess: null,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
