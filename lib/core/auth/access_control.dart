import 'package:flutter/foundation.dart';

enum AppRole {
  systemAdmin,
  doctor,
  medicalReviewer,
  pharmacist,
  careCoordinator,
  patient,
}

enum AppPermission {
  viewPatient,
  editPatient,
  createTreatmentPlan,
  createTreatmentRequest,
  reviewEligibility,
  approveTreatment,
  rejectTreatment,
  sendToPharmacy,
  dispenseMedication,
  managePharmacyInventory,
  startFollowUp,
  viewLabResults,
  editLabResults,
  viewDocuments,
  editDocuments,
  manageAppointments,
  viewAuditLog,
  recordAdherence,
  recordPatientActivity,
  requestMedication,
}

class AccessControlProvider extends ChangeNotifier {
  AppRole _role;

  AccessControlProvider({AppRole initialRole = AppRole.systemAdmin})
    : _role = initialRole;

  AppRole get role => _role;

  static const Map<AppRole, Set<AppPermission>> _permissions = {
    AppRole.systemAdmin: {...AppPermission.values},
    AppRole.doctor: {
      AppPermission.viewPatient,
      AppPermission.editPatient,
      AppPermission.createTreatmentPlan,
      AppPermission.createTreatmentRequest,
      AppPermission.reviewEligibility,
      AppPermission.startFollowUp,
      AppPermission.viewLabResults,
      AppPermission.editLabResults,
      AppPermission.viewDocuments,
      AppPermission.editDocuments,
      AppPermission.manageAppointments,
      AppPermission.viewAuditLog,
      AppPermission.recordPatientActivity,
    },
    AppRole.medicalReviewer: {
      AppPermission.viewPatient,
      AppPermission.reviewEligibility,
      AppPermission.approveTreatment,
      AppPermission.rejectTreatment,
      AppPermission.sendToPharmacy,
      AppPermission.viewLabResults,
      AppPermission.viewDocuments,
      AppPermission.viewAuditLog,
    },
    AppRole.pharmacist: {
      AppPermission.viewPatient,
      AppPermission.dispenseMedication,
      AppPermission.managePharmacyInventory,
      AppPermission.viewLabResults,
      AppPermission.viewDocuments,
      AppPermission.viewAuditLog,
    },
    AppRole.careCoordinator: {
      AppPermission.viewPatient,
      AppPermission.startFollowUp,
      AppPermission.manageAppointments,
      AppPermission.viewLabResults,
      AppPermission.viewDocuments,
      AppPermission.viewAuditLog,
      AppPermission.recordPatientActivity,
    },
    AppRole.patient: {
      AppPermission.viewPatient,
      AppPermission.viewLabResults,
      AppPermission.viewDocuments,
      AppPermission.recordAdherence,
      AppPermission.recordPatientActivity,
      AppPermission.requestMedication,
    },
  };

  bool can(AppPermission permission) =>
      _permissions[_role]?.contains(permission) ?? false;

  void setRole(AppRole role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }
}
