import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side: Graphic / Branding
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/illustrations/login_hero.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.navy.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('login_title'),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.translate('login_subtitle'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.9),
                              letterSpacing: 2.0,
                            ),
                      ),
                    ],
                  ),
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
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t.translate('select_role'),
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.translate('choose_portal'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textSecondary),
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
                                  imagePath: 'assets/images/admin.png',
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildRoleCard(
                                  role: UserRole.doctor,
                                  title: t.translate('doctor_physician'),
                                  imagePath: 'assets/images/doctor.png',
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
                                  imagePath: 'assets/images/pharmacy.png',
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildRoleCard(
                                  role: UserRole.patient,
                                  title: t.translate('patient_portal'),
                                  imagePath: 'assets/images/patient.png',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          if (_selectedRole != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.key,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedRole == UserRole.admin
                                          ? context.tr('demo_cred_admin')
                                          : (_selectedRole == UserRole.doctor
                                                ? context.tr(
                                                    'demo_cred_clinical',
                                                  )
                                                : (_selectedRole ==
                                                          UserRole.center
                                                      ? context.tr(
                                                          'demo_cred_pharmacy',
                                                        )
                                                      : context.tr(
                                                          'demo_cred_patient',
                                                        ))),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Access Button
                          Container(
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedRole != null
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 
                                          0.3,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: _selectedRole != null && !_isLoading
                                  ? _handleLogin
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedRole != null
                                    ? AppColors.primary
                                    : AppColors.border.withValues(alpha: 0.5),
                                foregroundColor: _selectedRole != null
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 28,
                                      width: 28,
                                      child: CircularProgressIndicator(
                                        color: AppColors.surface,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      t.translate('access_portal'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: _selectedRole != null
                                            ? FontWeight.w700
                                            : FontWeight.w600,
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
                      icon: Icon(
                        LucideIcons.globe,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        localeProvider.locale.languageCode == 'en'
                            ? context.tr('arabic')
                            : context.tr('english'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
    required String imagePath,
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 240, // Uniform height
          transform: isHovered && !isSelected
              ? Matrix4.translationValues(0, -8, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isHovered
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.border.withValues(alpha: 0.5)),
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : (isHovered
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 170, // Fixed height for the image to fill top section
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                      // Optional subtle overlay for selection state
                      if (isSelected)
                        Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title.replaceAll('\n', ' '),
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
