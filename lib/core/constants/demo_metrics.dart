/// National-scale demo figures (registry total vs in-app sample cohort).
class DemoMetrics {
  DemoMetrics._();

  static const int nationalEnrolled = 42150;
  static const int nationalEligible = 28400;
  static const double nationalSubsidyBaseAed = 42.5e6;
  static const int nationalFraudPreventedBase = 342;
  static const double baselineNationalBmi = 33.5;

  static String formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String formatAed(double amount) {
    if (amount >= 1e6) return '${(amount / 1e6).toStringAsFixed(1)}M AED';
    if (amount >= 1e3) return '${(amount / 1e3).toStringAsFixed(0)}K AED';
    return '${amount.toStringAsFixed(0)} AED';
  }

  static String formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';
}
