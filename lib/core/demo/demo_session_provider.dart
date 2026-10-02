import 'package:flutter/foundation.dart';

/// In-memory identity/context used by the client demo.
///
/// This is intentionally not an authentication service. It only makes the
/// selected demo patient explicit so every portal reads the same patient.
class DemoSessionProvider extends ChangeNotifier {
  String _patientId;
  String _pharmacyCenterId;

  DemoSessionProvider({
    String initialPatientId = 'P999',
    String initialPharmacyCenterId = 'C001',
  }) : _patientId = initialPatientId,
       _pharmacyCenterId = initialPharmacyCenterId;

  String get patientId => _patientId;
  String get pharmacyCenterId => _pharmacyCenterId;

  void selectPharmacyCenter(String centerId) {
    if (centerId.isEmpty || centerId == _pharmacyCenterId) return;
    _pharmacyCenterId = centerId;
    notifyListeners();
  }

  void selectPatient(String patientId) {
    if (patientId.isEmpty || patientId == _patientId) return;
    _patientId = patientId;
    notifyListeners();
  }
}
