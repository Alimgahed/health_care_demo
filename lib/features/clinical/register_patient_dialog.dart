import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/mock_data.dart';
import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import 'patient_clinical_models.dart';

/// Full beneficiary registration: demographics, chronic disease, lab PDF upload.
class RegisterPatientDialog extends StatefulWidget {
  const RegisterPatientDialog({super.key});

  static Future<Patient?> show(BuildContext context) {
    return showDialog<Patient>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Dialog(
        insetPadding: EdgeInsets.all(32),
        child: SizedBox(width: 820, height: 720, child: RegisterPatientDialog()),
      ),
    );
  }

  @override
  State<RegisterPatientDialog> createState() => _RegisterPatientDialogState();
}

class _RegisterPatientDialogState extends State<RegisterPatientDialog> {
  int _step = 0;
  final _nameEn = TextEditingController();
  final _nameAr = TextEditingController();
  final _eid = TextEditingController(text: '784-1990-');
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _hba1c = TextEditingController();
  final _glucose = TextEditingController();

  String _gender = 'Male';
  String _nationality = 'United Arab Emirates';
  String _emirate = 'Dubai';
  ResidencyStatus _residency = ResidencyStatus.citizen;
  bool _hasChronic = false;
  final Set<String> _selectedConditions = {};
  final List<PatientAttachment> _attachments = [];

  static const _conditionOptions = [
    ('Type 2 Diabetes', 'السكري من النوع 2'),
    ('Hypertension', 'ارتفاع ضغط الدم'),
    ('Obesity', 'السمنة'),
    ('PCOS', 'تكيس المبايض'),
    ('Dyslipidemia', 'اضطراب شحميات الدم'),
    ('NAFLD', 'دهون كبدية غير كحولية'),
  ];

  @override
  void dispose() {
    _nameEn.dispose();
    _nameAr.dispose();
    _eid.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _hba1c.dispose();
    _glucose.dispose();
    super.dispose();
  }

  String _nationalityAr(String en) {
    switch (en) {
      case 'United Arab Emirates':
        return 'الإمارات العربية المتحدة';
      case 'United Kingdom':
        return 'المملكة المتحدة';
      case 'United States':
        return 'الولايات المتحدة';
      case 'India':
        return 'الهند';
      case 'Pakistan':
        return 'باكستان';
      case 'Egypt':
        return 'مصر';
      default:
        return en;
    }
  }

  String _emirateAr(String en) {
    switch (en) {
      case 'Abu Dhabi':
        return 'أبوظبي';
      case 'Dubai':
        return 'دبي';
      case 'Sharjah':
        return 'الشارقة';
      case 'Ajman':
        return 'عجمان';
      case 'Umm Al Quwain':
        return 'أم القيوين';
      case 'Ras Al Khaimah':
        return 'رأس الخيمة';
      case 'Fujairah':
        return 'الفجيرة';
      default:
        return en;
    }
  }

  double? get _bmi {
    final w = double.tryParse(_weight.text);
    final h = double.tryParse(_height.text);
    if (w == null || h == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        final name = f.name;
        final ext = name.split('.').last.toLowerCase();
        final mime = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
        _attachments.add(
          PatientAttachment(
            id: 'DOC-${DateTime.now().millisecondsSinceEpoch}-${_attachments.length}',
            fileName: name,
            mimeType: mime,
            uploadedAt: DateTime.now(),
            category: ext == 'pdf' ? 'lab_report' : 'imaging',
          ),
        );
      }
    });
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        return _nameEn.text.trim().isNotEmpty &&
            _nameAr.text.trim().isNotEmpty &&
            _eid.text.trim().length >= 10 &&
            (int.tryParse(_age.text) ?? 0) > 0;
      case 1:
        final w = double.tryParse(_weight.text);
        final h = double.tryParse(_height.text);
        if (w == null || h == null || w < 30 || h < 100) return false;
        if (_hasChronic && _selectedConditions.isEmpty) return false;
        return true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _submit(BuildContext context) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final w = double.parse(_weight.text);
    final h = double.parse(_height.text);
    final conditionsEn = <String>[];
    final conditionsAr = <String>[];
    if (_hasChronic) {
      for (final opt in _conditionOptions) {
        if (_selectedConditions.contains(opt.$1)) {
          conditionsEn.add(opt.$1);
          conditionsAr.add(opt.$2);
        }
      }
    } else {
      conditionsEn.add('Obesity (program indication)');
      conditionsAr.add('السمنة (مؤشر البرنامج)');
    }

    final emLatLng = _emirate == 'Dubai'
        ? (25.2048, 55.2708)
        : _emirate == 'Abu Dhabi'
            ? (24.4539, 54.3773)
            : (25.3463, 55.4209);

    final newP = Patient(
      id: provider.generateNextPatientId(),
      emiratesId: _eid.text.trim(),
      fullName: _nameEn.text.trim(),
      fullNameAr: _nameAr.text.trim(),
      nationality: _nationality,
      nationalityAr: _nationalityAr(_nationality),
      residencyStatus: _residency,
      age: int.parse(_age.text),
      gender: _gender,
      genderAr: _gender == 'Male' ? 'ذكر' : 'أنثى',
      weight: w,
      height: h,
      medicalConditions: conditionsEn,
      medicalConditionsAr: conditionsAr,
      hasChronicDisease: _hasChronic,
      hba1cPercent: double.tryParse(_hba1c.text),
      fastingGlucoseMgDl: double.tryParse(_glucose.text),
      clinicalAttachments: List.from(_attachments),
      lastDispensingDate: null,
      nextEligibleDate: 'Eligible Now',
      currentDose: '2.5 mg',
      latitude: emLatLng.$1,
      longitude: emLatLng.$2,
      emirate: _emirate,
      emirateAr: _emirateAr(_emirate),
      weightHistory: [w],
      doseHistory: [],
      complianceRate: 1.0,
    );

    provider.registerPatient(newP);
    Navigator.pop(context, newP);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.userPlus, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('register_new_patient'),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _stepChip(context, 0, context.tr('demographics_section')),
              _stepChip(context, 1, context.tr('clinical_assessment')),
              _stepChip(context, 2, context.tr('lab_documents_section')),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _step == 0
                ? _buildDemographicsStep(context)
                : _step == 1
                    ? _buildClinicalStep(context)
                    : _buildDocumentsStep(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_step > 0)
                TextButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(context.tr('back')),
                ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _validateStep()
                    ? () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _submit(context);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: Text(_step < 2 ? context.tr('next') : context.tr('register_beneficiary_btn')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepChip(BuildContext context, int index, String label) {
    final active = _step == index;
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDemographicsStep(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameEn,
          decoration: InputDecoration(labelText: context.tr('full_name_en')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameAr,
          decoration: InputDecoration(labelText: context.tr('full_name_ar')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _eid,
          decoration: InputDecoration(labelText: context.tr('emirates_id')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('age')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(labelText: context.tr('gender')),
                items: [
                  DropdownMenuItem(value: 'Male', child: Text(context.tr('male'))),
                  DropdownMenuItem(value: 'Female', child: Text(context.tr('female'))),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'Male'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _nationality,
          decoration: InputDecoration(labelText: context.tr('nationality')),
          items: ['United Arab Emirates', 'United Kingdom', 'United States', 'India', 'Pakistan', 'Egypt']
              .map((n) => DropdownMenuItem(value: n, child: Text(context.nationalityLabel(n))))
              .toList(),
          onChanged: (v) => setState(() => _nationality = v ?? _nationality),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ResidencyStatus>(
                value: _residency,
                decoration: InputDecoration(labelText: context.tr('residency_status')),
                items: [
                  DropdownMenuItem(value: ResidencyStatus.citizen, child: Text(context.tr('emirati'))),
                  DropdownMenuItem(value: ResidencyStatus.resident, child: Text(context.tr('resident'))),
                  DropdownMenuItem(value: ResidencyStatus.visitor, child: Text(context.tr('visitor'))),
                ],
                onChanged: (v) => setState(() => _residency = v ?? _residency),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _emirate,
                decoration: InputDecoration(labelText: context.tr('region')),
                items: ['Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah']
                    .map((e) => DropdownMenuItem(value: e, child: Text(context.emirateLabel(e))))
                    .toList(),
                onChanged: (v) => setState(() => _emirate = v ?? _emirate),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClinicalStep(BuildContext context) {
    final bmi = _bmi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: context.tr('weight_kg'), suffixText: 'kg'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _height,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.tr('height_cm'), suffixText: 'cm'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (bmi != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.tr('calculated_bmi', {'bmi': bmi.toStringAsFixed(1)}),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('has_chronic_disease'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(context.tr('has_chronic_disease_hint')),
          value: _hasChronic,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() {
            _hasChronic = v;
            if (!v) _selectedConditions.clear();
          }),
        ),
        if (_hasChronic) ...[
          Text(context.tr('select_chronic_conditions'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditionOptions.map((opt) {
              final selected = _selectedConditions.contains(opt.$1);
              return FilterChip(
                label: Text(context.isArabic ? opt.$2 : opt.$1),
                selected: selected,
                onSelected: (s) => setState(() {
                  if (s) {
                    _selectedConditions.add(opt.$1);
                  } else {
                    _selectedConditions.remove(opt.$1);
                  }
                }),
              );
            }).toList(),
          ),
        ] else
          Text(context.tr('no_chronic_note'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        Text(context.tr('lab_values_section'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(context.tr('lab_values_hint'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hba1c,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.tr('hba1c_label'),
                  suffixText: '%',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _glucose,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('fasting_glucose_label'),
                  suffixText: 'mg/dL',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('upload_lab_hint'), style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickFiles,
          icon: const Icon(LucideIcons.upload),
          label: Text(context.tr('upload_lab_pdf')),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        if (_attachments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.fileUp, size: 40, color: AppColors.textSecondary),
                const SizedBox(height: 8),
                Text(context.tr('no_files_yet'), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
        else
          ..._attachments.map(
            (doc) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  doc.isPdf ? LucideIcons.fileText : LucideIcons.image,
                  color: AppColors.primary,
                ),
                title: Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(context.tr('document_uploaded_at', {'date': doc.uploadedAt.toString().split('.').first})),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                  onPressed: () => setState(() => _attachments.remove(doc)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
