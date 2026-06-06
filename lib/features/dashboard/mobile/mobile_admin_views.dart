import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/demo_metrics.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../program_alerts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE DASHBOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MobileAdminDashboardView extends StatelessWidget {
  final AppLocalizations t;
  const MobileAdminDashboardView({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dp, _) {
        final tr = context.tr;
        final avgBmi = dp.averageBmi;
        final fraudPrevented = dp.fraudIncidentsPrevented;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('nav_dashboard'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              // KPI Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _MobileKpiCard(
                    icon: LucideIcons.users,
                    value: DemoMetrics.formatCount(DemoMetrics.nationalEnrolled),
                    label: tr('registered_patients_national'),
                    accentColor: AppColors.primary,
                  ),
                  _MobileKpiCard(
                    icon: LucideIcons.wallet,
                    value: DemoMetrics.formatAed(dp.totalGovtSubsidyDisbursed),
                    label: tr('govt_subsidy_expenditure'),
                    accentColor: AppColors.accent,
                  ),
                  _MobileKpiCard(
                    icon: LucideIcons.activity,
                    value: avgBmi.toStringAsFixed(1),
                    label: tr('national_avg_bmi_cohort'),
                    accentColor: AppColors.success,
                  ),
                  _MobileKpiCard(
                    icon: LucideIcons.shieldAlert,
                    value: fraudPrevented.toString(),
                    label: tr('fraud_abuse_prevented'),
                    accentColor: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Mobile compact center inventory summary
              Text(
                tr('center_inventory_status'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dp.centers.length,
                itemBuilder: (context, index) {
                  final center = dp.centers[index];
                  final totalStock = center.inventory2_5mg + center.inventory5mg + center.inventory7_5mg + center.inventory10mg;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    color: AppColors.surface,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(LucideIcons.building, color: AppColors.primary, size: 20),
                      ),
                      title: Text(center.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(center.getLocalizedRegion(context)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$totalStock units', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(totalStock < 100 ? tr('replenishment_critical') : tr('stock_adequate'), 
                            style: TextStyle(color: totalStock < 100 ? AppColors.error : AppColors.success, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _MobileKpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const _MobileKpiCard({required this.icon, required this.value, required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE MANAGE DOCTORS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MobileManageDoctorsView extends StatelessWidget {
  final AppLocalizations t;
  const MobileManageDoctorsView({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dp.doctors.length,
      itemBuilder: (context, index) {
        final doctor = dp.doctors[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(LucideIcons.user, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(doctor.specialty, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('active'),
                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(LucideIcons.building, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(doctor.getLocalizedHospital(context), style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.mail, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(doctor.email, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit logic goes here')));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(context.tr('nav_manage_doctors')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE MANAGE CENTERS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MobileManageCentersView extends StatelessWidget {
  final AppLocalizations t;
  const MobileManageCentersView({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dp.centers.length,
      itemBuilder: (context, index) {
        final center = dp.centers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.building2, color: AppColors.accent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(center.getLocalizedName(context), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(center.getLocalizedRegion(context), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(icon: LucideIcons.mapPin, label: center.getLocalizedRegion(context)),
                    _InfoItem(icon: LucideIcons.package, label: '${center.inventory2_5mg + center.inventory5mg} units'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(context.tr('nav_manage_centers')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE INVENTORY VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MobileInventoryView extends StatelessWidget {
  final AppLocalizations t;
  const MobileInventoryView({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dp.centers.length,
      itemBuilder: (context, index) {
        final center = dp.centers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(center.getLocalizedName(context), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            subtitle: Text(center.getLocalizedRegion(context), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            leading: CircleAvatar(backgroundColor: AppColors.background, child: Icon(LucideIcons.package, color: AppColors.primary, size: 18)),
            children: [
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _MobileDoseRow(dose: '2.5 mg', available: center.inventory2_5mg, dispensed: center.dispensed2_5mg, total: 200, context: context),
                    const SizedBox(height: 12),
                    _MobileDoseRow(dose: '5.0 mg', available: center.inventory5mg, dispensed: center.dispensed5mg, total: 200, context: context),
                    const SizedBox(height: 12),
                    _MobileDoseRow(dose: '7.5 mg', available: center.inventory7_5mg, dispensed: center.dispensed7_5mg, total: 200, context: context),
                    const SizedBox(height: 12),
                    _MobileDoseRow(dose: '10.0 mg', available: center.inventory10mg, dispensed: center.dispensed10mg, total: 200, context: context),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          dp.replenishInventory(center.id, '2.5 mg', 50);
                          dp.replenishInventory(center.id, '5.0 mg', 50);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('stock_restock_msg')),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.truck, size: 16, color: Colors.white),
                        label: Text(context.tr('manage_stock_replenishment'), style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileDoseRow extends StatelessWidget {
  final String dose;
  final int available;
  final int dispensed;
  final int total;
  final BuildContext context;

  const _MobileDoseRow({required this.dose, required this.available, required this.dispensed, required this.total, required this.context});

  @override
  Widget build(BuildContext context) {
    final isLow = available < 50;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(dose, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            Text('${context.tr('available')}: $available', style: TextStyle(color: isLow ? AppColors.error : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: available / total,
            backgroundColor: AppColors.border,
            color: isLow ? AppColors.error : AppColors.success,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE FRAUD AUDIT VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MobileFraudAuditView extends StatelessWidget {
  final AppLocalizations t;
  const MobileFraudAuditView({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final fraudLog = fraudProgramAlerts(context, dp);
    
    if (fraudLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shieldCheck, size: 48, color: AppColors.success.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(context.tr('no_fraud_alerts'), style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fraudLog.length,
      itemBuilder: (context, index) {
        final log = fraudLog[index];
        final isCritical = log.kind == ProgramAlertKind.flagged;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isCritical ? AppColors.error.withValues(alpha: 0.5) : Colors.transparent),
          ),
          elevation: 0,
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      log.icon, 
                      color: log.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCritical ? context.tr('alert_flagged') : context.tr('alert_override'),
                        style: TextStyle(fontWeight: FontWeight.bold, color: log.color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(log.message, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.time, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                      child: Text(isCritical ? 'FLAGGED' : 'OVERRIDDEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE REGIONAL ANALYTICS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class MobileRegionalAnalyticsView extends StatefulWidget {
  final AppLocalizations t;
  const MobileRegionalAnalyticsView({super.key, required this.t});

  @override
  State<MobileRegionalAnalyticsView> createState() => _MobileRegionalAnalyticsViewState();
}

class _MobileRegionalAnalyticsViewState extends State<MobileRegionalAnalyticsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final tr = context.tr;
    
    // Group patients by Emirate
    final Map<String, List<Patient>> patientsByEmirate = {};
    for (var p in dataProvider.patients) {
      if (!patientsByEmirate.containsKey(p.emirate)) {
        patientsByEmirate[p.emirate] = [];
      }
      patientsByEmirate[p.emirate]!.add(p);
    }

    final sortedEmirates = patientsByEmirate.keys.toList()
      ..sort((a, b) => patientsByEmirate[b]!.length.compareTo(patientsByEmirate[a]!.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.search, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: tr('search'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedEmirates.length,
            itemBuilder: (context, index) {
              final emirate = sortedEmirates[index];
              final localizedEmirate = patientsByEmirate[emirate]!.first.getLocalizedEmirate(context);
              
              if (_searchQuery.isNotEmpty && 
                  !localizedEmirate.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                  !emirate.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return const SizedBox.shrink();
              }

              final count = patientsByEmirate[emirate]!.length;
              final avgBMI = patientsByEmirate[emirate]!.map((p) => p.bmi).reduce((a, b) => a + b) / count;
              final progressValue = 0.7 + (index * 0.05);
              final progressPercentage = (70 + (index * 5)).toString();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizedEmirate,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(avgBMI.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.activity, size: 12, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(tr('filter_patients'), '$count', LucideIcons.users),
                          ),
                          Expanded(
                            child: _buildStatItem(tr('actual_dispensed'), '${count * 4}', LucideIcons.package),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(tr('dispensing_vs_goals'), style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('$progressPercentage%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}