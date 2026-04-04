import 'package:fluent_ui/fluent_ui.dart';
import 'package:belediye_otomasyon/core/widgets/app_scaffold_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:belediye_otomasyon/core/utils/api_error.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_error_info.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _errorMessage;
  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad soyad gereklidir';
    }
    if (value.trim().length < 3) {
      return 'Ad soyad en az 3 karakter olmalıdır';
    }
    return null;
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
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Şifre en az bir büyük harf içermelidir';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Şifre en az bir küçük harf içermelidir';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Şifre en az bir rakam içermelidir';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrar gereklidir';
    }
    if (value != _passwordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    // Manual validation
    final fullNameError = _validateFullName(_fullNameController.text);
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);
    final confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);

    setState(() {
      _fullNameError = fullNameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _errorMessage = null;
    });

    if (fullNameError != null || emailError != null || passwordError != null || confirmPasswordError != null) {
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            role: 'user',
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
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ve Başlık
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentIcons.add_friend,
                    size: 48,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Yeni Hesap Oluştur',
                  style: theme.typography.title?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sisteme kayıt olmak için bilgilerinizi girin',
                  style: theme.typography.subtitle?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                  textAlign: TextAlign.center,
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
                          // Full Name
                          AuthTextField(
                            controller: _fullNameController,
                            label: 'Ad Soyad',
                            placeholder: 'Adınızı ve soyadınızı giriniz',
                            icon: FluentIcons.contact,
                            textInputAction: TextInputAction.next,
                            errorText: _fullNameError,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 20),

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
                            placeholder: 'En az 8 karakter, büyük/küçük harf ve rakam',
                            icon: FluentIcons.lock,
                            obscureText: !_isPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            textInputAction: TextInputAction.next,
                            errorText: _passwordError,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password
                          AuthTextField(
                            controller: _confirmPasswordController,
                            label: 'Şifre Tekrar',
                            placeholder: 'Şifrenizi tekrar giriniz',
                            icon: FluentIcons.lock,
                            obscureText: !_isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                            textInputAction: TextInputAction.done,
                            errorText: _confirmPasswordError,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 24),

                          // Error Message
                          if (_errorMessage != null) ...[
                            AuthErrorInfo(
                              title: 'Kayıt Hatası',
                              message: _errorMessage!,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Register Button
                          AuthButton(
                            onPressed: _handleRegister,
                            text: 'Kayıt Ol',
                            isLoading: isLoading,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 12),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Zaten hesabınız var mı? ',
                                style: theme.typography.body,
                              ),
                              HyperlinkButton(
                                onPressed: () {
                                  context.pop();
                                },
                                child: const Text('Giriş Yap'),
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

