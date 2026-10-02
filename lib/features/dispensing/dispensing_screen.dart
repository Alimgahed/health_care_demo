import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_toast.dart';
import '../journey/journey_models.dart';
import 'patient_dispensing_details.dart';

class DispensingScreen extends StatefulWidget {
  final String? highlightPatientId;

  const DispensingScreen({super.key, this.highlightPatientId});

  @override
  State<DispensingScreen> createState() => _DispensingScreenState();
}

class _DispensingScreenState extends State<DispensingScreen> {
  final TextEditingController _searchController = TextEditingController();

  Patient? _findPatient(DataProvider provider, String query) {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      final centerId = provider.centers.isEmpty
          ? ''
          : provider.centers.first.id;
      return provider.patients.firstWhere(
        (p) =>
            provider.pharmacyRequests.any(
              (request) =>
                  request.patientId == p.id &&
                  request.assignedCenterId == centerId &&
                  request.status != PharmacyRequestStatus.dispensed &&
                  request.status != PharmacyRequestStatus.cancelled,
            ) &&
            (p.emiratesId.contains(q) ||
                p.id.toLowerCase() == q.toLowerCase() ||
                p
                    .getLocalizedFullName(context)
                    .toLowerCase()
                    .contains(q.toLowerCase())),
      );
    } catch (_) {
      return null;
    }
  }

  void _searchPatient() {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final match = _findPatient(provider, _searchController.text);

    if (match == null) {
      CustomToast.showMessage(
        context,
        context.tr('patient_not_found'),
        isError: true,
      );
      return;
    }
    _searchController.clear();
    setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDispensingDetails(
          patient: match,
          centerId: provider.centers.isEmpty ? '' : provider.centers.first.id,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.highlightPatientId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openHighlightPatient(),
      );
    }
  }

  void _openHighlightPatient() {
    if (!mounted) return;
    final provider = Provider.of<DataProvider>(context, listen: false);
    final p = provider.getPatientById(widget.highlightPatientId!);
    if (p == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDispensingDetails(
          patient: p,
          centerId: provider.centers.isEmpty ? '' : provider.centers.first.id,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final center = provider.centers.isEmpty ? null : provider.centers.first;
    final query = _searchController.text.trim().toLowerCase();
    final requests =
        provider.pharmacyRequests
            .where(
              (request) =>
                  request.assignedCenterId == center?.id &&
                  request.status == PharmacyRequestStatus.ready &&
                  provider
                          .treatmentRequestById(request.treatmentRequestId)
                          ?.status ==
                      RequestStatus.readyToDispense &&
                  (query.isEmpty ||
                      request.id.toLowerCase().contains(query) ||
                      (provider
                              .getPatientById(request.patientId)
                              ?.emiratesId
                              .contains(query) ??
                          false) ||
                      (provider
                              .getPatientById(request.patientId)
                              ?.getLocalizedFullName(context)
                              .toLowerCase()
                              .contains(query) ??
                          false)),
            )
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('dispensing_facility'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.isArabic ? 'طلبات الصرف' : 'Dispensing requests',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              center?.getLocalizedName(context) ??
                  (context.isArabic
                      ? 'لا يوجد مركز محدد'
                      : 'No center selected'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.tr('search_eid_hint'),
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: IconButton(
                  tooltip: context.isArabic ? 'بحث' : 'Search',
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: _searchController.text.trim().isEmpty
                        ? AppColors.disabled
                        : AppColors.primary,
                  ),
                  onPressed: _searchController.text.trim().isEmpty
                      ? null
                      : _searchPatient,
                ),
              ),
              onSubmitted: (_) => _searchPatient(),
            ),
            const SizedBox(height: 24),
            Text(
              context.isArabic
                  ? 'جاهز للمراجعة والتسليم (${requests.length})'
                  : 'Ready for review and handover (${requests.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.isNotEmpty
                            ? (context.isArabic
                                  ? 'لا توجد طلبات مطابقة. غيّر البحث أو امسحه.'
                                  : 'No matching requests. Change or clear the search.')
                            : (context.isArabic
                                  ? 'لا توجد طلبات صرف معتمدة لهذا المركز حالياً.'
                                  : 'No approved dispensing requests are assigned to this center.'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (query.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: Text(
                            context.isArabic ? 'مسح البحث' : 'Clear search',
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              for (final request in requests)
                Builder(
                  builder: (context) {
                    final patient = provider.getPatientById(request.patientId);
                    if (patient == null) return const SizedBox.shrink();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        title: Text(
                          patient.getLocalizedFullName(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${request.dose} • ${request.id}',
                          textDirection: TextDirection.ltr,
                          textAlign: context.isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          context.isArabic
                              ? LucideIcons.chevronLeft
                              : LucideIcons.chevronRight,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientDispensingDetails(
                              patient: patient,
                              centerId: center!.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
