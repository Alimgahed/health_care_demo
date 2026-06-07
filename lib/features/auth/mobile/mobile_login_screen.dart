import 'dart:ui';
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

class _MobileLoginScreenState extends State<MobileLoginScreen> with SingleTickerProviderStateMixin {
  UserRole? _selectedRole;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
              ),
            ),
          ),
          
          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Premium Logo Presentation
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Icon(
                                          Icons.health_and_safety,
                                          size: 60,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            t.translate('login_title'),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.translate('login_subtitle'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.surface.withValues(alpha: 0.85),
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Login Form Card
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t.translate('select_role'),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.translate('choose_portal'),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildRoleCard(
                                    role: UserRole.doctor,
                                    title: t.translate('doctor_physician'),
                                    imagePath: 'assets/images/doctor.png',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRoleCard(
                                    role: UserRole.center,
                                    title: t.translate('dispensing_center'),
                                    imagePath: 'assets/images/pharmacy.png',
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                            
                            // Demo Credential Banner
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _selectedRole != null
                                  ? Container(
                                      key: ValueKey<UserRole>(_selectedRole!),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(LucideIcons.info, color: AppColors.primary, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _selectedRole == UserRole.admin
                                                  ? 'Demo: admin@moh.gov.ae'
                                                  : (_selectedRole == UserRole.doctor
                                                      ? 'Demo: clinical@moh.gov.ae'
                                                      : (_selectedRole == UserRole.center
                                                          ? 'Demo: pharmacy@moh.gov.ae'
                                                          : 'Demo: patient@mounjaro.ae')),
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            
                            const Spacer(),
                            const SizedBox(height: 32),

                            // Premium Access Button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: _selectedRole != null
                                    ? LinearGradient(
                                        colors: [AppColors.primary, AppColors.primaryDark],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: _selectedRole == null ? AppColors.border.withValues(alpha: 0.5) : null,
                                boxShadow: _selectedRole != null
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _selectedRole != null && !_isLoading ? _handleLogin : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Center(
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
                                              fontSize: 18,
                                              fontWeight: _selectedRole != null ? FontWeight.w800 : FontWeight.w600,
                                              color: _selectedRole != null ? Colors.white : AppColors.textSecondary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Language Switcher Toggle with Glassmorphism
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                    child: TextButton.icon(
                      onPressed: () {
                        localeProvider.toggleLanguage();
                      },
                      icon: const Icon(LucideIcons.globe, color: Colors.white, size: 18),
                      label: Text(
                        localeProvider.locale.languageCode == 'en' ? 'العربية' : 'English',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.background.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
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
    required String imagePath,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 160, // Fixed height to prevent overflow and ensure uniformity
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected  ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                      height: 1.2,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}