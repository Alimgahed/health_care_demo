import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/constants/mock_data.dart';
import '../../auth/login_screen.dart';

class WebPatientShell extends StatefulWidget {
  const WebPatientShell({super.key});

  @override
  State<WebPatientShell> createState() => _WebPatientShellState();
}

class _WebPatientShellState extends State<WebPatientShell> {
  int _selectedIndex = 0; // 0 = Home / Dashboard, 1 = My Profile
  final String _patientId = 'P001'; // Mocked as Ahmed Al Mansoori for the patient app

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);

    // Fetch active patient from provider to keep it reactive
    final patient = dataProvider.patients.firstWhere((p) => p.id == _patientId, orElse: () => dataProvider.patients.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.home, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              'Patient Portal - Welcome back, ${patient.getLocalizedFullName(context).split(' ')[0]}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navy),
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () => localeProvider.toggleLanguage(),
            icon: const Icon(LucideIcons.globe, color: AppColors.navy),
            label: Text(
              localeProvider.locale.languageCode == 'en' ? 'العربية' : 'English',
              style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(t, patient),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: _selectedIndex == 0
                ? _buildDashboardView(t, patient, dataProvider)
                : _buildProfileView(t, patient),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppLocalizations t, Patient patient) {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _buildSidebarItem(LucideIcons.home, 'Home Dashboard', 0),
          _buildSidebarItem(LucideIcons.userCircle, 'My Health Profile', 1),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(patient.getLocalizedFullName(context).substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.getLocalizedFullName(context).split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const Text('Patient Portal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.navy,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboardView(AppLocalizations t, Patient patient, DataProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Next Injection schedule & Dose
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Treatment Status & Adherence',
                            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Prescribed Dose: ${patient.currentDose}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Next injection due tomorrow at 9:00 AM',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Simulate check-in
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Adherence logged successfully! Keep up the good work.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Mark Injection as Taken'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // KPIs (Current Weight, BMI, Target weight)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildKpiCard('Current Weight', '${patient.weight.toStringAsFixed(1)} kg', '-${(patient.weightHistory.first - patient.weight).toStringAsFixed(1)} kg total lost', LucideIcons.scale, AppColors.info),
                    const SizedBox(height: 16),
                    _buildKpiCard('Current BMI', patient.bmi.toStringAsFixed(1), patient.bmi >= 30 ? 'Classified: Obesity' : 'Classified: Normal weight', LucideIcons.activity, patient.bmi >= 30 ? AppColors.error : AppColors.success),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Row 2: Weight Loss Chart & Achievements
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weight Chart (65%)
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Weight Loss Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 8),
                        const Text('Historical track of your weight checks recorded by your physician.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 250,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border.withOpacity(0.5), strokeWidth: 1),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    getTitlesWidget: (value, meta) {
                                      int idx = value.toInt();
                                      if (idx >= 0 && idx < patient.weightHistory.length) {
                                        return Text('Check #${idx + 1}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: patient.weightHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 4,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
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
              const SizedBox(width: 24),
              
              // Achievements (35%)
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Earned Badges & Milestones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 24),
                        _buildAchievementTile(LucideIcons.medal, '1 Month Streak', 'Adhered perfectly to dose timing', AppColors.accent),
                        const Divider(height: 24),
                        _buildAchievementTile(LucideIcons.flame, 'Obesity Reduction', 'Achieved first 5kg weight reduction', AppColors.error),
                        const Divider(height: 24),
                        _buildAchievementTile(LucideIcons.award, 'Clinical Compliance', 'Doctor check-in schedules fully completed', AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTile(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView(AppLocalizations t, Patient patient) {
    // Calculates copay info
    final double coverage = patient.residencyStatus == ResidencyStatus.citizen ? 1.0 :
                            (patient.residencyStatus == ResidencyStatus.resident ? 0.5 : 0.0);
    final double govtPays = 1000.0 * coverage;
    final double copay = 1000.0 - govtPays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Health Profile & Coverage', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          const Text('Manage your medical demographics and government-supported insurance subsidies.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Demographics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 20),
                        _buildDetailRow('Full Name', patient.getLocalizedFullName(context)),
                        const SizedBox(height: 12),
                        _buildDetailRow('Emirates ID', patient.emiratesId),
                        const SizedBox(height: 12),
                        _buildDetailRow('Nationality', patient.getLocalizedNationality(context)),
                        const SizedBox(height: 12),
                        _buildDetailRow('Residency Status', patient.residencyStatus.toString().split('.')[1].toUpperCase()),
                        const SizedBox(height: 12),
                        _buildDetailRow('Emirate', patient.getLocalizedEmirate(context)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Government Subsidy Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 20),
                        _buildDetailRow('Base Medication Price', '1,000.00 AED'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Coverage Rate', '${(coverage * 100).toStringAsFixed(0)}%'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Government Contribution', '${govtPays.toStringAsFixed(2)} AED', color: AppColors.success),
                        const Divider(height: 24),
                        _buildDetailRow('Your Copay (per check-in)', '${copay.toStringAsFixed(2)} AED', isHighlight: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              fontSize: isHighlight ? 16 : 14,
              color: color ?? AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}
