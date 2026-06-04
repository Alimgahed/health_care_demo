import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../dashboard/admin_shell.dart';
import '../../dashboard/center_shell.dart';
import '../../dashboard/doctor_shell.dart';
import '../../dashboard/patient_shell.dart';

enum UserRole { admin, doctor, center, patient }

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  UserRole? _selectedRole;
  UserRole? _hoveredRole;
  bool _isLoading = false;


  void _handleLogin() {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Widget nextScreen;
      switch (_selectedRole!) {
        case UserRole.admin:
          nextScreen = const AdminShell();
          break;
        case UserRole.doctor:
          nextScreen = const DoctorShell();
          break;
        case UserRole.center:
          nextScreen = const CenterShell();
          break;
        case UserRole.patient:
          nextScreen = const PatientShell();
          break;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side: Graphic / Branding
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.health_and_safety,
                                  size: 80,
                                  color: AppColors.primary,
                                ),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      t.translate('login_title'),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.translate('login_subtitle'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.accentLight,
                        letterSpacing: 4.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Side: Login Form
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t.translate('select_role'),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.translate('choose_portal'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          
                          // Roles Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleCard(
                                  role: UserRole.admin,
                                  title: t.translate('ministry_executive'),
                                  icon: LucideIcons.building2,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildRoleCard(
                                  role: UserRole.doctor,
                                  title: t.translate('doctor_physician'),
                                  icon: LucideIcons.stethoscope,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoleCard(
                                  role: UserRole.center,
                                  title: t.translate('dispensing_center'),
                                  icon: LucideIcons.store,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildRoleCard(
                                  role: UserRole.patient,
                                  title: t.translate('patient_portal'),
                                  icon: LucideIcons.user,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          if (_selectedRole != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.key, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedRole == UserRole.admin
                                          ? 'Demo Credential: admin@moh.gov.ae (National Executive)'
                                          : (_selectedRole == UserRole.doctor
                                              ? 'Demo Credential: clinical@moh.gov.ae (Clinician Portal)'
                                              : (_selectedRole == UserRole.center
                                                  ? 'Demo Credential: pharmacy@moh.gov.ae (Dispensing Depot)'
                                                  : 'Demo Credential: patient@mounjaro.ae (Ahmed Al Mansoori)')),
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 40),
                          
                          // Access Button
                          Container(

                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedRole != null
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      )
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: _selectedRole != null && !_isLoading ? _handleLogin : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedRole != null ? AppColors.primary : AppColors.border.withOpacity(0.5),
                                foregroundColor: _selectedRole != null ? Colors.white : AppColors.textSecondary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      t.translate('access_portal'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: _selectedRole != null ? FontWeight.w700 : FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Language Switcher Toggle
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: TextButton.icon(
                      onPressed: () {
                        localeProvider.toggleLanguage();
                      },
                      icon: const Icon(LucideIcons.globe, color: AppColors.navy),
                      label: Text(
                        localeProvider.locale.languageCode == 'en' ? 'العربية' : 'English',
                        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final isHovered = _hoveredRole == role;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRole = role),
      onExit: (_) => setState(() => _hoveredRole = null),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 180, // Fixed height for web cards
          transform: isHovered && !isSelected 
              ? (Matrix4.identity()..translate(0, -6, 0)) 
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isHovered ? AppColors.primary.withOpacity(0.5) : AppColors.border.withOpacity(0.5)),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : (isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.navy,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
