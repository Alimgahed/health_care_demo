import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';
import 'treatment_plan_builder.dart';

class Patient360View extends StatefulWidget {
  final Patient patient;

  const Patient360View({super.key, required this.patient});

  @override
  State<Patient360View> createState() => _Patient360ViewState();
}

class _Patient360ViewState extends State<Patient360View> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final activePlan = dataProvider.treatmentPlans.cast<TreatmentPlan?>().firstWhere(
      (p) => p?.patientId == widget.patient.id && p?.status == 'Active',
      orElse: () => null,
    );

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.navy,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  child: Text(
                    widget.patient.getLocalizedFullName(context).substring(0, 1),
                    style: const TextStyle(fontSize: 32, color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.getLocalizedFullName(context),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildHeaderBadge(LucideIcons.hash, widget.patient.emiratesId),
                          const SizedBox(width: 16),
                          _buildHeaderBadge(LucideIcons.user, '${widget.patient.age} ${t.translate('age')}'),
                          const SizedBox(width: 16),
                          _buildHeaderBadge(LucideIcons.mapPin, widget.patient.getLocalizedEmirate(context)),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: const EdgeInsets.all(24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: SizedBox(
                          width: 900,
                          height: 700,
                          child: TreatmentPlanBuilder(patient: widget.patient, existingPlan: activePlan),
                        ),
                      ),
                    );
                  },
                  icon: Icon(activePlan == null ? LucideIcons.plusCircle : LucideIcons.edit),
                  label: Text(activePlan == null ? t.translate('create_treatment_plan') : t.translate('edit_plan')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: t.translate('overview')),
              Tab(text: t.translate('treatment_plan')),
              Tab(text: t.translate('medical_history')),
              Tab(text: t.translate('activity_log')),
            ],
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(t),
                _buildTreatmentPlanTab(t, activePlan),
                _buildMedicalHistoryTab(t),
                _buildActivityLogTab(t, dataProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(t.translate('weight'), '${widget.patient.weight} kg', LucideIcons.activity, AppColors.primary)),
              const SizedBox(width: 24),
              Expanded(child: _buildMetricCard(t.translate('bmi'), widget.patient.bmi.toStringAsFixed(1), LucideIcons.activitySquare, widget.patient.bmi >= 35.0 ? AppColors.error : AppColors.warning)),
              const SizedBox(width: 24),
              Expanded(child: _buildMetricCard(t.translate('compliance_score'), '${(widget.patient.complianceRate * 100).toInt()}%', LucideIcons.checkCircle, AppColors.success)),
            ],
          ),
          const SizedBox(height: 32),
          Text('BMI Trend', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 24),
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.patient.weightHistory.asMap().entries.map((e) {
                      double bmi = e.value / ((widget.patient.height / 100) * (widget.patient.height / 100));
                      return FlSpot(e.key.toDouble(), bmi);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlanTab(AppLocalizations t, TreatmentPlan? plan) {
    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text('No Active Plan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanSection(t.translate('medication_plan'), [
            _buildPlanRow(LucideIcons.pill, t.translate('select_dose'), plan.medicationDose),
            _buildPlanRow(LucideIcons.clock, t.translate('injection_frequency'), 'Every ${plan.medicationFrequencyDays} days'),
          ]),
          const SizedBox(height: 32),
          _buildPlanSection(t.translate('therapy_plan'), [
            _buildPlanRow(LucideIcons.mapPin, t.translate('therapy_center'), plan.assignedCenterId ?? 'None'),
            _buildPlanRow(LucideIcons.calendar, t.translate('sessions'), '${plan.sessions.where((s) => s.isAttended).length} / ${plan.totalSessions} ${t.translate('completed')}'),
          ]),
          const SizedBox(height: 32),
          _buildPlanSection(t.translate('home_exercises'), plan.homeExercises.map((e) => 
            _buildPlanRow(LucideIcons.activity, e.name, '${e.durationMinutes} min • ${e.sets}x${e.reps}')
          ).toList()),
        ],
      ),
    );
  }

  Widget _buildPlanSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlanRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryTab(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanSection('Chronic Conditions', [
            _buildPlanRow(LucideIcons.activity, 'Condition', 'Obesity (Class II)'),
            _buildPlanRow(LucideIcons.activity, 'Condition', 'Type 2 Diabetes Mellitus'),
          ]),
          const SizedBox(height: 32),
          _buildPlanSection('Past Surgeries', [
            _buildPlanRow(LucideIcons.scissors, 'Procedure', 'Appendectomy (2015)'),
          ]),
          const SizedBox(height: 32),
          _buildPlanSection('Family History', [
            _buildPlanRow(LucideIcons.users, 'History', 'Father: Hypertension, Mother: Diabetes'),
          ]),
        ],
      ),
    );
  }

  Widget _buildActivityLogTab(AppLocalizations t, DataProvider provider) {
    final patientLogs = provider.logs.where((l) => l.patientId == widget.patient.id).toList();
    
    if (patientLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.history, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('No Activity Logs Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: patientLogs.length,
      itemBuilder: (context, index) {
        final log = patientLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.activity, color: AppColors.primary),
            ),
            title: Text(log.getLocalizedAction(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Recorded by: ${log.getLocalizedCenterName(context)}', style: const TextStyle(color: AppColors.textSecondary)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                const SizedBox(height: 4),
                Text('${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
