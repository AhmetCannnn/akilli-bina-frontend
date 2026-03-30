import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:belediye_otomasyon/core/utils/modal_helpers.dart'
    show showSuccessInfoBar, showErrorInfoBar, showDeleteDialog, buildModalTitle;
import 'package:belediye_otomasyon/core/utils/api_error.dart' show ApiException, humanizeError;
import 'package:belediye_otomasyon/features/auth/presentation/providers/auth_provider.dart';
import 'package:belediye_otomasyon/features/auth/data/services/auth_api_service.dart';
import 'package:belediye_otomasyon/features/employees/data/services/employee_api_service.dart';
import 'package:belediye_otomasyon/features/buildings/data/services/building_api_service.dart';
import 'package:belediye_otomasyon/theme/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  final BuildingApiService _buildingService = BuildingApiService();
  final AuthApiService _authService = AuthApiService();

  bool _notifications = true;
  final List<String> _themeOptions = ['Sistem', 'Açık', 'Koyu'];

  // Kullanıcı bilgileri
  String _userName = '';
  String _userRole = '';
  String _userEmail = '';
  String _userPhone = '';
  
  // Çalışan detayları
  String _userPosition = ''; 
  String _userBuilding = '';
  DateTime _userHireDate = DateTime.now();
  String? _employeeId; // Backend'e kaydetmek için çalışan ID'si

  bool _isLoading = true;

  // Profil düzenleme durumu
  bool _isEditingProfile = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;
  late TextEditingController _buildingController;

  // Şifre değiştirme durumu
  bool _isPasswordExpanded = false;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String _passwordStrength = '';
  int _passwordStrengthLevel = 0; // 0-4 arası (0: çok zayıf, 4: çok güçlü)
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Widget build edildikten sonra verileri çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _positionController = TextEditingController();
    _buildingController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    // Şifre güç kontrolü için listener ekle
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final password = _newPasswordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthLevel = 0;
      });
      return;
    }

    int strength = 0;
    String strengthText = '';

    // Uzunluk kontrolü
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Büyük harf kontrolü
    if (password.contains(RegExp(r'[A-Z]'))) strength++;

    // Küçük harf kontrolü
    if (password.contains(RegExp(r'[a-z]'))) strength++;

    // Rakam kontrolü
    if (password.contains(RegExp(r'[0-9]'))) strength++;

    // Özel karakter kontrolü
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    // Güç seviyesini 0-4 arasına sınırla
    _passwordStrengthLevel = strength > 4 ? 4 : strength;

    // Güç metni
    if (_passwordStrengthLevel <= 1) {
      strengthText = 'Çok Zayıf';
    } else if (_passwordStrengthLevel == 2) {
      strengthText = 'Zayıf';
    } else if (_passwordStrengthLevel == 3) {
      strengthText = 'Orta';
    } else if (_passwordStrengthLevel == 4) {
      strengthText = 'Güçlü';
    } else {
      strengthText = 'Çok Güçlü';
    }

    setState(() {
      _passwordStrength = strengthText;
    });
  }

  Future<void> _loadUserData() async {
    // Auth provider asenkron çalıştığı için, değeri gerçekten yüklenene kadar bekleyelim
    final authState = await ref.read(authControllerProvider.future);
    final user = authState?.userData;

    if (user != null) {
      setState(() {
        _userRole = user['role'] ?? 'Kullanıcı';
        // Email artık users tablosunda yok, employees tablosundan alınacak
      });

      // Çalışan bilgilerini çek (User ID ile) - İsim ve email bilgisi de buradan gelecek
      try {
        final userId = user['id']; // AuthProvider'dan gelen ID
        debugPrint('Aranan User ID: $userId');

        if (userId != null) {
          final employee = await _employeeService.getEmployeeByUserId(userId);
          debugPrint('Bulunan Çalışan: $employee');
          
          if (employee != null) {
            setState(() {
              // İsim ve email bilgilerini employees tablosundan al
              final firstName = employee['first_name'] ?? '';
              final lastName = employee['last_name'] ?? '';
              _userName = '$firstName $lastName'.trim();
              _userEmail = employee['email'] ?? ''; // Email employees tablosundan
              _userPhone = employee['phone'] ?? '';
              _userPosition = employee['position'] ?? '';
              _userHireDate = employee['hire_date'] != null 
                  ? DateTime.parse(employee['hire_date']) 
                  : DateTime.now();
              _employeeId = employee['id']?.toString(); // Çalışan ID'sini sakla
            });

            // Bina bilgilerini çek
            if (employee['building_id'] != null) {
              debugPrint('Bina ID: ${employee['building_id']}');
              final building = await _buildingService.getBuilding(employee['building_id']);
              setState(() {
                _userBuilding = building['name'] ?? 'Bina #${employee['building_id']}';
              });
            }
          } else {
             debugPrint('Çalışan kaydı bulunamadı (API null döndü)');
          }
        }
      } catch (e) {
        debugPrint('Kullanıcı detayları yüklenirken hata: $e');
      }
    }

    setState(() {
      _isLoading = false;
      _updateControllers();
    });
  }

  void _updateControllers() {
    _nameController.text = _userName;
    _emailController.text = _userEmail;
    _phoneController.text = _userPhone;
    _positionController.text = _userPosition;
    _buildingController.text = _userBuilding;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _buildingController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    if (_isLoading) {
      return const ScaffoldPage(
        content: Center(child: ProgressRing()),
      );
    }

    return ScaffoldPage(
      content: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Profil Kartı
            _buildProfileCard(theme),
            const SizedBox(height: 24),
            
            // Güvenlik
            Card(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildPasswordChangeSection(theme),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Uygulama Tercihleri
            Card(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildThemeSelector(theme),
                  const SizedBox(height: 12),
                   _buildSettingSwitch(
                  'Bildirimler',
                  FluentIcons.ringer,
                  _notifications,
                  (value) {
                    setState(() {
                      _notifications = value;
                    });
                    // TODO: Bildirim ayarlarını güncelle
                  },
                  theme,
                ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hakkında
            Card(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildSettingTile(
                    'Uygulama Versiyonu',
                      FluentIcons.app_icon_default,
                    'v1.0.0',
                    null,
                    theme,
                  ),
                    const SizedBox(height: 8),
                  _buildSettingTile(
                    'Lisans Bilgileri',
                      FluentIcons.document,
                    'MIT License',
                      null,
                    theme,
                  ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(FluentThemeData theme) {
    return Card(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FluentIcons.contact,
                  size: 40,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _isEditingProfile 
                  ? _buildProfileEditForm(theme)
                  : _buildProfileInfo(theme),
              ),
              if (!_isEditingProfile)
                IconButton(
                  icon: const Icon(FluentIcons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditingProfile = true;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(FluentThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _userName,
          style: theme.typography.title,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _userRole,
                style: theme.typography.caption?.copyWith(
                  color: theme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _userPosition,
                style: theme.typography.caption,
              ),
            ),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _userBuilding,
                style: theme.typography.caption?.copyWith(
                   color: Colors.orange.dark,
                   fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoRow(FluentIcons.mail, _userEmail, theme),
        const SizedBox(height: 8),
        _buildInfoRow(FluentIcons.phone, _userPhone, theme),
        const SizedBox(height: 8),
        _buildInfoRow(FluentIcons.city_next, 'Bina: $_userBuilding', theme),
        const SizedBox(height: 8),
        _buildInfoRow(FluentIcons.calendar, 'İşe Başlama: ${_userHireDate.day}.${_userHireDate.month}.${_userHireDate.year}', theme),
      ],
    );
  }

  Widget _buildProfileEditForm(FluentThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profili Düzenle', style: theme.typography.subtitle),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Ad Soyad',
          child: TextBox(
            controller: _nameController,
            placeholder: 'Ad Soyad giriniz',
          ),
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'E-posta',
          child: TextBox(
            controller: _emailController,
            placeholder: 'E-posta adresi giriniz',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 12),
        InfoLabel(
          label: 'Telefon',
          child: TextBox(
            controller: _phoneController,
            placeholder: 'Telefon numarası giriniz',
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InfoLabel(
                label: 'Pozisyon',
                child: TextBox(
                  controller: _positionController,
                  placeholder: 'Pozisyon',
                ),
              ),
            ),
            const SizedBox(width: 12),
             Expanded(
              child: InfoLabel(
                label: 'Bağlı Olduğu Bina',
                child: TextBox(
                  controller: _buildingController,
                  placeholder: 'Bina Adı/ID',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InfoLabel(
           label: 'İşe Başlama Tarihi',
           child: DatePicker(
             selected: _userHireDate,
             onChanged: (date) {
               setState(() {
                 _userHireDate = date;
               });
             },
           ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button(
              child: const Text('İptal'),
              onPressed: () {
                setState(() {
                  _isEditingProfile = false;
                  // Değişiklikleri geri al
                  _nameController.text = _userName;
                  _emailController.text = _userEmail;
                  _phoneController.text = _userPhone;
                  _positionController.text = _userPosition;
                  _buildingController.text = _userBuilding;
                });
              },
            ),
            const SizedBox(width: 12),
            FilledButton(
              child: const Text('Kaydet'),
              onPressed: () async {
                if (_employeeId == null) {
                  showErrorInfoBar(context, 'Çalışan bilgisi bulunamadı.');
                  return;
                }

                try {
                  // Ad Soyad'ı first_name ve last_name'e ayır
                  final nameParts = _nameController.text.trim().split(' ');
                  final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
                  final lastName = nameParts.length > 1 
                      ? nameParts.sublist(1).join(' ') 
                      : '';

                  // Backend'e gönderilecek veri (email artık employees tablosunda)
                  final updateData = {
                    'first_name': firstName,
                    'last_name': lastName,
                    'email': _emailController.text.trim(), // Email employees tablosunda
                    'phone': _phoneController.text.trim(),
                    'position': _positionController.text.trim(),
                    'hire_date': _userHireDate.toIso8601String().split('T')[0], // YYYY-MM-DD formatı
                  };

                  // Backend'e kaydet (employees tablosu - email dahil)
                  await _employeeService.updateEmployee(_employeeId!, updateData);

                  // Başarılı olursa state'i güncelle
                  setState(() {
                    _userName = _nameController.text;
                    _userEmail = _emailController.text;
                    _userPhone = _phoneController.text;
                    _userPosition = _positionController.text;
                    _userBuilding = _buildingController.text;
                    _isEditingProfile = false;
                  });

                  showSuccessInfoBar(context, 'Profil bilgileri güncellendi.');
                  
                  // Verileri yeniden yükle (bina bilgisi de güncellenebilir)
                  await _loadUserData();
                } catch (e) {
                  debugPrint('Profil güncelleme hatası: $e');
                  showErrorInfoBar(context, 'Profil güncellenirken hata oluştu: ${e.toString()}');
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, FluentThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.typography.body?.color?.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.typography.body,
        ),
      ],
    );
  }

  Widget _buildSection(
    FluentThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.accentColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Card(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(FluentThemeData theme) {
    // Tema değişikliklerini dinle
    final currentThemeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentThemeModeString = themeNotifier.getThemeModeString();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(6),
             decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)
             ),
             child: Icon(
               FluentIcons.brightness,
               color: theme.accentColor,
               size: 16,
             ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Tema Modu',
              style: theme.typography.bodyStrong,
            ),
          ),
          ComboBox<String>(
            value: currentThemeModeString,
            items: _themeOptions.map((mode) {
              return ComboBoxItem(
                value: mode,
                child: Text(mode),
              );
            }).toList(),
            onChanged: (value) async {
              if (value != null) {
                await themeNotifier.setThemeMode(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    FluentThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
             padding: const EdgeInsets.all(6),
             decoration: BoxDecoration(
                color: value ? theme.accentColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6)
             ),
             child: Icon(
            icon,
            color: value ? theme.accentColor : theme.iconTheme.color?.withOpacity(0.7),
            size: 16,
          ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.typography.bodyStrong,
            ),
          ),
          ToggleSwitch(
            checked: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback? onTap,
    FluentThemeData theme,
  ) {
    return ListTile(
      onPressed: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: theme.accentColor,
          size: 16,
        ),
      ),
      title: Text(
        title,
        style: theme.typography.bodyStrong,
      ),
      subtitle: Text(
        subtitle,
        style: theme.typography.caption?.copyWith(
          color: theme.typography.caption?.color?.withOpacity(0.7),
        ),
      ),
      trailing: onTap != null
          ? Icon(
              FluentIcons.chevron_right,
              color: theme.iconTheme.color?.withOpacity(0.5),
              size: 12,
            )
          : null,
    );
  }

  Widget _buildPasswordChangeSection(FluentThemeData theme) {
    return Column(
      children: [
        ListTile(
          onPressed: () {
            setState(() {
              _isPasswordExpanded = !_isPasswordExpanded;
              if (!_isPasswordExpanded) {
                // Kapatıldığında formu temizle
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
                _passwordStrength = '';
                _passwordStrengthLevel = 0;
              }
            });
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              FluentIcons.lock,
              color: theme.accentColor,
              size: 16,
            ),
          ),
          title: Text(
            'Şifre Değiştir',
            style: theme.typography.bodyStrong,
          ),
          trailing: Icon(
            _isPasswordExpanded ? FluentIcons.chevron_up : FluentIcons.chevron_down,
            color: theme.iconTheme.color?.withOpacity(0.5),
            size: 12,
          ),
        ),
        if (_isPasswordExpanded) ...[
          const SizedBox(height: 16),
          _buildPasswordChangeForm(theme),
        ],
      ],
    );
  }

  Widget _buildPasswordChangeForm(FluentThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: 'Mevcut Şifre',
          child: TextBox(
            controller: _currentPasswordController,
            placeholder: 'Mevcut şifrenizi giriniz',
            obscureText: _obscureCurrentPassword,
            suffix: IconButton(
              icon: Icon(
                _obscureCurrentPassword ? FluentIcons.view : FluentIcons.hide3,
                size: 16,
              ),
              onPressed: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Yeni Şifre',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextBox(
                controller: _newPasswordController,
                placeholder: 'Yeni şifrenizi giriniz',
                obscureText: _obscureNewPassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? FluentIcons.view : FluentIcons.hide3,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              if (_newPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPasswordStrengthIndicator(theme),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        InfoLabel(
          label: 'Yeni Şifre Tekrar',
          child: TextBox(
            controller: _confirmPasswordController,
            placeholder: 'Yeni şifrenizi tekrar giriniz',
            obscureText: _obscureConfirmPassword,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? FluentIcons.view : FluentIcons.hide3,
                size: 16,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        ),
        if (_confirmPasswordController.text.isNotEmpty &&
            _newPasswordController.text != _confirmPasswordController.text) ...[
          const SizedBox(height: 4),
          Text(
            'Şifreler eşleşmiyor',
            style: theme.typography.caption?.copyWith(
              color: Colors.red,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Button(
              child: const Text('İptal'),
              onPressed: () {
                setState(() {
                  _isPasswordExpanded = false;
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmPasswordController.clear();
                  _passwordStrength = '';
                  _passwordStrengthLevel = 0;
                });
              },
            ),
            const SizedBox(width: 12),
            FilledButton(
              child: const Text('Şifreyi Güncelle'),
              onPressed: () async {
                await _handlePasswordChange(theme);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(FluentThemeData theme) {
    // Renkleri daha canlı yap
    Color getStrengthColor(int level) {
      switch (level) {
        case 0:
        case 1:
          return const Color(0xFFFF4444); // Canlı kırmızı
        case 2:
          return const Color(0xFFFFAA00); // Canlı turuncu/sarı
        case 3:
          return const Color(0xFFFFD700); // Canlı sarı/altın
        case 4:
        default:
          return const Color(0xFF00CC66); // Canlı yeşil
      }
    }

    Color strengthColor = getStrengthColor(_passwordStrengthLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Nokta göstergesi - 4 nokta
            ...List.generate(4, (index) {
              final isActive = index < _passwordStrengthLevel;
              final dotColor = isActive 
                  ? getStrengthColor(_passwordStrengthLevel)
                  : Colors.grey.withOpacity(0.3);
              
              return Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive 
                          ? dotColor 
                          : Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),
            Text(
              _passwordStrength,
              style: theme.typography.caption?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Şifre en az 8 karakter, büyük harf, küçük harf ve rakam içermelidir',
          style: theme.typography.caption?.copyWith(
            color: theme.typography.caption?.color?.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePasswordChange(FluentThemeData theme) async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validasyon
    if (currentPassword.isEmpty) {
      showErrorInfoBar(context, 'Lütfen mevcut şifrenizi giriniz.');
      return;
    }

    if (newPassword.isEmpty) {
      showErrorInfoBar(context, 'Lütfen yeni şifrenizi giriniz.');
      return;
    }

    if (newPassword.length < 8) {
      showErrorInfoBar(context, 'Yeni şifre en az 8 karakter olmalıdır.');
      return;
    }

    if (_passwordStrengthLevel < 2) {
      showErrorInfoBar(
        context,
        'Lütfen daha güçlü bir şifre seçiniz. Şifre en az bir büyük harf, bir küçük harf ve bir rakam içermelidir.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showErrorInfoBar(
        context,
        'Yeni şifreler eşleşmiyor. Lütfen yeni şifrenizi tekrar doğru girdiğinizden emin olun.',
      );
      return;
    }

    if (currentPassword == newPassword) {
      showErrorInfoBar(
        context,
        'Yeni şifre mevcut şifre ile aynı olamaz. Lütfen farklı bir şifre seçiniz.',
      );
      return;
    }

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Başarılı olursa formu temizle ve kapat
      setState(() {
        _isPasswordExpanded = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _passwordStrength = '';
        _passwordStrengthLevel = 0;
      });

      showSuccessInfoBar(context, 'Şifreniz başarıyla güncellendi.');
    } catch (e) {
      debugPrint('Şifre değiştirme hatası: $e');
      
      // Hata mesajını parse et ve kullanıcı dostu hale getir
      String errorMessage = _parsePasswordChangeError(e);
      
      showErrorInfoBar(context, errorMessage);
    }
  }

  String _parsePasswordChangeError(dynamic error) {
    // Önce humanizeError ile temel mesajı al
    String baseMessage = humanizeError(error);
    
    // ApiException ise detaylı kontrol yap
    if (error is ApiException) {
      final statusCode = error.statusCode;
      final message = error.message.toLowerCase();
      
      // Mevcut şifre yanlış hatası (400)
      if (statusCode == 400 && 
          (message.contains('mevcut şifre yanlış') || 
           message.contains('mevcut şifre') ||
           message.contains('current_password') ||
           (message.contains('yanlış') && message.contains('şifre')))) {
        return 'Mevcut şifreniz yanlış. Lütfen doğru şifreyi girdiğinizden emin olun.';
      }
      
      // Yeni şifre mevcut şifre ile aynı hatası (400)
      if (statusCode == 400 && 
          (message.contains('aynı olamaz') || 
           message.contains('same') ||
           message.contains('identical'))) {
        return 'Yeni şifre mevcut şifre ile aynı olamaz. Lütfen farklı bir şifre seçiniz.';
      }
      
      // Şifre validasyon hataları (422 veya 400) - Pydantic validasyon hataları
      if (statusCode == 422 || statusCode == 400) {
        // Birden fazla validasyon hatası olabilir, hepsini kontrol et
        List<String> validationErrors = [];
        
        if (message.contains('8 karakter') || message.contains('min_length')) {
          validationErrors.add('en az 8 karakter');
        }
        if (message.contains('büyük harf') || message.contains('uppercase') || message.contains('isupper')) {
          validationErrors.add('en az bir büyük harf');
        }
        if (message.contains('küçük harf') || message.contains('lowercase') || message.contains('islower')) {
          validationErrors.add('en az bir küçük harf');
        }
        if (message.contains('rakam') || message.contains('digit') || message.contains('isdigit') || message.contains('number')) {
          validationErrors.add('en az bir rakam');
        }
        
        if (validationErrors.isNotEmpty) {
          if (validationErrors.length == 1) {
            return 'Yeni şifre ${validationErrors.first} içermelidir.';
          } else {
            return 'Yeni şifre ${validationErrors.join(', ')} içermelidir.';
          }
        }
      }
      
      // 404 Not Found
      if (statusCode == 404) {
        return 'Şifre değiştirme servisi bulunamadı. Lütfen daha sonra tekrar deneyin.';
      }
      
      // 401 Unauthorized
      if (statusCode == 401) {
        return 'Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.';
      }
      
      // 500 Internal Server Error
      if (statusCode == 500) {
        return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
      }
      
      // Backend'den gelen mesajı direkt kullan (zaten Türkçe ve anlaşılır olmalı)
      // Ancak çok uzunsa kısalt
      if (baseMessage.isNotEmpty && baseMessage != error.toString()) {
        // Eğer mesaj çok uzunsa veya teknik detaylar içeriyorsa, daha kullanıcı dostu hale getir
        if (baseMessage.length > 150) {
          return 'Şifre değiştirilirken bir hata oluştu. Lütfen bilgilerinizi kontrol edip tekrar deneyin.';
        }
        return baseMessage;
      }
    }
    
    // String olarak gelen hatalar için kontrol
    String errorString = error.toString().toLowerCase();
    
    // Timeout hataları
    if (errorString.contains('timeout') || errorString.contains('zaman aşımı')) {
      return 'İstek zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';
    }
    
    // Bağlantı hataları
    if (errorString.contains('connection') || 
        errorString.contains('bağlantı') ||
        errorString.contains('network') ||
        errorString.contains('connectionerror')) {
      return 'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.';
    }
    
    // Genel hata mesajı - humanizeError'dan gelen mesajı kullan
    if (baseMessage.isNotEmpty && baseMessage.length < 200 && !baseMessage.contains('ApiException')) {
      return baseMessage;
    }
    
    // Son çare: genel mesaj
    return 'Şifre değiştirilirken bir hata oluştu. Lütfen bilgilerinizi kontrol edip tekrar deneyin.';
  }

}
