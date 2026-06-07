import 'package:flutter/material.dart';

import '../../../core/constants/demo_metrics.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/localization/l10n_extension.dart';
import '../program_alerts.dart';

enum _EntityKind { patient, center, doctor }

enum _QueryEntityKind { patient, center, doctor, unknown }

class _EntityMatch<T> {
  final T entity;
  final _EntityKind kind;
  final int score;

  const _EntityMatch(this.entity, this.kind, this.score);
}

/// Data-driven assistant for the national alerts command center (demo / MOH presentation).
class AlertOsAiAssistant {
  AlertOsAiAssistant._();

  static String reply(BuildContext context, DataProvider dp, String rawQuery) {
    final isAr = context.isArabic;
    final q = _normalize(rawQuery);

    if (q.isEmpty) {
      return isAr
          ? 'اكتب سؤالك أو اختر أحد الاقتراحات أدناه.'
          : 'Type a question or pick a suggestion below.';
    }

    if (_matches(q, ['مساعدة', 'help', 'ماذا', 'what can', 'سيناريو', 'capabilities', 'أمثلة', 'examples'])) {
      return _help(isAr, dp, context);
    }
    if (_matches(q, ['تجميد', 'freeze'])) {
      return context.tr('ai_action_freeze');
    }

    final operational = _tryOperationalReply(context, dp, q, isAr);
    if (operational != null) return operational;

    final entityReply = _tryEntityReply(context, dp, rawQuery, q, isAr);
    if (entityReply != null) return entityReply;

    return isAr
        ? 'لم أتعرف على الطلب. اكتب مباشرة:\n'
            '• اسم مستفيد: «أحمد المنصوري» أو «سارة يوسف»\n'
            '• اسم مستشفى: «مستشفى دبي المركزي» أو «مدينة أبوظبي الطبية»\n'
            '• اسم طبيب: «د. أحمد المنصوري»\n'
            '• أو: «ملخص البرنامج» | «التنبيهات» | «مساعدة»'
        : 'I could not match that request. Type directly:\n'
            '• Beneficiary: "Ahmed Al Mansoori" or "Sarah Yousef"\n'
            '• Hospital: "Dubai Central Hospital"\n'
            '• Physician: "Dr. Ahmed Al Mansoori"\n'
            '• Or: "Program summary" | "Alerts" | "Help"';
  }

  static List<String> suggestionPrompts(BuildContext context) {
    final isAr = context.isArabic;
    if (isAr) {
      return [
        'ملخص البرنامج الوطني',
        'التنبيهات النشطة',
        'المستفيدون الجاهزون للصرف',
        'مخزون المنشآت',
        'تفاصيل المريض P001',
        'قائمة الأطباء',
        'سجل الاحتيال',
        'معلومات مونجارو',
      ];
    }
    return [
      'National program summary',
      'Active alerts',
      'Ready to dispense',
      'Facility inventory',
      'Patient P001 details',
      'List of doctors',
      'Fraud log',
      'Mounjaro medication info',
    ];
  }

  static String? _tryOperationalReply(
    BuildContext context,
    DataProvider dp,
    String q,
    bool isAr,
  ) {
    final patientId = _extractPatientId(q);
    if (patientId != null) {
      final patient = _findPatientById(dp, patientId);
      if (patient != null) return _patientDetail(context, dp, patient, isAr);
    }

    if (_matches(q, ['ملخص', 'summary', 'overview', 'تقرير', 'report', 'dashboard', 'لوحة'])) {
      return _programSummary(context, dp, isAr);
    }

    if (_matches(q, ['تنبيه', 'alert', 'notification', 'تنبيهات'])) {
      return _alertsSummary(context, dp, isAr);
    }

    if (_matches(q, ['احتيال', 'fraud', 'misuse', 'override', 'flagged', 'إساءة']) ||
        (_matches(q, ['سجل', 'log']) && _matches(q, ['احتيال', 'fraud', 'override', 'إساءة']))) {
      return _fraudSummary(context, dp, isAr);
    }

    if (_matches(q, ['صرف', 'dispens', 'جاهز', 'ready']) &&
        (_matches(q, ['مستفيد', 'beneficiar', 'patient', 'dispense']) || q.contains('للصرف'))) {
      return _dispensingSummary(context, dp, isAr);
    }

    if (_matches(q, ['مخزون', 'inventory', 'stock', 'إمداد', 'supply', 'منشآت', 'centers', 'facilities', 'نقص', 'مغزون', 'مغزى'])) {
      final stripped = _stripFillers(q);
      if (stripped.isNotEmpty && !_isOperationalOnly(stripped)) {
        final centerMatches = _rankCenters(dp, stripped);
        if (centerMatches.isNotEmpty && centerMatches.first.score >= 70) {
          return _centerDetail(context, centerMatches.first.entity, isAr);
        }
      }
      return _inventorySummary(context, dp, isAr);
    }

    if (_matches(q, ['قائمة', 'list']) && _matches(q, ['طبيب', 'doctor', 'أطباء', 'physician'])) {
      return _doctorsSummary(context, dp, isAr);
    }
    if (_matches(q, ['طبيب', 'doctor', 'physician', 'أطباء', 'doctors']) && !_looksLikeNameOnlyQuery(q)) {
      return _doctorsSummary(context, dp, isAr);
    }

    if (_matches(q, ['قائمة', 'list', 'كل المستفيد', 'all patient', 'المستفيدون', 'beneficiaries']) &&
        !_looksLikeNameOnlyQuery(q)) {
      return _patientsSummary(context, dp, isAr);
    }

    if (_matches(q, ['مونجارو', 'mounjaro', 'tirzepatide', 'تيرزيباتيد', 'دواء', 'medication', 'drug', 'جرعة', 'dose']) ||
        (_matches(q, ['معلومات', 'info', 'information']) && _matches(q, ['مونجارو', 'mounjaro', 'medication', 'دواء']))) {
      return _medicationInfo(context, dp, q, isAr);
    }

    if (_matches(q, ['اعتماد', 'review', 'pending', 'مراجعة', 'موافقة', 'authorization'])) {
      return _pendingReviews(context, dp, isAr);
    }

    if (_matches(q, ['برنامج', 'program', 'national', 'وطني', 'moh', 'وزارة', 'إحصاء', 'statistics', 'kpi']) &&
        !_matches(q, ['ملخص', 'summary', 'overview', 'تقرير', 'report'])) {
      return _nationalKpis(isAr);
    }

    if (_matches(q, ['سجل', 'log', 'audit', 'activity', 'نشاط', 'events']) &&
        !_matches(q, ['احتيال', 'fraud'])) {
      return _recentLogs(context, dp, isAr);
    }

    if (_matches(q, ['علاج طبيعي', 'therapy', 'rehab', 'تأهيل'])) {
      return _therapySummary(context, dp, isAr);
    }

    if ((_matches(q, ['إمارة', 'emirate']) ||
            _matches(q, ['دبي', 'dubai', 'abu dhabi', 'sharjah', 'أبوظبي', 'الشارقة', 'عجمان', 'العين', 'fujairah', 'ras al'])) &&
        !_looksLikeNameOnlyQuery(q)) {
      return _emirateBreakdown(context, dp, q, isAr);
    }

    if (_matches(q, ['عدم التزام', 'compliance', 'non compliance', 'متأخر'])) {
      return _nonCompliance(context, dp, isAr);
    }

    return null;
  }

  static String? _extractPatientId(String q) {
    final match = RegExp(r'p0?\d{2,3}').firstMatch(q.replaceAll(' ', ''));
    if (match == null) return null;
    final raw = match.group(0)!.toUpperCase();
    final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
    if (digits == null) return null;
    return 'P${digits.padLeft(3, '0')}';
  }

  static Patient? _findPatientById(DataProvider dp, String id) {
    for (final p in dp.patients) {
      if (p.id.toUpperCase() == id) return p;
    }
    return null;
  }

  static bool _isOperationalOnly(String stripped) {
    return _meaningfulTokens(stripped).isEmpty;
  }

  static const _stopWords = {
    'ملخص', 'summary', 'overview', 'report', 'dashboard', 'تقرير', 'لوحة',
    'برنامج', 'program', 'national', 'وطني', 'operational', 'تشغيل',
    'تنبيه', 'alert', 'notification', 'تنبيهات', 'نشطة', 'active', 'alerts',
    'مخزون', 'inventory', 'stock', 'supply', 'imdad', 'إمداد', 'منشآت', 'facilities', 'centers',
    'مستفيد', 'beneficiary', 'beneficiaries', 'patient', 'مريض', 'المستفيدون',
    'جاهز', 'ready', 'dispense', 'dispensing', 'صرف', 'للصرف',
    'قائمة', 'list', 'doctors', 'doctor', 'physician', 'أطباء', 'طبيب',
    'احتيال', 'fraud', 'misuse', 'override', 'flagged', 'إساءة',
    'سجل', 'log', 'audit', 'activity', 'نشاط', 'events',
    'معلومات', 'info', 'information', 'medication', 'drug', 'dose', 'جرعة', 'دواء',
    'مونجارو', 'mounjaro', 'tirzepatide', 'تيرزيباتيد',
    'تفاصيل', 'details', 'profile', 'ملف', 'بيانات', 'حالة',
    'اعتماد', 'review', 'pending', 'مراجعة', 'موافقة', 'authorization',
    'إحصاء', 'statistics', 'kpi', 'moh', 'وزارة',
    'علاج', 'therapy', 'rehab', 'تأهيل', 'طبيعي',
    'عدم', 'compliance', 'التزام', 'متأخر',
    'ال', 'في', 'من', 'على', 'و', 'the', 'of', 'for', 'to', 'and', 'or',
  };

  static List<String> _meaningfulTokens(String text) {
    return _normalizeArabic(text)
        .split(' ')
        .where((t) => t.length >= 2 && !_stopWords.contains(t))
        .toList();
  }

  static String _normalize(String raw) => _normalizeArabic(raw.trim().toLowerCase());

  static String _normalizeArabic(String s) {
    var t = s.toLowerCase();
    t = t.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ؤ', 'و').replaceAll('ئ', 'ي');
    t = t.replaceAll('ة', 'ه').replaceAll('ى', 'ي').replaceAll('ـ', '');
    t = t.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    return t;
  }

  static String _stripFillers(String q) {
    const fillers = [
      'مريض', 'المريض', 'مستفيد', 'المستفيد', 'تفاصيل', 'بيانات', 'ملف', 'حالة',
      'من فضلك', 'لو سمحت', 'عايز', 'عاوز', 'ابغى', 'أريد', 'اريد', 'وريني', 'اعرض',
      'مخزون', 'مغزون', 'مغزى', 'stock', 'inventory', 'supply',
      'مستشفى', 'المستشفى', 'مركز', 'المركز', 'منشأة', 'المنشأة', 'صيدلية',
      'طبيب', 'الطبيب', 'دكتور', 'الدكتور', 'د.', 'dr.', 'dr',
      'patient', 'beneficiary', 'details', 'profile', 'show', 'about', 'info',
      'center', 'facility', 'hospital', 'doctor', 'physician',
      'ما هو', 'ما هي', 'مين', 'من هو', 'who is', 'tell me about',
    ];
    var t = q;
    for (final f in fillers) {
      t = t.replaceAll(_normalizeArabic(f), ' ');
    }
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _matches(String q, List<String> tokens) =>
      tokens.any((t) => q.contains(_normalizeArabic(t)));

  static bool _looksLikeNameOnlyQuery(String q) {
    final stripped = _stripFillers(q);
    final tokens = _meaningfulTokens(stripped.isNotEmpty ? stripped : q);
    if (tokens.isEmpty) return false;
    return tokens.length <= 5 && !_matchesOperationalKeywords(q);
  }

  static bool _matchesOperationalKeywords(String q) {
    if (_extractPatientId(q) != null &&
        _matches(q, ['تفاصيل', 'details', 'profile', 'ملف', 'مريض', 'patient', 'مستفيد', 'beneficiary'])) {
      return true;
    }
    return _matches(q, ['ملخص', 'summary', 'overview', 'تقرير', 'report', 'dashboard', 'لوحة']) ||
        _matches(q, ['تنبيه', 'alert', 'notification', 'تنبيهات', 'نشطة', 'active', 'alerts']) ||
        _matches(q, ['احتيال', 'fraud', 'misuse', 'override', 'flagged', 'إساءة']) ||
        (_matches(q, ['سجل', 'log']) && _matches(q, ['احتيال', 'fraud', 'override', 'إساءة'])) ||
        (_matches(q, ['صرف', 'dispens', 'جاهز', 'ready']) &&
            (_matches(q, ['مستفيد', 'beneficiar', 'patient', 'dispense']) || q.contains('للصرف'))) ||
        _matches(q, ['مخزون', 'inventory', 'stock', 'إمداد', 'supply', 'منشات', 'centers', 'facilities', 'نقص', 'مغزون', 'مغزى']) ||
        (_matches(q, ['قائمة', 'list']) && _matches(q, ['طبيب', 'doctor', 'أطباء', 'physician'])) ||
        (_matches(q, ['طبيب', 'doctor', 'physician', 'أطباء', 'doctors']) && !_looksLikePersonNameQuery(q)) ||
        (_matches(q, ['قائمة', 'list', 'كل المستفيد', 'all patient', 'المستفيدون', 'beneficiaries']) &&
            !_looksLikePersonNameQuery(q)) ||
        _matches(q, ['مونجارو', 'mounjaro', 'tirzepatide', 'تيرزيباتيد', 'دواء', 'medication', 'drug', 'جرعة', 'dose']) ||
        (_matches(q, ['معلومات', 'info', 'information']) && _matches(q, ['مونجارو', 'mounjaro', 'medication', 'دواء'])) ||
        _matches(q, ['اعتماد', 'review', 'pending', 'مراجعة', 'موافقة', 'authorization']) ||
        (_matches(q, ['برنامج', 'program', 'national', 'وطني', 'moh', 'وزارة', 'إحصاء', 'statistics', 'kpi']) &&
            !_matches(q, ['ملخص', 'summary', 'overview', 'تقرير', 'report'])) ||
        (_matches(q, ['سجل', 'log', 'audit', 'activity', 'نشاط', 'events']) && !_matches(q, ['احتيال', 'fraud'])) ||
        _matches(q, ['علاج طبيعي', 'therapy', 'rehab', 'تأهيل']) ||
        _matches(q, ['عدم التزام', 'compliance', 'non compliance', 'متأخر']);
  }

  static bool _looksLikePersonNameQuery(String q) {
    final stripped = _stripFillers(q);
    final tokens = _meaningfulTokens(stripped.isNotEmpty ? stripped : q);
    return tokens.isNotEmpty && tokens.length <= 4;
  }

  static _QueryEntityKind _inferEntityKind(String q) {
    if (_extractPatientId(q) != null ||
        _matches(q, ['مريض', 'مستفيد', 'patient', 'beneficiary'])) {
      return _QueryEntityKind.patient;
    }
    if (_matches(q, [
      'مستشفى', 'عيادة', 'مركز', 'مدينة', 'منشأة', 'منشات',
      'hospital', 'clinic', 'center', 'facility', 'medical city', 'صيدلية',
    ])) {
      return _QueryEntityKind.center;
    }
    if (_matches(q, ['طبيب', 'دكتور', 'doctor', 'physician', 'dr', 'د.'])) {
      return _QueryEntityKind.doctor;
    }
    return _QueryEntityKind.unknown;
  }

  static DispensingCenter? _findExactCenter(DataProvider dp, String search) {
    final s = _normalizeArabic(search);
    if (s.length < 4) return null;

    DispensingCenter? bestPartial;
    var bestPartialLen = 0;

    for (final c in dp.centers) {
      final names = [_normalizeArabic(c.name), _normalizeArabic(c.nameAr)];
      for (final name in names) {
        if (name.isEmpty) continue;
        if (s == name) return c;
        if (name.contains(s) && s.length >= 8) return c;
        if (s.contains(name) && name.length >= 8) return c;
        if (name.contains(s) && s.length > bestPartialLen) {
          bestPartial = c;
          bestPartialLen = s.length;
        }
      }
    }
    return bestPartialLen >= 10 ? bestPartial : null;
  }

  static Patient? _findExactPatient(DataProvider dp, String search) {
    final s = _normalizeArabic(search);
    if (s.length < 4) return null;
    for (final p in dp.patients) {
      final names = [_normalizeArabic(p.fullName), _normalizeArabic(p.fullNameAr)];
      for (final name in names) {
        if (name.isEmpty) continue;
        if (s == name) return p;
        if (name.contains(s) && s.length >= 6) return p;
      }
    }
    return null;
  }

  static Doctor? _findExactDoctor(DataProvider dp, String search) {
    final s = _normalizeArabic(search);
    if (s.length < 4) return null;
    for (final d in dp.doctors) {
      final names = [_normalizeArabic(d.name), _normalizeArabic(d.nameAr)];
      for (final name in names) {
        if (name.isEmpty) continue;
        if (s == name) return d;
        if (name.contains(s) && s.length >= 6) return d;
      }
    }
    return null;
  }

  static String? _tryEntityReply(
    BuildContext context,
    DataProvider dp,
    String rawQuery,
    String q,
    bool isAr,
  ) {
    if (_matchesOperationalKeywords(q)) return null;

    final stripped = _stripFillers(q);
    final search = stripped.isNotEmpty ? stripped : q;
    final tokens = _meaningfulTokens(search);
    if (tokens.isEmpty) return null;

    const minScore = 72;
    final kind = _inferEntityKind(q);

    final exactPatient = kind != _QueryEntityKind.center ? _findExactPatient(dp, search) : null;
    if (exactPatient != null) return _patientDetail(context, dp, exactPatient, isAr);

    final exactCenter = kind != _QueryEntityKind.patient ? _findExactCenter(dp, search) : null;
    if (exactCenter != null) return _centerDetail(context, exactCenter, isAr);

    final exactDoctor = kind != _QueryEntityKind.center ? _findExactDoctor(dp, search) : null;
    if (exactDoctor != null) return _doctorDetail(context, dp, exactDoctor, isAr);

    final rankPatients = kind == _QueryEntityKind.patient || kind == _QueryEntityKind.unknown;
    final rankCenters = kind == _QueryEntityKind.center || kind == _QueryEntityKind.unknown;
    final rankDoctors = kind == _QueryEntityKind.doctor || kind == _QueryEntityKind.unknown;

    final patientMatches = rankPatients ? _rankPatients(dp, search) : <({Patient entity, int score})>[];
    final centerMatches = rankCenters ? _rankCenters(dp, search) : <({DispensingCenter entity, int score})>[];
    final doctorMatches = rankDoctors ? _rankDoctors(dp, search) : <({Doctor entity, int score})>[];

    final bestPatient = patientMatches.isNotEmpty ? patientMatches.first : null;
    final bestCenter = centerMatches.isNotEmpty ? centerMatches.first : null;
    final bestDoctor = doctorMatches.isNotEmpty ? doctorMatches.first : null;

    if (kind == _QueryEntityKind.center && bestCenter != null && bestCenter.score >= minScore) {
      final runnerUp = centerMatches.length > 1 ? centerMatches[1].score : 0;
      if (bestCenter.score >= 80 || bestCenter.score - runnerUp >= 10) {
        return _centerDetail(context, bestCenter.entity, isAr);
      }
    }

    if (kind == _QueryEntityKind.patient && bestPatient != null && bestPatient.score >= minScore) {
      return _patientDetail(context, dp, bestPatient.entity, isAr);
    }

    if (kind == _QueryEntityKind.doctor && bestDoctor != null && bestDoctor.score >= minScore) {
      return _doctorDetail(context, dp, bestDoctor.entity, isAr);
    }

    final candidates = <_EntityMatch<dynamic>>[];
    if (bestPatient != null && bestPatient.score >= minScore) {
      candidates.add(_EntityMatch(bestPatient.entity, _EntityKind.patient, bestPatient.score));
    }
    if (bestCenter != null && bestCenter.score >= minScore) {
      candidates.add(_EntityMatch(bestCenter.entity, _EntityKind.center, bestCenter.score));
    }
    if (bestDoctor != null && bestDoctor.score >= minScore) {
      candidates.add(_EntityMatch(bestDoctor.entity, _EntityKind.doctor, bestDoctor.score));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final top = candidates.first;

    if (top.score >= 80 && (candidates.length == 1 || top.score - candidates[1].score >= 12)) {
      switch (top.kind) {
        case _EntityKind.patient:
          return _patientDetail(context, dp, top.entity as Patient, isAr);
        case _EntityKind.center:
          return _centerDetail(context, top.entity as DispensingCenter, isAr);
        case _EntityKind.doctor:
          return _doctorDetail(context, dp, top.entity as Doctor, isAr);
      }
    }

    if (candidates.length > 1 && candidates[1].score >= top.score - 5) {
      return _disambiguation(context, patientMatches, centerMatches, doctorMatches, kind, minScore, isAr);
    }

    switch (top.kind) {
      case _EntityKind.patient:
        return _patientDetail(context, dp, top.entity as Patient, isAr);
      case _EntityKind.center:
        return _centerDetail(context, top.entity as DispensingCenter, isAr);
      case _EntityKind.doctor:
        return _doctorDetail(context, dp, top.entity as Doctor, isAr);
    }
  }

  static String _disambiguation(
    BuildContext context,
    List<({Patient entity, int score})> patients,
    List<({DispensingCenter entity, int score})> centers,
    List<({Doctor entity, int score})> doctors,
    _QueryEntityKind kind,
    int minScore,
    bool isAr,
  ) {
    final lines = <String>[];

    void addPatients() {
      for (final p in patients.where((e) => e.score >= minScore).take(4)) {
        lines.add('  • ${p.entity.getLocalizedFullName(context)} (${p.entity.id})');
      }
    }

    void addCenters() {
      for (final c in centers.where((e) => e.score >= minScore).take(4)) {
        lines.add('  • ${c.entity.getLocalizedName(context)} (${c.entity.id})');
      }
    }

    void addDoctors() {
      for (final d in doctors.where((e) => e.score >= minScore).take(3)) {
        lines.add('  • ${d.entity.getLocalizedName(context)} (${d.entity.id})');
      }
    }

    switch (kind) {
      case _QueryEntityKind.center:
        addCenters();
      case _QueryEntityKind.patient:
        addPatients();
      case _QueryEntityKind.doctor:
        addDoctors();
      case _QueryEntityKind.unknown:
        addCenters();
        addPatients();
        addDoctors();
    }

    if (lines.isEmpty) {
      return isAr
          ? 'لم أجد تطابقاً دقيقاً — اكتب الاسم كاملاً.'
          : 'No close match found — please type the full name.';
    }

    return isAr
        ? 'وجدت أكثر من نتيجة — حدّد الاسم كاملاً:\n${lines.join('\n')}'
        : 'Multiple matches — please use the full name:\n${lines.join('\n')}';
  }

  static List<({Patient entity, int score})> _rankPatients(DataProvider dp, String search) {
    final results = <({Patient entity, int score})>[];
    for (final p in dp.patients) {
      final score = _scoreNameMatch(
        search,
        [p.fullName, p.fullNameAr, p.id, p.emiratesId],
      );
      if (score > 0) results.add((entity: p, score: score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  static List<({DispensingCenter entity, int score})> _rankCenters(DataProvider dp, String search) {
    final results = <({DispensingCenter entity, int score})>[];
    final tokenCount = _meaningfulTokens(search).length;
    for (final c in dp.centers) {
      final fields = tokenCount >= 2
          ? [c.name, c.nameAr, c.id]
          : [c.name, c.nameAr, c.region, c.regionAr, c.id];
      var score = _scoreNameMatch(search, fields);
      if (score > 0) results.add((entity: c, score: score));
    }
    return results..sort((a, b) => b.score.compareTo(a.score));
  }

  static List<({Doctor entity, int score})> _rankDoctors(DataProvider dp, String search) {
    final results = <({Doctor entity, int score})>[];
    for (final d in dp.doctors) {
      final score = _scoreNameMatch(
        search,
        [d.name, d.nameAr, d.id, d.hospital, d.hospitalAr, d.specialty, d.specialtyAr],
      );
      if (score > 0) results.add((entity: d, score: score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  static int maxScore(int a, int b) => a > b ? a : b;

  static int _scoreNameMatch(String search, List<String> fields) {
    if (search.isEmpty) return 0;
    final s = _normalizeArabic(search);
    var best = 0;

    for (final field in fields) {
      final f = _normalizeArabic(field);
      if (f.isEmpty) continue;

      if (s == f) best = maxScore(best, 100);
      if (f.contains(s) && s.length >= 4) best = maxScore(best, 92);
      if (s.contains(f) && f.length >= 5) best = maxScore(best, 90);

      final searchTokens = _meaningfulTokens(search);
      final fieldTokens = f.split(' ').where((t) => t.length >= 2).toList();
      if (searchTokens.isEmpty) continue;

      var matched = 0;
      for (final st in searchTokens) {
        if (fieldTokens.any((ft) {
          if (ft == st) return true;
          if (st.length >= 4 && ft.length >= 4 && (ft.contains(st) || st.contains(ft))) return true;
          return false;
        })) {
          matched++;
        }
      }
      if (matched == searchTokens.length && searchTokens.length >= 2) {
        best = maxScore(best, 88);
      } else if (matched >= 2) {
        best = maxScore(best, 50 + matched * 12);
      } else if (matched == 1 && searchTokens.length == 1 && searchTokens.first.length >= 4) {
        best = maxScore(best, 60);
      }
    }

    final idMatch = RegExp(r'p0?\d{2,3}').firstMatch(s.replaceAll(' ', ''));
    if (idMatch != null) {
      for (final field in fields) {
        if (_normalizeArabic(field).contains(_normalizeArabic(idMatch.group(0)!))) {
          best = maxScore(best, 98);
        }
      }
    }

    return best;
  }

  static String _help(bool isAr, DataProvider dp, BuildContext context) {
    final samplePatient = dp.patients.isNotEmpty
        ? dp.patients.first.getLocalizedFullName(context)
        : (isAr ? 'أحمد المنصوري' : 'Ahmed Al Mansoori');
    final sampleCenter = dp.centers.isNotEmpty
        ? dp.centers.first.getLocalizedName(context)
        : (isAr ? 'مستشفى دبي المركزي' : 'Dubai Central Hospital');

    if (isAr) {
      return 'اكتب مباشرة — بدون أوامر معقدة:\n\n'
          'مستفيد\n'
          '• «$samplePatient» → ملف كامل (جرعة، BMI، صرف، خطة)\n\n'
          'مستشفى / منشأة\n'
          '• «$sampleCenter» → مخزون كل الجرعات\n\n'
          'طبيب\n'
          '• «د. أحمد المنصوري» → تخصص ومنشأة\n\n'
          'تشغيل\n'
          '• «ملخص البرنامج» | «التنبيهات» | «جاهز للصرف»\n'
          '• «سجل الاحتيال» | «مونجارو» | «إحصائيات البرنامج»';
    }
    return 'Type naturally — no complex commands:\n\n'
        'Beneficiary\n'
        '• "$samplePatient" → full profile (dose, BMI, dispense, plan)\n\n'
        'Hospital / facility\n'
        '• "$sampleCenter" → stock for all doses\n\n'
        'Physician\n'
        '• "Dr. Ahmed Al Mansoori" → specialty & hospital\n\n'
        'Operations\n'
        '• "Program summary" | "Alerts" | "Ready to dispense"\n'
        '• "Fraud log" | "Mounjaro" | "Program statistics"';
  }

  static String _programSummary(BuildContext context, DataProvider dp, bool isAr) {
    final alerts = collectProgramAlerts(context, dp).where((a) => a.kind != ProgramAlertKind.allClear).length;
    final ready = dp.countPatientsReadyToDispense();
    final pending = dp.pendingClinicalReviews.length;
    final lowCenters = dp.centers.where((c) => c.totalAvailable <= 40).length;

    if (isAr) {
      return 'ملخص تشغيلي — برنامج مونجارو الوطني\n'
          '────────────────────────\n'
          '• مستفيدون في العينة: ${dp.patients.length}\n'
          '• جاهزون للصرف الآن: $ready\n'
          '• اعتمادات طبية معلقة: $pending\n'
          '• تنبيهات نشطة: $alerts\n'
          '• منشآت بمخزون منخفض: $lowCenters\n'
          '• أطباء معالجون: ${dp.doctors.length}\n'
          '• منشآت صرف: ${dp.centers.length}';
    }
    return 'Operational summary — National Mounjaro Program\n'
        '────────────────────────\n'
        '• Sample cohort: ${dp.patients.length} beneficiaries\n'
        '• Ready to dispense now: $ready\n'
        '• Pending physician authorizations: $pending\n'
        '• Active alerts: $alerts\n'
        '• Low-stock facilities: $lowCenters\n'
        '• Treating physicians: ${dp.doctors.length}\n'
        '• Dispensing facilities: ${dp.centers.length}';
  }

  static String _alertsSummary(BuildContext context, DataProvider dp, bool isAr) {
    final all = collectProgramAlerts(context, dp).where((a) => a.kind != ProgramAlertKind.allClear).toList();
    final fraud = all.where((a) => a.category == AlertCategory.fraud).length;
    final medical = all.where((a) => a.category == AlertCategory.clinical).length;
    final supply = all.where((a) => a.category == AlertCategory.supply).length;
    final top = all.take(3).map((a) => '  • ${a.message}').join('\n');

    if (isAr) {
      return 'التنبيهات النشطة: ${all.length}\n'
          '• أمن واحتيال: $fraud\n'
          '• متابعة طبية: $medical\n'
          '• إمداد: $supply\n\n'
          'أبرز التنبيهات:\n$top';
    }
    return 'Active alerts: ${all.length}\n'
        '• Security & fraud: $fraud\n'
        '• Medical follow-up: $medical\n'
        '• Supply: $supply\n\n'
        'Top alerts:\n$top';
  }

  static String _fraudSummary(BuildContext context, DataProvider dp, bool isAr) {
    final logs = dp.misusePreventionLogs.take(8).toList();
    if (logs.isEmpty) {
      return isAr ? 'لا توجد سجلات احتيال أو تجاوز في آخر البيانات.' : 'No fraud or override records in current data.';
    }
    final lines = logs.map((l) {
      final patient = l.getLocalizedPatientName(context);
      final action = l.getLocalizedAction(context);
      final center = l.getLocalizedCenterName(context);
      return '  • $patient — $action (${l.getLocalizedStatus(context)}) @ $center';
    }).join('\n');

    return isAr
        ? 'سجل منع إساءة الاستخدام — آخر ${logs.length} أحداث:\n$lines'
        : 'Misuse prevention log — last ${logs.length} events:\n$lines';
  }

  static String _patientsSummary(BuildContext context, DataProvider dp, bool isAr) {
    final lines = dp.patients.take(8).map((p) {
      final name = p.getLocalizedFullName(context);
      final dose = context.mounjaroDoseLabel(p.currentDose);
      return '  • $name (${p.id}) — $dose';
    }).join('\n');
    final more = dp.patients.length > 8 ? '\n  … +${dp.patients.length - 8} ${isAr ? 'آخرون' : 'more'}' : '';

    return isAr
        ? 'المستفيدون (${dp.patients.length}):\n$lines$more\n\nاكتب اسم أي مستفيد للتفاصيل الكاملة.'
        : 'Beneficiaries (${dp.patients.length}):\n$lines$more\n\nType any name for the full profile.';
  }

  static String _patientDetail(BuildContext context, DataProvider dp, Patient p, bool isAr) {
    final plan = dp.getPlanForPatient(p.id);
    final center = dp.getDispensingCenterById(p.lastDispensingCenterId);
    final name = p.getLocalizedFullName(context);
    final emirate = p.getLocalizedEmirate(context);
    final dose = context.mounjaroDoseLabel(p.currentDose);
    final bmi = p.bmi.toStringAsFixed(1);
    final eligible = p.programEligibility.eligible;
    final dispenseStatus = _dispenseStatusLabel(dp, p, isAr);
    final weightLoss = p.weightHistory.length >= 2
        ? (p.weightHistory.first - p.weight).toStringAsFixed(1)
        : '—';
    final conditions = p.getLocalizedMedicalConditions(context).join(isAr ? '، ' : ', ');
    final patientAlerts = collectProgramAlerts(context, dp)
        .where((a) => a.message.contains(p.id) || a.message.contains(name))
        .take(3)
        .map((a) => '  • ${a.message}')
        .join('\n');

    if (isAr) {
      return 'ملف المستفيد — $name\n'
          '════════════════════════\n'
          '• الرقم: ${p.id}\n'
          '• الهوية الإماراتية: ${p.emiratesId}\n'
          '• العمر: ${p.age} سنة | ${p.getLocalizedGender(context)} | $emirate\n'
          '• الجنسية: ${p.getLocalizedNationality(context)} | ${p.getLocalizedResidency(context)}\n'
          '• الوزن الحالي: ${p.weight} kg | الطول: ${p.height} cm | BMI: $bmi\n'
          '• فقدان الوزن: $weightLoss kg | الالتزام: ${(p.complianceRate * 100).toStringAsFixed(0)}%\n'
          '${p.hba1cPercent != null ? "• HbA1c: ${p.hba1cPercent}% | سكر صائم: ${p.fastingGlucoseMgDl ?? "—"} mg/dL\n" : ""}'
          '• الحالات: $conditions\n'
          '────────────────────────\n'
          'العلاج\n'
          '• الجرعة الحالية: $dose\n'
          '• آخر صرف: ${p.lastDispensingDate ?? "لم يصرف بعد"}\n'
          '• الاستحقاق القادم: ${p.nextEligibleDate ?? "—"}\n'
          '• حالة الصرف: $dispenseStatus\n'
          '• الأهلية: ${eligible ? "مؤهل للبرنامج" : "غير مؤهل"}\n'
          '${center != null ? "• آخر منشأة صرف: ${center.getLocalizedName(context)}\n" : ""}'
          '${plan != null ? "• الخطة العلاجية: ${plan.medicationDose} كل ${plan.medicationFrequencyDays} يوم | الهدف ${plan.targetWeight} kg\n" : ""}'
          '${patientAlerts.isNotEmpty ? "\nتنبيهات مرتبطة:\n$patientAlerts" : ""}';
    }
    return 'Beneficiary profile — $name\n'
        '════════════════════════\n'
        '• ID: ${p.id}\n'
        '• Emirates ID: ${p.emiratesId}\n'
        '• Age: ${p.age} | ${p.getLocalizedGender(context)} | $emirate\n'
        '• Nationality: ${p.getLocalizedNationality(context)} | ${p.getLocalizedResidency(context)}\n'
        '• Weight: ${p.weight} kg | Height: ${p.height} cm | BMI: $bmi\n'
        '• Weight loss: $weightLoss kg | Compliance: ${(p.complianceRate * 100).toStringAsFixed(0)}%\n'
        '${p.hba1cPercent != null ? "• HbA1c: ${p.hba1cPercent}% | Fasting glucose: ${p.fastingGlucoseMgDl ?? "—"} mg/dL\n" : ""}'
        '• Conditions: $conditions\n'
        '────────────────────────\n'
        'Treatment\n'
        '• Current dose: $dose\n'
        '• Last dispense: ${p.lastDispensingDate ?? "Never"}\n'
        '• Next eligible: ${p.nextEligibleDate ?? "—"}\n'
        '• Dispensing status: $dispenseStatus\n'
        '• Program eligible: ${eligible ? "Yes" : "No"}\n'
        '${center != null ? "• Last dispensing facility: ${center.getLocalizedName(context)}\n" : ""}'
        '${plan != null ? "• Care plan: ${plan.medicationDose} every ${plan.medicationFrequencyDays} days | target ${plan.targetWeight} kg\n" : ""}'
        '${patientAlerts.isNotEmpty ? "\nRelated alerts:\n$patientAlerts" : ""}';
  }

  static String _dispenseStatusLabel(DataProvider dp, Patient p, bool isAr) {
    switch (dp.dispensingUiStatus(p)) {
      case DispensingUiStatus.eligible:
        return isAr ? 'جاهز للصرف' : 'Ready to dispense';
      case DispensingUiStatus.pendingCarePlan:
        return isAr ? 'بانتظار اعتماد الخطة' : 'Pending care plan';
      case DispensingUiStatus.pendingClinicalReview:
        return isAr ? 'بانتظار مراجعة طبية' : 'Pending clinical review';
      case DispensingUiStatus.approvedEarly:
        return isAr ? 'معتمد للصرف المبكر' : 'Early dispense approved';
      case DispensingUiStatus.clinicalIneligible:
        return isAr ? 'غير مؤهل سريرياً' : 'Clinically ineligible';
    }
  }

  static String _doctorsSummary(BuildContext context, DataProvider dp, bool isAr) {
    final lines = dp.doctors.map((d) {
      return '  • ${d.getLocalizedName(context)} (${d.id}) — ${d.getLocalizedSpecialty(context)}';
    }).join('\n');
    return isAr
        ? 'الأطباء (${dp.doctors.length}):\n$lines\n\nاكتب اسم الطبيب للتفاصيل.'
        : 'Physicians (${dp.doctors.length}):\n$lines\n\nType a physician name for details.';
  }

  static String _doctorDetail(BuildContext context, DataProvider dp, Doctor d, bool isAr) {
    final patientsOnFile = dp.patients
        .where((p) => p.emirate == d.emirate || p.emirateAr == d.emirateAr)
        .length;

    if (isAr) {
      return 'ملف الطبيب — ${d.getLocalizedName(context)}\n'
          '════════════════════════\n'
          '• الرقم: ${d.id}\n'
          '• التخصص: ${d.getLocalizedSpecialty(context)}\n'
          '• المنشأة: ${d.getLocalizedHospital(context)}\n'
          '• الإمارة: ${d.getLocalizedEmirate(context)}\n'
          '• البريد: ${d.email}\n'
          '• مستفيدون في نفس الإمارة (عينة): $patientsOnFile';
    }
    return 'Physician profile — ${d.getLocalizedName(context)}\n'
        '════════════════════════\n'
        '• ID: ${d.id}\n'
        '• Specialty: ${d.getLocalizedSpecialty(context)}\n'
        '• Hospital: ${d.getLocalizedHospital(context)}\n'
        '• Emirate: ${d.getLocalizedEmirate(context)}\n'
        '• Email: ${d.email}\n'
        '• Beneficiaries in same emirate (sample): $patientsOnFile';
  }

  static String _inventorySummary(BuildContext context, DataProvider dp, bool isAr) {
    final lines = dp.centers.map((c) {
      final name = c.getLocalizedName(context);
      final region = c.getLocalizedRegion(context);
      final flag = c.totalAvailable <= 20
          ? (isAr ? ' ⚠ حرج' : ' ⚠ critical')
          : c.totalAvailable <= 40
              ? (isAr ? ' ⚡ منخفض' : ' ⚡ low')
              : '';
      return '  • $name ($region)\n'
          '    2.5:${c.inventory2_5mg} | 5:${c.inventory5mg} | 7.5:${c.inventory7_5mg} | 10:${c.inventory10mg}$flag';
    }).join('\n');

    return isAr
        ? 'مخزون المنشآت:\n$lines\n\nاكتب اسم مستشفى واحد للتفاصيل الكاملة.'
        : 'Facility inventory:\n$lines\n\nType one hospital name for full details.';
  }

  static String _centerDetail(BuildContext context, DispensingCenter c, bool isAr) {
    final status = c.totalAvailable <= 20
        ? (isAr ? 'حرج — إمداد طارئ مطلوب' : 'Critical — emergency supply needed')
        : c.totalAvailable <= 40
            ? (isAr ? 'منخفض — مراقبة' : 'Low — monitor closely')
            : (isAr ? 'مستقر' : 'Stable');
    final utilization = c.totalAllocated == 0
        ? 0.0
        : (c.totalDispensed / c.totalAllocated * 100);

    if (isAr) {
      return 'منشأة الصرف — ${c.getLocalizedName(context)}\n'
          '════════════════════════\n'
          '• الرقم: ${c.id}\n'
          '• الإمارة: ${c.getLocalizedRegion(context)}\n'
          '• الهاتف: ${c.phone}\n'
          '• حالة المخزون: $status\n'
          '────────────────────────\n'
          'مخزون مونجارو (وحدات)\n'
          '• 2.5 mg: ${c.inventory2_5mg}\n'
          '• 5 mg: ${c.inventory5mg}\n'
          '• 7.5 mg: ${c.inventory7_5mg}\n'
          '• 10 mg: ${c.inventory10mg}\n'
          '────────────────────────\n'
          '• إجمالي متاح: ${c.totalAvailable} وحدة\n'
          '• إجمالي مصروف: ${c.totalDispensed} وحدة\n'
          '• نسبة الاستهلاك: ${utilization.toStringAsFixed(0)}%';
    }
    return 'Dispensing facility — ${c.getLocalizedName(context)}\n'
        '════════════════════════\n'
        '• ID: ${c.id}\n'
        '• Emirate: ${c.getLocalizedRegion(context)}\n'
        '• Phone: ${c.phone}\n'
        '• Stock status: $status\n'
        '────────────────────────\n'
        'Mounjaro stock (units)\n'
        '• 2.5 mg: ${c.inventory2_5mg}\n'
        '• 5 mg: ${c.inventory5mg}\n'
        '• 7.5 mg: ${c.inventory7_5mg}\n'
        '• 10 mg: ${c.inventory10mg}\n'
        '────────────────────────\n'
        '• Total available: ${c.totalAvailable}\n'
        '• Total dispensed: ${c.totalDispensed}\n'
        '• Utilization: ${utilization.toStringAsFixed(0)}%';
  }

  static String _dispensingSummary(BuildContext context, DataProvider dp, bool isAr) {
    final ready = dp.patients.where((p) => dp.canDispensePatient(p)).toList();
    if (ready.isEmpty) {
      return isAr ? 'لا يوجد مستفيدون جاهزون للصرف حالياً.' : 'No beneficiaries are ready to dispense right now.';
    }
    final lines = ready.take(8).map((p) {
      return '  • ${p.getLocalizedFullName(context)} (${p.id}) — ${context.mounjaroDoseLabel(p.currentDose)}';
    }).join('\n');
    return isAr
        ? 'جاهزون للصرف (${ready.length}):\n$lines'
        : 'Ready to dispense (${ready.length}):\n$lines';
  }

  static String _medicationInfo(BuildContext context, DataProvider dp, String q, bool isAr) {
    final doses = ['2.5', '5', '7.5', '10'];
    final byDose = <String, int>{};
    for (final d in doses) {
      byDose[d] = dp.patients.where((p) => p.currentDose.contains(d)).length;
    }

    final ranked = _rankPatients(dp, _stripFillers(q));
    final match = ranked.isNotEmpty && ranked.first.score >= 80 ? ranked.first.entity : null;

    if (isAr) {
      var text = 'مونجارو (تيرزيباتيد)\n'
          '════════════════════════\n'
          '• الجرعات المعتمدة: 2.5 | 5 | 7.5 | 10 mg\n'
          '• على 2.5 mg: ${byDose['2.5']} | 5 mg: ${byDose['5']}\n'
          '• على 7.5 mg: ${byDose['7.5']} | 10 mg: ${byDose['10']}\n'
          '• منشآت الصرف: ${dp.centers.length}';
      if (match != null) {
        text += '\n\n${match.getLocalizedFullName(context)}: ${context.mounjaroDoseLabel(match.currentDose)}';
      }
      return text;
    }
    var text = 'Mounjaro (tirzepatide)\n'
        '════════════════════════\n'
        '• Approved doses: 2.5 | 5 | 7.5 | 10 mg\n'
        '• On 2.5 mg: ${byDose['2.5']} | 5 mg: ${byDose['5']}\n'
        '• On 7.5 mg: ${byDose['7.5']} | 10 mg: ${byDose['10']}\n'
        '• Dispensing facilities: ${dp.centers.length}';
    if (match != null) {
      text += '\n\n${match.getLocalizedFullName(context)}: ${context.mounjaroDoseLabel(match.currentDose)}';
    }
    return text;
  }

  static String _pendingReviews(BuildContext context, DataProvider dp, bool isAr) {
    final reviews = dp.pendingClinicalReviews;
    if (reviews.isEmpty) {
      return isAr ? 'لا توجد اعتمادات طبية معلقة.' : 'No pending physician authorizations.';
    }
    final lines = reviews.take(6).map((r) {
      return '  • ${r.patient.getLocalizedFullName(context)} (${r.patient.id})';
    }).join('\n');
    return isAr
        ? 'اعتمادات معلقة (${reviews.length}):\n$lines'
        : 'Pending authorizations (${reviews.length}):\n$lines';
  }

  static String _nationalKpis(bool isAr) {
    if (isAr) {
      return 'مؤشرات البرنامج الوطني\n'
          '════════════════════════\n'
          '• المسجلون: ${DemoMetrics.formatCount(DemoMetrics.nationalEnrolled)}\n'
          '• المؤهلون: ${DemoMetrics.formatCount(DemoMetrics.nationalEligible)}\n'
          '• الدعم الحكومي: ${DemoMetrics.formatAed(DemoMetrics.nationalSubsidyBaseAed)}\n'
          '• حوادث إساءة استخدام مُنعَة: ${DemoMetrics.nationalFraudPreventedBase}\n'
          '• BMI الوطني: ${DemoMetrics.baselineNationalBmi}';
    }
    return 'National program KPIs\n'
        '════════════════════════\n'
        '• Enrolled: ${DemoMetrics.formatCount(DemoMetrics.nationalEnrolled)}\n'
        '• Eligible: ${DemoMetrics.formatCount(DemoMetrics.nationalEligible)}\n'
        '• Government subsidy: ${DemoMetrics.formatAed(DemoMetrics.nationalSubsidyBaseAed)}\n'
        '• Misuse prevented: ${DemoMetrics.nationalFraudPreventedBase}\n'
        '• National BMI: ${DemoMetrics.baselineNationalBmi}';
  }

  static String _recentLogs(BuildContext context, DataProvider dp, bool isAr) {
    final logs = dp.logs.take(5).toList();
    if (logs.isEmpty) return isAr ? 'السجل فارغ.' : 'Log is empty.';
    final lines = logs.map((l) {
      return '  • ${l.formatTimestamp(context)} — ${l.getLocalizedAction(context)} — ${l.getLocalizedPatientName(context)}';
    }).join('\n');
    return isAr ? 'آخر العمليات:\n$lines' : 'Recent activity:\n$lines';
  }

  static String _therapySummary(BuildContext context, DataProvider dp, bool isAr) {
    final lines = dp.therapyCenters.map((t) {
      return '  • ${t.getLocalizedName(context)} — ${t.getLocalizedEmirate(context)}';
    }).join('\n');
    return isAr
        ? 'مراكز العلاج الطبيعي (${dp.therapyCenters.length}):\n$lines'
        : 'Physical therapy centers (${dp.therapyCenters.length}):\n$lines';
  }

  static String _emirateBreakdown(BuildContext context, DataProvider dp, String q, bool isAr) {
    final counts = <String, int>{};
    for (final p in dp.patients) {
      final key = p.getLocalizedEmirate(context);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final filtered = counts.entries.where((e) => q.contains(_normalizeArabic(e.key))).toList();
    final entries = filtered.isNotEmpty ? filtered : counts.entries;
    final lines = entries.map((e) => '  • ${e.key}: ${e.value}').join('\n');
    return isAr ? 'المستفيدون حسب الإمارة:\n$lines' : 'Beneficiaries by emirate:\n$lines';
  }

  static String _nonCompliance(BuildContext context, DataProvider dp, bool isAr) {
    final alerts = collectProgramAlerts(context, dp)
        .where((a) => a.kind == ProgramAlertKind.nonCompliance)
        .take(6)
        .toList();
    if (alerts.isEmpty) {
      return isAr ? 'لا توجد حالات عدم التزام مسجلة.' : 'No non-compliance cases recorded.';
    }
    final lines = alerts.map((a) => '  • ${a.message}').join('\n');
    return isAr ? 'عدم الالتزام:\n$lines' : 'Non-compliance:\n$lines';
  }
}
