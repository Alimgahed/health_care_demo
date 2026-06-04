import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/mock_data.dart';
import '../models/treatment_plan.dart';

class SessionCheckinScreen extends StatefulWidget {
  final TreatmentPlan plan;
  final TherapySession session;

  const SessionCheckinScreen({super.key, required this.plan, required this.session});

  @override
  State<SessionCheckinScreen> createState() => _SessionCheckinScreenState();
}

class _SessionCheckinScreenState extends State<SessionCheckinScreen> {
  final TextEditingController _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_weightController.text.isEmpty) return;
    final weight = double.tryParse(_weightController.text);
    if (weight == null) return;

    final provider = Provider.of<DataProvider>(context, listen: false);
    provider.checkInSession(widget.plan.id, widget.session.id, weight);
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('success'))));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('session_checkin')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.plan.assignedCenterId ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Session ${widget.session.sessionNumber}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(t.translate('post_session_log'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t.translate('weight_after_session') + ' (kg)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.activity),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submit(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(t.translate('mark_attendance')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
