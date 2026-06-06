import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';

class WebPlanOverviewView extends StatefulWidget {
  final Patient patient;

  const WebPlanOverviewView({super.key, required this.patient});

  @override
  State<WebPlanOverviewView> createState() => _WebPlanOverviewViewState();
}

class _WebPlanOverviewViewState extends State<WebPlanOverviewView> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _progressController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final plan = dataProvider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(context.tr('no_treatment_plan_mobile') ?? 'No treatment plan', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final double rawProgress = (widget.patient.weightHistory.isNotEmpty)
        ? (widget.patient.weightHistory.first - widget.patient.weight) / (widget.patient.weightHistory.first - plan.targetWeight)
        : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final int attendedSessions = plan.sessions.where((s) => s.isAttended).length;
    final double weightLost = widget.patient.weightHistory.isNotEmpty ? widget.patient.weightHistory.first - widget.patient.weight : 0;
    final double remaining = widget.patient.weight - plan.targetWeight;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.clipboardList, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('nav_overview_plan') ?? 'Plan Overview',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.5)),
                    Text('خطتك العلاجية الشاملة', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: plan.clinicalApprovalStatus == 'approved' ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: plan.clinicalApprovalStatus == 'approved' ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: plan.clinicalApprovalStatus == 'approved' ? AppColors.success : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        plan.clinicalApprovalStatus == 'approved' ? (context.tr('approved') ?? 'Approved') : (context.tr('pending_review') ?? 'Pending'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: plan.clinicalApprovalStatus == 'approved' ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Row 1: Progress Hero + Quick Stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Hero Card
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: Stack(
                      children: [
                        Positioned(right: -30, top: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface.withValues(alpha: 0.06)))),
                        Row(
                          children: [
                            // Animated Circular Progress Ring
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(150, 150),
                                        painter: _RingPainter(progress: progress * _progressAnimation.value, trackColor: Colors.white24, progressColor: Colors.white),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('${(progress * _progressAnimation.value * 100).toStringAsFixed(0)}%',
                                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1)),
                                          const Text('مكتمل', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الهدف الحالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text('${plan.targetWeight} kg',
                                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1, height: 1)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _infoBadge(LucideIcons.trendingDown, 'فقدت ${weightLost.toStringAsFixed(1)} kg', Colors.white.withValues(alpha: 0.25)),
                                      const SizedBox(width: 10),
                                      _infoBadge(LucideIcons.target, 'متبقي ${remaining.toStringAsFixed(1)} kg', Colors.white.withValues(alpha: 0.15)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Linear progress bar for journey
                                  AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, _) => ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progress * _progressAnimation.value,
                                        backgroundColor: AppColors.background.withValues(alpha: 0.2),
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Journey Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text('Lost ${weightLost.toStringAsFixed(1)} kg', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Quick Stats Column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildStatCard(context, LucideIcons.checkCircle, 'الجلسات', '$attendedSessions/${plan.totalSessions}', AppColors.primary),
                      const SizedBox(height: 16),
                      _buildStatCard(context, LucideIcons.trendingUp, 'معدل الالتزام', '95%', AppColors.success),
                      const SizedBox(height: 16),
                      _buildStatCard(context, LucideIcons.flame, 'سلسلة الالتزام', '12 يوم', AppColors.accent),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Row 2: Weight Journey Card (Full Width)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weight Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      _infoBadge(LucideIcons.trendingDown, '↓ ${weightLost.toStringAsFixed(1)} kg lost', AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildWeightPoint('Start', widget.patient.weightHistory.first, AppColors.error),
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(height: 4, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
                            Container(
                              height: 4,
                              alignment: Alignment.centerLeft,
                              child: AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, _) => FractionallySizedBox(
                                  widthFactor: progress * _progressAnimation.value,
                                  child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                              child: Text('${widget.patient.weight.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      _buildWeightPoint('Target', plan.targetWeight.toDouble(), AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildMetricChip(LucideIcons.activity, 'BMI Progress', 'Improving', AppColors.info)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricChip(LucideIcons.calendarClock, 'Est. Completion', '8 weeks', AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Row 3: Plan Details + Sessions Overview & Timeline
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Details Card
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(LucideIcons.clipboardList, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Text('تفاصيل الخطة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _detailRow(context, LucideIcons.userCheck, 'الطبيب المعالج', plan.doctorName),
                        const Divider(height: 28),
                        _detailRow(context, LucideIcons.calendar, 'تاريخ البدء', '${plan.createdAt.day}/${plan.createdAt.month}/${plan.createdAt.year}'),
                        const Divider(height: 28),
                        _detailRow(context, LucideIcons.target, 'مدة الخطة', '${plan.totalSessions} جلسات'),
                        const Divider(height: 28),
                        _detailRow(context, LucideIcons.stethoscope, 'نوع العلاج', 'علاج تغذوي', valueColor: AppColors.textPrimary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Sessions Timeline + Next Milestone + Health Metrics
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Sessions Timeline Preview
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('نظرة عامة على الجلسات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 30,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: plan.totalSessions,
                                separatorBuilder: (context, index) => Container(width: 20, height: 2, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  bool isAttended = index < attendedSessions;
                                  bool isNext = index == attendedSessions;
                                  return Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: isAttended ? AppColors.success : (isNext ? AppColors.primary.withValues(alpha: 0.1) : AppColors.border),
                                      shape: BoxShape.circle,
                                      border: isNext ? Border.all(color: AppColors.primary, width: 2) : null,
                                    ),
                                    child: isAttended ? const Icon(LucideIcons.check, size: 14, color: Colors.white) : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('$attendedSessions من ${plan.totalSessions} مكتملة', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Next Milestone Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.navy, AppColors.primaryDark]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.3), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(LucideIcons.target, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Next Milestone', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('90 kg Milestone', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 46, height: 46,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(value: 0.6, strokeWidth: 4, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent)),
                                  const Text('60%', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _infoBadge(IconData icon, String label, Color bg, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: textColor),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: valueColor ?? AppColors.primary)),
      ],
    );
  }

  Widget _buildWeightPoint(String label, double weight, Color color) {
    return Column(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 3), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]),
        ),
        const SizedBox(height: 8),
        Text('${weight.toStringAsFixed(0)}kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMetricChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({required this.progress, required this.trackColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 10.0;
    final bgPaint = Paint()..color = trackColor..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = progressColor..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}