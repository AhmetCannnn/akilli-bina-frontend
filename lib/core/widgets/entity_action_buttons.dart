import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';

class EntityActionButtons extends StatelessWidget {
  const EntityActionButtons({
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
    final theme = FluentTheme.of(context);
    final resolvedEditColor = editColor ?? theme.accentColor;
    final resolvedDeleteColor = deleteColor ?? Colors.red;
    final resolvedDetailColor = detailColor ?? theme.iconTheme.color ?? Colors.grey;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onPrimary != null && (primaryLabel ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppUiTokens.space6),
            child: primaryTooltip != null
                ? Tooltip(
                    message: primaryTooltip!,
                    child: Button(
                      onPressed: onPrimary,
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(size.contentPadding),
                      ),
                      child: Text(primaryLabel!),
                    ),
                  )
                : Button(
                    onPressed: onPrimary,
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(size.contentPadding),
                    ),
                    child: Text(primaryLabel!),
                  ),
          ),
        if (onEdit != null)
          Tooltip(
            message: editTooltip,
            child: IconButton(
              icon: Icon(
                FluentIcons.edit,
                size: size.iconSize,
                color: resolvedEditColor,
              ),
              onPressed: onEdit,
            ),
          ),
        if (onDelete != null)
          Tooltip(
            message: deleteTooltip,
            child: IconButton(
              icon: Icon(
                FluentIcons.delete,
                size: size.iconSize,
                color: resolvedDeleteColor,
              ),
              onPressed: onDelete,
            ),
          ),
        if (onDetail != null)
          Tooltip(
            message: detailTooltip,
            child: IconButton(
              icon: Icon(
                FluentIcons.view,
                size: size.iconSize,
                color: resolvedDetailColor,
              ),
              onPressed: onDetail,
            ),
          ),
      ],
    );

    if (width == null) {
      return row;
    }

    return SizedBox(width: width, child: row);
  }
}

