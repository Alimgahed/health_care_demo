import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/locale_provider.dart';
import '../utils/dose_utils.dart';

enum ActivityEventType {
  dispense,
  carePlan,
  registration,
  clinicalReview,
  weightUpdate,
  doseChange,
  documentUpload,
  inventoryReplenish,
  adminAction,
  misusePrevented,
  other,
}

/// Beneficiary audit trail entry (dispensing, care plan, clinical actions).
class ActivityLog {
  final String id;
  final String patientName;
  final String patientNameAr;
  final String patientId;
  final ActivityEventType eventType;
  final String action;
  final String actionAr;
  final String centerName;
  final String centerNameAr;
  final DateTime timestamp;
  final String status;
  final String statusAr;

  ActivityLog({
    required this.id,
    required this.patientName,
    required this.patientNameAr,
    required this.patientId,
    required this.eventType,
    required this.action,
    required this.actionAr,
    required this.centerName,
    required this.centerNameAr,
    required this.timestamp,
    required this.status,
    required this.statusAr,
  });

  bool _isAr(BuildContext context) =>
      Provider.of<LocaleProvider>(context, listen: false).locale.languageCode == 'ar';

  String getLocalizedPatientName(BuildContext context) =>
      _isAr(context) ? patientNameAr : patientName;
  String getLocalizedAction(BuildContext context) => _isAr(context) ? actionAr : action;
  String getLocalizedCenterName(BuildContext context) => _isAr(context) ? centerNameAr : centerName;
  String getLocalizedStatus(BuildContext context) => _isAr(context) ? statusAr : status;

  /// UI switch key (dispense | care_plan | …).
  String get eventKind => switch (eventType) {
        ActivityEventType.dispense => 'dispense',
        ActivityEventType.carePlan => 'care_plan',
        ActivityEventType.registration => 'registration',
        ActivityEventType.clinicalReview => 'clinical_review',
        ActivityEventType.inventoryReplenish => 'inventory_replenish',
        ActivityEventType.adminAction => 'admin_action',
        ActivityEventType.misusePrevented => 'misuse_prevented',
        _ => 'other',
      };

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  /// ISO-style date + 24h time (locale-aware date order).
  String formatTimestamp(BuildContext context) {
    final d = timestamp;
    final isAr = _isAr(context);
    final date = isAr
        ? '${_pad2(d.day)}/${_pad2(d.month)}/${d.year}'
        : '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';
    final time = '${_pad2(d.hour)}:${_pad2(d.minute)}';
    return '$date · $time';
  }

  /// Same as [formatTimestamp] without [BuildContext] (EN date order).
  String get formattedTimestamp {
    final d = timestamp;
    return '${d.year}-${_pad2(d.month)}-${_pad2(d.day)} · ${_pad2(d.hour)}:${_pad2(d.minute)}';
  }

  static ActivityLog dispense({
    required String id,
    required PatientRef patient,
    required String dose,
    required CenterRef center,
    required DateTime timestamp,
    String status = 'Success',
    String statusAr = 'ناجح',
    bool isOverride = false,
  }) {
    final d = DoseUtils.toInventoryDose(dose);
    return ActivityLog(
      id: id,
      patientName: patient.name,
      patientNameAr: patient.nameAr,
      patientId: patient.id,
      eventType: ActivityEventType.dispense,
      action: 'Medication dispensed · $d · ${center.name}',
      actionAr: 'صرف دواء · $d · ${center.nameAr}',
      centerName: center.name,
      centerNameAr: center.nameAr,
      timestamp: timestamp,
      status: isOverride ? 'Overridden' : status,
      statusAr: isOverride ? 'تم التجاوز' : statusAr,
    );
  }

  static ActivityLog carePlan({
    required String id,
    required PatientRef patient,
    required String dose,
    required int intervalDays,
    required DateTime timestamp,
    bool pendingReview = false,
  }) {
    final d = DoseUtils.toInventoryDose(dose);
    return ActivityLog(
      id: id,
      patientName: patient.name,
      patientNameAr: patient.nameAr,
      patientId: patient.id,
      eventType: ActivityEventType.carePlan,
      action: pendingReview
          ? 'Care plan pending approval · $d · every $intervalDays days'
          : 'Care plan documented · $d · every $intervalDays days',
      actionAr: pendingReview
          ? 'خطة رعاية بانتظار الاعتماد · $d · كل $intervalDays يوم'
          : 'توثيق خطة رعاية · $d · كل $intervalDays يوم — ليس صرفاً',
      centerName: 'Physician Portal',
      centerNameAr: 'بوابة الطبيب المعالج',
      timestamp: timestamp,
      status: pendingReview ? 'Pending' : 'Success',
      statusAr: pendingReview ? 'قيد المراجعة' : 'ناجح',
    );
  }

  static ActivityLog clinicalReviewApproved({
    required String id,
    required PatientRef patient,
    required DateTime timestamp,
  }) {
    return ActivityLog(
      id: id,
      patientName: patient.name,
      patientNameAr: patient.nameAr,
      patientId: patient.id,
      eventType: ActivityEventType.clinicalReview,
      action: 'Physician authorization approved · dispensing authorized',
      actionAr: 'اعتماد الطبيب · صرف مُصرّح',
      centerName: 'Physician Portal',
      centerNameAr: 'بوابة الطبيب المعالج',
      timestamp: timestamp,
      status: 'Success',
      statusAr: 'ناجح',
    );
  }

  static ActivityLog inventoryReplenish({
    required String id,
    required String centerName,
    required String centerNameAr,
    required String dose,
    required int amount,
    required DateTime timestamp,
  }) {
    final d = DoseUtils.toInventoryDose(dose);
    return ActivityLog(
      id: id,
      patientName: 'System',
      patientNameAr: 'النظام',
      patientId: 'SYS',
      eventType: ActivityEventType.inventoryReplenish,
      action: 'Inventory replenished · $amount units added ($d)',
      actionAr: 'تزويد مخزون · تمت إضافة $amount وحدة ($d)',
      centerName: centerName,
      centerNameAr: centerNameAr,
      timestamp: timestamp,
      status: 'Success',
      statusAr: 'ناجح',
    );
  }

  static ActivityLog adminAction({
    required String id,
    required String actionDesc,
    required String actionDescAr,
    required DateTime timestamp,
  }) {
    return ActivityLog(
      id: id,
      patientName: 'Admin',
      patientNameAr: 'المدير',
      patientId: 'ADM',
      eventType: ActivityEventType.adminAction,
      action: actionDesc,
      actionAr: actionDescAr,
      centerName: 'MoHAP Headquarters',
      centerNameAr: 'المقر الرئيسي للوزارة',
      timestamp: timestamp,
      status: 'Success',
      statusAr: 'ناجح',
    );
  }

  /// Blocked or supervisor-overridden misuse attempt (misuse prevention log).
  static ActivityLog misusePrevented({
    required String id,
    required PatientRef patient,
    required CenterRef center,
    required String reason,
    required String reasonAr,
    required DateTime timestamp,
    bool overridden = false,
  }) {
    return ActivityLog(
      id: id,
      patientName: patient.name,
      patientNameAr: patient.nameAr,
      patientId: patient.id,
      eventType: ActivityEventType.misusePrevented,
      action: overridden
          ? 'Override approved · $reason · ${center.name}'
          : 'Misuse blocked · $reason · ${center.name}',
      actionAr: overridden
          ? 'تجاوز معتمد · $reasonAr · ${center.nameAr}'
          : 'منع إساءة · $reasonAr · ${center.nameAr}',
      centerName: center.name,
      centerNameAr: center.nameAr,
      timestamp: timestamp,
      status: overridden ? 'Overridden' : 'Flagged',
      statusAr: overridden ? 'تم التجاوز' : 'مُبلّغ',
    );
  }
}

/// Lightweight refs for log factories (avoids circular imports with [Patient]).
class PatientRef {
  final String id;
  final String name;
  final String nameAr;
  const PatientRef({required this.id, required this.name, required this.nameAr});
}

class CenterRef {
  final String name;
  final String nameAr;
  const CenterRef({required this.name, required this.nameAr});
}
