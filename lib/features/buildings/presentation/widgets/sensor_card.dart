import 'package:fluent_ui/fluent_ui.dart';

/// Sensör kartı widget'ı - feature içi ortak kullanım için
class SensorCard extends StatelessWidget {
  const SensorCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.minMax,
    this.updatedAgo,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? minMax;
  final String? updatedAgo;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.title?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (minMax != null || updatedAgo != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (minMax != null) ...[
                    Expanded(
                      child: Text(
                        minMax!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.caption?.copyWith(
                          color: theme.typography.caption?.color?.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  if (updatedAgo != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      FluentIcons.clock,
                      size: 12,
                      color: theme.typography.caption?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      updatedAgo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.caption?.copyWith(
                        color: theme.typography.caption?.color?.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
