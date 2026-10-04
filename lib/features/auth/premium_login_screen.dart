import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/auth/access_control.dart';
import '../../core/demo/demo_session_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/admin_shell.dart';
import '../dashboard/center_shell.dart';
import '../dashboard/doctor_shell.dart';
import '../dashboard/patient_shell.dart';

enum LoginRole { admin, doctor, reviewer, center, patient }

class PremiumLoginScreen extends StatefulWidget {
  const PremiumLoginScreen({super.key});

  @override
  State<PremiumLoginScreen> createState() => _PremiumLoginScreenState();
}

class _PremiumLoginScreenState extends State<PremiumLoginScreen> {
  LoginRole? _role;

  void _login() {
    final role = _role;
    if (role == null) return;
    final access = context.read<AccessControlProvider>();
    final demoPatientId = context.read<DemoSessionProvider>().patientId;
    final Widget destination;
    switch (role) {
      case LoginRole.admin:
        access.setRole(AppRole.systemAdmin);
        destination = const AdminShell();
      case LoginRole.doctor:
        access.setRole(AppRole.doctor);
        destination = DoctorShell(initialPatientId: demoPatientId);
      case LoginRole.reviewer:
        access.setRole(AppRole.medicalReviewer);
        destination = DoctorShell(
          initialPatientId: demoPatientId,
          initialTabIndex: 1,
        );
      case LoginRole.center:
        access.setRole(AppRole.pharmacist);
        destination = CenterShell(initialPatientId: demoPatientId);
      case LoginRole.patient:
        access.setRole(AppRole.patient);
        context.read<DemoSessionProvider>().selectPatient('P999');
        destination = const PatientShell();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: destination),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) {
            return _LoginForm(
              compact: true,
              selectedRole: _role,
              onRoleChanged: (role) => setState(() => _role = role),
              onLogin: _login,
            );
          }
          final formDirection = Directionality.of(context);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _CareJourneyPanel()),
                Expanded(
                  child: Directionality(
                    textDirection: formDirection,
                    child: _LoginForm(
                      selectedRole: _role,
                      onRoleChanged: (role) => setState(() => _role = role),
                      onLogin: _login,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CareJourneyPanel extends StatelessWidget {
  const _CareJourneyPanel();

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final steps = ar
        ? [
            'تسجيل المريض',
            'القرار السريري',
            'المراجعة والاعتماد',
            'الصرف والمتابعة',
          ]
        : [
            'Patient registration',
            'Clinical decision',
            'Review and approval',
            'Dispensing and follow-up',
          ];
    final icons = [
      LucideIcons.userRound,
      LucideIcons.stethoscope,
      LucideIcons.badgeCheck,
      LucideIcons.pill,
    ];
    return ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 42,
                    color: AppColors.accentLight,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    ar
                        ? 'رحلة رعاية واحدة، فرق عمل مترابطة'
                        : 'One care journey, connected teams',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ar
                        ? 'تتبع الطلب من التقييم الطبي حتى صرف العلاج ومتابعة المريض.'
                        : 'Follow each request from clinical assessment through dispensing and patient follow-up.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ...List.generate(
                    steps.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .25),
                              ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              icons[index],
                              size: 18,
                              color: AppColors.accentLight,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              steps[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _LoginForm extends StatefulWidget {
  final LoginRole? selectedRole;
  final ValueChanged<LoginRole> onRoleChanged;
  final VoidCallback onLogin;
  final bool compact;

  const _LoginForm({
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onLogin,
    this.compact = false,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F8F8)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 22 : 36,
        vertical: widget.compact ? 8 : 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: locale.toggleLanguage,
                      icon: const Icon(LucideIcons.globe, size: 15),
                      label: Text(_arabic ? 'English' : 'العربية'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF183E4B),
                        backgroundColor: const Color(0xFFEDF3F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: widget.compact ? 8 : 14),
                  Column(
                    children: [
                      SizedBox(
                        width: widget.compact ? 76 : 120,
                        height: widget.compact ? 76 : 120,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'healthcare',
                        ),
                      ),
                      SizedBox(height: widget.compact ? 5 : 12),
                      Text(
                        'healthcare',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0A3341),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _arabic
                            ? 'منصة إدارة برامج الرعاية الصحية'
                            : 'Healthcare Program Management Platform',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF536E78),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _arabic
                            ? 'عمليات رعاية متكاملة وآمنة'
                            : 'Connected and secure care operations',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF75858C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.compact ? 16 : 28),
                  if (widget.compact) ...[
                    _mobileAssistantCard(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _arabic ? 'اختر مساحة العمل' : 'Choose a workspace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF082E3C),
                      fontSize: widget.compact ? 26 : 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _arabic
                        ? 'تابع رحلة الرعاية من منظور كل فريق'
                        : 'Explore the connected care journey by role',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6D7D85),
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: widget.compact ? 16 : 25),
                  _fieldLabel(
                    _arabic ? 'اختر بوابة الدخول' : 'Choose your portal',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _role(
                        LoginRole.admin,
                        LucideIcons.shieldCheck,
                        'النظام',
                        'System',
                        'إدارة شاملة وصلاحيات الأمن',
                        'Full management & security',
                      ),
                      _role(
                        LoginRole.doctor,
                        LucideIcons.stethoscope,
                        'الطبيب',
                        'Doctor',
                        'إدارة المرضى وخطط العلاج',
                        'Patients & treatment plans',
                      ),
                      if (!widget.compact)
                        _role(
                          LoginRole.reviewer,
                          LucideIcons.badgeCheck,
                          'المراجع الطبي',
                          'Medical Reviewer',
                          'مراجعة واعتماد الطلبات',
                          'Review & approve requests',
                        ),
                      _role(
                        LoginRole.center,
                        LucideIcons.pill,
                        'منشأة الصرف',
                        'Pharmacy',
                        'إدارة الصرف والمخزون',
                        'Dispensing & inventory',
                      ),
                      _role(
                        LoginRole.patient,
                        LucideIcons.userRound,
                        'المريض',
                        'Patient',
                        'متابعة رحلتي العلاجية',
                        'Track my health journey',
                      ),
                    ],
                  ),
                  SizedBox(height: widget.compact ? 18 : 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: widget.selectedRole != null
                          ? widget.onLogin
                          : null,
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? LucideIcons.arrowLeft
                            : LucideIcons.arrowRight,
                        size: 18,
                      ),
                      label: Text(
                        _arabic ? 'فتح مساحة العمل' : 'Open workspace',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.surfaceMuted,
                        disabledForegroundColor: AppColors.disabled,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _arabic
                        ? 'نسخة تجريبية • لا يوجد تسجيل دخول أو مزامنة حقيقية'
                        : 'Demo preview • No real sign-in or live sync',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF75858C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileAssistantCard() {
    final title = _arabic ? 'مساعد الرعاية' : 'Care assistant';
    final detail = _arabic
        ? 'معاينة توضيحية مبنية على بيانات التجربة'
        : 'Preview illustration · demo records only';

    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.paleSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/illustrations/healthcare_assistant.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF123D3F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF526B67),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(LucideIcons.sparkles, size: 18, color: AppColors.primaryDark),
        ],
      ),
    );
  }

  Widget _role(
    LoginRole role,
    IconData icon,
    String ar,
    String en,
    String subAr,
    String subEn,
  ) {
    final selected = widget.selectedRole == role;
    final label = _arabic ? ar : en;
    final compactDescriptions = {
      LoginRole.admin: _arabic ? 'إدارة النظام' : 'Admin operations',
      LoginRole.doctor: _arabic ? 'رعاية المرضى' : 'Patient care',
      LoginRole.center: _arabic ? 'الدواء والمخزون' : 'Medicine & stock',
      LoginRole.patient: _arabic ? 'رحلتي الصحية' : 'My care journey',
      LoginRole.reviewer: _arabic ? 'مراجعة الطلبات' : 'Request review',
    };
    final description = widget.compact
        ? compactDescriptions[role]!
        : (_arabic ? subAr : subEn);
    return SizedBox(
      width: widget.compact ? (MediaQuery.sizeOf(context).width - 52) / 2 : 92,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: widget.compact ? 0 : 6),
        child: Semantics(
          button: true,
          selected: selected,
          label: '$label. $description',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onRoleChanged(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: widget.compact ? 92 : 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: .09)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFDCE5E8),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF718088),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF42545C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 9,
                      color: const Color(0xFF657A76),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF304A54),
      fontWeight: FontWeight.w700,
      fontSize: 14,
    ),
  );
}

class _HealthcareStory extends StatefulWidget {
  final bool compact;
  const _HealthcareStory({required this.compact});

  @override
  State<_HealthcareStory> createState() => _HealthcareStoryState();
}

class _HealthcareStoryState extends State<_HealthcareStory>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _hovered;

  bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = .7;
      } else {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => LayoutBuilder(
        builder: (context, box) {
          final t = _controller.value;
          final pulse = math.sin(t * math.pi * 2);
          return ClipRect(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF061C2A),
                    Color(0xFF063943),
                    Color(0xFF064532),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _AmbientPainter(t)),
                  Transform.translate(
                    offset: widget.compact
                        ? Offset.zero
                        : Offset(pulse * 8, -pulse * 3),
                    child: Transform.scale(
                      scale: widget.compact ? 1 : .98 + .035 * _camera(t),
                      child: _scene(box, t),
                    ),
                  ),
                  PositionedDirectional(
                    start: widget.compact ? 18 : 36,
                    end: widget.compact ? 18 : 36,
                    bottom: widget.compact ? 15 : 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _arabic
                              ? 'من البيانات إلى الرعاية المتكاملة'
                              : 'From data to connected care',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.compact ? 18 : 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _arabic
                              ? 'نظام ذكي يربط رحلة المريض من التسجيل إلى العلاج والصرف والمتابعة.'
                              : 'One intelligent system connecting the complete patient journey.',
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .7),
                            fontSize: widget.compact ? 9.5 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scene(BoxConstraints box, double t) {
    final modules = widget.compact
        ? _storyModules.take(4).toList()
        : _storyModules;
    final w = box.maxWidth;
    final h = box.maxHeight;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _NetworkPainter(
              t,
              modules.map((e) => e.position).toList(),
            ),
          ),
        ),
        Positioned(
          left: widget.compact ? w * .38 : w * .41,
          top: widget.compact ? h * .24 : h * .27,
          width: widget.compact ? 92 : math.min(w * .21, 205),
          height: widget.compact ? 120 : math.min(h * .38, 315),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x333FE0C7),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, .72, 1],
                ).createShader(rect),
                child: Image.asset(
                  'assets/images/doctor.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        if (!widget.compact)
          Positioned(
            left: w * .36,
            top: h * .1,
            width: math.min(w * .3, 300),
            child: _aiPanel(t),
          ),
        ...modules.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final visible = _stage(t, .05 + i * .045);
          final width = widget.compact ? 128.0 : math.min(w * .23, 225.0);
          final x = (item.position.dx * w - width / 2).clamp(
            8.0,
            w - width - 8,
          );
          final y = (item.position.dy * h).clamp(8.0, h - 116);
          return Positioned(
            left: x,
            top: y,
            width: width,
            child: Opacity(
              opacity: visible,
              child: Transform.translate(
                offset: Offset(
                  0,
                  (1 - visible) * 14 + math.sin(t * 8 + i) * 2.5,
                ),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hovered = i),
                  onExit: (_) => setState(() => _hovered = null),
                  child: _module(item, _hovered == i, i == 0),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _aiPanel(double t) => ClipRRect(
    borderRadius: BorderRadius.circular(17),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFF082635).withValues(alpha: .72),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFF5CE9D7).withValues(alpha: .45),
          ),
        ),
        child: Row(
          children: [
            Transform.rotate(
              angle: t * math.pi * 2,
              child: Container(
                width: 39,
                height: 39,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFF4CE0CB),
                      Colors.transparent,
                      Color(0xFF729EFF),
                    ],
                  ),
                ),
                child: const Icon(
                  LucideIcons.brainCircuit,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI HEALTH ASSISTANT',
                    style: TextStyle(
                      color: Color(0xFF68F0DE),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  Text(
                    _arabic
                        ? 'تحليل بيانات المريض...'
                        : 'Analyzing patient data...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _module(
    _StoryModule item,
    bool hovered,
    bool patient,
  ) => AnimatedScale(
    duration: const Duration(milliseconds: 220),
    scale: hovered ? 1.055 : 1,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(
              0xFF0A3440,
            ).withValues(alpha: hovered ? .9 : .68),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.color.withValues(alpha: hovered ? .9 : .4),
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: hovered ? .2 : .07),
                blurRadius: 18,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: item.color, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _arabic ? item.ar : item.en,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: item.color, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
              if (!widget.compact || hovered) ...[
                const SizedBox(height: 6),
                Text(
                  patient
                      ? (_arabic
                            ? 'أحمد المنصوري · 45 سنة\n784-1990-1234567-1 · نشط'
                            : 'Ahmed Al Mansoori · 45\n784-1990-1234567-1 · Active')
                      : (_arabic ? item.detailAr : item.detailEn),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .68),
                    fontSize: 8.8,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  double _camera(double t) =>
      Curves.easeInOut.transform(t < .5 ? t * 2 : (1 - t) * 2);

  double _stage(double t, double start) {
    if (t > .93) return ((1 - t) / .07).clamp(0, 1);
    return ((t - start) / .055).clamp(0, 1);
  }
}

class _StoryModule {
  final String ar;
  final String en;
  final String detailAr;
  final String detailEn;
  final IconData icon;
  final Color color;
  final Offset position;

  const _StoryModule(
    this.ar,
    this.en,
    this.detailAr,
    this.detailEn,
    this.icon,
    this.color,
    this.position,
  );
}

const _storyModules = <_StoryModule>[
  _StoryModule(
    'سجل المرضى',
    'Patient Profile',
    'بيانات المريض ومؤشراته الصحية',
    'Patient identity and health indicators',
    LucideIcons.userRound,
    Color(0xFF55E2CF),
    Offset(.17, .17),
  ),
  _StoryModule(
    'نتائج المختبر',
    'Laboratory',
    'HbA1c · CRP · ESR · سكر الدم',
    'HbA1c · CRP · ESR · glucose',
    LucideIcons.flaskConical,
    Color(0xFF72A8FF),
    Offset(.79, .17),
  ),
  _StoryModule(
    'الذكاء الاصطناعي',
    'AI Insights',
    'تحليل التاريخ والمخاطر والتوصيات',
    'History, risks and recommendations',
    LucideIcons.brainCircuit,
    Color(0xFFA08CFF),
    Offset(.11, .42),
  ),
  _StoryModule(
    'خطة العلاج',
    'Treatment Plan',
    'الدواء والجرعة والمتابعة',
    'Medication, dosage and follow-up',
    LucideIcons.clipboardCheck,
    Color(0xFFECC260),
    Offset(.86, .41),
  ),
  _StoryModule(
    'الأهلية',
    'Eligibility',
    'المعايير السريرية والتغطية: مؤهل',
    'Clinical criteria and coverage: eligible',
    LucideIcons.shieldCheck,
    Color(0xFF54D39A),
    Offset(.14, .66),
  ),
  _StoryModule(
    'الصيدلية والصرف',
    'Pharmacy',
    'المخزون وآخر صرف والاستحقاق',
    'Inventory, dispense and eligibility',
    LucideIcons.pill,
    Color(0xFF50D6E7),
    Offset(.85, .65),
  ),
  _StoryModule(
    'المواعيد',
    'Appointments',
    'الطبيب والتاريخ وموعد المتابعة',
    'Doctor, date and follow-up',
    LucideIcons.calendarDays,
    Color(0xFFFFA867),
    Offset(.29, .78),
  ),
  _StoryModule(
    'سجل التدقيق',
    'Audit Trail',
    'إنشاء ← اعتماد ← صرف ← متابعة',
    'Created → approved → dispensed → follow-up',
    LucideIcons.listChecks,
    Color(0xFF86DFB8),
    Offset(.67, .78),
  ),
];

class _AmbientPainter extends CustomPainter {
  final double progress;
  _AmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF38D7BD).withValues(alpha: .17),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .55, size.height * .46),
              radius: size.shortestSide * .58,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final paint = Paint()
      ..color = const Color(0xFF9BF6E8).withValues(alpha: .33);
    for (var i = 0; i < 38; i++) {
      final x = (i * 73.0 + progress * size.width * .2) % size.width;
      final y = (i * 49.0 + math.sin(progress * 7 + i) * 17) % size.height;
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.7 : .8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => true;
}

class _NetworkPainter extends CustomPainter {
  final double progress;
  final List<Offset> points;
  _NetworkPainter(this.progress, this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .47);
    final line = Paint()
      ..color = const Color(0xFF4FE1CD).withValues(alpha: .22)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final particle = Paint()..color = const Color(0xFF83F7E7);
    for (var i = 0; i < points.length; i++) {
      final target = Offset(
        points[i].dx * size.width,
        points[i].dy * size.height,
      );
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          (center.dx + target.dx) / 2,
          center.dy + (i.isEven ? -25 : 25),
          target.dx,
          target.dy,
        );
      canvas.drawPath(path, line);
      final metric = path.computeMetrics().first;
      final tangent = metric.getTangentForOffset(
        metric.length * ((progress * 2.1 + i * .13) % 1),
      );
      if (tangent != null) canvas.drawCircle(tangent.position, 2, particle);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => true;
}
