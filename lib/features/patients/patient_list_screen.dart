import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import 'patient_profile_screen.dart';

class PatientListScreen extends StatefulWidget {
  final String? highlightPatientId;

  const PatientListScreen({super.key, this.highlightPatientId});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.highlightPatientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dp = Provider.of<DataProvider>(context, listen: false);
        final p = dp.getPatientById(widget.highlightPatientId!);
        if (p != null && mounted) {
          setState(() => _searchQuery = p.emiratesId);
          _searchController.text = p.emiratesId;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    
    // Filter patients based on search
    final filteredPatients = dataProvider.patients.where((p) {
      return p.getLocalizedFullName(context).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.emiratesId.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('patients_registry_title')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: context.tr('search_patient'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(
                    child: Text(context.tr('no_matching_patients')),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredPatients.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              patient.getLocalizedFullName(context).substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            patient.getLocalizedFullName(context),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                          subtitle: Text('${context.tr('patients_list_subtitle')}: ${patient.emiratesId}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientProfileScreen(patient: patient),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
