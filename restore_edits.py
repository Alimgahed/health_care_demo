import re

# Web Admin Shell
with open('lib/features/dashboard/web/web_admin_shell.dart', 'r') as f:
    content = f.read()

# 1. Import ThemeProvider and ActivityFeedTicker
if "'../../../core/theme/theme_provider.dart'" not in content:
    content = content.replace(
        "import '../../../core/theme/app_colors.dart';",
        "import '../../../core/theme/app_colors.dart';\nimport '../../../core/theme/theme_provider.dart';\nimport '../admin_views/activity_feed_ticker.dart';"
    )

# 2. Add Theme Toggle
theme_toggle = """          const SizedBox(width: 8),
          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _iconBtn(
                themeProvider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                onTap: themeProvider.toggleTheme,
              );
            },
          ),"""

if "themeProvider.isDarkMode" not in content:
    content = content.replace(
        "onTap: localeProvider.toggleLanguage,\n          ),\n          const SizedBox(width: 8),\n          // Notifications",
        "onTap: localeProvider.toggleLanguage,\n          ),\n" + theme_toggle + "\n          const SizedBox(width: 8),\n          // Notifications"
    )

# 3. Add ActivityFeedTicker
ticker = """              // ── Activity Log (AI Ticker) ──────────────────────────────────
              const ActivityFeedTicker(),
              const SizedBox(height: 24),"""

if "ActivityFeedTicker()" not in content:
    content = content.replace(
        """              const SizedBox(height: 24),

              // ── Main Charts Row""",
        ticker + """

              // ── Main Charts Row"""
    )

with open('lib/features/dashboard/web/web_admin_shell.dart', 'w') as f:
    f.write(content)

# Patient 360 View
with open('lib/features/treatment_plan/web/patient_360_view.dart', 'r') as f:
    content360 = f.read()

if "'../../clinical/ai_decision_support_card.dart'" not in content360:
    content360 = content360.replace(
        "import '../../models/treatment_plan.dart';",
        "import '../../models/treatment_plan.dart';\nimport '../../clinical/ai_decision_support_card.dart';"
    )

if "AiDecisionSupportCard(patient: patient)" not in content360:
    content360 = content360.replace(
        """        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard""",
        """        children: [
          AiDecisionSupportCard(patient: patient),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildMetricCard"""
    )

with open('lib/features/treatment_plan/web/patient_360_view.dart', 'w') as f:
    f.write(content360)

