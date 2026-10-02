import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/auth/access_control.dart';
import 'journey_models.dart';
import 'journey_provider.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 9, vsync: this);
  final TextEditingController _search = TextEditingController();
  String _searchResult = '';

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  String b(String en, String ar) => _ar ? ar : en;

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jp = context.watch<JourneyProvider>();
    final r = jp.request;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(b('Connected Medication Journey', 'رحلة الدواء المترابطة')),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(child: _demoBadge()),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            b('Overview', 'نظرة عامة'),
            b('Medical History', 'التاريخ الطبي'),
            b('Diagnoses', 'التشخيصات'),
            b('Lab Results', 'التحاليل'),
            b('Medication History', 'سجل الأدوية'),
            b('Treatment Requests', 'طلبات العلاج'),
            b('Treatment Journey', 'رحلة العلاج'),
            b('Attachments', 'المرفقات'),
            b('Audit Trail', 'سجل التدقيق'),
          ].map((x) => Tab(text: x)).toList(),
        ),
      ),
      body: Column(
        children: [
          _journeyStrip(r.status),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _overview(jp),
                _history(r),
                _diagnoses(r),
                _labs(r),
                _medications(r),
                _requestWorkspace(jp),
                _timeline(r),
                _attachments(r),
                _audit(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      b('Clinical decision support', 'دعم القرار السريري'),
      style: TextStyle(
        color: AppColors.warning,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );

  Widget _journeyStrip(RequestStatus active) {
    const ordered = [
      RequestStatus.draft,
      RequestStatus.submitted,
      RequestStatus.assessing,
      RequestStatus.underReview,
      RequestStatus.approved,
      RequestStatus.readyToDispense,
      RequestStatus.dispensed,
      RequestStatus.monitoring,
    ];
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ordered.map((s) {
            final reached =
                active == s ||
                (active != RequestStatus.rejected &&
                    active != RequestStatus.needsInformation &&
                    active.index >= s.index);
            return Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: reached ? AppColors.success : Colors.white24,
                  child: Icon(
                    reached ? Icons.check : Icons.circle,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _status(s),
                  style: TextStyle(
                    color: reached ? Colors.white : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (s != ordered.last)
                  Container(
                    width: 28,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white30,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _overview(JourneyProvider jp) {
    final r = jp.request;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric(
              b('Total Requests', 'إجمالي الطلبات'),
              '${jp.totalRequests}',
              Icons.description,
            ),
            _metric(
              b('Approved', 'موافق عليه'),
              '${jp.approvedRequests}',
              Icons.check_circle,
            ),
            _metric(
              b('Pending', 'قيد الانتظار'),
              '${jp.pendingRequests}',
              Icons.hourglass_top,
            ),
            _metric(
              b('Dispensed', 'تم صرفه'),
              '${jp.dispensedRequests}',
              Icons.medication,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _patientHeader(r),
        const SizedBox(height: 16),
        _aiPanel(
          b('Clinical summary', 'الملخص السريري'),
          b(
            '${r.patientNameEn} has documented ${r.diagnosisEn}. Previous ${r.previousTreatmentEn} is recorded. CRP is ${r.crp ?? 'missing'} mg/L and ESR is ${r.esr ?? 'missing'}. ${r.recentDuplicate ? 'Recent duplicate dispensing requires review.' : 'No recent duplicate dispensing was found.'}',
            '${r.patientNameAr} لديه تشخيص موثق: ${r.diagnosisAr}. العلاج السابق موثق: ${r.previousTreatmentAr}. نتيجة CRP هي ${r.crp ?? 'غير متوفرة'} ونتيجة ESR هي ${r.esr ?? 'غير متوفرة'}. ${r.recentDuplicate ? 'يوجد صرف مكرر حديث يتطلب المراجعة.' : 'لا يوجد صرف مكرر حديث.'}',
          ),
        ),
        const SizedBox(height: 16),
        _aiPanel(
          b('Programme overview', 'نظرة عامة على البرنامج'),
          b(
            '${jp.pendingRequests} cases require attention. Approval rate is ${(jp.approvalRate * 100).round()}%.',
            '${jp.pendingRequests} حالات تحتاج إلى متابعة. نسبة الموافقة ${(jp.approvalRate * 100).round()}٪. جميع المؤشرات مشتقة من بيانات العرض المحلية الحالية.',
          ),
        ),
        const SizedBox(height: 16),
        _naturalLanguageSearch(jp),
      ],
    );
  }

  Widget _naturalLanguageSearch(JourneyProvider jp) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b('Search treatment records', 'البحث في سجلات العلاج'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            b(
              'Search by pending, rejected, missing labs, or dispensed status.',
              'ابحث عن حالة معلقة أو مرفوضة أو تحاليل مفقودة أو صرف مكتمل.',
            ),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: b('Search treatment records', 'ابحث في سجلات العلاج'),
            ),
            onSubmitted: (_) => _runSearch(jp),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _runSearch(jp),
            icon: const Icon(Icons.auto_awesome),
            label: Text(b('Search local data', 'بحث في البيانات المحلية')),
          ),
          if (_searchResult.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _searchResult,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    ),
  );

  void _runSearch(JourneyProvider jp) {
    final q = _search.text.toLowerCase();
    setState(() {
      if (q.contains('reject') || q.contains('مرفوض')) {
        _searchResult = b(
          '${jp.rejectedRequests} rejected request(s) found.',
          'تم العثور على ${jp.rejectedRequests} طلبات مرفوضة.',
        );
      } else if (q.contains('pending') ||
          q.contains('review') ||
          q.contains('معلق') ||
          q.contains('مراجع')) {
        _searchResult = b(
          '${jp.pendingRequests} request(s) are waiting for action.',
          'يوجد ${jp.pendingRequests} طلبات بانتظار الإجراء.',
        );
      } else if (q.contains('missing') ||
          q.contains('crp') ||
          q.contains('esr') ||
          q.contains('مفقود')) {
        final missing = jp.request.criteria
            .where((c) => c.result == CriterionResult.missing)
            .length;
        _searchResult = b(
          '$missing missing evidence item(s) in the selected case.',
          'يوجد $missing عناصر أدلة مفقودة في الحالة المحددة.',
        );
      } else if (q.contains('dispens') || q.contains('صرف')) {
        _searchResult = b(
          '${jp.dispensedRequests} locally recorded dispensed request(s).',
          'يوجد ${jp.dispensedRequests} طلبات مصروفة مسجلة محليًا.',
        );
      } else {
        _searchResult = b(
          'Intent not recognized. Use pending, rejected, missing labs, or dispensed.',
          'لم يتم التعرف على السؤال. استخدم: معلق، مرفوض، تحاليل مفقودة، أو تم الصرف.',
        );
      }
    });
  }

  Widget _patientHeader(DemoTreatmentRequest r) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              (_ar ? r.patientNameAr : r.patientNameEn).substring(0, 1),
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ar ? r.patientNameAr : r.patientNameEn,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${r.mrn} • ${r.age} • ${_ar ? r.genderAr : r.genderEn}'),
                Text(
                  _ar ? r.hospitalAr : r.hospitalEn,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _statusChip(r.status),
        ],
      ),
    ),
  );

  Widget _history(DemoTreatmentRequest r) =>
      _simplePage(b('Relevant Medical History', 'التاريخ الطبي المرتبط'), [
        _row(b('Condition', 'الحالة'), _ar ? r.diagnosisAr : r.diagnosisEn),
        _row(
          b('Previous treatment', 'العلاج السابق'),
          _ar ? r.previousTreatmentAr : r.previousTreatmentEn,
        ),
        _row(
          b('Current treatment', 'العلاج الحالي'),
          _ar ? r.currentMedicationAr : r.currentMedicationEn,
        ),
      ]);

  Widget _diagnoses(DemoTreatmentRequest r) =>
      _simplePage(b('Diagnoses', 'التشخيصات'), [
        _row(
          b('Primary diagnosis', 'التشخيص الأساسي'),
          _ar ? r.diagnosisAr : r.diagnosisEn,
        ),
        _row(
          b('Treatment indication', 'دواعي العلاج'),
          _ar ? r.indicationAr : r.indicationEn,
        ),
      ]);
  Widget _labs(
    DemoTreatmentRequest r,
  ) => _simplePage(b('Laboratory Evidence', 'الأدلة المخبرية'), [
    _row('CRP', r.crp == null ? b('Missing', 'غير متوفر') : '${r.crp} mg/L'),
    _row('ESR', r.esr == null ? b('Missing', 'غير متوفر') : '${r.esr} mm/hr'),
  ]);
  Widget _medications(DemoTreatmentRequest r) =>
      _simplePage(b('Medication History', 'سجل الأدوية'), [
        _row(
          b('Current', 'الحالي'),
          _ar ? r.currentMedicationAr : r.currentMedicationEn,
        ),
        _row(b('Requested', 'المطلوب'), '${r.medication} — ${r.dose}'),
        _row(
          b('Duplicate check', 'فحص التكرار'),
          r.recentDuplicate ? b('Warning', 'تحذير') : b('Passed', 'ناجح'),
        ),
      ]);
  Widget _attachments(DemoTreatmentRequest r) =>
      _simplePage(b('Supporting Attachments', 'المرفقات الداعمة'), [
        _row(
          b('Physician report', 'تقرير الطبيب'),
          r.physicianReportAttached
              ? b('Attached', 'مرفق')
              : b('Missing', 'غير مرفق'),
        ),
        _row(
          b('Laboratory report', 'تقرير المختبر'),
          r.esr != null ? b('Attached', 'مرفق') : b('Incomplete', 'غير مكتمل'),
        ),
      ]);

  Widget _requestWorkspace(JourneyProvider jp) {
    final r = jp.request;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _patientHeader(r),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b('Treatment Request ${r.id}', 'طلب العلاج ${r.id}'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _row(
                  b('Diagnosis', 'التشخيص'),
                  _ar ? r.diagnosisAr : r.diagnosisEn,
                ),
                _row(b('Medication', 'الدواء'), '${r.medication} — ${r.dose}'),
                _row(
                  b('Previous therapy', 'العلاج السابق'),
                  _ar ? r.previousTreatmentAr : r.previousTreatmentEn,
                ),
                _row(
                  b('Priority', 'الأولوية'),
                  r.urgent ? b('URGENT', 'عاجل') : b('Routine', 'عادي'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _eligibility(r),
        const SizedBox(height: 12),
        _decisionSupport(r),
        const SizedBox(height: 12),
        _actions(jp),
      ],
    );
  }

  Widget _eligibility(DemoTreatmentRequest r) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b('Eligibility Assessment', 'تقييم الأهلية'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...r.criteria.map(
            (c) => ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Icon(
                _criterionIcon(c.result),
                color: _criterionColor(c.result),
              ),
              title: Text(
                _ar ? c.labelAr : c.labelEn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_ar ? c.evidenceAr : c.evidenceEn),
              trailing: _criterionChip(c.result),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_ar ? c.explanationAr : c.explanationEn),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _decisionSupport(DemoTreatmentRequest r) => _aiPanel(
    b('AI Clinical Decision Support', 'دعم القرار السريري بالذكاء الاصطناعي'),
    '${b('Recommendation', 'التوصية')}: ${_recommendation(r.aiRecommendation)}\n\n${b('Why?', 'لماذا؟')} ${_reason(r)}\n\n${b('Suggested next action', 'الإجراء المقترح')}: ${_nextAction(r)}',
  );

  String _reason(DemoTreatmentRequest r) {
    final passed = r.criteria
        .where((c) => c.result == CriterionResult.pass)
        .length;
    final missing = r.criteria
        .where((c) => c.result == CriterionResult.missing)
        .length;
    final warnings = r.criteria
        .where((c) => c.result == CriterionResult.warning)
        .length;
    return b(
      '$passed criteria passed; $missing missing and $warnings warning(s). Exact evidence is shown above.',
      'نجح $passed معايير؛ يوجد $missing مفقود و$warnings تحذير. الأدلة التفصيلية موضحة أعلاه.',
    );
  }

  String _nextAction(DemoTreatmentRequest r) => switch (r.aiRecommendation) {
    AiRecommendation.approve => b(
      'Authorized reviewer should verify evidence and decide.',
      'على المراجع المخول التحقق من الأدلة واتخاذ القرار.',
    ),
    AiRecommendation.review => b(
      'Review the warning before a human decision.',
      'مراجعة التحذير قبل اتخاذ القرار البشري.',
    ),
    AiRecommendation.moreInformation => b(
      'Obtain the missing evidence and resubmit.',
      'استكمال الأدلة المفقودة وإعادة الإرسال.',
    ),
  };

  Widget _actions(JourneyProvider jp) {
    final r = jp.request;
    final actions = <Widget>[];
    void add(String label, IconData icon, VoidCallback onTap, {Color? color}) =>
        actions.add(
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
            style: color == null
                ? null
                : ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
          ),
        );
    if (r.status == RequestStatus.draft &&
        jp.can(AppPermission.createTreatmentRequest)) {
      add(
        b('Submit request', 'إرسال الطلب'),
        Icons.send,
        () => _show(jp.submit()),
      );
    }
    if (r.status == RequestStatus.needsInformation &&
        jp.can(AppPermission.editLabResults)) {
      add(
        b('Complete missing information', 'استكمال المعلومات الناقصة'),
        Icons.science_outlined,
        () => _missingLabsDialog(jp),
        color: AppColors.warning,
      );
    }
    if (r.status == RequestStatus.submitted &&
        jp.can(AppPermission.reviewEligibility)) {
      add(
        b('Run eligibility assessment', 'تشغيل تقييم الأهلية'),
        Icons.rule,
        () => _show(jp.evaluate()),
      );
    }
    if (r.status == RequestStatus.underReview &&
        jp.can(AppPermission.approveTreatment)) {
      add(
        b('Approve', 'موافقة'),
        Icons.check,
        () => _reviewDialog(jp, ReviewDecision.approve),
        color: AppColors.success,
      );
      add(
        b('Reject', 'رفض'),
        Icons.close,
        () => _reviewDialog(jp, ReviewDecision.reject),
        color: AppColors.error,
      );
      add(
        b('Request information', 'طلب معلومات'),
        Icons.help_outline,
        () => _reviewDialog(jp, ReviewDecision.moreInformation),
        color: AppColors.warning,
      );
    }
    if (r.status == RequestStatus.approved &&
        jp.can(AppPermission.sendToPharmacy)) {
      add(
        b('Send to pharmacy', 'إرسال للصيدلية'),
        Icons.local_pharmacy,
        () => _show(jp.markReadyForDispensing()),
      );
    }
    if (r.status == RequestStatus.readyToDispense &&
        jp.can(AppPermission.dispenseMedication)) {
      add(
        b('Verify & dispense', 'التحقق والصرف'),
        Icons.medication,
        () => _dispenseDialog(jp),
        color: AppColors.primary,
      );
    }
    if (r.status == RequestStatus.dispensed &&
        jp.can(AppPermission.startFollowUp)) {
      add(
        b('Start monitoring', 'بدء المتابعة'),
        Icons.monitor_heart,
        () => _show(jp.startMonitoring()),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b('Human action', 'الإجراء البشري'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              b(
                'AI provides decision support. Final clinical/authorization decision remains with the authorized human reviewer.',
                'يوفر الذكاء الاصطناعي دعمًا للقرار. يظل القرار السريري وقرار التفويض النهائي مسؤولية المراجع البشري المخول.',
              ),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (actions.isEmpty)
              Text(
                b(
                  'No action is available for this state.',
                  'لا يوجد إجراء متاح لهذه الحالة.',
                ),
              )
            else
              Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewDialog(
    JourneyProvider jp,
    ReviewDecision decision,
  ) async {
    final c = TextEditingController();
    final needsReason =
        decision != ReviewDecision.approve ||
        jp.request.aiRecommendation != AiRecommendation.approve;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(b('Human review decision', 'قرار المراجعة البشرية')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              needsReason
                  ? b(
                      'A reason is required for this decision.',
                      'يلزم توضيح سبب هذا القرار.',
                    )
                  : b(
                      'Add a note for the clinical audit trail if needed.',
                      'يمكن إضافة ملاحظة إلى سجل المراجعة السريرية.',
                    ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: b(
                  'Decision / override reason',
                  'سبب القرار أو مخالفة التوصية',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(b('Cancel', 'إلغاء')),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: c,
            builder: (context, value, _) => ElevatedButton(
              onPressed: needsReason && value.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, value.text),
              child: Text(b('Confirm', 'تأكيد')),
            ),
          ),
        ],
      ),
    );
    if (reason != null && mounted) _show(jp.review(decision, reason: reason));
  }

  Future<void> _missingLabsDialog(JourneyProvider jp) async {
    final crp = TextEditingController();
    final esr = TextEditingController();
    final source = TextEditingController(
      text: b('Central laboratory', 'المختبر المركزي'),
    );
    final report = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          b(
            'Complete missing laboratory results',
            'استكمال نتائج المختبر الناقصة',
          ),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                b(
                  'CRP and ESR are required to continue eligibility evaluation.',
                  'يلزم إدخال CRP وESR لاستكمال تقييم الأهلية.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: crp,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'CRP (mg/L)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: esr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'ESR (mm/hr)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: source,
                decoration: InputDecoration(
                  labelText: b('Laboratory source', 'مصدر المختبر'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: report,
                decoration: InputDecoration(
                  labelText: b(
                    'Physician report reference / file name',
                    'مرجع تقرير الطبيب / اسم الملف',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${b('Collection date', 'تاريخ جمع العينة')}: ${DateTime.now().toIso8601String().split('T').first}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(b('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(b('Save and re-evaluate', 'حفظ وإعادة التقييم')),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final crpValue = double.tryParse(crp.text.trim());
    final esrValue = double.tryParse(esr.text.trim());
    if (crpValue == null || esrValue == null) {
      _show(
        const TransitionResult(
          false,
          'Enter valid numeric CRP and ESR values.',
        ),
      );
      return;
    }
    _show(
      jp.completeMissingLaboratoryInformation(
        crp: crpValue,
        esr: esrValue,
        collectedAt: DateTime.now(),
        source: source.text.trim(),
        physicianReportReference: report.text.trim(),
      ),
    );
  }

  Future<void> _dispenseDialog(JourneyProvider jp) async {
    final issues = jp.pharmacySafetyIssues();
    final c = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          b(
            'AI Pharmacy Safety Assistant',
            'مساعد سلامة الصيدلية بالذكاء الاصطناعي',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _demoBadge(),
            const SizedBox(height: 12),
            Text(
              issues.isEmpty
                  ? b(
                      'All deterministic safety checks passed.',
                      'اجتازت الحالة جميع فحوصات السلامة المحلية.',
                    )
                  : issues.join('\n'),
            ),
            if (issues.isNotEmpty)
              TextField(
                controller: c,
                decoration: InputDecoration(
                  labelText: b(
                    'Authorized override reason',
                    'سبب التجاوز المخول',
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(b('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(b('Dispense', 'صرف')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _show(jp.dispense(overrideReason: c.text));
    }
  }

  void _show(TransitionResult result) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );

  Widget _timeline(DemoTreatmentRequest r) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      _aiPanel(
        b(
          'AI Treatment Monitoring Assistant',
          'مساعد متابعة العلاج بالذكاء الاصطناعي',
        ),
        r.status.index >= RequestStatus.monitoring.index
            ? b(
                '${r.adherencePercent}% adherence. ${r.monitoringObservationEn} Suggested action: complete follow-up on ${_date(r.followUpAt)}.',
                'نسبة الالتزام ${r.adherencePercent}٪. ${r.monitoringObservationAr} الإجراء المقترح: إتمام المتابعة بتاريخ ${_date(r.followUpAt)}.',
              )
            : b(
                'Monitoring insights become available after dispensing.',
                'تظهر رؤى المتابعة بعد صرف الدواء.',
              ),
      ),
      const SizedBox(height: 12),
      ...r.audit.map(
        (e) => Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(e.action),
            subtitle: Text(
              '${e.actor} • ${e.role}${e.reason.isEmpty ? '' : '\n${e.reason}'}',
            ),
            trailing: Text(_date(e.timestamp)),
          ),
        ),
      ),
    ],
  );

  Widget _audit(DemoTreatmentRequest r) => ListView(
    padding: const EdgeInsets.all(20),
    children: r.audit
        .map(
          (e) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.action,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${b('Actor', 'المنفذ')}: ${e.actor} (${e.role})'),
                  Text(
                    '${b('State', 'الحالة')}: ${e.previousState == null ? '—' : _status(e.previousState!)} → ${_status(e.newState)}',
                  ),
                  Text('${b('Time', 'الوقت')}: ${_date(e.timestamp)}'),
                  if (e.reason.isNotEmpty)
                    Text('${b('Reason', 'السبب')}: ${e.reason}'),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );

  Widget _simplePage(String title, List<Widget> children) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    ],
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 190,
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  Widget _metric(String label, String value, IconData icon) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _aiPanel(String title, String body) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _demoBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(color: Colors.white, height: 1.5)),
        const SizedBox(height: 12),
        Text(
          b(
            'Supporting information only • Human review required',
            'معلومات داعمة فقط • المراجعة البشرية مطلوبة',
          ),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _statusChip(RequestStatus s) => Chip(
    label: Text(_status(s)),
    backgroundColor: s == RequestStatus.rejected
        ? AppColors.error.withValues(alpha: .15)
        : AppColors.primary.withValues(alpha: .12),
  );
  Widget _criterionChip(CriterionResult r) => Chip(
    label: Text(
      _criterionName(r),
      style: TextStyle(
        color: _criterionColor(r),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: _criterionColor(r).withValues(alpha: .12),
  );
  IconData _criterionIcon(CriterionResult r) => switch (r) {
    CriterionResult.pass => Icons.check_circle,
    CriterionResult.fail => Icons.cancel,
    CriterionResult.missing => Icons.help,
    CriterionResult.warning => Icons.warning,
    CriterionResult.notApplicable => Icons.remove_circle,
  };
  Color _criterionColor(CriterionResult r) => switch (r) {
    CriterionResult.pass => AppColors.success,
    CriterionResult.fail => AppColors.error,
    CriterionResult.missing => AppColors.warning,
    CriterionResult.warning => Colors.orange,
    CriterionResult.notApplicable => AppColors.textSecondary,
  };
  String _criterionName(CriterionResult r) => switch (r) {
    CriterionResult.pass => b('PASS', 'ناجح'),
    CriterionResult.fail => b('FAIL', 'فشل'),
    CriterionResult.missing => b('MISSING', 'مفقود'),
    CriterionResult.warning => b('WARNING', 'تحذير'),
    CriterionResult.notApplicable => b('N/A', 'لا ينطبق'),
  };
  String _recommendation(AiRecommendation r) => switch (r) {
    AiRecommendation.approve => b('RECOMMEND APPROVAL', 'يوصي بالموافقة'),
    AiRecommendation.review => b('REVIEW REQUIRED', 'المراجعة مطلوبة'),
    AiRecommendation.moreInformation => b(
      'MORE INFORMATION',
      'معلومات إضافية مطلوبة',
    ),
  };
  String _status(RequestStatus s) => switch (s) {
    RequestStatus.draft => b('Draft', 'مسودة'),
    RequestStatus.submitted => b('Submitted', 'مرسل'),
    RequestStatus.assessing => b('Assessing', 'قيد التقييم'),
    RequestStatus.needsInformation => b('Needs information', 'يحتاج معلومات'),
    RequestStatus.underReview => b('Under review', 'قيد المراجعة'),
    RequestStatus.approved => b('Approved', 'موافق عليه'),
    RequestStatus.rejected => b('Rejected', 'مرفوض'),
    RequestStatus.readyToDispense => b('Ready to dispense', 'جاهز للصرف'),
    RequestStatus.dispensed => b('Dispensed', 'تم الصرف'),
    RequestStatus.monitoring => b('Monitoring', 'متابعة'),
    RequestStatus.renewalDue => b('Renewal due', 'التجديد مستحق'),
    RequestStatus.completed => b('Completed', 'مكتمل'),
    RequestStatus.expired => b('Expired', 'منتهي الصلاحية'),
    RequestStatus.cancelled => b('Cancelled', 'ملغي'),
  };
  String _date(DateTime? d) => d == null
      ? '—'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
