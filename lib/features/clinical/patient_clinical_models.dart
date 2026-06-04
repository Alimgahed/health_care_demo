/// One medication handover at an authorized dispensing facility.
class PatientDispenseRecord {
  final String date;
  final String dose;
  final String centerId;

  const PatientDispenseRecord({
    required this.date,
    required this.dose,
    required this.centerId,
  });
}

/// Clinical attachments and extended beneficiary fields for the clinical portal demo.
class PatientAttachment {
  final String id;
  final String fileName;
  final String mimeType;
  final DateTime uploadedAt;
  final String category; // lab_report | imaging | referral | other

  const PatientAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.uploadedAt,
    this.category = 'lab_report',
  });

  bool get isPdf => mimeType.contains('pdf') || fileName.toLowerCase().endsWith('.pdf');
}
