import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import 'session_checkin_screen.dart';

class PlanSessionsScreen extends StatefulWidget {
  final Patient patient;

  const PlanSessionsScreen({super.key, required this.patient});

  @override
  State<PlanSessionsScreen> createState() => _PlanSessionsScreenState();
}

class _PlanSessionsScreenState extends State<PlanSessionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _filterIndex = 0; // 0: All, 1: Completed, 2: Upcoming

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<DataProvider>(context);
    final plan = provider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return _buildEmptyState(context, isDark);
    }

    final upcomingSession = plan.sessions.firstWhere(
      (s) => !s.isAttended,
      orElse: () => plan.sessions.last,
    );
    final centerName = plan.assignedCenterId == null
        ? context.tr('not_assigned')
        : provider.therapyCenterLabel(context, plan.assignedCenterId);

    final attendedSessions = plan.sessions.where((s) => s.isAttended).toList();
    final upcomingSessions = plan.sessions.where((s) => !s.isAttended).toList();

    List<TherapySession> filteredSessions;
    switch (_filterIndex) {
      case 1:
        filteredSessions = attendedSessions;
        break;
      case 2:
        filteredSessions = upcomingSessions;
        break;
      default:
        filteredSessions = plan.sessions;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 20),
            _buildProgressSummary(context, isDark, plan, attendedSessions.length),
            const SizedBox(height: 20),
            _buildUpcomingHeroCard(context, isDark, plan, upcomingSession, centerName),
            const SizedBox(height: 20),
            _buildStreakCard(context, isDark, attendedSessions.length),
            const SizedBox(height: 20),
            _buildSessionStats(context, isDark, plan, attendedSessions),
            const SizedBox(height: 20),
            _buildFilterBar(context, isDark, plan),
            const SizedBox(height: 16),
            ...filteredSessions
                .map((s) => _buildEnhancedSessionCard(context, isDark, s, plan))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.calendarX2,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('no_treatment_plan_mobile'),
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('nav_sessions'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your therapy journey',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Icon(LucideIcons.calendarDays,
              size: 20, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildProgressSummary(BuildContext context, bool isDark,
      dynamic plan, int attended) {
    final double progress = attended / plan.totalSessions;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '$attended of ${plan.totalSessions} sessions',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isDark ? AppColors.darkBorder : AppColors.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                '${plan.totalSessions - attended} remaining',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingHeroCard(BuildContext context, bool isDark, dynamic plan,
      TherapySession upcomingSession, String centerName) {
    final isCompleted = upcomingSession.isAttended;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(LucideIcons.calendarCheck,
                          color: AppColors.surface, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Session',
                            style: TextStyle(
                                color: AppColors.surface70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('session_n_of_total', {
                              'n': '${upcomingSession.sessionNumber}',
                              'total': '${plan.totalSessions}'
                            }),
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withOpacity(0.25)
                            : AppColors.accent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.success.withOpacity(0.5)
                              : AppColors.accent.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        isCompleted ? 'Done' : 'Upcoming',
                        style: TextStyle(
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.accentLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Info row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _buildHeroInfoRow(
                        LucideIcons.calendar,
                        'Date',
                        '${upcomingSession.scheduledDate.day}/${upcomingSession.scheduledDate.month}/${upcomingSession.scheduledDate.year}',
                      ),
                      const SizedBox(height: 10),
                      _buildHeroInfoRow(
                          LucideIcons.mapPin, 'Center', centerName),
                      const SizedBox(height: 10),
                      _buildHeroInfoRow(
                          LucideIcons.clock, 'Time', '10:00 AM'),
                      const SizedBox(height: 10),
                      _buildHeroInfoRow(
                          LucideIcons.userCheck, 'Doctor', 'Dr. Ahmed Khalil'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isCompleted
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionCheckinScreen(
                                    plan: plan, session: upcomingSession),
                              ),
                            );
                          },
                    icon: Icon(
                      isCompleted
                          ? LucideIcons.checkCircle
                          : LucideIcons.logIn,
                      size: 18,
                    ),
                    label: Text(
                      isCompleted
                          ? (context.tr('completed') ?? 'Completed')
                          : context.tr('session_checkin'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white24,
                      disabledForegroundColor: Colors.white54,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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

  Widget _buildHeroInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 15),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: AppColors.surface,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context, bool isDark, int attended) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.flame, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$attended Sessions in a row',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Text(
              '🔥 $attended',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStats(BuildContext context, bool isDark, dynamic plan,
      List<TherapySession> attended) {
    final avgWeight = attended.isEmpty
        ? '--'
        : (attended
                    .where((s) => s.weightAfter != null)
                    .fold<double>(
                        0,
                        (sum, s) => sum + (s.weightAfter ?? 0)) /
                attended.where((s) => s.weightAfter != null).length)
            .toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            isDark,
            icon: LucideIcons.checkCircle2,
            label: 'Completed',
            value: '${attended.length}',
            sub: 'sessions',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            isDark,
            icon: LucideIcons.calendarClock,
            label: 'Remaining',
            value: '${plan.totalSessions - attended.length}',
            sub: 'sessions',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            isDark,
            icon: LucideIcons.scale,
            label: 'Avg Weight',
            value: avgWeight,
            sub: 'kg/session',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(bool isDark,
      {required IconData icon,
      required String label,
      required String value,
      required String sub,
      required Color color}) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(sub,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, bool isDark, dynamic plan) {
    final tabs = ['All', 'Completed', 'Upcoming'];
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('session_history') ?? 'Session History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = _filterIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tabs[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSessionCard(BuildContext context, bool isDark,
      TherapySession session, dynamic plan) {
    final isAttended = session.isAttended;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return GestureDetector(
      onTap: isAttended
          ? () => _showSessionDetailsSheet(context, isDark, session)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAttended
                ? AppColors.success.withOpacity(0.25)
                : borderColor,
            width: isAttended ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isAttended
                    ? AppColors.success.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isAttended
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Icon(
                isAttended ? LucideIcons.checkCircle2 : LucideIcons.clock,
                size: 20,
                color: isAttended ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('session_n_of_total', {
                          'n': '${session.sessionNumber}',
                          'total': '${plan.totalSessions}'
                        }),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAttended
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAttended ? 'Attended' : 'Scheduled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isAttended
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${session.scheduledDate.day}/${session.scheduledDate.month}/${session.scheduledDate.year}',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      if (isAttended && session.weightAfter != null) ...[
                        const SizedBox(width: 12),
                        Icon(LucideIcons.scale,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${session.weightAfter} kg',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isAttended) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight,
                  size: 18, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  void _showSessionDetailsSheet(
      BuildContext context, bool isDark, TherapySession session) {
    final sheetBg = isDark ? AppColors.darkSurface : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.checkCircle2,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session ${session.sessionNumber} Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Completed',
                        style: TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSheetRow(context, isDark,
                  icon: LucideIcons.calendar,
                  label: 'Date',
                  value:
                      '${session.scheduledDate.day}/${session.scheduledDate.month}/${session.scheduledDate.year}',
                  color: AppColors.primary),
              const SizedBox(height: 12),
              _buildSheetRow(context, isDark,
                  icon: LucideIcons.scale,
                  label: context.tr('weight_after') ?? 'Weight After',
                  value: '${session.weightAfter ?? '--'} kg',
                  color: AppColors.info),
              const SizedBox(height: 12),
              _buildSheetRow(context, isDark,
                  icon: LucideIcons.clock,
                  label: 'Duration',
                  value: '45 minutes',
                  color: AppColors.accent),
              const SizedBox(height: 12),
              _buildSheetRow(context, isDark,
                  icon: LucideIcons.userCheck,
                  label: 'Doctor',
                  value: 'Dr. Ahmed Khalil',
                  color: AppColors.success),
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  context.tr('notes') ?? 'Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground.withOpacity(0.5)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border),
                  ),
                  child: Text(
                    session.notes ?? '--',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    context.tr('close') ?? 'Close',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(BuildContext context, bool isDark,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            )),
      ],
    );
  }
}