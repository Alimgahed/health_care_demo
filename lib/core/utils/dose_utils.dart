/// Normalizes Mounjaro dose labels between clinical plans and inventory keys.
class DoseUtils {
  DoseUtils._();

  static const List<String> planDoseOptions = ['2.5 mg', '5.0 mg', '7.5 mg', '10.0 mg'];

  static String toInventoryDose(String dose) {
    final d = dose.trim().toLowerCase();
    if (d.contains('2.5')) return '2.5 mg';
    if (d.contains('7.5')) return '7.5 mg';
    if (d.contains('10')) return '10 mg';
    if (d.contains('5')) return '5 mg';
    return dose;
  }

  static bool dosesMatch(String a, String b) => toInventoryDose(a) == toInventoryDose(b);
}
