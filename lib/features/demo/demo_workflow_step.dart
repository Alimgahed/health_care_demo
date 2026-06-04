enum DemoPortalRole { admin, doctor, center, patient }

class DemoWorkflowStep {
  final int index;
  final String titleKey;
  final String bodyKey;
  final String tipKey;
  final DemoPortalRole role;
  /// When [role] is [DemoPortalRole.admin], open this tab in [WebAdminShell].
  final int? adminNavIndex;
  final String? patientId;
  final int doctorTabIndex;
  final String? scenarioPatientId;

  const DemoWorkflowStep({
    required this.index,
    required this.titleKey,
    required this.bodyKey,
    required this.tipKey,
    required this.role,
    this.adminNavIndex,
    this.patientId,
    this.doctorTabIndex = 0,
    this.scenarioPatientId,
  });
}

const int kDemoWorkflowStepCount = 8;

const List<DemoWorkflowStep> kDemoWorkflowSteps = [
  DemoWorkflowStep(
    index: 0,
    titleKey: 'demo_step_1_title',
    bodyKey: 'demo_step_1_body',
    tipKey: 'demo_step_1_tip',
    role: DemoPortalRole.admin,
    adminNavIndex: 0,
  ),
  DemoWorkflowStep(
    index: 1,
    titleKey: 'demo_step_2_title',
    bodyKey: 'demo_step_2_body',
    tipKey: 'demo_step_2_tip',
    role: DemoPortalRole.admin,
    adminNavIndex: 2,
  ),
  DemoWorkflowStep(
    index: 2,
    titleKey: 'demo_step_3_title',
    bodyKey: 'demo_step_3_body',
    tipKey: 'demo_step_3_tip',
    role: DemoPortalRole.doctor,
    patientId: 'P001',
    doctorTabIndex: 0,
  ),
  DemoWorkflowStep(
    index: 3,
    titleKey: 'demo_step_4_title',
    bodyKey: 'demo_step_4_body',
    tipKey: 'demo_step_4_tip',
    role: DemoPortalRole.doctor,
    patientId: 'P002',
    doctorTabIndex: 1,
    scenarioPatientId: 'P002',
  ),
  DemoWorkflowStep(
    index: 4,
    titleKey: 'demo_step_5_title',
    bodyKey: 'demo_step_5_body',
    tipKey: 'demo_step_5_tip',
    role: DemoPortalRole.center,
    patientId: 'P001',
  ),
  DemoWorkflowStep(
    index: 5,
    titleKey: 'demo_step_6_title',
    bodyKey: 'demo_step_6_body',
    tipKey: 'demo_step_6_tip',
    role: DemoPortalRole.center,
    patientId: 'P003',
    scenarioPatientId: 'P003',
  ),
  DemoWorkflowStep(
    index: 6,
    titleKey: 'demo_step_7_title',
    bodyKey: 'demo_step_7_body',
    tipKey: 'demo_step_7_tip',
    role: DemoPortalRole.patient,
    patientId: 'P001',
  ),
  DemoWorkflowStep(
    index: 7,
    titleKey: 'demo_step_8_title',
    bodyKey: 'demo_step_8_body',
    tipKey: 'demo_step_8_tip',
    role: DemoPortalRole.admin,
    adminNavIndex: 5,
  ),
];
