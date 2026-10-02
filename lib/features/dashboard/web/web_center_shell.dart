import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/access_control.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/demo/demo_session_provider.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/dose_utils.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/login_screen.dart';
import '../../dispensing/web_pharmacy_dispensing_view.dart';

class WebCenterShell extends StatefulWidget {
  final String? initialPatientId;
  final bool embeddedInAdmin;

  const WebCenterShell({
    super.key,
    this.initialPatientId,
    this.embeddedInAdmin = false,
  });

  @override
  State<WebCenterShell> createState() => _WebCenterShellState();
}

class _WebCenterShellState extends State<WebCenterShell> {
  int _selectedIndex =
      0; // 0 = Dispense medication, 1 = Live Inventory, 2 = Dispense Logs
  String _localCenterId = 'C001';

  int _readyRequestCountForCenter(
    DataProvider provider,
    DispensingCenter center,
  ) {
    return provider.pharmacyRequests.where((request) {
      if (request.assignedCenterId != center.id ||
          request.status != PharmacyRequestStatus.ready) {
        return false;
      }
      return provider
          .validateDispensing(
            patientId: request.patientId,
            centerId: center.id,
            hasPermission: true,
          )
          .canDispense;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context);
    final demoSession = context.watch<DemoSessionProvider?>();

    final requestedCenterId = demoSession?.pharmacyCenterId ?? _localCenterId;
    final center = dataProvider.centers.firstWhere(
      (c) => c.id == requestedCenterId,
      orElse: () => dataProvider.centers.first,
    );

    final body = _selectedIndex == 0
        ? WebPharmacyDispensingView(
            center: center,
            initialPatientId: widget.initialPatientId,
          )
        : (_selectedIndex == 1
              ? _buildInventoryView(context, dataProvider, center)
              : _buildLogsView(context, dataProvider, center));

    if (widget.embeddedInAdmin) {
      return ColoredBox(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmbeddedAdminHeader(context, center, dataProvider),
            Expanded(child: body),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= AppLayout.desktopBreakpoint;
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: showSidebar
              ? null
              : Drawer(child: _buildSidebar(context, dataProvider, center)),
          body: Row(
            children: [
              if (showSidebar)
                SizedBox(
                  width: AppLayout.desktopSidebar,
                  child: _buildSidebar(context, dataProvider, center),
                ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopbar(
                      context,
                      localeProvider,
                      dataProvider,
                      center,
                      showMenuButton: !showSidebar,
                    ),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmbeddedAdminHeader(
    BuildContext context,
    DispensingCenter center,
    DataProvider provider,
  ) {
    final ready = _readyRequestCountForCenter(provider, center);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin_embed_dispensing_title'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin_embed_dispensing_sub', {
                        'center': center.getLocalizedName(context),
                      }),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (ready > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '$ready ${context.tr('badge_ready_dispense')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              _centerSelector(context, provider, center),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _embeddedTab(
                context,
                LucideIcons.scanLine,
                context.tr('dispense_mounjaro'),
                0,
              ),
              _embeddedTab(
                context,
                LucideIcons.package,
                context.tr('live_stock_inventory'),
                1,
              ),
              _embeddedTab(
                context,
                LucideIcons.history,
                context.tr('dispensing_activity_logs'),
                2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _embeddedTab(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final selected = _selectedIndex == index;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopbar(
    BuildContext context,
    LocaleProvider localeProvider,
    DataProvider dataProvider,
    DispensingCenter center, {
    required bool showMenuButton,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () {
                  Scaffold.of(ctx).openDrawer();
                },
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('dispensing_portal'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  center.getLocalizedName(context),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _centerSelector(context, dataProvider, center),
          if (_readyRequestCountForCenter(dataProvider, center) > 0) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_readyRequestCountForCenter(dataProvider, center)} ${context.tr('badge_ready_dispense')}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: localeProvider.toggleLanguage,
            icon: Icon(
              LucideIcons.globe,
              size: 14,
              color: AppColors.textPrimary,
            ),
            label: Text(
              localeProvider.locale.languageCode == 'en'
                  ? context.tr('arabic')
                  : context.tr('english'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LucideIcons.logOut,
              size: 18,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: IconButton.styleFrom(
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    DataProvider provider,
    DispensingCenter center,
  ) {
    final readyCount = _readyRequestCountForCenter(provider, center);
    return Container(
      width: 240,
      color: AppColors.navy,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ncc_brand'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        context.tr('center_portal_subtitle'),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navSection(context.tr('nav_operations')),
                  _buildSidebarItem(
                    LucideIcons.scanLine,
                    context.tr('dispense_mounjaro'),
                    0,
                    badge: readyCount > 0 ? '$readyCount' : null,
                  ),
                  _buildSidebarItem(
                    LucideIcons.package,
                    context.tr('live_stock_inventory'),
                    1,
                  ),
                  _buildSidebarItem(
                    LucideIcons.history,
                    context.tr('dispensing_activity_logs'),
                    2,
                  ),
                ],
              ),
            ),
          ),
          // User
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'PA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('pharmacist_role'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.tr('center_depot'),
                        style: TextStyle(
                          color: AppColors.surface54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index, {
    String? badge,
  }) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateForUi(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Widget _buildInventoryView(
    BuildContext context,
    DataProvider provider,
    DispensingCenter center,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('inventory_stock_dashboard'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('inventory_stock_sub'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: _buildStockCard(
                  context,
                  context.tr('mounjaro_dose_2_5'),
                  provider.availableStockForDose(center, '2.5 mg'),
                  'C001_2.5',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStockCard(
                  context,
                  context.tr('mounjaro_dose_5_0'),
                  provider.availableStockForDose(center, '5 mg'),
                  'C001_5.0',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStockCard(
                  context,
                  context.tr('mounjaro_dose_7_5'),
                  provider.availableStockForDose(center, '7.5 mg'),
                  'C001_7.5',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStockCard(
                  context,
                  context.tr('mounjaro_dose_10_0'),
                  provider.availableStockForDose(center, '10 mg'),
                  'C001_10.0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('request_restock'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('request_restock_sub'),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _showRestockDialog(context, provider, center),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(context.tr('simulate_restock')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.isArabic
                        ? 'دفعات المخزون والصلاحية'
                        : 'Stock batches & expiry',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...center.batches.map(
                    (batch) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(child: Text('${batch.id} · ${batch.dose}')),
                          Text(
                            '${context.isArabic ? 'الكمية' : 'Qty'} ${batch.quantity}',
                          ),
                          const SizedBox(width: 20),
                          Text(
                            '${context.isArabic ? 'الصلاحية' : 'Expiry'} ${_formatDateForUi(batch.expiryDate)}',
                            style: TextStyle(
                              color: batch.expiryDate.isBefore(DateTime.now())
                                  ? AppColors.error
                                  : AppColors.textSecondary,
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
        ],
      ),
    );
  }

  Future<void> _showRestockDialog(
    BuildContext context,
    DataProvider provider,
    DispensingCenter center,
  ) async {
    final canManageInventory = Provider.of<AccessControlProvider>(
      context,
      listen: false,
    ).can(AppPermission.managePharmacyInventory);
    final quantityController = TextEditingController(text: '10');
    var dose = '5 mg';
    var expiry = DateTime.now().add(const Duration(days: 365));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            context.isArabic ? 'إضافة دفعة مخزون' : 'Add stock batch',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: dose,
                  decoration: InputDecoration(
                    labelText: context.isArabic ? 'الجرعة' : 'Dose',
                  ),
                  items: DoseUtils.planDoseOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: DoseUtils.toInventoryDose(item),
                          child: Text(DoseUtils.toInventoryDose(item)),
                        ),
                      )
                      .toSet()
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => dose = value);
                    }
                  },
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.isArabic ? 'الكمية' : 'Quantity',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.calendar),
                  label: Text(
                    '${context.isArabic ? 'تاريخ الصلاحية' : 'Expiry date'} · ${_formatDateForUi(expiry)}',
                  ),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: expiry,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (selected != null) {
                      setDialogState(() => expiry = selected);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: canManageInventory
                  ? () {
                      final quantity = int.tryParse(
                        quantityController.text.trim(),
                      );
                      if (quantity == null ||
                          quantity <= 0 ||
                          !expiry.isAfter(DateTime.now())) {
                        return;
                      }
                      provider.replenishInventory(
                        center.id,
                        dose,
                        quantity,
                        authorized: canManageInventory,
                        expiryDate: expiry,
                      );
                      Navigator.pop(dialogContext);
                      CustomToast.show(
                        context,
                        title: context.tr('stock_updated'),
                        message:
                            '$quantity × $dose · ${_formatDateForUi(expiry)}',
                        icon: LucideIcons.packageCheck,
                        color: AppColors.success,
                      );
                    }
                  : null,
              child: Text(context.isArabic ? 'حفظ الدفعة' : 'Save batch'),
            ),
          ],
        ),
      ),
    );
    quantityController.dispose();
  }

  Widget _buildStockCard(
    BuildContext context,
    String doseTitle,
    int stock,
    String code,
  ) {
    bool lowStock = stock < 10;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(LucideIcons.package, color: AppColors.primary),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lowStock
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lowStock
                        ? context.tr('low_stock')
                        : context.tr('good_stock'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: lowStock ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '$stock',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: lowStock ? AppColors.error : AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doseTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.tr('sku_label', {'code': code}),
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerSelector(
    BuildContext context,
    DataProvider provider,
    DispensingCenter selectedCenter,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCenter.id,
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 18),
          items: provider.centers
              .map(
                (center) => DropdownMenuItem<String>(
                  value: center.id,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 175),
                    child: Text(
                      center.getLocalizedName(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (centerId) {
            if (centerId == null) return;
            final session = context.read<DemoSessionProvider?>();
            if (session != null) {
              session.selectPharmacyCenter(centerId);
            } else {
              setState(() => _localCenterId = centerId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLogsView(
    BuildContext context,
    DataProvider provider,
    DispensingCenter facility,
  ) {
    final centerLogs = provider.logs
        .where(
          (l) =>
              l.centerName == facility.name ||
              l.centerNameAr == facility.nameAr ||
              l.getLocalizedCenterName(context) ==
                  facility.getLocalizedName(context),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('recent_center_activity'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('recent_center_activity_sub'),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ListView.separated(
                  itemCount: centerLogs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = centerLogs[index];
                    bool overridden = log.status == 'Overridden';
                    return ListTile(
                      leading: Icon(
                        overridden
                            ? LucideIcons.shieldAlert
                            : LucideIcons.checkCircle,
                        color: overridden ? AppColors.error : AppColors.success,
                      ),
                      title: Text(
                        '${log.getLocalizedPatientName(context)} - ${log.getLocalizedAction(context)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        log.eventKind == 'dispense'
                            ? '${context.tr('dispensed_at_facility', {'facility': log.getLocalizedCenterName(context)})}\n${context.tr('processed_at', {'time': log.formattedTimestamp})}'
                            : context.tr('processed_at', {
                                'time': log.formattedTimestamp,
                              }),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: overridden
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.getLocalizedStatus(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: overridden
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
