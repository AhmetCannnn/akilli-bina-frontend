import 'package:fluent_ui/fluent_ui.dart';

/// Proje standardı: Fluent [ScaffoldPage] `padding` verilmezse üstte
/// `kPageDefaultVerticalPadding` (24px) ekler; [NavigationView] ile bu çifte boşluk yaratır.
///
/// Varsayılan `padding: EdgeInsets.zero` — iç boşlukları her ekran kendi [content] ile verir.
class AppScaffoldPage extends StatelessWidget {
  const AppScaffoldPage({
    super.key,
    this.header,
    required this.content,
    this.bottomBar,
    this.padding = EdgeInsets.zero,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget? header;
  final Widget content;
  final Widget? bottomBar;
  final EdgeInsets padding;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: header,
      content: content,
      bottomBar: bottomBar,
      padding: padding,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
