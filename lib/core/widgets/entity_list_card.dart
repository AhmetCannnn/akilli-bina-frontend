import 'package:fluent_ui/fluent_ui.dart';

import 'entity_tag.dart';

/// Rounded icon container used in list card headers (reports-style).
class EntityListCardLeadingIconBox extends StatelessWidget {
  const EntityListCardLeadingIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.iconSize = 20,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = 8,
  });

  final IconData icon;
  final Color color;
  final double iconSize;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Küçük başlık etiketi; görünüm [EntityTag] ile aynı.
class EntityListCardHeaderPill extends StatelessWidget {
  const EntityListCardHeaderPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return EntityTag(label: label, color: color);
  }
}

/// Top row: [leading] + title + optional subtitle + optional [trailing].
class EntityListCardHeaderRow extends StatelessWidget {
  const EntityListCardHeaderRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleSpacing = 12,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double titleSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      children: [
        leading,
        SizedBox(width: titleSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.typography.bodyStrong?.copyWith(fontSize: 16),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.typography.caption?.copyWith(
                    color: theme.typography.caption?.color?.withOpacity(0.7),
                    overflow: TextOverflow.visible,
                  ),
                  softWrap: false,
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// One meta segment for the footer row: 16px icon + caption.
class EntityListCardMetaIconText extends StatelessWidget {
  const EntityListCardMetaIconText({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.iconTheme.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.typography.caption?.copyWith(
            color: theme.typography.caption?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Fluent [Card] list row: header, description, footer (e.g. meta + actions).
class EntityListCard extends StatelessWidget {
  const EntityListCard({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.padding = const EdgeInsets.all(16),
    this.wrapInCard = true,
    this.prependInCard,
    required this.header,
    required this.description,
    required this.footer,
    this.sectionGap = 12,
    this.descriptionMaxLines,
  });

  final EdgeInsets margin;
  final EdgeInsets padding;

  /// When false, only the inner column is built (no [Card] / margin). Use inside a parent [Card].
  final bool wrapInCard;

  /// Optional block above the header row (e.g. issue tag [Wrap]).
  final Widget? prependInCard;

  final Widget header;
  final String description;
  final Widget footer;
  final double sectionGap;
  final int? descriptionMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final inner = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prependInCard != null) ...[
            prependInCard!,
            SizedBox(height: sectionGap),
          ],
          header,
          SizedBox(height: sectionGap),
          Text(
            description,
            style: theme.typography.body?.copyWith(
              color: theme.typography.body?.color?.withOpacity(0.8),
            ),
            maxLines: descriptionMaxLines,
            overflow: descriptionMaxLines != null
                ? TextOverflow.ellipsis
                : TextOverflow.clip,
          ),
          SizedBox(height: sectionGap),
          footer,
        ],
      ),
    );
    if (!wrapInCard) {
      return inner;
    }
    return Container(
      margin: margin,
      child: Card(
        child: inner,
      ),
    );
  }
}
