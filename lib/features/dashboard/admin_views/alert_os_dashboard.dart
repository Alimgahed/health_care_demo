import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/mock_data.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../program_alerts.dart';
import 'alert_os_ai_assistant.dart';

enum AlertOSSection { overview, liveFeed, aiChat }

/// Main sidebar indices for AlertOS sections (WebAdminShell).
const int kAlertOSNavOverview = 4;
const int kAlertOSNavLiveFeed = 5;
const int kAlertOSNavAiChat = 6;
const int kAlertOSNavFraudLog = 7;
const int kAlertOSNavReports = 8;

int alertOSSectionNavIndex(AlertOSSection section) {
  switch (section) {
    case AlertOSSection.overview:
      return kAlertOSNavOverview;
    case AlertOSSection.liveFeed:
      return kAlertOSNavLiveFeed;
    case AlertOSSection.aiChat:
      return kAlertOSNavAiChat;
  }
}

AlertOSSection? alertOSSectionFromNavIndex(int index) {
  switch (index) {
    case kAlertOSNavOverview:
      return AlertOSSection.overview;
    case kAlertOSNavLiveFeed:
      return AlertOSSection.liveFeed;
    case kAlertOSNavAiChat:
      return AlertOSSection.aiChat;
    default:
      return null;
  }
}

class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime time;
  ChatMessage({required this.isUser, required this.text, required this.time});
}

class FeedItem {
  final AlertCategory category;
  final String message;
  final DateTime time;
  FeedItem({required this.category, required this.message, required this.time});
}

class AlertOSDashboard extends StatefulWidget {
  final AlertOSSection section;
  final ValueChanged<AlertOSSection>? onSectionNavigate;

  const AlertOSDashboard({
    super.key,
    this.section = AlertOSSection.overview,
    this.onSectionNavigate,
  });

  @override
  State<AlertOSDashboard> createState() => _AlertOSDashboardState();
}

class _AlertOSDashboardState extends State<AlertOSDashboard> {
  AlertCategory? _filterCategory;
  String _searchQuery = '';
  String _sortMode = 'newest';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<FeedItem> _feedItems = [];
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatCtrl = TextEditingController();
  bool _aiTyping = false;
  Timer? _feedTimer;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  final ScrollController _feedScroll = ScrollController();
  final ScrollController _chatScroll = ScrollController();
  final ScrollController _contentScroll = ScrollController();

  late List<String> _feedPool;

  final List<AlertCategory> _feedCategoryPool = [
    AlertCategory.fraud,
    AlertCategory.supply,
    AlertCategory.clinical,
    AlertCategory.fraud,
    AlertCategory.supply,
    AlertCategory.clinical,
    AlertCategory.supply,
    AlertCategory.fraud,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _feedPool = [
      context.tr('feed_msg_1'),
      context.tr('feed_msg_2'),
      context.tr('feed_msg_3'),
      context.tr('feed_msg_4'),
      context.tr('feed_msg_5'),
      context.tr('feed_msg_6'),
      context.tr('feed_msg_7'),
      context.tr('feed_msg_8'),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatMessages.add(ChatMessage(
        isUser: false,
        text: context.tr('ai_welcome_msg'),
        time: DateTime.now(),
      ));
      for (int i = 0; i < 4; i++) {
        _addFeedItem();
      }
    });

    _feedTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _addFeedItem());
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _addFeedItem() {
    if (_feedPool.isEmpty) return;
    final rnd = Random();
    final idx = rnd.nextInt(_feedPool.length);
    _feedItems.insert(0, FeedItem(
      category: _feedCategoryPool[idx],
      message: _feedPool[idx],
      time: DateTime.now(),
    ));
    if (_feedItems.length > 20) _feedItems.removeLast();
  }

  @override
  void dispose() {
    _feedTimer?.cancel();
    _clockTimer?.cancel();
    _searchCtrl.dispose();
    _chatCtrl.dispose();
    _feedScroll.dispose();
    _chatScroll.dispose();
    _contentScroll.dispose();
    super.dispose();
  }

  List<ProgramAlert> _filteredAlerts(List<ProgramAlert> allAlerts, {AlertCategory? forceCategory}) {
    final categoryFilter = forceCategory ?? _filterCategory;
    var list = allAlerts.where((a) {
      if (a.kind == ProgramAlertKind.allClear) return false;
      if (categoryFilter != null && a.category != categoryFilter) return false;
      if (_searchQuery.isNotEmpty &&
          !a.message.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !a.localizedKindLabel(context).toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    if (_sortMode == 'severity') {
      list.sort((a, b) => b.severity.compareTo(a.severity));
    } else if (_sortMode == 'oldest') {
      list.sort((a, b) => a.id.compareTo(b.id));
    } else {
      list.sort((a, b) => b.id.compareTo(a.id));
    }
    return list;
  }

  Future<void> _sendChat(String text) async {
    if (text.trim().isEmpty) return;
    _chatCtrl.clear();
    setState(() {
      _chatMessages.add(ChatMessage(isUser: true, text: text, time: DateTime.now()));
      _aiTyping = true;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    _scrollChat();
    await Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(800)));
    final reply = AlertOsAiAssistant.reply(context, context.read<DataProvider>(), text);
    if (mounted) {
      setState(() {
        _aiTyping = false;
        _chatMessages.add(ChatMessage(isUser: false, text: reply, time: DateTime.now()));
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollChat();
    }
  }

  void _scrollChat() {
    if (_chatScroll.hasClients) {
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _applyFilter(AlertCategory? category) {
    setState(() => _filterCategory = category);
    if (_contentScroll.hasClients) {
      _contentScroll.jumpTo(0);
    }
  }

  int _countForCategory(List<ProgramAlert> alerts, AlertCategory cat) =>
      alerts.where((a) => a.category == cat && a.kind != ProgramAlertKind.allClear).length;

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final allAlerts = collectProgramAlerts(context, dp);
    final activeAlerts = allAlerts.where((a) => a.kind != ProgramAlertKind.allClear).toList();
    final timeStr =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(timeStr, activeAlerts.length),
          const SizedBox(height: 16),
          if (widget.section == AlertOSSection.overview) ...[
            _buildMetricRow(activeAlerts),
            const SizedBox(height: 20),
          ],
          Expanded(child: _buildSectionContent(activeAlerts)),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String time, int totalAlerts) {
    final (title, subtitle, icon) = switch (widget.section) {
      AlertOSSection.overview => (
          context.tr('nav_ai_alerts'),
          context.tr('ai_command_center_desc'),
          LucideIcons.bot,
        ),
      AlertOSSection.liveFeed => (
          context.tr('live_activity_feed'),
          context.tr('live_activity_feed_desc'),
          LucideIcons.radio,
        ),
      AlertOSSection.aiChat => (
          context.tr('ai_assistant_title'),
          context.tr('ai_assistant_subtitle'),
          LucideIcons.bot,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (widget.section == AlertOSSection.overview)
          _buildLiveStatusChip(time, totalAlerts),
      ],
    );
  }

  Widget _buildLiveStatusChip(String time, int totalAlerts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _liveDot(),
          const SizedBox(width: 8),
          Text(
            context.tr('live_badge') ?? 'مباشر',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 20,
            color: AppColors.border,
          ),
          Text(
            time,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 20,
            color: AppColors.border,
          ),
          _badge(
            totalAlerts.toString(),
            totalAlerts > 0 ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            context.tr('active_alerts_singular'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _liveDot() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.error, blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricRow(List<ProgramAlert> allAlerts) {
    final fraudCount = _countForCategory(allAlerts, AlertCategory.fraud);
    final clinicalCount = _countForCategory(allAlerts, AlertCategory.clinical);
    final supplyCount = _countForCategory(allAlerts, AlertCategory.supply);

    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context.tr('security_fraud') ?? 'أمن واحتيال',
            fraudCount,
            AppColors.error,
            LucideIcons.shieldAlert,
            onTap: () => _applyFilter(AlertCategory.fraud),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            context.tr('clinical_followup') ?? 'متابعة سريرية',
            clinicalCount,
            AppColors.accent,
            LucideIcons.stethoscope,
            onTap: () => _applyFilter(AlertCategory.clinical),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            context.tr('supply_crises') ?? 'أزمات الإمداد',
            supplyCount,
            AppColors.warning,
            LucideIcons.package,
            onTap: () => _applyFilter(AlertCategory.supply),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            context.tr('total_alerts') ?? 'إجمالي التنبيهات',
            allAlerts.length,
            AppColors.info,
            LucideIcons.bell,
            onTap: () => _applyFilter(null),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, int count, Color color, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent(List<ProgramAlert> allAlerts) {
    return _panelShell(
      child: switch (widget.section) {
        AlertOSSection.overview => _buildOverviewContent(allAlerts),
        AlertOSSection.liveFeed => _buildLiveFeedContent(),
        AlertOSSection.aiChat => _buildAIChatContent(),
      },
    );
  }

  Widget _panelShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildAlertsToolbar({String? title, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title ?? context.tr('active_alerts') ?? 'التنبيهات النشطة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: context.tr('search') ?? 'بحث...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 8),
          _sortDropdown(),
        ],
      ),
    );
  }

  Widget _buildOverviewContent(List<ProgramAlert> allAlerts) {
    final categories = [
      (AlertCategory.fraud, context.tr('security_fraud'), LucideIcons.shieldAlert, AppColors.error),
      (AlertCategory.clinical, context.tr('clinical_followup'), LucideIcons.stethoscope, AppColors.accent),
      (AlertCategory.supply, context.tr('supply_crises'), LucideIcons.package, AppColors.warning),
    ];

    final filtered = _filteredAlerts(allAlerts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAlertsToolbar(
          title: context.tr('active_alerts'),
          icon: LucideIcons.bell,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _buildFilterChips(allAlerts),
        ),
        Expanded(
          child: _filterCategory == null
              ? ListView(
                  controller: _contentScroll,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final cat in categories) ...[
                      _buildCategoryGroup(
                        allAlerts,
                        cat.$1,
                        cat.$2,
                        cat.$3,
                        cat.$4,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_filteredAlerts(allAlerts).isEmpty) _buildEmptyState(),
                  ],
                )
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      controller: _contentScroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _alertListTile(filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<ProgramAlert> allAlerts) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterChip(
          label: context.tr('all'),
          icon: LucideIcons.layoutGrid,
          color: AppColors.primary,
          isActive: _filterCategory == null,
          count: allAlerts.length,
          onTap: () => _applyFilter(null),
        ),
        _filterChip(
          label: context.tr('security_fraud_short'),
          icon: LucideIcons.shieldAlert,
          color: AppColors.error,
          isActive: _filterCategory == AlertCategory.fraud,
          count: _countForCategory(allAlerts, AlertCategory.fraud),
          onTap: () => _applyFilter(AlertCategory.fraud),
        ),
        _filterChip(
          label: context.tr('clinical_short'),
          icon: LucideIcons.stethoscope,
          color: AppColors.accent,
          isActive: _filterCategory == AlertCategory.clinical,
          count: _countForCategory(allAlerts, AlertCategory.clinical),
          onTap: () => _applyFilter(AlertCategory.clinical),
        ),
        _filterChip(
          label: context.tr('supply_short'),
          icon: LucideIcons.package,
          color: AppColors.warning,
          isActive: _filterCategory == AlertCategory.supply,
          count: _countForCategory(allAlerts, AlertCategory.supply),
          onTap: () => _applyFilter(AlertCategory.supply),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? color : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: isActive ? color : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? color : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive ? color : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(
    List<ProgramAlert> allAlerts,
    AlertCategory category,
    String title,
    IconData icon,
    Color color,
  ) {
    final alerts = _filteredAlerts(allAlerts, forceCategory: category);
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _applyFilter(category),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                _badge('${alerts.length}', color),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _applyFilter(category),
                  icon: Icon(Icons.filter_alt_outlined, size: 14, color: color),
                  label: Text(
                    context.tr('view_all'),
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...alerts.take(4).map(_alertListTile),
        if (alerts.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${alerts.length - 4} ${context.tr('more_alerts') ?? 'تنبيهات أخرى'}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _alertListTile(ProgramAlert alert) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showActionDialog(alert),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: alert.color,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: alert.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(alert.kindIcon, color: alert.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: alert.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      alert.localizedKindLabel(context),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: alert.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.access_time, size: 11, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    alert.time,
                                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alert.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ...List.generate(
                                    3,
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: i < alert.severity ? alert.color : AppColors.border,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (alert.action.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: alert.color.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(alert.actionIcon, size: 12, color: alert.color),
                                          const SizedBox(width: 4),
                                          Text(
                                            alert.action,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: alert.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            Text(
              context.tr('no_matching_alerts') ?? 'لا توجد تنبيهات مطابقة',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(ProgramAlert alert) {
    if (alert.action.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: alert.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(alert.kindIcon, color: alert.color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr('alert_details') ?? 'تفاصيل التنبيه',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
            const SizedBox(height: 12),
            Text(
              '${context.tr('suggested_action') ?? 'الإجراء المقترح:'} ${alert.action}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr('time_label') ?? 'الوقت:'} ${alert.time}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('close') ?? 'إغلاق', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${context.tr('action_executed_successfully') ?? 'تم تنفيذ:'} ${alert.action}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: alert.color, foregroundColor: Colors.white),
            icon: Icon(alert.actionIcon, size: 16),
            label: Text(alert.action, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _sortDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortMode,
          isDense: true,
          style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          items: [
            DropdownMenuItem(value: 'newest', child: Text(context.tr('sort_newest') ?? 'الأحدث')),
            DropdownMenuItem(value: 'oldest', child: Text(context.tr('sort_oldest') ?? 'الأقدم')),
            DropdownMenuItem(value: 'severity', child: Text(context.tr('sort_severity') ?? 'الأشد')),
          ],
          onChanged: (v) => setState(() => _sortMode = v!),
        ),
      ),
    );
  }

  Widget _buildLiveFeedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _liveDot(),
              const SizedBox(width: 8),
              Text(
                context.tr('live_activity_feed') ?? 'سجل الأنشطة المباشر',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text('${_feedItems.length}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              Text(context.tr('alert_count') ?? 'تنبيه', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _feedItems.clear()),
                icon: Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                tooltip: context.tr('clear') ?? 'مسح',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _feedItems.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  controller: _feedScroll,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _feedItems.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                  itemBuilder: (ctx, i) {
                    final item = _feedItems[i];
                    final color = item.category == AlertCategory.fraud
                        ? AppColors.error
                        : item.category == AlertCategory.clinical
                            ? AppColors.accent
                            : AppColors.warning;
                    final label = item.category == AlertCategory.fraud
                        ? (context.tr('security_fraud_short') ?? 'احتيال')
                        : item.category == AlertCategory.clinical
                            ? (context.tr('clinical_short') ?? 'سريري')
                            : (context.tr('supply_short') ?? 'إمداد');
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.message,
                                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}:${item.time.second.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAIChatContent() {
    final suggestions = AlertOsAiAssistant.suggestionPrompts(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navy, AppColors.primaryDark, AppColors.primary],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
                ),
                child: const Icon(LucideIcons.sparkles, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('ai_assistant_title'),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('ai_assistant_subtitle'),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.tr('ai_assistant_live'),
                      style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView.builder(
              controller: _chatScroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _chatMessages.length + (_aiTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_aiTyping && i == _chatMessages.length) {
                  return _typingIndicator();
                }
                return _chatBubble(_chatMessages[i]);
              },
            ),
          ),
        ),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('ai_suggestions_label'),
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                    label: Text(suggestions[i], style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.background,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _sendChat(suggestions[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendChat,
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.tr('ai_chat_hint'),
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                child: InkWell(
                  onTap: () => _sendChat(_chatCtrl.text),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.35 + (i * 0.2)),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
        shape: BoxShape.circle,
      ),
      child: const Icon(LucideIcons.bot, color: Colors.white, size: 14),
    );
  }

  Widget _userAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(Icons.person_outline, color: AppColors.navy, size: 15),
    );
  }

  String _formatChatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _chatBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _botAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isUser ? 0.08 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatChatTime(msg.time),
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _userAvatar(),
          ],
        ],
      ),
    );
  }
}
