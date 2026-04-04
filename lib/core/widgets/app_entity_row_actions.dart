import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/entity_action_buttons.dart';

/// Satır sonu **Düzenle / Sil / Detay** (ve isteğe bağlı birincil metin) aksiyonları.
///
/// [EntityActionButtons] ile aynı API; varsayılan boyut **Çalışanlar** listesindeki gibi
/// [AppControlSize.md] (ikon ~14px, padding md).
///
/// **Geçiş planı (adım adım):**
/// 1. Bina detay kartı üst aksiyonları — tamam.
/// 2. `employees_tab`, `visitors_tab`, `building_reports_tab` vb. listeler.
/// 3. `reports_screen`, `maintenance_suggestions_screen`, arıza kartları.
/// 4. Sekme/toolbar’da sıkışık yerler için gerektiğinde `size: AppControlSize.sm` geçilir.
class AppEntityRowActions extends StatelessWidget {
  const AppEntityRowActions({
    super.key,
    this.width,
    this.primaryLabel,
    this.onPrimary,
    this.primaryTooltip,
    this.onEdit,
    this.onDelete,
    this.onDetail,
    this.editTooltip = 'Düzenle',
    this.deleteTooltip = 'Sil',
    this.detailTooltip = 'Detay',
    this.editColor,
    this.deleteColor,
    this.detailColor,
    this.size = AppControlSize.md,
  });

  final double? width;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? primaryTooltip;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDetail;
  final String editTooltip;
  final String deleteTooltip;
  final String detailTooltip;
  final Color? editColor;
  final Color? deleteColor;
  final Color? detailColor;
  final AppControlSize size;

  @override
  Widget build(BuildContext context) {
    return EntityActionButtons(
      width: width,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      primaryTooltip: primaryTooltip,
      onEdit: onEdit,
      onDelete: onDelete,
      onDetail: onDetail,
      editTooltip: editTooltip,
      deleteTooltip: deleteTooltip,
      detailTooltip: detailTooltip,
      editColor: editColor,
      deleteColor: deleteColor,
      detailColor: detailColor,
      size: size,
    );
  }
}
