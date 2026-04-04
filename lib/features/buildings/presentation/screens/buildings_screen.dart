import 'package:fluent_ui/fluent_ui.dart';
import '../utils/building_helpers.dart';
// Dummy data import removed - now using backend data
import 'add_building_modal.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/api_error.dart';
import 'package:belediye_otomasyon/core/design/ui_tokens.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/core/widgets/entity_add_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/building_provider.dart';

class BuildingsScreen extends ConsumerWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final buildingsAsync = ref.watch(buildingControllerProvider);
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
        child: buildingsAsync.when(
          data: (buildings) => _BuildingsTabs(buildings: buildings),
          loading: () => const Center(child: ProgressRing()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(humanizeError(error)),
                Button(
                  child: const Text('Yeniden Dene'),
                  onPressed: () => ref.refresh(buildingControllerProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingList extends StatelessWidget {
  const _BuildingList({required this.buildings});

  final List<Map<String, dynamic>> buildings;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (buildings.isEmpty) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  // Sidebar'daki \"Binalar\" ikonu ile aynı
                  FluentIcons.city_next,
                  size: 48,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Henüz bina kaydı bulunmuyor',
                  style: theme.typography.body?.copyWith(
                    color: theme.iconTheme.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;
          if (isNarrow) {
            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: buildings.length,
              itemBuilder: (context, index) => _BuildingCard(building: buildings[index]),
            );
          }
          final spacing = 12.0;
          final itemWidth = (constraints.maxWidth - spacing) / 2;
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: buildings
                  .map((b) => SizedBox(width: itemWidth, child: _BuildingCard(building: b)))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  const _BuildingCard({required this.building});

  final Map<String, dynamic> building;

  Widget _buildPhoto(String url) {
    final hasUrl = url.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasUrl
          ? Image.network(
              url,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildFallback(isLoading: true);
              },
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback({bool isLoading = false}) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: isLoading
            ? const ProgressRing()
            : Icon(
                FluentIcons.home,
                color: Colors.blue,
                size: 24,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Button(
        onPressed: () {
          context.push('/building-detail/${building['id']}');
        },
        style: ButtonStyle(
          padding: ButtonState.all(EdgeInsets.zero),
          backgroundColor: ButtonState.all(Colors.transparent),
        ),
        child: Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildPhoto(building['photo_url']?.toString() ?? ''),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building['name'] ?? 'Bina Adı',
                        style: theme.typography.bodyStrong?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        building['address'] ?? 'Adres',
                        style: theme.typography.caption?.copyWith(
                          color: theme.typography.caption?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  FluentIcons.chevron_right,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingsTabs extends ConsumerStatefulWidget {
  const _BuildingsTabs({super.key, required this.buildings});

  final List<Map<String, dynamic>> buildings;

  @override
  ConsumerState<_BuildingsTabs> createState() => _BuildingsTabsState();
}

class _BuildingsTabsState extends ConsumerState<_BuildingsTabs> {
  int _currentIndex = 0;
  static const _filters = [
    {'label': 'Tümü', 'type': null},
    {'label': 'KOMEK', 'type': 'KOMEK'},
    {'label': 'Müze', 'type': 'Müze'},
    {'label': 'Hizmet', 'type': 'Hizmet Binası'},
  ];

  List<Map<String, dynamic>> _filteredBuildings() {
    final type = _filters[_currentIndex]['type'];
    if (type == null) return widget.buildings;
    return widget.buildings.where((b) => b['building_type'] == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final filtered = _filteredBuildings();
    return Column(
      children: [
        // Merkezde filtre sekmeleri (buton grubu)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_filters.length, (i) {
                    final f = _filters[i];
                    return _FilterButton(
                      label: f['label'] as String,
                      selected: _currentIndex == i,
                      onPressed: () => setState(() => _currentIndex = i),
                      theme: theme,
                    );
                  }),
                ),
              ),
              Positioned(
                right: 0,
                child: EntityAddButton(
                  label: 'Yeni Bina',
                  tooltip: 'Yeni Bina',
                  onPressed: () {
                    AddBuildingModal.showAddBuildingModal(context, ref);
                  },
                ),
              ),
            ],
          ),
        ),
        // İçerik: tam genişlik
        Expanded(
          child: _BuildingList(buildings: filtered),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color base = theme.accentColor;
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: ButtonState.resolveWith(
          (states) => selected ? base.withOpacity(0.12) : Colors.transparent,
        ),
        padding: ButtonState.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      ),
      child: Text(
        label,
        style: theme.typography.body?.copyWith(
          color: selected ? base : theme.typography.body?.color,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// BuildingType enum'ı domain/models/building.dart'dan import ediliyor
// UI extension'ları (icon, color) building_helpers.dart'da tanımlı

