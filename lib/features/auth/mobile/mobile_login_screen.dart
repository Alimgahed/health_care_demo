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

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  UserRole? _selectedRole;
  bool _isLoading = false;

  void _handleLogin() {
    if (_selectedRole == null) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network authentication
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
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // Header Logo Area
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                        child: Column(
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.health_and_safety,
                                          size: 60,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              t.translate('login_title'),
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.translate('login_subtitle'),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.accentLight,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Login Card
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 20,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  t.translate('select_role'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t.translate('choose_portal'),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Roles Grid (Flexible to prevent overflow)
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Column(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildRoleCard(
                                                    role: UserRole.admin,
                                                    title: t.translate(
                                                      'ministry_executive',
                                                    ),
                                                    icon: LucideIcons.building2,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _buildRoleCard(
                                                    role: UserRole.doctor,
                                                    title: t.translate(
                                                      'doctor_physician',
                                                    ),
                                                    icon:
                                                        LucideIcons.stethoscope,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildRoleCard(
                                                    role: UserRole.center,
                                                    title: t.translate(
                                                      'dispensing_center',
                                                    ),
                                                    icon: LucideIcons.store,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: _buildRoleCard(
                                                    role: UserRole.patient,
                                                    title: t.translate(
                                                      'patient_portal',
                                                    ),
                                                    icon: LucideIcons.user,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                 const SizedBox(height: 16),
                                 if (_selectedRole != null)
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                     decoration: BoxDecoration(
                                       color: AppColors.primary.withOpacity(0.06),
                                       borderRadius: BorderRadius.circular(12),
                                       border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                                     ),
                                     child: Text(
                                       _selectedRole == UserRole.admin
                                           ? 'Demo Credential: admin@moh.gov.ae'
                                           : (_selectedRole == UserRole.doctor
                                               ? 'Demo Credential: clinical@moh.gov.ae'
                                               : (_selectedRole == UserRole.center
                                                   ? 'Demo Credential: pharmacy@moh.gov.ae'
                                                   : 'Demo Credential: patient@mounjaro.ae')),
                                       style: const TextStyle(
                                         color: AppColors.navy,
                                         fontWeight: FontWeight.bold,
                                         fontSize: 12,
                                       ),
                                       textAlign: TextAlign.center,
                                     ),
                                   ),
                                 const SizedBox(height: 24),

                                 // Access Button
                                 Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _selectedRole != null
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _selectedRole != null && !_isLoading
                                        ? _handleLogin
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _selectedRole != null
                                          ? AppColors.primary
                                          : AppColors.border,
                                      foregroundColor: _selectedRole != null
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            t.translate('access_portal'),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: _selectedRole != null
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                                // Add bottom safe area padding naturally
                                SizedBox(
                                  height: MediaQuery.of(context).padding.bottom,
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
          ),

          // Language Switcher Toggle
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton.icon(
                  onPressed: () {
                    localeProvider.toggleLanguage();
                  },
                  icon: const Icon(LucideIcons.globe, color: Colors.white),
                  label: Text(
                    localeProvider.locale.languageCode == 'en'
                        ? 'العربية'
                        : 'English',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.border.withOpacity(0.5),
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
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.navy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
