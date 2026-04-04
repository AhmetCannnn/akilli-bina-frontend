import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_error_info.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gereklidir';
    }
    final email = value.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    // Manual validation
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _errorMessage = null;
    });

    if (emailError != null || passwordError != null) {
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = humanizeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return AppScaffoldPage(
      content: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Logo ve Başlık
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.city_next,
                    size: 48,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Akıllı Binalar',
                  style: theme.typography.title?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yönetim Sistemi',
                  style: theme.typography.subtitle?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email
                          AuthTextField(
                            controller: _emailController,
                            label: 'E-posta',
                            placeholder: 'E-posta adresinizi giriniz',
                            icon: FluentIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            errorText: _emailError,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 20),

                          // Password
                          AuthTextField(
                            controller: _passwordController,
                            label: 'Şifre',
                            placeholder: 'Şifrenizi giriniz',
                            icon: FluentIcons.lock,
                            obscureText: !_isPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            textInputAction: TextInputAction.done,
                            errorText: _passwordError,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 24),

                          // Error Message
                          if (_errorMessage != null) ...[
                            AuthErrorInfo(
                              title: 'Giriş Hatası',
                              message: _errorMessage!,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Login Button
                          AuthButton(
                            onPressed: _handleLogin,
                            text: 'Giriş Yap',
                            isLoading: isLoading,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 12),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Hesabınız yok mu? ',
                                  style: theme.typography.body,
                                  softWrap: true,
                                ),
                              ),
                              HyperlinkButton(
                                onPressed: () {
                                  context.push('/register');
                                },
                                child: const Text('Kayıt Ol'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

