import 'package:flutter/foundation.dart';

/// Tracks client-demo walkthrough progress (checklist + focused beneficiary).
class DemoFlowProvider extends ChangeNotifier {
  String _focusPatientId = 'P001';
  final Set<int> _completedSteps = {};
  int? _activePortalStep;

  String get focusPatientId => _focusPatientId;
  Set<int> get completedSteps => Set.unmodifiable(_completedSteps);
  int? get activePortalStep => _activePortalStep;

  void setFocusPatient(String patientId) {
    if (_focusPatientId == patientId) return;
    _focusPatientId = patientId;
    notifyListeners();
  }

  void markStepComplete(int stepIndex) {
    if (_completedSteps.add(stepIndex)) notifyListeners();
  }

  void unmarkStep(int stepIndex) {
    if (_completedSteps.remove(stepIndex)) notifyListeners();
  }

  void resetProgress() {
    _completedSteps.clear();
    _activePortalStep = null;
    notifyListeners();
  }

  void beginPortalStep(int stepIndex) {
    _activePortalStep = stepIndex;
    notifyListeners();
  }

  void endPortal() {
    _activePortalStep = null;
    notifyListeners();
  }
}
