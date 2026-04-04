import 'package:belediye_otomasyon/core/utils/api_error.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:belediye_otomasyon/features/auth/data/services/auth_api_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

class InviteCompleteScreen extends StatefulWidget {
  const InviteCompleteScreen({
    required this.token,
    super.key,
  });

  final String token;

  @override
  State<InviteCompleteScreen> createState() => _InviteCompleteScreenState();
}

class _InviteCompleteScreenState extends State<InviteCompleteScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (widget.token.trim().isEmpty) {
      return 'Davet tokenı bulunamadı. Linki kontrol edin.';
    }
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır.';
    }
    if (confirm != password) {
      return 'Şifreler eşleşmiyor.';
    }
    return null;
  }

  Future<void> _handleComplete() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authApiService.completeInvite(
        token: widget.token.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _successMessage =
            (result['message'] ?? 'Davet tamamlandı. Giriş yapabilirsiniz.')
                .toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = humanizeError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return AppScaffoldPage(
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Davet Tamamlama',
                    style: theme.typography.title?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Şifrenizi belirleyerek hesabınızı aktifleştirin.',
                    style: theme.typography.body,
                  ),
                  const SizedBox(height: 16),
                  TextBox(
                    controller: _passwordController,
                    placeholder: 'Yeni şifre',
                    obscureText: !_showPassword,
                    suffix: IconButton(
                      icon: Icon(
                        _showPassword
                            ? FluentIcons.hide3
                            : FluentIcons.red_eye,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextBox(
                    controller: _confirmController,
                    placeholder: 'Şifre tekrar',
                    obscureText: !_showConfirm,
                    suffix: IconButton(
                      icon: Icon(
                        _showConfirm
                            ? FluentIcons.hide3
                            : FluentIcons.red_eye,
                      ),
                      onPressed: () {
                        setState(() => _showConfirm = !_showConfirm);
                      },
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    InfoBar(
                      title: const Text('Hata'),
                      content: Text(_errorMessage!),
                      severity: InfoBarSeverity.error,
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 12),
                    InfoBar(
                      title: const Text('Başarılı'),
                      content: Text(_successMessage!),
                      severity: InfoBarSeverity.success,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleComplete,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: ProgressRing(strokeWidth: 2),
                                )
                              : const Text('Hesabı Aktifleştir'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HyperlinkButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Giriş ekranına dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

