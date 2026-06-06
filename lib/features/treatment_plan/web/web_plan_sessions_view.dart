import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import '../mobile/session_checkin_screen.dart';

class WebPlanSessionsView extends StatefulWidget {
  final Patient patient;

  const WebPlanSessionsView({super.key, required this.patient});

  @override
  State<WebPlanSessionsView> createState() => _WebPlanSessionsViewState();
}

class _WebPlanSessionsViewState extends State<WebPlanSessionsView> with TickerProviderStateMixin {
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
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final plan = provider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(LucideIcons.calendarX2, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(context.tr('no_treatment_plan_mobile') ?? 'No Plan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    final upcomingSession = plan.sessions.firstWhere((s) => !s.isAttended, orElse: () => plan.sessions.last);
    final centerName = plan.assignedCenterId == null ? (context.tr('not_assigned') ?? 'Not Assigned') : provider.therapyCenterLabel(context, plan.assignedCenterId);

    final attendedSessions = plan.sessions.where((s) => s.isAttended).toList();
    final upcomingSessions = plan.sessions.where((s) => !s.isAttended).toList();

    List<TherapySession> filteredSessions;
    switch (_filterIndex) {
      case 1: filteredSessions = attendedSessions; break;
      case 2: filteredSessions = upcomingSessions; break;
      default: filteredSessions = plan.sessions;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, plan, attendedSessions.length),
            const SizedBox(height: 32),
            _buildSessionStats(context, plan, attendedSessions),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildUpcomingHeroCard(context, plan, upcomingSession, centerName),
                      const SizedBox(height: 24),
                      _buildStreakCard(context, attendedSessions.length),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterBar(context),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 140,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          return _buildEnhancedSessionCard(context, filteredSessions[index], plan);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic plan, int attended) {
    double progress = attended / plan.totalSessions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(LucideIcons.calendarDays, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('nav_sessions') ?? 'Sessions', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text('Track your therapy journey', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('$attended of ${plan.totalSessions} Sessions', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStats(BuildContext context, dynamic plan, List<TherapySession> attended) {
    final avgWeight = attended.isEmpty
        ? '--'
        : (attended.where((s) => s.weightAfter != null).fold<double>(0, (sum, s) => sum + (s.weightAfter ?? 0)) / attended.where((s) => s.weightAfter != null).length).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(child: _buildStatBox(context, icon: LucideIcons.checkCircle2, label: 'Completed', value: '${attended.length}', sub: 'sessions', color: AppColors.success)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatBox(context, icon: LucideIcons.calendarClock, label: 'Remaining', value: '${plan.totalSessions - attended.length}', sub: 'sessions', color: AppColors.info)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatBox(context, icon: LucideIcons.scale, label: 'Avg Weight', value: avgWeight, sub: 'kg/session', color: AppColors.accent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatBox(context, icon: LucideIcons.flame, label: 'Current Streak', value: '${attended.length}', sub: 'sessions', color: AppColors.warning)),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, {required IconData icon, required String label, required String value, required String sub, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
              const SizedBox(width: 4),
              Text(sub, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildUpcomingHeroCard(BuildContext context, dynamic plan, TherapySession upcomingSession, String centerName) {
    final isCompleted = upcomingSession.isAttended;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface.withValues(alpha: 0.08)))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(LucideIcons.calendarCheck, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Next Session', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(context.tr('session_n_of_total', {'n': '${upcomingSession.sessionNumber}', 'total': '${plan.totalSessions}'}) ?? 'Session ${upcomingSession.sessionNumber}',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildHeroInfoRow(LucideIcons.calendar, 'Date', '${upcomingSession.scheduledDate.day}/${upcomingSession.scheduledDate.month}/${upcomingSession.scheduledDate.year}'),
                      const SizedBox(height: 12),
                      _buildHeroInfoRow(LucideIcons.mapPin, 'Center', centerName),
                      const SizedBox(height: 12),
                      _buildHeroInfoRow(LucideIcons.clock, 'Time', '10:00 AM'),
                      const SizedBox(height: 12),
                      _buildHeroInfoRow(LucideIcons.userCheck, 'Doctor', 'Dr. Ahmed Khalil'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isCompleted
                        ? null
                        : () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SessionCheckinScreen(plan: plan, session: upcomingSession)));
                          },
                    icon: Icon(isCompleted ? LucideIcons.checkCircle : LucideIcons.logIn, size: 18),
                    label: Text(isCompleted ? 'Completed' : (context.tr('session_checkin') ?? 'Check-in'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white24,
                      disabledForegroundColor: Colors.white54,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context, int attended) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentLight]), borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.flame, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Streak', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('$attended Sessions in a row', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final tabs = ['All', 'Completed', 'Upcoming'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _filterIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedSessionCard(BuildContext context, TherapySession session, dynamic plan) {
    final isAttended = session.isAttended;
    return MouseRegion(
      cursor: isAttended ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isAttended ? () => _showSessionDetailsSheet(context, session) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isAttended ? AppColors.success.withValues(alpha: 0.3) : AppColors.border, width: isAttended ? 2 : 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isAttended ? AppColors.success.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(isAttended ? LucideIcons.checkCircle2 : LucideIcons.clock, size: 22, color: isAttended ? AppColors.success : AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session ${session.sessionNumber}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Text('${session.scheduledDate.day}/${session.scheduledDate.month}/${session.scheduledDate.year}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (isAttended && session.weightAfter != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${session.weightAfter} kg', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                    ),
                ],
              ),
              const Spacer(),
              if (isAttended)
                Text('Tap to view details →', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))
              else
                Text('Upcoming appointment', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetailsSheet(BuildContext context, TherapySession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 28)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session ${session.sessionNumber} Details', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('${session.scheduledDate.day}/${session.scheduledDate.month}/${session.scheduledDate.year}', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildDetailTile(LucideIcons.scale, 'Weight After', '${session.weightAfter ?? '--'} kg')),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Session Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Text(session.notes ?? 'No notes recorded for this session.', style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}