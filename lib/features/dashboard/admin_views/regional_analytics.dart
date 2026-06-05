import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/constants/mock_data.dart';
import '../../../../core/constants/demo_metrics.dart';

class RegionalAnalytics extends StatefulWidget {
  const RegionalAnalytics({super.key});

  @override
  State<RegionalAnalytics> createState() => _RegionalAnalyticsState();
}

class _RegionalAnalyticsState extends State<RegionalAnalytics> {
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  static const _tabKeys = [
    'report_tab_geo',
    'report_tab_hospitals',
    'report_tab_doctors',
    'report_tab_financial',
  ];

  String _getTabLabel(BuildContext context, int index) => context.tr(_tabKeys[index]);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('reports_center_title'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.navy)),
              
              // Search Box
              Container(
                width: 300,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.tr('search'),
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabKeys.length, (index) {
                final isSelected = _selectedTabIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                      ),
                      child: Text(
                        _getTabLabel(context, index),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),

          // Report Content
          Expanded(
            child: _buildSelectedReport(dataProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedReport(DataProvider dp) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildGeographicalReport(dp);
      case 1:
        return _buildHospitalsReport(dp);
      case 2:
        return _buildDoctorsReport(dp);
      case 3:
        return _buildFinancialReport(dp);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. Geographical Report ──────────────────────────────────────────────────
  Widget _buildGeographicalReport(DataProvider dp) {
    final Map<String, List<Patient>> patientsByEmirate = {};
    for (var p in dp.patients) {
      if (!patientsByEmirate.containsKey(p.emirate)) {
        patientsByEmirate[p.emirate] = [];
      }
      patientsByEmirate[p.emirate]!.add(p);
    }

    final sortedEmirates = patientsByEmirate.keys.toList()
      ..sort((a, b) => patientsByEmirate[b]!.length.compareTo(patientsByEmirate[a]!.length));

    return Column(
      children: [
        _buildTableHeader(context, [
          'report_geo_emirate',
          'report_geo_total_patients',
          'report_geo_doses_dispensed',
          'report_geo_avg_bmi',
          'report_geo_target_pct',
        ]),
        Expanded(
          child: _buildTableBody(
            itemCount: sortedEmirates.length,
            itemBuilder: (context, index) {
              final emirate = sortedEmirates[index];
              final localizedEmirate = patientsByEmirate[emirate]!.first.getLocalizedEmirate(context);
              if (_searchQuery.isNotEmpty && !localizedEmirate.toLowerCase().contains(_searchQuery.toLowerCase())) return const SizedBox.shrink();

              final count = patientsByEmirate[emirate]!.length;
              final avgBMI = patientsByEmirate[emirate]!.map((p) => p.bmi).reduce((a, b) => a + b) / count;
              
              return _buildTableRow([
                Text(localizedEmirate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                Text('$count', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                Text('${count * 4}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Row(
                  children: [
                    Text(avgBMI.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.trendingDown, size: 16, color: AppColors.success),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.7 + (index * 0.05),
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('${(70 + (index * 5))}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ],
                ),
              ]);
            },
          ),
        ),
      ],
    );
  }

  // ── 2. Hospitals Report ──────────────────────────────────────────────────────
  Widget _buildHospitalsReport(DataProvider dp) {
    return Column(
      children: [
        _buildTableHeader(context, [
          'report_hosp_name',
          'report_hosp_emirate',
          'report_hosp_total_doses',
          'report_hosp_active_patients',
          'report_hosp_stock_status',
        ]),
        Expanded(
          child: _buildTableBody(
            itemCount: dp.centers.length,
            itemBuilder: (context, index) {
              final center = dp.centers[index];
              if (_searchQuery.isNotEmpty && !center.name.toLowerCase().contains(_searchQuery.toLowerCase())) return const SizedBox.shrink();
              
              final isLowStock = center.inventory5mg < 10;
              
              return _buildTableRow([
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(LucideIcons.building2, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(center.getLocalizedName(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy))),
                  ],
                ),
                Text(center.getLocalizedRegion(context), style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                Text('${(index + 1) * 125}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text('${(index + 1) * 25}', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLowStock ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLowStock ? context.tr('report_hosp_low_stock') : context.tr('report_hosp_available'),
                    style: TextStyle(color: isLowStock ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ]);
            },
          ),
        ),
      ],
    );
  }

  // ── 3. Doctors Report ────────────────────────────────────────────────────────
  Widget _buildDoctorsReport(DataProvider dp) {
    return Column(
      children: [
        _buildTableHeader(context, [
          'report_doc_name',
          'report_doc_specialty',
          'report_doc_patients',
          'report_doc_prescriptions',
          'report_doc_compliance',
        ]),
        Expanded(
          child: _buildTableBody(
            itemCount: dp.doctors.length,
            itemBuilder: (context, index) {
              final doc = dp.doctors[index];
              if (_searchQuery.isNotEmpty && !doc.name.toLowerCase().contains(_searchQuery.toLowerCase())) return const SizedBox.shrink();
              
              final compliance = 95 - (index * 2);
              
              return _buildTableRow([
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.navy,
                      radius: 16,
                      child: Text(doc.name[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(doc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy))),
                  ],
                ),
                Text(doc.specialty, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                Text('${50 - (index * 5)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${120 - (index * 10)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: compliance / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(compliance >= 90 ? AppColors.success : AppColors.warning),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('$compliance%', style: TextStyle(fontWeight: FontWeight.bold, color: compliance >= 90 ? AppColors.success : AppColors.warning)),
                  ],
                ),
              ]);
            },
          ),
        ),
      ],
    );
  }

  // ── 4. Financial Report ──────────────────────────────────────────────────────
  Widget _buildFinancialReport(DataProvider dp) {
    return Column(
      children: [
        _buildTableHeader(context, [
          'report_fin_category',
          'report_fin_total_patients',
          'report_fin_total_cost',
          'report_fin_govt_subsidy',
          'report_fin_patient_copay',
        ]),
        Expanded(
          child: _buildTableBody(
            itemCount: 2,
            itemBuilder: (context, index) {
              final isCitizen = index == 0;
              final label = isCitizen ? context.tr('report_fin_citizen') : context.tr('report_fin_resident');
              if (_searchQuery.isNotEmpty && !label.toLowerCase().contains(_searchQuery.toLowerCase())) return const SizedBox.shrink();
              
              final count = isCitizen ? 120 : 80;
              final totalCost = count * 1000 * 4; // 4 doses
              final subsidy = isCitizen ? totalCost : (totalCost * 0.5);
              final copay = totalCost - subsidy;
              
              return _buildTableRow([
                Row(
                  children: [
                    Icon(isCitizen ? LucideIcons.badgeCheck : LucideIcons.users, color: AppColors.navy, size: 20),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  ],
                ),
                Text('$count', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                Text(DemoMetrics.formatAed(totalCost.toDouble()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                Text(DemoMetrics.formatAed(subsidy.toDouble()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                Text(DemoMetrics.formatAed(copay.toDouble()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning)),
              ]);
            },
          ),
        ),
      ],
    );
  }

  // ── UI Helpers ──────────────────────────────────────────────────────────────

  Widget _buildTableHeader(BuildContext context, List<String> headerKeys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Row(
        children: headerKeys.map((key) => Expanded(
          child: Text(context.tr(key), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 0)),
        )).toList(),
      ),
    );
  }

  Widget _buildTableBody({required int itemCount, required Widget Function(BuildContext, int) itemBuilder}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ListView.separated(
        itemCount: itemCount,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _buildTableRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: children.map((child) => Expanded(child: child)).toList(),
      ),
    );
  }
}
