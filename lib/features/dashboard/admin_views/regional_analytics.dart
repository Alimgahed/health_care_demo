import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/mock_data.dart';

class RegionalAnalytics extends StatefulWidget {
  const RegionalAnalytics({super.key});

  @override
  State<RegionalAnalytics> createState() => _RegionalAnalyticsState();
}

class _RegionalAnalyticsState extends State<RegionalAnalytics> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dataProvider = Provider.of<DataProvider>(context);
    
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

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.translate('nav_analytics'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.navy)),
              
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
                    Icon(LucideIcons.search, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: t.translate('search'),
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(t.translate('filter_emirate').toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1))),
                Expanded(flex: 2, child: Text(t.translate('filter_patients').toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1))),
                Expanded(flex: 2, child: Text(t.translate('actual_dispensed').toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1))),
                Expanded(flex: 2, child: Text(t.translate('bmi').toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1))),
                Expanded(flex: 3, child: Text(t.translate('dispensing_vs_goals').toUpperCase(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1))),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ListView.separated(
                itemCount: sortedEmirates.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final emirate = sortedEmirates[index];
                  // If we wanted, we could translate the emirate name here using a helper, 
                  // but for now we'll just grab the localized emirate from the first patient in that emirate
                  final localizedEmirate = patientsByEmirate[emirate]!.first.getLocalizedEmirate(context);
                  
                  if (_searchQuery.isNotEmpty && 
                      !localizedEmirate.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                      !emirate.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }

                  final count = patientsByEmirate[emirate]!.length;
                  final avgBMI = patientsByEmirate[emirate]!.map((p) => p.bmi).reduce((a, b) => a + b) / count;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(localizedEmirate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('$count', style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${count * 4}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Text(avgBMI.toStringAsFixed(1), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                              const SizedBox(width: 8),
                              Icon(LucideIcons.trendingDown, size: 16, color: AppColors.success),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
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
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
