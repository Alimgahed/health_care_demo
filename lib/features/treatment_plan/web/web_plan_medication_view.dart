import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../patient_app/medication_order/medication_order_wizard.dart' as mounjaro_demo;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';

class WebPlanMedicationView extends StatefulWidget {
  final Patient patient;

  const WebPlanMedicationView({super.key, required this.patient});

  @override
  State<WebPlanMedicationView> createState() => _WebPlanMedicationViewState();
}

class _WebPlanMedicationViewState extends State<WebPlanMedicationView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _injectionDone = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final plan = dataProvider.getPlanForPatient(widget.patient.id);

    if (plan == null) {
      return const Center(child: Text('No Medication Plan', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, plan),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1 (flex: 2) - Injection Hero & Schedule
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildNextDoseHeroCard(context, plan),
                    const SizedBox(height: 24),
                    _buildScheduleCard(context, plan),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Column 2 (flex: 3) - Adherence & Dosage Info
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildAdherenceCard(context),
                    const SizedBox(height: 24),
                    _buildDosageInfoCard(context),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Column 3 (flex: 3) - History & Side Effects Tabs
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildTabBar(context),
                    const SizedBox(height: 24),
                    _buildTabContent(context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildRefillCard(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic plan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.syringe, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('nav_medication') ?? 'Medication', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const Text('Mounjaro (Tirzepatide) — Weekly Injection', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
          child: Row(
            children: [
              const Icon(LucideIcons.pill, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(plan.medicationDose ?? '5 mg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextDoseHeroCard(BuildContext context, dynamic plan) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
          Positioned(left: -10, bottom: -30, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.12)))),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 70 + (_pulseAnimation.value * 12), height: 70 + (_pulseAnimation.value * 12), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06 * (1 - _pulseAnimation.value)))),
                            Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)), child: const Icon(LucideIcons.syringe, color: Colors.white, size: 28)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Next Mounjaro Dose', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('In 5 Days', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                            child: const Text('Thursday, Jun 12', style: TextStyle(color: AppColors.accentLight, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: List.generate(7, (i) {
                    final isToday = i == 1;
                    final isPast = i == 0;
                    final isNext = i == 6;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isPast ? Colors.white.withValues(alpha: 0.9) : (isToday ? AppColors.accent : (isNext ? AppColors.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2))),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i], style: TextStyle(fontSize: 10, color: isToday ? AppColors.accent : Colors.white60, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _injectionDone = !_injectionDone;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_injectionDone ? 'Injection marked as taken.' : 'Injection unmarked.'), backgroundColor: _injectionDone ? AppColors.success : AppColors.primary));
                    },
                    icon: Icon(_injectionDone ? LucideIcons.checkCircle : LucideIcons.check, size: 20),
                    label: Text(_injectionDone ? 'تم التسجيل ✓' : 'تسجيل الحقنة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _injectionDone ? AppColors.success : Colors.white,
                      foregroundColor: _injectionDone ? Colors.white : AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildScheduleCard(BuildContext context, dynamic plan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Injection Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 20),
          _buildInfoRow(LucideIcons.repeat, 'Frequency', 'Weekly'),
          const Divider(height: 24),
          _buildInfoRow(LucideIcons.calendarClock, 'Reminder Time', '09:00 AM (Thursdays)'),
          const Divider(height: 24),
          _buildInfoRow(LucideIcons.history, 'Last Injection', '5 Days Ago (Thigh)'),
        ],
      ),
    );
  }

  Widget _buildAdherenceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Adherence Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('Excellent', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildAdherenceStat('100%', 'This Month', AppColors.success, LucideIcons.checkCircle2)),
              Container(width: 1, height: 48, color: AppColors.border),
              Expanded(child: _buildAdherenceStat('4/4', 'Doses Taken', AppColors.primary, LucideIcons.pill)),
              Container(width: 1, height: 48, color: AppColors.border),
              Expanded(child: _buildAdherenceStat('0', 'Missed', AppColors.info, LucideIcons.x)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(4, (week) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                        child: const Center(child: Icon(LucideIcons.check, size: 16, color: AppColors.success)),
                      ),
                      const SizedBox(height: 6),
                      Text('Wk ${week + 1}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceStat(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDosageInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.info, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Text('Dosage Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(LucideIcons.pill, 'Medication', 'Mounjaro (Tirzepatide)'),
          const Divider(height: 24),
          _buildInfoRow(LucideIcons.droplets, 'Current Dose', '5 mg', color: AppColors.accent),
          const Divider(height: 24),
          _buildInfoRow(LucideIcons.trendingUp, 'Dose Escalation', '2.5 → 5 → 7.5 mg', color: AppColors.info),
          const Divider(height: 24),
          _buildInfoRow(LucideIcons.mapPin, 'Injection Site', 'Abdomen / Thigh / Arm', color: AppColors.success),
          const Divider(height: 24),
          _buildInfoRow(LucideIcons.thermometer, 'Storage', '2°C – 8°C (Refrigerated)', color: AppColors.navy),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color color = AppColors.primary}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final tabs = ['History', 'Schedule', 'Side Effects'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(tabs[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    if (_selectedTab == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            _buildHistoryItem('Week 4', '2 days ago', '5 mg', 'Abdomen'),
            const Divider(height: 32),
            _buildHistoryItem('Week 3', '9 days ago', '5 mg', 'Thigh'),
            const Divider(height: 32),
            _buildHistoryItem('Week 2', '16 days ago', '2.5 mg', 'Abdomen'),
          ],
        ),
      );
    } else if (_selectedTab == 1) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Text('Schedule list goes here', style: TextStyle(color: AppColors.textSecondary)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Text('Side effects guide goes here', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
  }

  Widget _buildHistoryItem(String week, String date, String dose, String site) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(LucideIcons.check, color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(week, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dose, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
            Text(site, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildRefillCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.navy.withValues(alpha: 0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                child: const Icon(LucideIcons.package, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Medication Refill Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('3 doses remaining (approx. 3 weeks)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const mounjaro_demo.MedicationOrderWizard(),
                ),
              );
            },
            icon: const Icon(LucideIcons.shoppingBag, size: 16),
            label: const Text('Request Refill', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
