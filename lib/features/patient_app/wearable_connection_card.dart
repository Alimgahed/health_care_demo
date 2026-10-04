import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/localization/l10n_extension.dart';
import '../../core/theme/app_colors.dart';

class WearableConnectionCard extends StatefulWidget {
  const WearableConnectionCard({super.key});

  @override
  State<WearableConnectionCard> createState() => _WearableConnectionCardState();
}

class _WearableConnectionCardState extends State<WearableConnectionCard> {
  static final Health _health = Health();
  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  bool _loading = false;
  int? _steps;
  double? _heartRate;
  String? _source;
  String? _error;

  Future<void> _connectAndSync() async {
    if (_loading) return;
    final ar = context.isArabic;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _health.configure();
      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) {
          throw StateError(
            ar
                ? 'يلزم السماح بنشاط الحركة لقراءة الخطوات.'
                : 'Allow activity recognition to read step data.',
          );
        }
      }
      final granted = await _health.requestAuthorization(
        _types,
        permissions: const [HealthDataAccess.READ, HealthDataAccess.READ],
      );
      if (!granted) {
        throw StateError(
          ar
              ? 'لم يتم منح إذن قراءة البيانات الصحية.'
              : 'Health data access was not granted.',
        );
      }

      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: DateTime(now.year, now.month, now.day),
        endTime: now,
      );
      final unique = _health.removeDuplicates(points);
      final stepPoints = unique.where(
        (point) => point.type == HealthDataType.STEPS,
      );
      final heartPoints = unique.where(
        (point) => point.type == HealthDataType.HEART_RATE,
      );
      final steps = stepPoints.fold<double>(
        0,
        (sum, point) =>
            sum +
            (point.value is NumericHealthValue
                ? (point.value as NumericHealthValue).numericValue
                : 0),
      );
      final latestHeart = heartPoints.isEmpty
          ? null
          : heartPoints.reduce((a, b) => a.dateTo.isAfter(b.dateTo) ? a : b);
      final source = unique.isEmpty ? null : unique.first.sourceName;
      if (!mounted) return;
      setState(() {
        _steps = steps.round();
        _heartRate = latestHeart?.value is NumericHealthValue
            ? (latestHeart!.value as NumericHealthValue).numericValue.toDouble()
            : null;
        _source = source;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message
              : (ar
                    ? 'تعذر الاتصال بتطبيق الصحة. تحقق من الإعدادات وحاول مرة أخرى.'
                    : 'Could not read from your health app. Check its setup and try again.'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.isArabic;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.paleSurface,
                  foregroundColor: AppColors.primaryDark,
                  child: const Icon(LucideIcons.watch, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? 'بيانات الساعة' : 'Wearable health data',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ar
                            ? 'Apple Health أو Health Connect'
                            : 'Apple Health or Health Connect',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _connectAndSync,
                  tooltip: ar ? 'مزامنة البيانات' : 'Sync health data',
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.refreshCw),
                ),
              ],
            ),
            if (_steps != null || _heartRate != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  if (_steps != null)
                    _Metric(
                      label: ar ? 'الخطوات اليوم' : 'Steps today',
                      value: '$_steps',
                      icon: LucideIcons.footprints,
                    ),
                  if (_heartRate != null)
                    _Metric(
                      label: ar ? 'آخر نبض' : 'Latest heart rate',
                      value: '${_heartRate!.round()} bpm',
                      icon: LucideIcons.heartPulse,
                    ),
                ],
              ),
              if (_source != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${ar ? 'مصدر البيانات' : 'Data source'}: $_source',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 8),
              Text(
                ar
                    ? 'اربط ساعة متوافقة بتطبيق الصحة في هاتفك، ثم اسمح بقراءة البيانات.'
                    : 'Connect a compatible watch to your phone health app, then allow read access.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: _loading ? null : _connectAndSync,
                  icon: const Icon(LucideIcons.watch, size: 18),
                  label: Text(ar ? 'ربط الساعة' : 'Connect watch'),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: AppColors.errorText, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    ],
  );
}
