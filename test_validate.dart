import 'lib/core/constants/mock_data.dart';

void main() {
  final dp = DataProvider();
  final p = dp.patients.first;
  final c = dp.centers.first;
  final v = dp.validateDispensing(patientId: p.id, centerId: c.id, hasPermission: true);
  // ignore: avoid_print
  print('ISSUES: ${v.issues}');
}
