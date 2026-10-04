export type Role = 'Admin' | 'Doctor' | 'Reviewer' | 'Pharmacist' | 'Patient'
export type RequestStatus = 'Completed' | 'Draft' | 'Under review' | 'Approved' | 'Needs information' | 'Rejected' | 'Ready to dispense' | 'Dispensed'
export type PatientType = 'Citizen' | 'Resident' | 'Visitor'
export type Coordinates = { lat: number; lng: number }
export type Patient = { demoPortrait?: { collection: 'everyday' | 'emirati'; slot: number }; location?: Coordinates; area?: string; previousIllnesses?: string[]; chronicConditions?: string[]; procedures?: {name:string;date:string;note:string}[]; doctorId?: string; centreId?: string; emirateId?: string; id: string; name: string; registeredAt?: string; age: number; emirate: string; bmi: number; diagnosis: string; latestLab: string; adherence: number; nameAr?: string; sex?: string; emiratesId?: string; nationality?: string; residency?: 'Citizen' | 'Resident' | 'Visitor'; currentDose?: string; lastFollowup?: string; nextEligibility?: string; eligibility?: 'Meets clinical criteria' | 'Not eligible' | 'Refill timing' | 'Review required'; treatmentStatus?: 'Active' | 'No active plan'; weightKg?: number; heightCm?: number; fastingGlucose?: string; isActive?: boolean; assignedDoctor?: string; treatmentCentre?: string }
export type TreatmentRequest = { integratedCarePlanId?: string; reviewerId?: string; medicationId?: string; approvalRoute?: 'Automatic' | 'Exception review'; doctorRationale?: string; exceptionReasons?: string[]; exceptionApproved?: boolean; id: string; patientId: string; planId: string; status: RequestStatus; dose: string; created: string; createdAt?: string; reviewer?: string; note?: string; prescriptionId?: string; approvalExpiresAt?: string; medication?: string; frequency?: string; durationDays?: number; startDate?: string; endDate?: string; indication?: string; instructions?: string; monitoringPlan?: string; followUpDate?: string }
export type TreatmentPlan = { medicationId?: string; id: string; patientId: string; medication: string; dose: string; frequency: string; durationDays: number; startDate: string; endDate: string; indication: string; instructions: string; monitoringPlan: string; followUpDate: string; status: 'Draft' | 'Submitted' | 'Under review' | 'Needs information' | 'Approved' | 'Rejected' | 'Pharmacy ready' | 'Dispensed' | 'Completed' }
export type Dispense = { medicationCoverage?: CoverageResult; centreId?: string; pharmacistId?: string; id: string; requestId: string; patientId: string; centre: string; date: string; dose: string; dispensedAt?: string; batchId?: string }
export type AuditEvent = { actorId?: string; id: string; actor: Role; action: string; entity: string; entityId: string; time: string; occurredAt?: string; detail: string; patientId?: string; previousState?: string; newState?: string; reason?: string; metadata?: Record<string, string> }
export type DoseRecord = { id: string; patientId: string; requestId: string; dose: string; recordedAt: string; status: 'Taken' }
export type PaymentRecord = { id:string; requestId:string; dispenseId:string; patientId:string; method:'Cash'|'Card'|'Covered'; coverage?:CoverageResult; amountAED:number; paidAt:string; receiptNumber:string }
export type SupplyRequest = { id:string; dose:string; centre:string; quantity:number; createdAt:string; status:'Requested'|'Received' }
export type FinancialRecord = { integratedCarePlanId?: string; coverage?: CoverageResult; dispensedAt?: string; id: string; requestId: string; patientId: string; amountAED: number; status: 'Estimated'; assessedAt: string }
export type Notification = { id: string; patientId: string; title: string; detail: string; createdAt: string; read: boolean; relatedEntity?: string; relatedEntityId?: string; priority?: 'Low' | 'Normal' | 'High' }
export type Vital = { id: string; patientId: string; weightKg: number; heightCm: number; bmi: number; systolic: number; diastolic: number; heartRate: number; recordedAt: string; actor: Role }
export type LabResult = { id: string; patientId: string; test: string; value: number; unit: string; reference: string; status: 'Normal' | 'Abnormal' | 'Pending'; date: string; source: string; interpretation: string }
export type ClinicalAssessment = { clinicianId?: string; id: string; patientId: string; reason: string; diagnosis: string; symptoms: string; medicalHistory: string; medications: string; allergies: string; findings: string; notes: string; status: 'Draft' | 'Submitted'; clinician: string; createdAt: string }
export type Appointment = { doctorId?: string; centreId?: string; id: string; patientId: string; doctor: string; centre: string; purpose: string; date: string; time: string; status: 'Scheduled' | 'Confirmed' | 'Completed' | 'Cancelled' | 'No show'; notes: string }
export type ExerciseRecord = { integratedCarePlanId?: string; exerciseId?: string; id: string; patientId: string; activity: string; durationMinutes: number; intensity: 'Light' | 'Moderate' | 'Vigorous'; date: string; notes: string }
export type InventoryBatch = { centreId?: string; medicationId?: string; id: string; dose: string; batchNumber: string; expiry: string; quantity: number; centre: string; receivedAt: string; source: string }
export type InventoryMovement = { centreId?: string; id: string; dose: string; batchId?: string; type: 'Receiving' | 'Dispensing' | 'Adjustment' | 'Restock' | 'Expiry' | 'Correction'; quantity: number; centre: string; actor: Role; at: string; reference: string; note: string }
export type ContractStatus = 'Active' | 'Pending' | 'Suspended'
export type CentreDirectoryDetails = { nameAr?: string; kind?: 'Treatment' | 'Physiotherapy' | 'Rehabilitation' | 'Integrated rehabilitation'; contractStatus?: ContractStatus; contractReference?: string; contractDate?: string; email?: string; manager?: string; services?: string[]; notes?: string; createdAt?: string }
export type DoctorProfile = { nameAr?: string; gender?: 'Male' | 'Female'; email?: string; phone?: string; programmeRole?: string; qualification?: string; joinedAt?: string; contractStatus?: ContractStatus; notes?: string; createdAt?: string; centreId?: string; id: string; name: string; specialty: string; licenseReference: string; centre: string; status: 'Active' | 'Inactive'; updatedAt?: string }
export type ReviewerProfile = { id: string; name: string; specialty: string; status: 'Active' | 'Inactive' }
export type CareCentre = CentreDirectoryDetails & { coordinates?: Coordinates; contact?: string; id: string; name: string; emirate: string; location: string; status: 'Active' | 'Inactive'; pharmacy: string }
export type AbuseReviewRecord = { id: string; eventType: string; severity: 'Critical' | 'Warning' | 'Info'; evidence: string; timestamp: string; status: 'New' | 'Under Review' | 'Resolved' | 'Dismissed'; patientId?: string; requestId?: string; updatedAt?: string }
export type CareProgram = { id: string; patientId: string; clinicianId: string; title: string; activities: string[]; weeklySessions: number; reviewDate: string; status: 'Active' | 'Completed' }
export type CareDocument = { id: string; patientId: string; title: string; date: string; authorId: string; content: string; fileName?: string; mimeType?: string; dataUrl?: string; sizeBytes?: number; labResultId?: string }
export type MedicationCatalogItem = { id: string; name: string; strengths: string[]; frequencies?: string[]; status?: 'Supported' | 'Unavailable'; unitCostAED: number }
export type ReportFilters = { from: string; to: string; scope: string; programme: string; category: string; type: string }
export type SavedReport = { id: string; name: string; type: string; generatedAt: string; generatedBy: string; filters: ReportFilters; rows: Record<string, string | number | boolean | undefined>[] }
export type ReportSchedule = { id: string; name: string; report: string; frequency: 'Weekly' | 'Monthly'; enabled: boolean }
export type ManualAlert = { id:string; title:string; detail:string; severity:'Critical'|'Warning'|'Info'; category:'Inventory'|'Treatment'|'Safety'|'Clinical'|'Appointments'; priority:'High'|'Medium'|'Low'; patientId?:string; medicationId?:string; centre?:string; timestamp:string }
export type AppData = { activityEventStates?: Record<string, { read: boolean; handled?: boolean }>; manualAlerts?: ManualAlert[]; savedReports?: SavedReport[]; reportSchedules?: ReportSchedule[]; careWorkflowVersion?: number; activePatientId?: string; activeDoctorId?: string; integratedCarePlans?: IntegratedCarePlan[]; rehabilitationCentres?: RehabilitationCentre[]; rehabilitationPrograms?: RehabilitationProgram[]; homeExercises?: HomeExercise[]; pharmacists?: { id: string; name: string; nameAr?: string; centreId: string }[]; supplyRequests?: SupplyRequest[]; medications?: MedicationCatalogItem[]; emirates?: { id: string; name: string }[]; carePrograms?: CareProgram[]; documents?: CareDocument[]; patients: Patient[]; requests: TreatmentRequest[]; treatmentPlans: TreatmentPlan[]; dispenses: Dispense[]; audit: AuditEvent[]; doses: DoseRecord[]; financial: FinancialRecord[]; payments?: PaymentRecord[]; notifications: Notification[]; vitals: Vital[]; labs: LabResult[]; assessments: ClinicalAssessment[]; appointments: Appointment[]; exercise: ExerciseRecord[]; batches: InventoryBatch[]; movements: InventoryMovement[]; doctors: DoctorProfile[]; reviewers: ReviewerProfile[]; centres: CareCentre[]; abuseReviews: AbuseReviewRecord[]; dismissedAlerts?: string[]; readAlerts?: string[] }
export const supportedDoses = ['2.5 mg', '5 mg', '7.5 mg', '10 mg'] as const
export const treatmentCentres = [
  'Abu Dhabi Primary Care Centre 2', 'Al Ain Medical Centre', 'Dubai Central Pharmacy',
  'Dubai Primary Care Centre 4', 'Sharjah Health Centre', 'Ajman Medical Centre',
  'Ras Al Khaimah Hospital', 'Fujairah Health Centre', 'Umm Al Quwain Clinic',
]
export const programmeDoctors = ['Dr. Laila Hassan', 'Dr. Omar Khalid'] as const
export const initialCentres: CareCentre[] = [
  { id: 'CTR-AUH-02', name: 'Abu Dhabi Primary Care Centre 2', emirate: 'Abu Dhabi', location: 'Al Danah · Abu Dhabi', status: 'Active', pharmacy: 'Abu Dhabi Primary Care Centre 2 Pharmacy', nameAr: "مركز أبوظبي للرعاية الأولية 2", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-001", contractDate: "2024-03-12", email: "ctr-auh-02@example.test", contact: "+97125551000", manager: "سالم المنصوري", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 24.487, "lng": 54.365}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-03-12T08:00:00.000Z" },
  { id: 'CTR-AIN-01', name: 'Al Ain Medical Centre', emirate: 'Abu Dhabi', location: 'Al Jimi · Al Ain', status: 'Active', pharmacy: 'Al Ain Medical Centre Pharmacy', nameAr: "مركز العين الطبي", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-002", contractDate: "2024-05-25", email: "ctr-ain-01@example.test", contact: "+97135551001", manager: "مريم الظاهري", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 24.245, "lng": 55.725}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-05-25T08:00:00.000Z" },
  { id: 'CTR-DXB-01', name: 'Dubai Central Pharmacy', emirate: 'Dubai', location: 'Al Barsha · Dubai', status: 'Active', pharmacy: 'Dubai Central Pharmacy', nameAr: "صيدلية دبي المركزية", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-003", contractDate: "2024-06-14", email: "ctr-dxb-01@example.test", contact: "+97145551002", manager: "خالد المهيري", services: ["Pharmacy"], coordinates: {"lat": 25.112, "lng": 55.199}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-06-14T08:00:00.000Z" },
  { id: 'CTR-DXB-04', name: 'Dubai Primary Care Centre 4', emirate: 'Dubai', location: 'Deira · Dubai', status: 'Active', pharmacy: 'Dubai Primary Care Centre 4 Pharmacy', nameAr: "مركز دبي للرعاية الأولية 4", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-004", contractDate: "2024-10-02", email: "ctr-dxb-04@example.test", contact: "+97145551003", manager: "نورة الكعبي", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 25.269, "lng": 55.326}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-10-02T08:00:00.000Z" },
  { id: 'CTR-SHJ-01', name: 'Sharjah Health Centre', emirate: 'Sharjah', location: 'Al Qasimia · Sharjah', status: 'Active', pharmacy: 'Sharjah Health Centre Pharmacy', nameAr: "مركز الشارقة الصحي", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-005", contractDate: "2024-08-18", email: "ctr-shj-01@example.test", contact: "+97165551004", manager: "أحمد القاسمي", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 25.342, "lng": 55.395}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-08-18T08:00:00.000Z" },
  { id: 'CTR-AJM-01', name: 'Ajman Medical Centre', emirate: 'Ajman', location: 'Al Nuaimia · Ajman', status: 'Active', pharmacy: 'Ajman Medical Centre Pharmacy', nameAr: "مركز عجمان الطبي", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-006", contractDate: "2024-01-03", email: "ctr-ajm-01@example.test", contact: "+97165551005", manager: "فاطمة النعيمي", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 25.389, "lng": 55.452}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-01-03T08:00:00.000Z" },
  { id: 'CTR-RAK-01', name: 'Ras Al Khaimah Hospital', emirate: 'Ras Al Khaimah', location: 'Al Nakheel · Ras Al Khaimah', status: 'Active', pharmacy: 'Ras Al Khaimah Hospital Pharmacy', nameAr: "مستشفى رأس الخيمة", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-007", contractDate: "2024-04-22", email: "ctr-rak-01@example.test", contact: "+97175551006", manager: "سعيد الشحي", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 25.803, "lng": 55.957}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-04-22T08:00:00.000Z" },
  { id: 'CTR-FUJ-01', name: 'Fujairah Health Centre', emirate: 'Fujairah', location: 'Al Faseel · Fujairah', status: 'Active', pharmacy: 'Fujairah Health Centre Pharmacy', nameAr: "مركز الفجيرة الصحي", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-008", contractDate: "2024-07-11", email: "ctr-fuj-01@example.test", contact: "+97195551007", manager: "حمد الشرقي", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 25.166, "lng": 56.348}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-07-11T08:00:00.000Z" },
  { id: 'CTR-UAQ-01', name: 'Umm Al Quwain Clinic', emirate: 'Umm Al Quwain', location: 'Al Raas · Umm Al Quwain', status: 'Active', pharmacy: 'Umm Al Quwain Clinic Pharmacy', nameAr: "مركز أم القيوين الطبي", kind: "Treatment", contractStatus: "Active", contractReference: "UAE-CARE-2024-009", contractDate: "2024-09-20", email: "ctr-uaq-01@example.test", contact: "+97165551008", manager: "عائشة المعلا", services: ["Consultations", "Pharmacy", "Home care"], coordinates: {"lat": 25.571, "lng": 55.565}, notes: "سجل تجريبي ضمن شبكة برنامج العلاج في الإمارات.", createdAt: "2024-09-20T08:00:00.000Z" },
]
export const initialDoctors: DoctorProfile[] = [
  {"id": "DOC-001", "name": "Dr. Laila Hassan", "nameAr": "د. ليلى حسن", "gender": "Female", "specialty": "Endocrinology", "licenseReference": "MOHAP-DEMO-00481", "centre": "Dubai Primary Care Centre 4", "status": "Active", "contractStatus": "Active", "programmeRole": "Treating physician", "qualification": "استشارية الغدد الصماء والسكري", "email": "laila.hassan@example.test", "phone": "+971505551100", "joinedAt": "2024-03-12", "createdAt": "2024-03-12T08:00:00.000Z", "notes": "ملف تجريبي مكتمل ضمن فريق برنامج العلاج في الإمارات."},
  {"id": "DOC-002", "name": "Dr. Omar Khalid", "nameAr": "د. عمر خالد", "gender": "Male", "specialty": "Family Medicine", "licenseReference": "MOHAP-DEMO-00816", "centre": "Abu Dhabi Primary Care Centre 2", "status": "Active", "contractStatus": "Active", "programmeRole": "Treating physician", "qualification": "استشاري طب الأسرة", "email": "omar.khalid@example.test", "phone": "+971505551101", "joinedAt": "2024-05-25", "createdAt": "2024-05-25T08:00:00.000Z", "notes": "ملف تجريبي مكتمل ضمن فريق برنامج العلاج في الإمارات."},
  {"id": "DOC-003", "name": "Dr. Sara Al Mansoori", "nameAr": "د. سارة المنصوري", "gender": "Female", "specialty": "Internal Medicine", "licenseReference": "MOHAP-DEMO-00923", "centre": "Sharjah Health Centre", "status": "Active", "contractStatus": "Active", "programmeRole": "Treating physician", "qualification": "أخصائية الباطنة العامة", "email": "sara.almansoori@example.test", "phone": "+971505551102", "joinedAt": "2024-06-14", "createdAt": "2024-06-14T08:00:00.000Z", "notes": "ملف تجريبي مكتمل ضمن فريق برنامج العلاج في الإمارات."},
  {"id": "DOC-004", "name": "Dr. Ahmed Al Ali", "nameAr": "د. أحمد العلي", "gender": "Male", "specialty": "Cardiology", "licenseReference": "MOHAP-DEMO-01034", "centre": "Al Ain Medical Centre", "status": "Active", "contractStatus": "Active", "programmeRole": "Treating physician", "qualification": "استشاري أمراض القلب", "email": "ahmed.alali@example.test", "phone": "+971505551103", "joinedAt": "2024-08-18", "createdAt": "2024-08-18T08:00:00.000Z", "notes": "ملف تجريبي مكتمل ضمن فريق برنامج العلاج في الإمارات."},
  {"id": "DOC-005", "name": "Dr. Reem Al Dhaheri", "nameAr": "د. ريم الظاهري", "gender": "Female", "specialty": "Physiotherapy", "licenseReference": "MOHAP-DEMO-01145", "centre": "Ajman Medical Centre", "status": "Active", "contractStatus": "Active", "programmeRole": "Physiotherapist", "qualification": "أخصائية العلاج الطبيعي وإعادة التأهيل", "email": "reem.aldhaheri@example.test", "phone": "+971505551104", "joinedAt": "2024-09-20", "createdAt": "2024-09-20T08:00:00.000Z", "notes": "ملف تجريبي مكتمل ضمن فريق برنامج العلاج في الإمارات."},
]
export const initialReviewers: ReviewerProfile[] = [
  { id: 'REV-001', name: 'Dr. Mariam Nasser', specialty: 'Clinical review', status: 'Active' },
  { id: 'REV-002', name: 'Dr. Khalid Rahman', specialty: 'Clinical review', status: 'Active' },
]
const centreForEmirate: Record<string, string> = {
  'Abu Dhabi': 'Abu Dhabi Primary Care Centre 2', Dubai: 'Dubai Primary Care Centre 4', Sharjah: 'Sharjah Health Centre', Ajman: 'Ajman Medical Centre',
  'Ras Al Khaimah': 'Ras Al Khaimah Hospital', Fujairah: 'Fujairah Health Centre', 'Umm Al Quwain': 'Umm Al Quwain Clinic',
}
export function inventoryByDose(data: Pick<AppData, 'batches'> & Partial<Pick<AppData, 'requests'>>): Record<string, number> {
  const onHand = onHandByDose(data)
  const requests = data.requests ?? []
  return Object.fromEntries(supportedDoses.map(dose => [dose, Math.max(0, onHand[dose] - Math.min(onHand[dose], requests.filter(item => item.status === 'Ready to dispense' && item.dose === dose).length))]))
}
export function onHandByDose(data: Pick<AppData, 'batches'>): Record<string, number> {
  const today = new Date().toISOString().slice(0, 10)
  return Object.fromEntries(supportedDoses.map(dose => [dose, data.batches.filter(batch => batch.dose === dose && batch.expiry > today).reduce((sum, batch) => sum + batch.quantity, 0)]))
}
export function reservedByDose(data: Pick<AppData, 'batches' | 'requests'>): Record<string, number> {
  const onHand = onHandByDose(data)
  return Object.fromEntries(supportedDoses.map(dose => [dose, Math.min(onHand[dose], data.requests.filter(item => item.status === 'Ready to dispense' && item.dose === dose).length)]))
}

const visiblePatients: Patient[] = [
  { id: 'P999', name: 'Ahmed Al Mansoori', nameAr: 'أحمد المنصوري', age: 45, sex: 'Male', emirate: 'Dubai', nationality: 'Emirati', residency: 'Citizen', emiratesId: '784-1990-1234567-1', bmi: 39.2, weightKg: 120, heightCm: 175, diagnosis: 'Type 2 diabetes', latestLab: 'HbA1c · 8.5%', fastingGlucose: '160 mg/dL', adherence: 0, currentDose: '10 mg', eligibility: 'Meets clinical criteria', treatmentStatus: 'Active', lastFollowup: '2026-06-12', nextEligibility: '2026-06-15', isActive: true },
  { id: 'P001', name: 'Ahmed Al Mansoori', nameAr: 'أحمد المنصوري', age: 49, sex: 'Male', emirate: 'Abu Dhabi', nationality: 'Jordanian', residency: 'Resident', bmi: 34.3, weightKg: 105, heightCm: 175, diagnosis: 'Type 2 diabetes', latestLab: 'HbA1c · 7.9%', fastingGlucose: '148 mg/dL', adherence: 0, currentDose: '5 mg', eligibility: 'Meets clinical criteria', treatmentStatus: 'Active', lastFollowup: '2026-06-10', isActive: true },
  { id: 'P002', name: 'Sara Yousef', nameAr: 'سارة يوسف', age: 39, sex: 'Female', emirate: 'Dubai', nationality: 'Jordanian', residency: 'Resident', bmi: 33.8, weightKg: 91, heightCm: 164, diagnosis: 'Type 2 diabetes', latestLab: 'HbA1c · 8.2%', fastingGlucose: '154 mg/dL', adherence: 0, currentDose: '2.5 mg', eligibility: 'Not eligible', treatmentStatus: 'Active', lastFollowup: '2026-06-15', isActive: true },
  { id: 'P003', name: 'Mahmoud Ibrahim', nameAr: 'محمود إبراهيم', age: 54, sex: 'Male', emirate: 'Sharjah', nationality: 'Egyptian', residency: 'Resident', bmi: 35.5, weightKg: 108, heightCm: 174, diagnosis: 'Type 2 diabetes', latestLab: 'HbA1c · 8.0%', fastingGlucose: '150 mg/dL', adherence: 0, currentDose: '2.5 mg', eligibility: 'Meets clinical criteria', treatmentStatus: 'Active', lastFollowup: '—', isActive: true },
  { id: 'P004', name: 'Fatima Al Qasimi', nameAr: 'فاطمة القاسمي', age: 46, sex: 'Female', emirate: 'Abu Dhabi', nationality: 'Emirati', residency: 'Citizen', bmi: 46.9, weightKg: 123, heightCm: 162, diagnosis: 'Weight management', latestLab: 'HbA1c · 5.7%', adherence: 0, currentDose: '7.5 mg', eligibility: 'Meets clinical criteria', treatmentStatus: 'No active plan', lastFollowup: '2026-05-20' },
  { id: 'P005', name: 'Rashid Al Nuaimi', nameAr: 'راشد النعيمي', age: 43, sex: 'Male', emirate: 'Dubai', nationality: 'Emirati', residency: 'Citizen', bmi: 30.9, weightKg: 95, heightCm: 175, diagnosis: 'Type 2 diabetes', latestLab: 'HbA1c · 7.6%', adherence: 0, currentDose: '5 mg', eligibility: 'Meets clinical criteria', treatmentStatus: 'No active plan', lastFollowup: '2026-06-05' },
  { id: 'P006', name: 'Sara Yousef', nameAr: 'سارة يوسف', age: 34, sex: 'Female', emirate: 'Sharjah', nationality: 'Lebanese', residency: 'Visitor', bmi: 35.3, weightKg: 96, heightCm: 165, diagnosis: 'Weight management', latestLab: 'HbA1c · 5.8%', adherence: 0, currentDose: '7.5 mg', eligibility: 'Meets clinical criteria', treatmentStatus: 'No active plan', lastFollowup: '2026-07-24' },
  { id: 'P007', name: 'Ahmed Al Mansoori', nameAr: 'أحمد المنصوري', age: 52, sex: 'Male', emirate: 'Abu Dhabi', nationality: 'Emirati', residency: 'Citizen', bmi: 38.6, weightKg: 118, heightCm: 175, diagnosis: 'Weight management', latestLab: 'HbA1c · 5.6%', adherence: 0, currentDose: '10 mg', eligibility: 'Not eligible', treatmentStatus: 'No active plan', lastFollowup: '—' },
  { id: 'P008', name: 'Khalid Al Hashmi', nameAr: 'خالد الهاشمي', age: 47, sex: 'Male', emirate: 'Ajman', nationality: 'Emirati', residency: 'Citizen', bmi: 35.4, weightKg: 109, heightCm: 175, diagnosis: 'Weight management', latestLab: 'HbA1c · 5.7%', adherence: 0, currentDose: '2.5 mg', eligibility: 'Not eligible', treatmentStatus: 'No active plan', lastFollowup: '—' },
  { id: 'P009', name: 'Fatima Al Qasimi', nameAr: 'فاطمة القاسمي', age: 50, sex: 'Female', emirate: 'Dubai', nationality: 'Emirati', residency: 'Resident', bmi: 46.7, weightKg: 122, heightCm: 162, diagnosis: 'Type 2 diabetes', latestLab: 'HbA1c · 8.3%', adherence: 0, currentDose: '5 mg', eligibility: 'Refill timing', treatmentStatus: 'No active plan', lastFollowup: '2026-09-22' },
]
const extraNames = ['Mariam Al Kaabi','Omar Al Shamsi','Noor Al Mazrouei','Yousef Al Ketbi','Aisha Hassan','Hamad Al Suwaidi','Reem Al Shehhi','Salem Al Dhaheri','Layla Nasser','Saeed Al Marri','Huda Abdulla','Majid Al Falasi']
const extraNamesAr = ['مريم الكعبي','عمر الشامسي','نور المزروعي','يوسف الكتبي','عائشة حسن','حمد السويدي','ريم الشحي','سالم الظاهري','ليلى ناصر','سعيد المري','هدى عبدالله','ماجد الفلاسي']
const arabicNameFor = (name:string) => extraNamesAr[extraNames.indexOf(name)]
const emirates = ['Abu Dhabi','Dubai','Sharjah','Ajman','Ras Al Khaimah','Fujairah','Umm Al Quwain']
const registrationDate=(index:number)=>`2026-${String(4+index%6).padStart(2,'0')}-${String(2+Math.floor(index/6)%27).padStart(2,'0')}`
const patients: Patient[] = [...visiblePatients.map((patient, index) => ({ ...patient, registeredAt:registrationDate(index), assignedDoctor: index % 2 === 0 || ['P999','P001'].includes(patient.id) ? 'Dr. Laila Hassan' : 'Dr. Omar Khalid', treatmentCentre: centreForEmirate[patient.emirate] })), ...Array.from({ length: 41 }, (_, index) => {
  const n = index + 10
  const bmi = Number((29.4 + ((n * 17) % 181) / 10).toFixed(1))
  const eligible = index < 26
  const emirate = emirates[index % emirates.length]
  return { id: `P${String(n).padStart(3, '0')}`, registeredAt:registrationDate(index+visiblePatients.length), name: extraNames[index % extraNames.length], nameAr: extraNamesAr[index % extraNamesAr.length], age: 31 + (n * 7) % 35, sex: index % 2 ? 'Male' : 'Female', emirate, nationality: index % 3 ? 'Emirati' : 'Jordanian', residency: index % 3 ? 'Citizen' : 'Resident', bmi, weightKg: Math.round(bmi * 1.72 ** 2), heightCm: 172, diagnosis: index % 4 ? 'Type 2 diabetes' : 'Weight management', latestLab: `HbA1c · ${(6.1 + (n % 28) / 10).toFixed(1)}%`, adherence: 0, currentDose: ['2.5 mg','5 mg','7.5 mg','10 mg'][index % 4], eligibility: eligible ? 'Meets clinical criteria' : index % 2 ? 'Not eligible' : 'Review required', treatmentStatus: 'No active plan', lastFollowup: index % 5 ? `2026-06-${String(1 + n % 27).padStart(2, '0')}` : '—', assignedDoctor: index < 4 || index % 2 === 0 ? 'Dr. Laila Hassan' : 'Dr. Omar Khalid', treatmentCentre: centreForEmirate[emirate] } as Patient
})]

// Expanded presentation cohort. Stable IDs allow saved v7 records to merge safely.
const demoMen=[['Ali','علي'],['Hassan','حسن'],['Khaled','خالد'],['Tariq','طارق'],['Ibrahim','إبراهيم'],['Adel','عادل'],['Nasser','ناصر'],['Faisal','فيصل'],['Sultan','سلطان'],['Walid','وليد'],['Sami','سامي']]
const demoWomen=[['Maha','مها'],['Salma','سلمى'],['Hanan','حنان'],['Dalia','داليا'],['Amal','أمل'],['Noura','نورة'],['Hessa','حصة'],['Rana','رنا'],['Yasmin','ياسمين'],['Maryam','مريم'],['Shaikha','شيخة']]
const demoFamilies=[['Al Hammadi','الحمادي'],['Mansour','منصور'],['Al Zaabi','الزعابي'],['Khalil','خليل'],['Al Ameri','العامري'],['Farouk','فاروق'],['Al Balooshi','البلوشي'],['Saleh','صالح'],['Al Mehairi','المهيري']]
for(let i=0;i<99;i++) {
 const n=i+51,sex=i%2?'Female':'Male'
 const given=(sex==='Male'?demoMen:demoWomen)[Math.floor(i/2)%11]
 const family=demoFamilies[Math.floor(i/11)%demoFamilies.length]
 const emirate=emirates[i%emirates.length],heightCm=(sex==='Female'?155:166)+i%15
 const bmi=Number((28.2+(i*7%145)/10).toFixed(1)),age=30+i*7%39
 const resident=i%3===1,visitor=i%13===0
 patients.push({id:`P${String(n).padStart(3,'0')}`,name:`${given[0]} ${family[0]}`,nameAr:`${given[1]} ${family[1]}`,age,sex,emirate,
  nationality:visitor?'Lebanese':resident?['Egyptian','Jordanian','Syrian'][Math.floor(i/3)%3]:'Emirati',
  residency:visitor?'Visitor':resident?'Resident':'Citizen',registeredAt:registrationDate(n),bmi,heightCm,weightKg:Math.round(bmi*(heightCm/100)**2),
  diagnosis:i%3?'Type 2 diabetes':'Weight management',latestLab:`HbA1c · ${(5.4+i%35/10).toFixed(1)}%`,adherence:0,
  treatmentStatus:'No active plan',isActive:true,lastFollowup:`2026-09-${String(1+i%27).padStart(2,'0')}`,
  assignedDoctor:Math.floor(i/2)%2?'Dr. Omar Khalid':'Dr. Laila Hassan',treatmentCentre:centreForEmirate[emirate]})
}
for(const [i,patient] of patients.entries()) {
 patient.demoPortrait={collection:patient.nationality==='Emirati'?'emirati':'everyday',slot:(Math.floor(i/2)%8)+(patient.sex==='Female'?8:0)}
}

export const seed: AppData = {
  savedReports: [],
  reportSchedules: [
    {id:'SCHEDULE-INVENTORY',name:'Weekly Inventory Report',report:'inventory',frequency:'Weekly',enabled:false},
    {id:'SCHEDULE-PROGRAMME',name:'Monthly Programme Report',report:'patients',frequency:'Monthly',enabled:false},
    {id:'SCHEDULE-SAFETY',name:'Safety Alerts Summary',report:'audit',frequency:'Weekly',enabled:false},
  ],
  activeDoctorId:'DOC-001',
  patients,
  doctors: initialDoctors,
  reviewers: initialReviewers,
  centres: initialCentres,
  abuseReviews: [],
  requests: [
    { id: 'TR-24008', patientId: 'P999', planId: 'TP-8781', status: 'Dispensed', dose: '10 mg', created: '12 June', createdAt: '2026-06-12T08:42:00.000Z', reviewer: 'Dr. Laila Hassan', prescriptionId: 'RX-24008', approvalExpiresAt: '2026-07-12' },
    { id: 'TR-24018', patientId: 'P010', planId: 'TP-8801', status: 'Under review', dose: '5 mg', created: 'Today, 09:42', createdAt: '2026-10-01T09:42:00.000Z' },
    { id: 'TR-24017', patientId: 'P011', planId: 'TP-8798', status: 'Approved', dose: '2.5 mg', created: 'Today, 08:16', createdAt: '2026-10-01T08:16:00.000Z', reviewer: 'Dr. Laila Hassan' },
    { id: 'TR-24015', patientId: 'P012', planId: 'TP-8791', status: 'Ready to dispense', dose: '5 mg', created: 'Yesterday, 16:32', createdAt: '2026-09-30T16:32:00.000Z', reviewer: 'Dr. Laila Hassan', prescriptionId: 'RX-24015', approvalExpiresAt: '2026-10-30' },
    { id: 'TR-24011', patientId: 'P013', planId: 'TP-8776', status: 'Needs information', dose: '2.5 mg', created: 'Yesterday, 11:08', createdAt: '2026-09-30T11:08:00.000Z', note: 'Updated renal panel required' },
  ],
  treatmentPlans: [
    { id: 'TP-8781', patientId: 'P999', medication: 'Mounjaro', dose: '10 mg', frequency: 'Weekly', durationDays: 84, startDate: '2026-06-12', endDate: '2026-09-03', indication: 'Type 2 diabetes', instructions: 'Inject once weekly as prescribed.', monitoringPlan: 'Monitor glucose and gastrointestinal symptoms.', followUpDate: '2026-10-04', status: 'Dispensed' },
    { id: 'TP-8801', patientId: 'P010', medication: 'Mounjaro', dose: '5 mg', frequency: 'Weekly', durationDays: 84, startDate: '2026-10-01', endDate: '2026-12-23', indication: 'Weight management', instructions: 'Use only after clinician approval.', monitoringPlan: 'Review after four weeks.', followUpDate: '2026-10-29', status: 'Under review' },
    { id: 'TP-8798', patientId: 'P011', medication: 'Mounjaro', dose: '2.5 mg', frequency: 'Weekly', durationDays: 84, startDate: '2026-10-01', endDate: '2026-12-23', indication: 'Clinical review', instructions: 'Use only after pharmacy verification.', monitoringPlan: 'Review tolerance at follow-up.', followUpDate: '2026-10-29', status: 'Approved' },
    { id: 'TP-8791', patientId: 'P012', medication: 'Mounjaro', dose: '5 mg', frequency: 'Weekly', durationDays: 84, startDate: '2026-10-01', endDate: '2026-12-23', indication: 'Clinical review', instructions: 'Inject once weekly as prescribed.', monitoringPlan: 'Review treatment response.', followUpDate: '2026-10-29', status: 'Pharmacy ready' },
    { id: 'TP-8776', patientId: 'P013', medication: 'Mounjaro', dose: '2.5 mg', frequency: 'Weekly', durationDays: 84, startDate: '2026-10-01', endDate: '2026-12-23', indication: 'Clinical review', instructions: 'Awaiting updated renal panel.', monitoringPlan: 'Repeat renal panel before decision.', followUpDate: '2026-10-15', status: 'Needs information' },
  ],
  dispenses: [{ id: 'DSP-24008', requestId: 'TR-24008', patientId: 'P999', centre: 'Dubai Primary Care Centre 4', date: '2026-06-12', dispensedAt: '2026-06-12T11:00:00.000Z', dose: '10 mg', batchId: 'BT-4' }], doses: [{ id: 'DO-011', patientId: 'P999', requestId: 'TR-24008', dose: '10 mg', recordedAt: '2026-09-24T06:00:00.000Z', status: 'Taken' }, { id: 'DO-010', patientId: 'P999', requestId: 'TR-24008', dose: '10 mg', recordedAt: '2026-09-17T06:00:00.000Z', status: 'Taken' }, { id: 'DO-009', patientId: 'P999', requestId: 'TR-24008', dose: '10 mg', recordedAt: '2026-09-10T06:00:00.000Z', status: 'Taken' }], financial: [{ id: 'FIN-24008', requestId: 'TR-24008', patientId: 'P999', amountAED: 0, status: 'Estimated', assessedAt: '2026-09-18T06:00:00.000Z' }], notifications: [{ id: 'NT-018', patientId: 'P010', title: 'Treatment request received', detail: 'Your care team is reviewing your request.', createdAt: 'Today, 09:42', read: false, relatedEntity: 'Treatment request', relatedEntityId: 'TR-24018' }], audit: [
    { id: 'EV-0831', actor: 'Doctor', action: 'Request submitted', entity: 'Treatment request', entityId: 'TR-24018', patientId: 'P010', time: '09:42', occurredAt: '2026-10-01T09:42:00.000Z', detail: 'Programme patient P010 · 5 mg', previousState: 'Draft', newState: 'Under review' },
    { id: 'EV-0830', actor: 'Pharmacist', action: 'Inventory reconciled', entity: 'National inventory', entityId: 'DXB-04', time: '09:18', occurredAt: '2026-10-01T09:18:00.000Z', detail: 'Dubai central pharmacy · 5 mg' },
    { id: 'EV-0829', actor: 'Reviewer', action: 'Information requested', entity: 'Treatment request', entityId: 'TR-24011', patientId: 'P013', time: '08:54', occurredAt: '2026-09-30T08:54:00.000Z', detail: 'Renal panel required before decision', previousState: 'Under review', newState: 'Needs information', reason: 'Updated renal panel required' },
    { id: 'EV-0828', actor: 'Reviewer', action: 'Request approved', entity: 'Treatment request', entityId: 'TR-24015', patientId: 'P012', time: '16:45', occurredAt: '2026-09-30T16:45:00.000Z', detail: 'Approved for pharmacy verification', previousState: 'Under review', newState: 'Ready to dispense' },
    { id: 'EV-0818', actor: 'Reviewer', action: 'Request approved', entity: 'Treatment request', entityId: 'TR-24017', patientId: 'P011', time: '09:03', occurredAt: '2026-10-01T09:03:00.000Z', detail: 'Clinical criteria reviewed', previousState: 'Under review', newState: 'Approved' },
    { id: 'EV-0413', actor: 'Pharmacist', action: 'Medication dispensed', entity: 'Treatment request', entityId: 'TR-24008', patientId: 'P999', time: '11:00', occurredAt: '2026-06-12T11:00:00.000Z', detail: 'Ahmed Al Mansoori · 10 mg', previousState: 'Ready to dispense', newState: 'Dispensed' },
    { id: 'EV-0412', actor: 'Reviewer', action: 'Request approved', entity: 'Treatment request', entityId: 'TR-24008', patientId: 'P999', time: '09:15', occurredAt: '2026-06-12T09:15:00.000Z', detail: 'Clinical criteria confirmed', previousState: 'Under review', newState: 'Ready to dispense' },
    { id: 'EV-0411', actor: 'Doctor', action: 'Request submitted', entity: 'Treatment request', entityId: 'TR-24008', patientId: 'P999', time: '08:42', occurredAt: '2026-06-12T08:42:00.000Z', detail: 'Ahmed Al Mansoori · 10 mg', previousState: 'Draft', newState: 'Under review' },
  ],
  vitals: patients.map((patient, index) => ({ id: `VT-${patient.id}`, patientId: patient.id, weightKg: patient.weightKg ?? Math.round(patient.bmi * 1.72 ** 2), heightCm: patient.heightCm ?? 172, bmi: patient.bmi, systolic: 118 + index % 22, diastolic: 72 + index % 12, heartRate: 66 + index % 24, recordedAt: index === 0 ? '2026-09-18T08:00:00.000Z' : `2026-09-${String(1 + index % 27).padStart(2, '0')}T08:00:00.000Z`, actor: 'Doctor' as Role })),
  labs: patients.map((patient, index) => {
    const value = Number(patient.latestLab.match(/(?:·|:)\s*([\d.]+)/)?.[1] ?? 0)
    return { id: `LB-${patient.id}-A1C`, patientId: patient.id, test: 'HbA1c', value, unit: '%', reference: '4.0–5.6%', status: value > 5.6 ? 'Abnormal' as const : 'Normal' as const, date: index === 0 ? '2026-09-18' : `2026-08-${String(1 + index % 28).padStart(2, '0')}`, source: 'Primary care laboratory', interpretation: value > 5.6 ? 'Above reference range; clinician review required.' : 'Within reference range.' }
  }),
  assessments: ['P999','P010','P011','P012','P013'].map((patientId, index) => ({ id: `CA-${patientId}-01`, patientId, reason: index === 0 ? 'Quarterly diabetes follow-up' : 'Treatment plan assessment', diagnosis: patients.find(patient => patient.id === patientId)?.diagnosis ?? 'Clinical review', symptoms: 'No acute symptoms reported', medicalHistory: index === 0 ? 'Type 2 diabetes; obesity' : 'History reviewed in patient record', medications: `Mounjaro ${patients.find(patient => patient.id === patientId)?.currentDose ?? '2.5 mg'} weekly`, allergies: 'No known allergies recorded', findings: 'Clinical evidence reviewed; confirm against current visit.', notes: 'Continue monitoring and review at follow-up.', status: 'Submitted' as const, clinician: 'Dr. Laila Hassan', createdAt: '2026-09-18T08:00:00.000Z' })),
  appointments: [{ id: 'AP-P010-TODAY', patientId: 'P010', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Clinical follow-up', date: '2026-10-01', time: '09:00', status: 'Scheduled', notes: '' }, { id: 'AP-P999-TODAY', patientId: 'P999', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Diabetes review', date: '2026-10-01', time: '09:30', status: 'Scheduled', notes: '' }, { id: 'AP-P013-TODAY', patientId: 'P013', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Review lab results', date: '2026-10-01', time: '10:00', status: 'Confirmed', notes: '' }, { id: 'AP-P012-TODAY', patientId: 'P012', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Care plan follow-up', date: '2026-10-01', time: '10:30', status: 'Scheduled', notes: '' }, { id: 'AP-P011-TODAY', patientId: 'P011', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Initial consultation', date: '2026-10-01', time: '11:00', status: 'Scheduled', notes: '' }, { id: 'AP-P999-01', patientId: 'P999', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Diabetes follow-up', date: '2026-10-04', time: '10:30', status: 'Confirmed', notes: 'Bring current medication list.' }, { id: 'AP-P010-01', patientId: 'P010', doctor: 'Dr. Laila Hassan', centre: 'Abu Dhabi Primary Care Centre 2', purpose: 'Initial clinical assessment', date: '2026-10-06', time: '09:00', status: 'Scheduled', notes: '' }, { id: 'AP-P011-01', patientId: 'P011', doctor: 'Dr. Laila Hassan', centre: 'Sharjah Health Centre', purpose: 'Treatment review', date: '2026-09-26', time: '11:00', status: 'Completed', notes: 'Plan reviewed.' }],
  exercise: [{ id: 'EX-P999-01', patientId: 'P999', activity: 'Walking', durationMinutes: 30, intensity: 'Moderate', date: '2026-09-30', notes: 'Evening walk' }],
  batches: Object.entries({ '2.5 mg': 42, '5 mg': 27, '7.5 mg': 16, '10 mg': 8 }).map(([dose, quantity], index) => ({ id: `BT-${index + 1}`, dose, batchNumber: `UAE-${dose.replaceAll('.', '').replaceAll(' ', '')}-2026-A`, expiry: index === 3 ? '2026-10-10' : '2027-03-31', quantity, centre: 'Dubai Central Pharmacy', receivedAt: '2026-06-01', source: 'Gulf Medical Supply LLC' })),
  movements: [
    { id: 'MV-004', dose: '10 mg', batchId: 'BT-4', type: 'Receiving', quantity: 9, centre: 'Dubai Central Pharmacy', actor: 'Admin', at: '2026-06-01T09:00:00.000Z', reference: 'GRN-2026-0004', note: 'Opening inventory balance' },
    { id: 'MV-003', dose: '7.5 mg', batchId: 'BT-3', type: 'Receiving', quantity: 16, centre: 'Dubai Central Pharmacy', actor: 'Admin', at: '2026-06-01T09:00:00.000Z', reference: 'GRN-2026-0003', note: 'Opening inventory balance' },
    { id: 'MV-002', dose: '5 mg', batchId: 'BT-2', type: 'Receiving', quantity: 27, centre: 'Dubai Central Pharmacy', actor: 'Admin', at: '2026-06-01T09:00:00.000Z', reference: 'GRN-2026-0002', note: 'Opening inventory balance' },
    { id: 'MV-001', dose: '2.5 mg', batchId: 'BT-1', type: 'Receiving', quantity: 42, centre: 'Dubai Central Pharmacy', actor: 'Admin', at: '2026-06-01T09:00:00.000Z', reference: 'GRN-2026-0001', note: 'Opening inventory balance' },
    { id: 'MV-000', dose: '10 mg', batchId: 'BT-4', type: 'Dispensing', quantity: -1, centre: 'Dubai Primary Care Centre 4', actor: 'Pharmacist', at: '2026-06-12T11:00:00.000Z', reference: 'DSP-24008', note: 'Historical patient dispensing' },
  ],
  dismissedAlerts: [],
  readAlerts: [],
}

const permissions: Record<Role, string[]> = {
  Admin: ['*'], Doctor: ['patient:read', 'request:create', 'request:submit', 'clinical:write', 'appointment:manage'], Reviewer: ['patient:read', 'request:review'], Pharmacist: ['patient:read', 'request:dispense', 'inventory:read', 'inventory:manage', 'alerts:manage'], Patient: ['patient:self', 'adherence:record', 'activity:self'],
}
export function can(role: Role, permission: string) { return permissions[role].includes('*') || permissions[role].includes(permission) }
export function canReadPatient(data: AppData, role: Role, patientId: string) {
  if (role === 'Admin') return data.patients.some(item => item.id === patientId)
  if (role === 'Doctor') { const doctor=data.doctors.find(item=>item.id===(data.activeDoctorId??data.doctors[0]?.id));return Boolean(doctor&&data.patients.some(item=>item.id===patientId&&(item.doctorId===doctor.id||item.assignedDoctor===doctor.name))) }
  if (role === 'Reviewer') return data.requests.some(item => item.patientId === patientId)
  if (role === 'Pharmacist') return data.requests.some(item => item.patientId === patientId && item.status === 'Ready to dispense') || data.dispenses.some(item => item.patientId === patientId)
  return role === 'Patient' && patientId === (data.activePatientId ?? 'P999')
}
function requirePatientAccess(data: AppData, role: Role, patientId: string) {
  if (!canReadPatient(data, role, patientId)) throw new Error(`Your ${role.toLowerCase()} role cannot access this patient record.`)
}
function eventTime() { return new Date().toLocaleTimeString('en-AE', { hour: '2-digit', minute: '2-digit' }) }
function validIsoDate(value: string) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false
  const date = new Date(`${value}T00:00:00.000Z`)
  return Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value
}
function nextMonthlyDispensingDate(date: string): string {
  const [year, month, day] = date.slice(0,10).split('-').map(Number)
  const lastDay = new Date(Date.UTC(year, month + 1, 0)).getUTCDate()
  return new Date(Date.UTC(year, month, Math.min(day, lastDay))).toISOString().slice(0,10)
}
export function refillEligibility(data: AppData, patientId: string, asOf = new Date().toISOString().slice(0,10)) {
  const latest = data.dispenses.filter(item=>item.patientId===patientId && item.date<=asOf).sort((a,b)=>b.date.localeCompare(a.date))[0]
  const nextEligibleDate = latest ? nextMonthlyDispensingDate(latest.date) : undefined
  return {lastDispense:latest,nextEligibleDate,eligible:!nextEligibleDate || asOf>=nextEligibleDate}
}
export function treatmentEligibility(data:AppData,patientId:string,asOf?:string) {
  const patient=data.patients.find(item=>item.id===patientId)
  if(!patient)throw new Error('Patient record could not be found.')
  const clinical=calculateEligibility(patient,data.labs)
  const refill=refillEligibility(data,patientId,asOf)
  const assessment=data.assessments.some(item=>item.patientId===patientId&&item.status==='Submitted')
  const lab=data.labs.some(item=>item.patientId===patientId&&item.test.toLowerCase()==='hba1c'&&item.status!=='Pending')
  const reasons=[...clinical.failed,...clinical.missing].map(item=>item.label)
  if(!refill.eligible)reasons.push(`Next medication dispensing date: ${refill.nextEligibleDate}`)
  if(!assessment)reasons.push('Submitted clinical assessment missing')
  if(!lab)reasons.push('HbA1c result missing')
  return {eligible:clinical.eligible&&refill.eligible&&assessment&&lab,clinical,refill,assessment,lab,reasons}
}
export function adherenceFor(data: AppData, patientId: string) {
  const now = Date.now()
  const cutoff = now - 28 * 86400000
  const recorded = new Set(data.doses.filter(item => item.patientId === patientId && new Date(item.recordedAt).getTime() >= cutoff && new Date(item.recordedAt).getTime() <= now).map(item => item.recordedAt.slice(0,10))).size
  const activeRequest = data.requests.filter(item=>item.patientId===patientId && item.status==='Dispensed').sort((a,b)=>(b.createdAt??b.created).localeCompare(a.createdAt??a.created))[0]
  const frequency = data.treatmentPlans.find(item=>item.id===activeRequest?.planId)?.frequency ?? 'Weekly'
  const expected = frequency === 'Daily' ? 28 : frequency === 'Every 2 weeks' ? 2 : 4
  return Math.round(Math.min(100, recorded / expected * 100))
}
function audit(actor: Role, action: string, entity: string, entityId: string, detail: string, previousState?: string, newState?: string, reason?: string): AuditEvent { return { id: nextRecordId('EV'), actor, action, entity, entityId, time: eventTime(), occurredAt: new Date().toISOString(), detail, previousState, newState, reason } }
export function decide(data: AppData, role: Role, requestId: string, action: 'approve' | 'information' | 'reject' | 'dispense', note = ''): AppData {
  const permission = action === 'dispense' ? 'request:dispense' : 'request:review'
  if (!can(role, permission)) throw new Error(`Your ${role.toLowerCase()} role cannot ${action} this request.`)
  const request = data.requests.find(item => item.id === requestId)
  if (!request) throw new Error('This request could not be found. Refresh the queue and try again.')
  if (action === 'dispense') {
    if (request.status !== 'Ready to dispense') throw new Error('Only approved requests can be dispensed.')
    const patient = data.patients.find(item => item.id === request.patientId)
    if (!patient) throw new Error('Patient record is missing. Contact the care team before dispensing.')
    if (!request.prescriptionId) throw new Error('This request has no linked prescription. Return it to the care team.')
    if (!request.approvalExpiresAt || !validIsoDate(request.approvalExpiresAt)) throw new Error('This approval is missing a valid expiry date. Request a new clinical review.')
    if (request.approvalExpiresAt < new Date().toISOString().slice(0, 10)) throw new Error('This approval has expired. Request a new clinical review.')
    if ((request.medication ?? 'Mounjaro') !== 'Mounjaro' || !supportedDoses.includes(request.dose as typeof supportedDoses[number])) throw new Error('This medication or dose is not supported by the programme.')
    if (data.dispenses.some(item => item.requestId === requestId)) throw new Error('This request already has a dispensing record.')
    if (!refillEligibility(data,patient.id).eligible && !request.exceptionApproved) throw new Error('The monthly refill interval has not passed. A documented exception approval is required.')
    if (!data.assessments.some(item => item.patientId === patient.id && item.status === 'Submitted')) throw new Error('Required clinical assessment is missing. Return the request to the care team.')
    if (!data.labs.some(item => item.patientId === patient.id && item.test.toLowerCase() === 'hba1c' && item.status !== 'Pending')) throw new Error('Required lab evidence is missing. Return the request to the care team.')
    const today = new Date().toISOString().slice(0, 10)
    const validBatches = data.batches.filter(item => item.dose === request.dose && item.quantity > 0 && item.expiry > today).sort((a, b) => a.expiry.localeCompare(b.expiry))
    const readyForDose = data.requests.filter(item => item.status === 'Ready to dispense' && item.dose === request.dose).slice().sort((a, b) => (a.createdAt ?? '').localeCompare(b.createdAt ?? ''))
    const reservationIndex = readyForDose.findIndex(item => item.id === request.id)
    const reservedForRequest = reservationIndex >= 0 && reservationIndex < (reservedByDose(data)[request.dose] ?? 0)
    const batch = validBatches[0]
    if (!batch) throw new Error(`No unexpired ${request.dose} batch is available. Replenish inventory or select another centre.`)
    if (!reservedForRequest && (inventoryByDose(data)[request.dose] ?? 0) < 1) throw new Error(`No unreserved ${request.dose} units are available.`)
    const stamp = new Date().toISOString()
    const dispenseId = nextRecordId('DSP')
    const centre = batch.centre
    const movement: InventoryMovement = { id: nextRecordId('MV'), dose: request.dose, batchId: batch.id, type: 'Dispensing', quantity: -1, centre, actor: role, at: stamp, reference: dispenseId, note: `Dispensed to ${patient.id}` }
    return { ...data, requests: data.requests.map(item => item.id === requestId ? { ...item, status: 'Dispensed' } : item), treatmentPlans: data.treatmentPlans.map(item => item.id === request.planId ? { ...item, status: 'Dispensed' } : item), batches: data.batches.map(item => item.id === batch.id ? { ...item, quantity: item.quantity - 1 } : item), movements: [movement, ...data.movements], patients: data.patients.map(item => item.id === patient.id ? { ...item, currentDose: request.dose, treatmentStatus: 'Active', isActive: true } : item), dispenses: [{ id: dispenseId, requestId, patientId: request.patientId, centre, date: new Date().toISOString().slice(0, 10), dispensedAt: stamp, dose: request.dose, batchId: batch.id, medicationCoverage:medicationCoverageForRequest(data,requestId) }, ...data.dispenses], financial: dispensingFinancialRecords(data,request,stamp), notifications: [{ id: nextRecordId('NT'), patientId: request.patientId, title: 'Medication dispensed', detail: `Your ${request.dose} medication is ready from ${centre}.`, createdAt: eventTime(), read: false, relatedEntity: 'Treatment request', relatedEntityId: requestId }, ...data.notifications], audit: [audit(role, 'Medication dispensed', 'Treatment request', requestId, `${patient.name} · ${request.dose}`, 'Ready to dispense', 'Dispensed'), audit(role, 'Inventory reduced', 'Medication batch', batch.batchNumber, '1 unit · ' + centre), ...data.audit] }
  }
  if (request.status !== 'Under review') throw new Error('Only requests currently under review can receive a decision. The doctor must resubmit requests that need information.')
  if ((action === 'information' || action === 'reject') && note.trim().length < 8) throw new Error('Add a clear reason of at least 8 characters before continuing.')
  if (action === 'approve') {
    const patient = data.patients.find(item => item.id === request.patientId)
    const plan = data.treatmentPlans.find(item => item.id === request.planId)
    if (!patient) throw new Error('A valid patient record is required before approval.')
    if (!plan || !plan.indication.trim() || !plan.instructions.trim() || !plan.monitoringPlan.trim() || !plan.frequency.trim()) throw new Error('The treatment plan is incomplete and cannot be approved.')
    const planLength = (new Date(`${plan.endDate}T00:00:00Z`).getTime() - new Date(`${plan.startDate}T00:00:00Z`).getTime()) / 86400000 + 1
    if (!Number.isInteger(plan.durationDays) || plan.durationDays < 28 || plan.durationDays > 365 || !validIsoDate(plan.startDate) || !validIsoDate(plan.endDate) || !validIsoDate(plan.followUpDate) || plan.endDate < plan.startDate || plan.followUpDate < plan.startDate || plan.followUpDate > plan.endDate || planLength !== plan.durationDays) throw new Error('The treatment plan has an invalid duration or date range.')
    if ((request.medication ?? plan.medication) !== 'Mounjaro' || !supportedDoses.includes(request.dose as typeof supportedDoses[number])) throw new Error('The requested medication or dose is unsupported.')
    if (!data.assessments.some(item => item.patientId === patient.id && item.status === 'Submitted')) throw new Error('A submitted clinical assessment is required before approval.')
    if (!data.labs.some(item => item.patientId === patient.id && item.test.toLowerCase() === 'hba1c' && item.status !== 'Pending')) throw new Error('Required HbA1c evidence is missing before approval.')
    if (!calculateEligibility(patient, data.labs).eligible && request.approvalRoute!=='Exception review') throw new Error('Current eligibility evidence does not meet the programme criteria.')
    if (request.approvalRoute==='Exception review' && (request.doctorRationale?.trim().length??0)<8) throw new Error('The doctor must record an exception rationale.')
    if (request.approvalRoute==='Exception review' && note.trim().length<8) throw new Error('Reviewer exception approval requires a reason of at least 8 characters.')
  }
  const status: RequestStatus = action === 'approve' ? 'Ready to dispense' : action === 'information' ? 'Needs information' : 'Rejected'
  const label = action === 'approve' ? 'Request approved' : action === 'information' ? 'Information requested' : 'Request rejected'
  const patient = data.patients.find(item => item.id === request.patientId)
  const planStatus = action === 'approve' ? 'Pharmacy ready' : action === 'information' ? 'Needs information' : 'Rejected'
  return { ...data, requests: data.requests.map(item => item.id === requestId ? { ...item, status, reviewer: role === 'Reviewer' ? 'Dr. Mariam Nasser' : 'Programme reviewer', prescriptionId: action === 'approve' ? item.prescriptionId ?? `RX-${requestId.slice(-5)}` : item.prescriptionId, approvalExpiresAt: action === 'approve' ? new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10) : item.approvalExpiresAt, note: note || undefined, exceptionApproved:action==='approve'&&item.approvalRoute==='Exception review'?true:item.exceptionApproved } : item), treatmentPlans: data.treatmentPlans.map(item => item.id === request.planId ? { ...item, status: planStatus } : item), notifications: patient ? [{ id: nextRecordId('NT'), patientId: patient.id, title: action === 'approve' ? 'Treatment approved' : action === 'information' ? 'More information needed' : 'Treatment request update', detail: action === 'approve' ? 'Your treatment is approved and moving to the pharmacy.' : note, createdAt: eventTime(), read: false, relatedEntity: 'Treatment request', relatedEntityId: requestId, priority: action === 'approve' ? 'Normal' : 'High' }, ...data.notifications] : data.notifications, audit: [{...audit(role, label, 'Treatment request', requestId, note || requestId, request.status, status, note || undefined),patientId:request.patientId}, ...data.audit] }
}

export function recordDose(data: AppData, role: Role, patientId: string, date = new Date().toISOString().slice(0, 10)): AppData {
  if (!can(role, 'adherence:record')) throw new Error(`Your ${role.toLowerCase()} role cannot record a patient dose.`)
  if (role === 'Patient' && patientId !== (data.activePatientId ?? 'P999')) throw new Error('You can only record a dose for your own patient profile.')
  if (!validIsoDate(date) || date !== new Date().toISOString().slice(0, 10)) throw new Error('A dose can only be recorded for today using a valid calendar date.')
  const patient = data.patients.find(item => item.id === patientId)
  if (!patient) throw new Error('Patient record could not be found.')
  const request = data.requests.filter(item => item.patientId === patientId && item.status === 'Dispensed').sort((a,b)=>(b.createdAt??'').localeCompare(a.createdAt??''))[0]
  if (!request) throw new Error('No active medication request is available for dose tracking.')
  if (data.doses.some(item => item.patientId === patientId && item.recordedAt.slice(0, 10) === date)) throw new Error('A dose has already been recorded today.')
  const dose: DoseRecord = { id: nextRecordId('DO'), patientId, requestId: request.id, dose: request.dose, recordedAt: new Date().toISOString(), status: 'Taken' }
  const next = { ...data, doses: [dose, ...data.doses], patients: data.patients, notifications: [{ id: nextRecordId('NT'), patientId, title: 'Dose recorded', detail: `Your ${dose.dose} dose was added to your adherence history.`, createdAt: eventTime(), read: false, relatedEntity: 'Dose record', relatedEntityId: dose.id }, ...data.notifications], audit: [{ ...audit(role, 'Dose recorded', 'Dose record', dose.id, `${patient.name} · ${dose.dose}`), patientId }, ...data.audit] }
  return { ...next, patients: next.patients.map(item => item.id === patientId ? { ...item, adherence: adherenceFor(next, patientId) } : item) }
}

export type RequestPlanInput = { frequency: string; durationDays: number; startDate: string; endDate: string; indication: string; instructions: string; monitoringPlan: string; followUpDate: string }
export function resubmitRequest(data: AppData, role: Role, requestId: string, note: string): AppData {
  requirePermission(role, 'request:submit')
  const request = data.requests.find(item => item.id === requestId)
  if (!request || request.status !== 'Needs information') throw new Error('Only a request returned for information can be resubmitted.')
  if (note.trim().length < 8) throw new Error('Add a clear summary of the updated evidence before resubmitting.')
  const patient = data.patients.find(item => item.id === request.patientId)
  if (!patient || !data.assessments.some(item => item.patientId === patient.id && item.status === 'Submitted')) throw new Error('A submitted clinical assessment is required before resubmission.')
  requirePatientAccess(data, role, patient.id)
  if (!data.labs.some(item => item.patientId === patient.id && item.test.toLowerCase() === 'hba1c' && item.status !== 'Pending')) throw new Error('Required HbA1c lab evidence is missing.')
  if (!calculateEligibility(patient, data.labs).eligible && request.approvalRoute!=='Exception review') throw new Error('Eligibility evidence still requires clinical review.')
  const next = { ...data, requests: data.requests.map(item => item.id === requestId ? { ...item, status: 'Under review' as const, note, doctorRationale:request.approvalRoute==='Exception review'?note:item.doctorRationale, created: 'Resubmitted just now', createdAt: new Date().toISOString() } : item), treatmentPlans: data.treatmentPlans.map(item => item.id === request.planId ? { ...item, status: 'Under review' as const } : item), notifications: [{ id: nextRecordId('NT'), patientId: patient.id, title: 'Updated treatment request submitted', detail: note, createdAt: eventTime(), read: false }, ...data.notifications], audit: [{ ...audit(role, 'Request resubmitted', 'Treatment request', requestId, note, 'Needs information', 'Under review', note), patientId: patient.id }, ...data.audit] }
  return next
}
export function submitRequest(data: AppData, role: Role, patientId: string, dose: string, details: RequestPlanInput = { frequency: 'Weekly', durationDays: 84, startDate: new Date().toISOString().slice(0, 10), endDate: new Date(Date.now() + 83 * 86400000).toISOString().slice(0, 10), indication: '', instructions: 'Use only as prescribed.', monitoringPlan: 'Review treatment response and tolerance.', followUpDate: new Date(Date.now() + 28 * 86400000).toISOString().slice(0, 10) }, options: {doctorRationale?:string} = {}): AppData {
  if (!can(role, 'request:submit')) throw new Error(`Your ${role.toLowerCase()} role cannot submit a treatment request.`)
  const patient = data.patients.find(item => item.id === patientId)
  if (!patient) throw new Error('Select a patient before submitting a request.')
  requirePatientAccess(data, role, patientId)
  if (!supportedDoses.includes(dose as typeof supportedDoses[number])) throw new Error('Select a supported medication dose.')
  if (data.requests.some(item => item.patientId === patientId && ['Under review', 'Approved', 'Ready to dispense'].includes(item.status))) throw new Error('This patient already has an active request. Continue that request or review its current status first.')
  if (!data.assessments.some(item => item.patientId === patientId && item.status === 'Submitted')) throw new Error('A submitted clinical assessment is required. Complete it in Clinical care before requesting treatment.')
  if (!data.labs.some(item => item.patientId === patientId && item.test.toLowerCase() === 'hba1c' && item.status !== 'Pending')) throw new Error('Required HbA1c lab evidence is missing. Add a result in Clinical care before submitting.')
  const eligibility = treatmentEligibility(data,patientId)
  if (!eligibility.eligible && (options.doctorRationale?.trim().length??0)<8) throw new Error(`System eligibility requires exception review: ${eligibility.reasons.join(', ')}. Add a doctor rationale of at least 8 characters.`)
  if (!details.frequency.trim() || !Number.isInteger(details.durationDays) || details.durationDays < 28 || details.durationDays > 365 || !validIsoDate(details.startDate) || !validIsoDate(details.endDate) || !details.indication.trim() || !details.instructions.trim() || !details.monitoringPlan.trim() || !validIsoDate(details.followUpDate)) throw new Error('Complete frequency, duration, dates, indication, instructions, monitoring and follow-up before submission.')
  const planLength = (new Date(`${details.endDate}T00:00:00Z`).getTime() - new Date(`${details.startDate}T00:00:00Z`).getTime()) / 86400000 + 1
  if (details.endDate < details.startDate || details.followUpDate < details.startDate || details.followUpDate > details.endDate || planLength !== details.durationDays) throw new Error('The plan end date must match its duration and follow-up must fall within the plan period.')
  const safeDetails: RequestPlanInput = {frequency:details.frequency,durationDays:details.durationDays,startDate:details.startDate,endDate:details.endDate,indication:details.indication,instructions:details.instructions,monitoringPlan:details.monitoringPlan,followUpDate:details.followUpDate}
  const id = nextRecordId('TR')
  const planId = nextRecordId('TP')
  const automatic=eligibility.eligible
  const status=automatic?'Ready to dispense' as const:'Under review' as const
  const plan: TreatmentPlan = { id: planId, patientId, medication: 'Mounjaro', dose, ...safeDetails, status: automatic?'Pharmacy ready':'Under review' }
  const request: TreatmentRequest = { id, patientId, planId, status, dose, created: 'Just now', createdAt: new Date().toISOString(), medication: 'Mounjaro', approvalRoute:automatic?'Automatic':'Exception review', doctorRationale:options.doctorRationale?.trim(), exceptionReasons:automatic?undefined:eligibility.reasons, prescriptionId:automatic?`RX-${id.slice(-5)}`:undefined, approvalExpiresAt:automatic?new Date(Date.now()+30*86400000).toISOString().slice(0,10):undefined, ...safeDetails }
  const action=automatic?'Request automatically authorized':'Doctor exception submitted'
  return { ...data, requests: [request, ...data.requests], treatmentPlans: [plan, ...data.treatmentPlans], notifications: [{ id: nextRecordId('NT'), patientId, title: automatic?'Medication request ready for pharmacy':'Exception request under review', detail: automatic?'The system criteria are met and the request is ready for pharmacy verification.':'The clinician rationale has been sent for exception review.', createdAt: eventTime(), read: false, relatedEntity: 'Treatment request', relatedEntityId: id }, ...data.notifications], audit: [{...audit(role, action, 'Treatment request', id, `${patient.name} · ${dose} · ${eligibility.reasons.join(', ')||'system criteria met'}`,undefined,status,options.doctorRationale?.trim()),patientId}, ...data.audit] }
}

function requirePermission(role: Role, permission: string) { if (!can(role, permission)) throw new Error(`Your ${role.toLowerCase()} role cannot perform this operation.`) }
function eventBundle(data: AppData, role: Role, action: string, entity: string, entityId: string, patientId: string | undefined, detail: string, previousState?: string, newState?: string, reason?: string) {
  return {
    audit: [{ ...audit(role, action, entity, entityId, detail, previousState, newState, reason), patientId }, ...data.audit],
    notifications: patientId ? [{ id: nextRecordId('NT'), patientId, title: action, detail, createdAt: eventTime(), read: false, relatedEntity: entity, relatedEntityId: entityId }, ...data.notifications] : data.notifications,
  }
}
export function calculateEligibility(patient: Patient, labs: LabResult[]) {
  const hba1c = labs.slice().sort((a,b) => b.date.localeCompare(a.date)).find(item => item.patientId === patient.id && item.test.toLowerCase() === 'hba1c' && item.status !== 'Pending')
  const criteria = [
    { label: 'Adult patient (18+)', passed: patient.age >= 18, evidence: `${patient.age} years` },
    { label: 'BMI at or above 30', passed: Number.isFinite(patient.bmi) && patient.bmi >= 30, evidence: patient.bmi > 0 && Number.isFinite(patient.bmi) ? `${patient.bmi.toFixed(1)} kg/m²` : 'Missing' },
    { label: 'Relevant diagnosis recorded', passed: /diabetes|weight/i.test(patient.diagnosis), evidence: patient.diagnosis || 'Missing' },
    { label: 'HbA1c result available', passed: Boolean(hba1c), evidence: hba1c ? `${hba1c.value} ${hba1c.unit} · ${hba1c.date}` : 'Required lab missing' },
  ]
  const missing = criteria.filter(item => item.evidence === 'Missing' || item.evidence === 'Required lab missing')
  const failed = criteria.filter(item => !item.passed && !missing.includes(item))
  return { eligible: criteria.every(item => item.passed), criteria, missing, failed, warnings: patient.bmi >= 40 ? ['BMI is at or above 40; clinician review is required.'] : [] }
}
export function recordVitals(data: AppData, role: Role, patientId: string, input: Omit<Vital, 'id' | 'patientId' | 'bmi' | 'recordedAt' | 'actor'>): AppData {
  requirePermission(role, 'clinical:write')
  const patient = data.patients.find(item => item.id === patientId)
  if (!patient) throw new Error('Select a patient before recording vitals.')
  requirePatientAccess(data, role, patientId)
  if (Object.values(input).some(value => !Number.isFinite(value)) || input.weightKg < 20 || input.weightKg > 400 || input.heightCm < 80 || input.heightCm > 250 || input.systolic < 50 || input.systolic > 260 || input.diastolic < 30 || input.diastolic > 160 || input.diastolic >= input.systolic || input.heartRate < 30 || input.heartRate > 240) throw new Error('Enter clinically plausible values for weight, height, blood pressure and heart rate.')
  const vital: Vital = { ...input, id: nextRecordId('VT'), patientId, bmi: Number((input.weightKg / ((input.heightCm / 100) ** 2)).toFixed(1)), recordedAt: new Date().toISOString(), actor: role }
  const patients = data.patients.map(item => {
    if (item.id !== patientId) return item
    const updated = { ...item, weightKg: vital.weightKg, heightCm: vital.heightCm, bmi: vital.bmi }
    const result = calculateEligibility(updated, data.labs)
    return { ...updated, eligibility: result.eligible ? 'Meets clinical criteria' as const : result.failed.some(entry => entry.label === 'BMI at or above 30') ? 'Not eligible' as const : 'Review required' as const }
  })
  const next = { ...data, vitals: [vital, ...data.vitals], patients }
  return { ...next, ...eventBundle(next, role, 'Vitals recorded', 'Vital', vital.id, patientId, `BMI ${vital.bmi} · ${vital.weightKg} kg · ${input.systolic}/${input.diastolic} mmHg`) }
}
export function recordLab(data: AppData, role: Role, patientId: string, input: Omit<LabResult, 'id' | 'patientId'>): AppData {
  requirePermission(role, 'clinical:write')
  if (!data.patients.some(item => item.id === patientId)) throw new Error('Select a valid patient before adding a lab result.')
  requirePatientAccess(data, role, patientId)
  if (!input.test.trim() || !input.unit.trim() || !validIsoDate(input.date) || input.date > new Date().toISOString().slice(0, 10) || !Number.isFinite(input.value) || input.value < 0 || !['Normal','Abnormal','Pending'].includes(input.status)) throw new Error('Enter a test, non-negative value, unit and valid collection date no later than today.')
  const lab: LabResult = { ...input, id: nextRecordId('LB'), patientId }
  const labs = [lab, ...data.labs]
  const patients = data.patients.map(item => {
    if (item.id !== patientId) return item
    const updated = input.test.toLowerCase() === 'hba1c' && input.status !== 'Pending' ? { ...item, latestLab: `HbA1c · ${input.value}%` } : item
    const result = calculateEligibility(updated, labs)
    return { ...updated, eligibility: result.eligible ? 'Meets clinical criteria' as const : result.failed.some(entry => entry.label === 'BMI at or above 30') ? 'Not eligible' as const : 'Review required' as const }
  })
  const next = { ...data, labs, patients }
  return { ...next, ...eventBundle(next, role, 'Lab result recorded', 'Lab result', lab.id, patientId, `${input.test} ${input.value} ${input.unit}`) }
}
export function attachPatientDocument(data: AppData, role: Role, patientId: string, input: Pick<CareDocument, 'title' | 'content' | 'fileName' | 'mimeType' | 'dataUrl' | 'sizeBytes' | 'labResultId'>): AppData {
  requirePermission(role, 'clinical:write')
  if (!data.patients.some(item => item.id === patientId)) throw new Error('Select a valid patient before attaching a document.')
  requirePatientAccess(data, role, patientId)
  const accepted = new Set(['application/pdf','image/jpeg','image/png','image/webp','text/plain','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
  if (!input.title.trim() || !input.fileName || !input.mimeType || !accepted.has(input.mimeType) || !input.dataUrl?.startsWith(`data:${input.mimeType};base64,`) || !input.sizeBytes || input.sizeBytes > 750_000) throw new Error('Attach a supported document up to 750 KB.')
  const document: CareDocument = { ...input, id: nextRecordId('DOC'), patientId, authorId: data.patients.find(item => item.id === patientId)?.doctorId ?? 'DOC-001', date: new Date().toISOString().slice(0,10), title: input.title.trim(), content: input.content.trim() }
  const next = { ...data, documents: [...(data.documents ?? []), document] }
  return { ...next, ...eventBundle(next, role, 'Patient document attached', 'Patient document', document.id, patientId, `${document.title} · ${document.fileName}`) }
}
export function saveAssessment(data: AppData, role: Role, assessment: Omit<ClinicalAssessment, 'id' | 'clinician' | 'createdAt'> & { id?: string }): AppData {
  requirePermission(role, 'clinical:write')
  if (!data.patients.some(item => item.id === assessment.patientId)) throw new Error('Select a valid patient before saving an assessment.')
  requirePatientAccess(data, role, assessment.patientId)
  if (!assessment.reason.trim() || !assessment.diagnosis.trim()) throw new Error('Reason for visit and diagnosis are required.')
  if (assessment.status === 'Submitted' && (!assessment.findings.trim() || !assessment.notes.trim())) throw new Error('Add clinical findings and a care plan note before submitting.')
  const old = data.assessments.find(item => item.id === assessment.id)
  const saved: ClinicalAssessment = { ...assessment, id: old?.id ?? nextRecordId('CA'), clinician: role === 'Doctor' ? 'Dr. Laila Hassan' : role, createdAt: old?.createdAt ?? new Date().toISOString() }
  const next = { ...data, assessments: [saved, ...data.assessments.filter(item => item.id !== saved.id)] }
  return { ...next, ...eventBundle(next, role, assessment.status === 'Submitted' ? 'Clinical assessment submitted' : 'Clinical assessment saved', 'Clinical assessment', saved.id, saved.patientId, `${saved.diagnosis} · ${saved.status}`) }
}
export function saveAppointment(data: AppData, role: Role, appointment: Omit<Appointment, 'id'> & { id?: string }): AppData {
  requirePermission(role, 'appointment:manage')
  if (!data.patients.some(item => item.id === appointment.patientId)) throw new Error('Select a patient for this appointment.')
  requirePatientAccess(data, role, appointment.patientId)
  if (!appointment.purpose.trim() || !appointment.doctor || !appointment.centre || !appointment.date || !appointment.time) throw new Error('Enter the purpose, doctor, treatment centre, date and time.')
  if (!data.doctors.some(item => item.name === appointment.doctor && item.status === 'Active')) throw new Error('Select an existing programme doctor that is active.')
  if (!data.centres.some(item => item.name === appointment.centre && item.status === 'Active')) throw new Error('Select an existing programme treatment centre that is active.')
  if (!validIsoDate(appointment.date) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(appointment.time)) throw new Error('Enter a valid calendar date and appointment time.')
  const when = new Date(`${appointment.date}T${appointment.time}`)
  if (Number.isNaN(when.getTime())) throw new Error('Enter a valid appointment date and time.')
  if (!appointment.id && when.getTime() < Date.now() - 60000) throw new Error('A new appointment must be scheduled in the future.')
  if (data.appointments.some(item => item.id !== appointment.id && item.doctor.toLowerCase() === appointment.doctor.toLowerCase() && item.date === appointment.date && item.time === appointment.time && !['Cancelled','No show'].includes(item.status))) throw new Error('That doctor already has an appointment at this date and time.')
  const saved: Appointment = { ...appointment, id: appointment.id ?? nextRecordId('AP') }
  const next = { ...data, appointments: [saved, ...data.appointments.filter(item => item.id !== saved.id)], integratedCarePlans:data.integratedCarePlans?.map(plan=>plan.appointmentId===saved.id?{...plan,followUpDate:saved.date}:plan) }
  return { ...next, ...eventBundle(next, role, appointment.id ? 'Appointment updated' : 'Appointment scheduled', 'Appointment', saved.id, saved.patientId, `${saved.purpose} · ${saved.date} ${saved.time}`) }
}
export function changeAppointmentStatus(data: AppData, role: Role, appointmentId: string, status: Appointment['status']): AppData {
  requirePermission(role, 'appointment:manage')
  const current = data.appointments.find(item => item.id === appointmentId)
  if (!current) throw new Error('Appointment not found.')
  requirePatientAccess(data, role, current.patientId)
  if (['Cancelled', 'Completed', 'No show'].includes(current.status)) throw new Error('This appointment is already closed.')
  if (status === 'Scheduled' || (current.status === 'Confirmed' && status === 'Confirmed')) throw new Error('This appointment transition is not allowed.')
  const appointmentTime = new Date(`${current.date}T${current.time}`).getTime()
  if ((status === 'Completed' || status === 'No show') && appointmentTime > Date.now()) throw new Error('A future appointment cannot be marked completed or no-show.')
  const next = { ...data, appointments: data.appointments.map(item => item.id === appointmentId ? { ...item, status } : item), patients:data.patients.map(p=>p.id===current.patientId&&status==='Completed'?{...p,lastFollowup:!p.lastFollowup||p.lastFollowup==='—'||current.date>p.lastFollowup?current.date:p.lastFollowup}:p) }
  return { ...next, ...eventBundle(next, role, `Appointment ${status.toLowerCase()}`, 'Appointment', appointmentId, current.patientId, current.purpose) }
}
export function recordExercise(data: AppData, role: Role, patientId: string, input: Omit<ExerciseRecord, 'id' | 'patientId'>): AppData {
  requirePermission(role, 'activity:self')
  if (role === 'Patient' && patientId !== (data.activePatientId ?? 'P999')) throw new Error('You can only record activity for your own patient profile.')
  if (!data.patients.some(item => item.id === patientId)) throw new Error('Patient record could not be found.')
  if (!Number.isFinite(input.durationMinutes) || !input.activity.trim() || input.durationMinutes < 1 || input.durationMinutes > 1440 || !validIsoDate(input.date) || !['Light','Moderate','Vigorous'].includes(input.intensity)) throw new Error('Enter a valid activity, duration from 1 to 1440 minutes, intensity and date.')
  if (input.date > new Date().toISOString().slice(0, 10)) throw new Error('Activity date cannot be in the future.')
  if(input.exerciseId){const plan=data.integratedCarePlans?.find(p=>p.id===input.integratedCarePlanId&&p.patientId===patientId&&p.status==='Active');if(!plan?.homeExerciseIds.includes(input.exerciseId)||!data.homeExercises?.some(e=>e.id===input.exerciseId&&e.name===input.activity))throw new Error('Select an exercise assigned in the active care plan.')}
  const exercise: ExerciseRecord = { ...input, id: nextRecordId('EX'), patientId }
  const next = { ...data, exercise: [exercise, ...data.exercise] }
  return { ...next, ...eventBundle(next, role, 'Activity recorded', 'Exercise record', exercise.id, patientId, `${exercise.activity} · ${exercise.durationMinutes} minutes`) }
}
export function restock(data: AppData, role: Role, dose: string, quantity: number, batchNumber: string, expiry: string, centre: string, source: string, receivedAt: string): AppData {
  requirePermission(role, 'inventory:manage')
  if (!supportedDoses.includes(dose as typeof supportedDoses[number])) throw new Error('Select a supported medication strength.')
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 10000) throw new Error('Quantity must be a whole number between 1 and 10,000.')
  if (!batchNumber.trim() || !source.trim() || !expiry || !receivedAt) throw new Error('Batch number, supplier/source, receipt date and expiry are required.')
  if (!data.centres.some(item => item.name === centre && item.status === 'Active')) throw new Error('Select an existing programme treatment centre that is active.')
  if (!validIsoDate(expiry) || expiry <= new Date().toISOString().slice(0, 10)) throw new Error('The batch expires on a valid date after today.')
  if (!validIsoDate(receivedAt) || receivedAt > new Date().toISOString().slice(0, 10) || receivedAt > expiry) throw new Error('Enter a valid receipt date no later than today and before expiry.')
  if (data.batches.some(item => item.batchNumber.toLowerCase() === batchNumber.trim().toLowerCase())) throw new Error('That batch number already exists in inventory.')
  const batch: InventoryBatch = { id: nextRecordId('BT'), dose, batchNumber: batchNumber.trim(), expiry, quantity, centre, receivedAt, source: source.trim() }
  const movement: InventoryMovement = { id: nextRecordId('MV'), dose, batchId: batch.id, type: 'Restock', quantity, centre, actor: role, at: new Date().toISOString(), reference: batchNumber, note: 'Stock received into programme inventory' }
  const next = { ...data, batches: [batch, ...data.batches], movements: [movement, ...data.movements] }
  return { ...next, ...eventBundle(next, role, 'Inventory restocked', 'Inventory batch', batch.id, undefined, `${quantity} units · ${dose} · ${batchNumber}`) }
}
export function markNotificationRead(data: AppData, role: Role, notificationId: string, patientId = 'P999'): AppData {
  const notification = data.notifications.find(item => item.id === notificationId)
  if (!notification) throw new Error('Notification not found.')
  if ((role === 'Patient' && notification.patientId !== patientId) || !canReadPatient(data,role,notification.patientId)) throw new Error('You can only update notifications on your own patient profile.')
  return { ...data, notifications: data.notifications.map(item => item.id === notificationId ? { ...item, read: true } : item) }
}
export function markNotificationsRead(data: AppData, role: Role, patientId = 'P999'): AppData {
  return { ...data, notifications: data.notifications.map(item => (role === 'Patient' && item.patientId !== patientId) || !canReadPatient(data,role,item.patientId) ? item : { ...item, read: true }) }
}
export function dismissAlert(data: AppData, role: Role, alertId: string): AppData {
  requirePermission(role, 'alerts:manage')
  const dismissed = new Set(data.dismissedAlerts ?? [])
  dismissed.add(alertId)
  return { ...data, dismissedAlerts: [...dismissed], audit: [audit(role, 'Alert dismissed', 'Operational alert', alertId, 'Alert dismissed by an administrator'), ...data.audit] }
}
export function markAlertRead(data: AppData, role: Role, alertId: string): AppData {
  requirePermission(role, 'alerts:manage')
  const read = new Set(data.readAlerts ?? [])
  read.add(alertId)
  return { ...data, readAlerts: [...read] }
}

export function updateDoctorProfile(data: AppData, role: Role, doctorId: string, updates: Pick<DoctorProfile, 'centre' | 'status'>): AppData {
  requirePermission(role, 'organization:manage')
  const current = data.doctors.find(item => item.id === doctorId)
  if (!current) throw new Error('Doctor record not found.')
  if (!data.centres.some(item => item.name === updates.centre)) throw new Error('Select an existing treatment centre.')
  const next = {
    ...data,
    doctors: data.doctors.map(item => item.id === doctorId ? { ...item, ...updates, updatedAt: new Date().toISOString() } : item),
    patients: current.centre === updates.centre ? data.patients : data.patients.map(item => item.assignedDoctor === current.name ? { ...item, treatmentCentre: updates.centre } : item),
  }
  const changed = `${current.status} · ${current.centre}`
  const value = `${updates.status} · ${updates.centre}`
  return { ...next, ...eventBundle(next, role, 'Doctor profile updated', 'Doctor', doctorId, undefined, `${current.name} · ${value}`, changed, value) }
}

export function updateCentreStatus(data: AppData, role: Role, centreId: string, status: CareCentre['status']): AppData {
  requirePermission(role, 'organization:manage')
  const current = data.centres.find(item => item.id === centreId)
  if (!current) throw new Error('Treatment centre not found.')
  if (current.status === status) throw new Error(`This centre is already ${status.toLowerCase()}.`)
  if (status === 'Inactive' && data.centres.filter(item => item.status === 'Active').length <= 1) throw new Error('At least one treatment centre must remain active.')
  const next = { ...data, centres: data.centres.map(item => item.id === centreId ? { ...item, status } : item) }
  return { ...next, ...eventBundle(next, role, 'Treatment centre status updated', 'Treatment centre', centreId, undefined, current.name, current.status, status) }
}

export function setAbuseReviewStatus(data: AppData, role: Role, review: Omit<AbuseReviewRecord, 'status' | 'updatedAt'>, status: AbuseReviewRecord['status']): AppData {
  requirePermission(role, 'organization:manage')
  const current = data.abuseReviews.find(item => item.id === review.id)
  const saved: AbuseReviewRecord = { ...current, ...review, status, updatedAt: new Date().toISOString() }
  const next = { ...data, abuseReviews: [saved, ...data.abuseReviews.filter(item => item.id !== saved.id)] }
  return { ...next, ...eventBundle(next, role, `Safety signal ${status.toLowerCase()}`, 'Safety review', review.id, review.patientId, `${review.eventType} · ${review.evidence}`, current?.status ?? 'New', status) }
}


// Stable, linked demonstration scenarios. No generated probabilities or external model.
let recordSequence = 0
function nextRecordId(prefix: string) { return `${prefix}-${Date.now()}-${++recordSequence}` }

export function releaseToPharmacy(data: AppData, role: Role, requestId: string): AppData {
  requirePermission(role, 'request:review')
  const request = data.requests.find(item => item.id === requestId)
  if (!request || request.status !== 'Approved') throw new Error('Only an approved request can be released to pharmacy.')
  // Reuse the same evidence validation as a fresh approval, preserving one approval policy.
  return decide({ ...data, requests: data.requests.map(item => item.id === requestId ? { ...item, status: 'Under review' } : item) }, role, requestId, 'approve', 'Approved evidence reviewed and released to pharmacy.')
}
export function completeTreatment(data: AppData, role: Role, requestId: string, reason: string): AppData {
  requirePermission(role, 'clinical:write')
  const request = data.requests.find(item => item.id === requestId)
  if (!request || request.status !== 'Dispensed') throw new Error('Only a dispensed treatment can be completed.')
  requirePatientAccess(data, role, request.patientId)
  if (reason.trim().length < 8) throw new Error('Record a follow-up summary of at least 8 characters.')
  const next: AppData = { ...data, requests: data.requests.map(item => item.id === requestId ? { ...item, status: 'Completed' } : item), treatmentPlans: data.treatmentPlans.map(item => item.id === request.planId ? { ...item, status: 'Completed' } : item) }
  return { ...next, ...eventBundle(next, role, 'Treatment completed', 'Treatment request', requestId, request.patientId, reason, 'Dispensed', 'Completed', reason) }
}
export type PatientRegistration = { name: string; nameAr?: string; age: number; sex: string; centreId: string; doctorId: string; residency?: PatientType; nationality?: string; emiratesId?: string; diagnosis?: string; fastingGlucose?: string; previousIllnesses?: string[]; chronicConditions?: string[]; procedures?: Patient['procedures'] }
export type PatientIntake = { patient: PatientRegistration; vitals?: Omit<Vital, 'id' | 'patientId' | 'bmi' | 'recordedAt' | 'actor'>; labs?: Omit<LabResult, 'id' | 'patientId'>[]; assessment?: Omit<ClinicalAssessment, 'id' | 'patientId' | 'clinician' | 'createdAt'>; appointment?: Pick<Appointment, 'purpose' | 'date' | 'time' | 'notes'>; documents?: Pick<CareDocument, 'title' | 'content' | 'fileName' | 'mimeType' | 'dataUrl' | 'sizeBytes'>[] }
export function registerPatient(data: AppData, role: Role, input: PatientRegistration): AppData {
  if (role !== 'Admin' && role !== 'Doctor') throw new Error('This role cannot register patients; only administrators and treating doctors may do so.')
  if (role === 'Doctor' && input.doctorId !== (data.activeDoctorId??data.doctors[0]?.id)) throw new Error('Doctors can register patients only under their own assignment.')
  const centre = data.centres.find(item => item.id === input.centreId && item.status === 'Active')
  const doctor = data.doctors.find(item => item.id === input.doctorId && item.status === 'Active')
  if (input.name.trim().length < 3 || !Number.isInteger(input.age) || input.age < 18 || input.age > 120 || !centre || !doctor) throw new Error('Enter a full name, adult age, active centre and doctor.')
  if (input.residency && !['Citizen','Resident','Visitor'].includes(input.residency)) throw new Error('Select a valid patient type.')
  const identity = input.emiratesId?.trim()
  if (identity && data.patients.some(item => item.emiratesId === identity)) throw new Error('A patient with this identity number already exists.')
  const patient: Patient = { ...input, registeredAt:new Date().toISOString().slice(0,10), nameAr: input.nameAr?.trim(), nationality: input.nationality?.trim(), emiratesId: identity, diagnosis: input.diagnosis?.trim() ?? '', fastingGlucose: input.fastingGlucose?.trim(), residency: input.residency ?? 'Resident', id: nextRecordId('P'), name: input.name.trim(), assignedDoctor: doctor.name, treatmentCentre: centre.name, emirate: centre.emirate, bmi: 0, latestLab: 'Not recorded', adherence: 0, eligibility: 'Review required', treatmentStatus: 'No active plan', isActive: true }
  const next = { ...data, patients: [...data.patients, patient] }
  return { ...next, ...eventBundle(next, role, 'Patient registered', 'Patient', patient.id, patient.id, patient.name) }
}
export function registerPatientWithIntake(data: AppData, role: Role, input: PatientIntake): AppData {
  let next = registerPatient(data, role, input.patient)
  const patientId = next.patients.at(-1)!.id
  if (input.vitals) next = recordVitals(next, role, patientId, input.vitals)
  for (const lab of input.labs ?? []) next = recordLab(next, role, patientId, lab)
  if (input.assessment) next = saveAssessment(next, role, { ...input.assessment, patientId })
  if (input.appointment) {
    const centre = next.centres.find(item => item.id === input.patient.centreId)!
    const doctor = next.doctors.find(item => item.id === input.patient.doctorId)!
    next = saveAppointment(next, role, { ...input.appointment, patientId, doctor: doctor.name, centre: centre.name, status: 'Scheduled' })
  }
  const accepted = new Set(['application/pdf','image/jpeg','image/png','image/webp','text/plain','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
  const documents = input.documents ?? []
  if (documents.some(item => !item.title.trim() || !item.fileName || !item.mimeType || !accepted.has(item.mimeType) || !item.dataUrl?.startsWith(`data:${item.mimeType};base64,`) || !item.sizeBytes || item.sizeBytes > 750_000) || documents.reduce((sum, item) => sum + (item.sizeBytes ?? 0), 0) > 1_500_000) throw new Error('Upload supported files up to 750 KB each and 1.5 MB total.')
  if (documents.length) next = { ...next, documents: [...(next.documents ?? []), ...documents.map(item => ({ ...item, id: nextRecordId('DOC'), patientId, authorId: input.patient.doctorId, date: new Date().toISOString().slice(0,10), title: item.title.trim(), content: item.content.trim() }))] }
  return next
}
export function careRisk(data: AppData, patientId: string) {
  const patient = data.patients.find(item => item.id === patientId)
  if (!patient) return { level: 'Missing data', reasons: ['Patient record unavailable'] }
  const readings = data.vitals.filter(item => item.patientId === patientId).sort((a,b) => a.recordedAt.localeCompare(b.recordedAt))
  const reasons: string[] = []
  if (patient.bmi >= 40) reasons.push('Recorded BMI is at or above the demonstration review threshold of 40.')
  if (readings.length > 1 && readings.at(-1)!.weightKg > readings[0].weightKg) reasons.push('Recorded weight has increased since the first measurement.')
  if (data.dispenses.some(item => item.patientId === patientId) && adherenceFor(data, patientId) < 50) reasons.push('Fewer than two dose days recorded in the last 28 days.')
  if (!data.labs.some(item => item.patientId === patientId && item.status !== 'Pending')) reasons.push('Laboratory evidence is missing.')
  return { level: reasons.length > 1 ? 'Priority review' : reasons.length ? 'Review suggested' : 'Routine follow-up', reasons }
}
export function patientJourney(data: AppData, patientId: string) {
  const requests = data.requests.filter(item => item.patientId === patientId)
  const stages = [
    ['Registration', data.patients.some(item => item.id === patientId)],
    ['Assessment', data.assessments.some(item => item.patientId === patientId && item.status === 'Submitted')],
    ['Lab evidence', data.labs.some(item => item.patientId === patientId && item.status !== 'Pending')],
    ['Human review', requests.some(item => ['Approved','Ready to dispense','Dispensed','Completed'].includes(item.status))],
    ['Dispensing', data.dispenses.some(item => item.patientId === patientId)],
    ['Continuous care', data.integratedCarePlans?.some(plan => plan.patientId === patientId && plan.status === 'Active') || data.doses.some(item => item.patientId === patientId) || data.exercise.some(item => item.patientId === patientId)],
    ['Follow-up', data.appointments.some(item => item.patientId === patientId && item.status === 'Completed')],
  ] as const
  return stages.map(([label, complete]) => ({ label, complete }))
}
export function canonicalize(data: AppData): AppData {
  const centreId=(name:string)=>data.centres.find(item=>item.name===name)?.id
  const clinicianId=(name:string)=>data.doctors.find(item=>item.name===name)?.id ?? data.reviewers.find(item=>item.name===name)?.id
  const medicationId=(name:string)=>data.medications?.find(item=>item.name===name)?.id ?? (name==='Mounjaro'?'MED-001':undefined)
  return { ...data,
    financial:data.financial.map(item=>({...item,coverage:calculateCoverage(data.patients.find(p=>p.id===item.patientId)?.residency ?? 'Visitor',item.amountAED)})),
    doctors:data.doctors.map(item=>({...item,centreId:centreId(item.centre)})),
    requests:data.requests.map(item=>({...item,reviewerId:item.reviewer?clinicianId(item.reviewer):undefined,medicationId:medicationId(item.medication??'Mounjaro')})),
    treatmentPlans:data.treatmentPlans.map(item=>({...item,medicationId:medicationId(item.medication)})),
    assessments:data.assessments.map(item=>({...item,clinicianId:clinicianId(item.clinician)})),
    appointments:data.appointments.map(item=>({...item,doctorId:clinicianId(item.doctor),centreId:centreId(item.centre)})),
    batches:data.batches.map(item=>({...item,centreId:centreId(item.centre),medicationId:'MED-001'})),
    movements:data.movements.map(item=>({...item,centreId:centreId(item.centre)})),
    dispenses:data.dispenses.map(item=>({...item,centreId:centreId(item.centre),pharmacistId:item.pharmacistId??'PH-001'})),
    audit:data.audit.map(item=>({...item,patientId:item.patientId??data.requests.find(request=>request.id===item.entityId)?.patientId})),
    patients: data.patients.map(patient => {
    const eligibility = calculateEligibility(patient, data.labs)
    const latestLab = data.labs.filter(item=>item.patientId===patient.id && item.test.toLowerCase()==='hba1c' && item.status!=='Pending').sort((a,b)=>b.date.localeCompare(a.date))[0]
    const active = data.requests.some(item => item.patientId === patient.id && item.status === 'Dispensed')
    return { ...patient, nameAr:patient.nameAr==='مستفيد البرنامج'?arabicNameFor(patient.name)??patient.nameAr:patient.nameAr, latestLab: latestLab ? `HbA1c · ${latestLab.value}%` : 'Not recorded', doctorId: data.doctors.find(item => item.name === patient.assignedDoctor)?.id, centreId: data.centres.find(item => item.name === patient.treatmentCentre)?.id, emirateId: `EM-${emirates.indexOf(patient.emirate) + 1}`, eligibility: !refillEligibility(data,patient.id).eligible ? 'Refill timing' : eligibility.eligible ? 'Meets clinical criteria' : eligibility.failed.length ? 'Not eligible' : 'Review required', treatmentStatus: active ? 'Active' : 'No active plan', adherence: adherenceFor(data, patient.id) }
  }) }
}

// Each scenario has its own request, evidence, plan and audit trail.
for (const [patientId, status, dose] of [
  ['P001','Dispensed','5 mg'], ['P002','Dispensed','2.5 mg'],
  ['P004','Under review','7.5 mg'], ['P005','Rejected','5 mg'],
  ['P006','Needs information','7.5 mg'], ['P007','Ready to dispense','10 mg'],
  ['P008','Under review','2.5 mg'], ['P009','Dispensed','5 mg'],
] as [string, RequestStatus, string][]) {
  const person = seed.patients.find(item => item.id === patientId)!
  const id = `TR-DEMO-${patientId}`
  const planId = `TP-DEMO-${patientId}`
  const dispensed = status === 'Dispensed'
  const started = dispensed ? '2026-09-03' : '2026-09-29'
  seed.requests.push({ id, patientId, planId, status, dose, medication: 'Mounjaro', created: started, createdAt: `${started}T08:00:00.000Z`, prescriptionId: dispensed || status === 'Ready to dispense' ? `RX-${patientId}` : undefined, approvalExpiresAt: '2026-10-31', reviewer: dispensed || status === 'Ready to dispense' || status === 'Rejected' ? 'Dr. Mariam Nasser' : undefined, note: status === 'Rejected' ? 'Demonstration criteria not met; return to clinician for an alternative care plan.' : status === 'Needs information' ? 'Laboratory evidence is pending. Obtain the result before review.' : undefined })
  seed.treatmentPlans.push({ id: planId, patientId, medication: 'Mounjaro', dose, frequency: 'Weekly', durationDays: 84, startDate: started, endDate: dispensed ? '2026-11-25' : '2026-12-21', followUpDate: '2026-10-15', indication: person.diagnosis, instructions: 'Follow the approved clinician prescription.', monitoringPlan: 'Review recorded symptoms, laboratory evidence and progress at follow-up.', status: status === 'Ready to dispense' ? 'Pharmacy ready' : status })
  seed.assessments.push({ id: `CA-DEMO-${patientId}`, patientId, reason: 'Weight management and metabolic follow-up', diagnosis: person.diagnosis, symptoms: 'No acute symptoms recorded', medicalHistory: person.diagnosis, medications: dispensed ? `Mounjaro ${dose}` : 'Medication reconciliation completed', allergies: 'No known allergies recorded', findings: 'Review current vitals and laboratory evidence.', notes: 'Shared care plan with follow-up and activity support.', status: 'Submitted', clinician: person.assignedDoctor!, createdAt: `${started}T08:00:00.000Z` })
  if (patientId !== 'P006') seed.labs.push({ id: `LB-DEMO-${patientId}`, patientId, test: 'HbA1c', value: Number(person.latestLab.match(/(?:·|:)\s*([0-9.]+)/)?.[1] ?? 6.5), unit: '%', reference: 'Demo evidence only', status: 'Abnormal', date: started, source: person.treatmentCentre!, interpretation: 'Review with the treating clinician.' })
  seed.vitals.push({ id: `VT-DEMO-${patientId}`, patientId, weightKg: person.weightKg!, heightCm: person.heightCm!, bmi: person.bmi, systolic: 128, diastolic: 82, heartRate: 76, recordedAt: `${started}T08:00:00.000Z`, actor: 'Doctor' })
  seed.audit.push({ id: `EV-DEMO-${patientId}`, patientId, actor: status === 'Under review' ? 'Doctor' : 'Reviewer', action: status === 'Rejected' ? 'Request rejected' : status === 'Needs information' ? 'Information requested' : 'Care pathway updated', entity: 'Treatment request', entityId: id, time: '10:00', occurredAt: `${started}T10:00:00.000Z`, detail: `${person.name} · ${status}`, newState: status })
  if (dispensed) {
    const batch = seed.batches.find(item => item.dose === dose)!
    seed.dispenses.push({ id: `DSP-DEMO-${patientId}`, patientId, requestId: id, dose, batchId: batch.id, centre: batch.centre, date: started, dispensedAt: `${started}T10:30:00.000Z` })
    seed.movements.push({ id: `MV-DEMO-${patientId}`, batchId: batch.id, dose, quantity: -1, type: 'Dispensing', centre: batch.centre, actor: 'Pharmacist', at: `${started}T10:30:00.000Z`, reference: `DSP-DEMO-${patientId}`, note: 'Linked demonstration dispensing' })
    batch.quantity -= 1
    seed.financial.push({ id: `FIN-DEMO-${patientId}`, patientId, requestId: id, amountAED: 1200, status: 'Estimated', assessedAt: `${started}T10:30:00.000Z` })
    for (const day of patientId === 'P002' ? [10] : [10,17,24]) seed.doses.push({ id: `DO-DEMO-${patientId}-${day}`, patientId, requestId: id, dose, status: 'Taken', recordedAt: `2026-09-${day}T06:00:00.000Z` })
  }
  seed.notifications.push({ id: `NT-DEMO-${patientId}`, patientId, title: 'Care plan update', detail: `${status}. View your care record for the next step.`, createdAt: `${started}T10:00:00.000Z`, read: false, relatedEntity: 'Treatment request', relatedEntityId: id })
}
Object.assign(seed.patients.find(item => item.id === 'P005')!,{bmi:27.1,weightKg:83})
seed.vitals.filter(item=>item.patientId==='P005').forEach(item=>{item.bmi=27.1;item.weightKg=83})
seed.batches.push({ id: 'BT-EXPIRED', dose: '7.5 mg', batchNumber: 'UAE-75-2026-OLD', quantity: 6, expiry: '2026-09-20', receivedAt: '2026-03-01', centre: 'Sharjah Health Centre', source: 'Gulf Medical Supply LLC' })
seed.movements.push({ id: 'MV-EXPIRED', batchId: 'BT-EXPIRED', dose: '7.5 mg', quantity: 6, type: 'Receiving', centre: 'Sharjah Health Centre', actor: 'Admin', at: '2026-03-01T09:00:00.000Z', reference: 'GRN-OLD', note: 'Expired batch excluded from available stock' })
seed.carePrograms = [{ id: 'REH-P999', patientId: 'P999', clinicianId: 'DOC-001', title: 'Mobility and daily movement', activities: ['Supported mobility', 'Home exercise', 'Walking'], weeklySessions: 3, reviewDate: '2026-10-15', status: 'Active' }, { id: 'REH-P001', patientId: 'P001', clinicianId: 'DOC-002', title: 'Supervised return to activity', activities: ['Physiotherapy', 'Home exercise'], weeklySessions: 2, reviewDate: '2026-10-12', status: 'Active' }]
seed.documents = [{ id: 'DOC-P999-CARE', patientId: 'P999', title: 'Shared care summary', authorId: 'DOC-001', date: '2026-09-18', content: 'Demonstration care summary. Review the linked clinical assessment, current prescription, laboratory evidence and scheduled follow-up. Medication decisions remain with the treating clinician.' }]
seed.exercise.push({ id: 'EX-REH-01', patientId: 'P999', activity: 'Home exercise', durationMinutes: 15, intensity: 'Light', date: '2026-09-28', notes: 'Completed the prescribed mobility session.' })
seed.vitals.push({ id: 'VT-P999-HISTORY', patientId: 'P999', weightKg: 124, heightCm: 175, bmi: 40.5, systolic: 134, diastolic: 84, heartRate: 78, recordedAt: '2026-08-18T08:00:00.000Z', actor: 'Doctor' })
// Additional linked scenarios: partial evidence, early refill, historic completion,
// multi-centre stock and blocked attempts (never duplicate successful dispensing).
seed.labs = seed.labs.filter(item => item.patientId !== 'P006')
seed.labs.push({id:'LB-P006-PENDING',patientId:'P006',test:'HbA1c',value:0,unit:'%',reference:'Pending',status:'Pending',date:'2026-09-29',source:'Sharjah Health Centre',interpretation:'Awaiting laboratory result.'})
const currentPlan = seed.treatmentPlans.find(item=>item.id==='TP-8781')!
currentPlan.durationDays=168
currentPlan.endDate='2026-11-26'
const oldPlan: TreatmentPlan = {...currentPlan,id:'TP-P999-HISTORY',dose:'5 mg',startDate:'2026-02-01',endDate:'2026-04-25',durationDays:84,followUpDate:'2026-03-01',status:'Completed'}
seed.treatmentPlans.push(oldPlan)
seed.requests.push({id:'TR-P999-HISTORY',patientId:'P999',planId:oldPlan.id,status:'Completed',dose:'5 mg',created:'2026-02-01',createdAt:'2026-02-01T08:00:00.000Z',reviewer:'Dr. Mariam Nasser',note:'Previous treatment course completed with clinical follow-up.'})
seed.appointments.push({id:'AP-P999-COMPLETE',patientId:'P999',doctor:'Dr. Laila Hassan',centre:'Dubai Primary Care Centre 4',purpose:'Treatment course follow-up',date:'2026-04-25',time:'09:00',status:'Completed',notes:'Reviewed treatment response and documented next care steps.'})
const refillSource = seed.requests.find(item=>item.id==='TR-DEMO-P009')!
const refillPlan = seed.treatmentPlans.find(item=>item.id===refillSource.planId)!
const priorDispense = seed.dispenses.find(item=>item.requestId===refillSource.id)!
priorDispense.date='2026-09-24';priorDispense.dispensedAt='2026-09-24T05:00:00.000Z'
seed.doses=seed.doses.filter(item=>item.patientId!=='P009'||item.recordedAt.slice(0,10)>='2026-09-24')
const priorMovement=seed.movements.find(item=>item.reference===priorDispense.id)!
priorMovement.at=priorDispense.dispensedAt
seed.requests.push({...refillSource,id:'TR-P009-REFILL',planId:'TP-P009-REFILL',status:'Ready to dispense',prescriptionId:'RX-P009-REFILL',created:'2026-09-30',createdAt:'2026-09-30T10:00:00.000Z',note:'Refill presented before the demonstration interval; pharmacy must block collection.'})
seed.treatmentPlans.push({...refillPlan,id:'TP-P009-REFILL',status:'Pharmacy ready'})
for (const [id,dose,quantity,centre] of [['BT-AUH','2.5 mg',20,'Abu Dhabi Primary Care Centre 2'],['BT-SHJ','7.5 mg',12,'Sharjah Health Centre']] as [string,string,number,string][]) {
  seed.batches.push({id,dose,quantity,centre,batchNumber:`UAE-${id}-2026`,expiry:'2027-02-28',receivedAt:'2026-09-20',source:'Gulf Medical Supply LLC'})
  seed.movements.push({id:`MV-${id}`,batchId:id,dose,quantity,centre,type:'Receiving',actor:'Pharmacist',at:'2026-09-20T09:00:00.000Z',reference:`GRN-${id}`,note:'Regional replenishment received'})
}
seed.audit.push({id:'EV-DUPLICATE-ATTEMPT',actor:'Pharmacist',action:'Duplicate dispensing attempt blocked',entity:'Treatment request',entityId:'TR-DEMO-P001',patientId:'P001',time:'09:00',occurredAt:'2026-09-29T09:00:00.000Z',detail:'Existing DSP-DEMO-P001 found. No additional stock or dispensing transaction was committed.'})
seed.audit.push({id:'EV-EARLY-REFILL',actor:'Pharmacist',action:'Early refill blocked',entity:'Treatment request',entityId:'TR-P009-REFILL',patientId:'P009',time:'11:00',occurredAt:'2026-09-30T11:00:00.000Z',detail:'Collection before the next monthly dispensing date. Referred to the care team.'})
seed.pharmacists=[{id:'PH-001',name:'Noor Al Hashmi',nameAr:'نور الهاشمي',centreId:'CTR-DXB-01'},{id:'PH-002',name:'Salem Al Kaabi',nameAr:'سالم الكعبي',centreId:'CTR-AUH-02'}]
seed.medications=[{id:'MED-001',name:'Mounjaro',strengths:[...supportedDoses],frequencies:['Weekly'],status:'Supported',unitCostAED:1200}]
seed.emirates=emirates.map((name,index)=>({id:`EM-${index+1}`,name}))
// Each added patient has clinical context, three recorded tests and a follow-up.
for(const [i,patient] of seed.patients.slice(51).entries()) {
 const date=patient.lastFollowup!,creatinine=Number((0.65+i%9*0.09).toFixed(2)),glucose=95+i*11%92
 seed.labs.push(
  {id:`LB-${patient.id}-GLU`,patientId:patient.id,test:'Fasting glucose',value:glucose,unit:'mg/dL',reference:'70–99 mg/dL',status:glucose>99?'Abnormal':'Normal',date,source:patient.treatmentCentre!,interpretation:'Illustrative result; review with the recorded clinical assessment.'},
  {id:`LB-${patient.id}-CRE`,patientId:patient.id,test:'Creatinine',value:creatinine,unit:'mg/dL',reference:'0.6–1.3 mg/dL',status:creatinine>1.3?'Abnormal':'Normal',date,source:patient.treatmentCentre!,interpretation:'Demonstration laboratory record for care-team review.'})
 seed.assessments.push({id:`CA-${patient.id}-INTAKE`,patientId:patient.id,reason:i%3?'Metabolic follow-up':'Weight management assessment',diagnosis:patient.diagnosis,
  symptoms:'No acute symptoms reported at the demonstration visit.',medicalHistory:patient.diagnosis,medications:'Medication reconciliation documented; no programme prescription issued.',
  allergies:'No known allergies reported in this demo record.',findings:'Vital signs and laboratory evidence recorded for review.',notes:'Review laboratory results and agree the next care step with the patient.',status:'Submitted',clinician:patient.assignedDoctor!,createdAt:`${date}T08:00:00.000Z`})
 seed.appointments.push({id:`AP-${patient.id}-FOLLOWUP`,patientId:patient.id,doctor:patient.assignedDoctor!,centre:patient.treatmentCentre!,purpose:'Review lab results',
  date:`2026-10-${String(3+Math.floor(i/6)).padStart(2,'0')}`,time:`${String(9+Math.floor((i%6)/2)).padStart(2,'0')}:${i%2?'30':'00'}`,status:i%3?'Scheduled':'Confirmed',notes:'Review the saved lab reports and clinical assessment.'})
}
Object.assign(seed, canonicalize(initializeCareEcosystem(seed)))
const sharedSummary = seed.documents?.find(item => item.id === 'DOC-P999-CARE')
if (sharedSummary) {
  const summaryText = `SHARED CARE SUMMARY / ملخص الرعاية المشتركة\nPatient / المريض: Ahmed Al Mansoori (P999)\nClinical assessment, treatment and follow-up are linked in the shared record.\nالتقييم السريري والعلاج والمتابعة مترابطة في السجل المشترك.\nDemonstration document; verify clinical decisions with the treating clinician.`
  sharedSummary.fileName = 'P999-care-summary.txt'
  sharedSummary.mimeType = 'text/plain'
  sharedSummary.dataUrl = `data:text/plain;charset=utf-8,${encodeURIComponent(summaryText)}`
  sharedSummary.sizeBytes = new TextEncoder().encode(summaryText).length
}
// Downloadable demonstration reports are generated from each patient's actual seeded lab record.
seed.documents = [...(seed.documents ?? []), ...seed.patients.flatMap(patient => {
  const lab = seed.labs.filter(item => item.patientId === patient.id).sort((a,b) => b.date.localeCompare(a.date))[0]
  if (!lab) return []
  const result = lab.status === 'Pending' ? 'Pending' : `${lab.value} ${lab.unit}`
  const report = [`LABORATORY REPORT / تقرير تحليل · DEMONSTRATION DATA / بيانات تجريبية`,`Patient / المريض: ${patient.name} (${patient.id})${patient.nameAr?` · ${patient.nameAr}`:''}`,`Test / التحليل: ${lab.test}`,`Collected / تاريخ السحب: ${lab.date}`,`Result / النتيجة: ${result}`,`Reference / النطاق المرجعي: ${lab.reference}`,`Status / الحالة: ${lab.status}`,`Laboratory / المختبر: ${lab.source}`,`Interpretation / التفسير: ${lab.interpretation}`].join('\n')
  return [{ id: `DOC-${patient.id}-${lab.id}`, patientId: patient.id, title: `${lab.test} laboratory report`, authorId: patient.doctorId ?? 'DOC-001', date: lab.date, content: lab.status === 'Pending' ? `${lab.test} · pending · ${lab.source}` : `${lab.test} · ${result} · ${lab.status} · ${lab.source}`, fileName: `${patient.id}-${lab.test.toLowerCase()}-${lab.date}.txt`, mimeType: 'text/plain', dataUrl: `data:text/plain;charset=utf-8,${encodeURIComponent(report)}`, sizeBytes: new TextEncoder().encode(report).length }]
})]

export type VerificationCheck = { id: string; label: string; passed: boolean; evidence: string }
export function verifyPharmacyRequest(data: AppData, requestId: string, identityConfirmed = false): VerificationCheck[] {
  const request = data.requests.find(item=>item.id===requestId)
  const patient = data.patients.find(item=>item.id===request?.patientId)
  const now = Date.now(), today = new Date(now).toISOString().slice(0,10)
  const refill=patient?refillEligibility(data,patient.id,today):undefined
  const candidates = data.batches.filter(item=>item.dose===request?.dose && item.quantity>0 && item.expiry>today).sort((a,b)=>a.expiry.localeCompare(b.expiry))
  const queued = data.requests.filter(item=>item.status==='Ready to dispense' && item.dose===request?.dose).slice().sort((a,b)=>(a.createdAt??'').localeCompare(b.createdAt??''))
  const position = queued.findIndex(item=>item.id===requestId)
  const available = request ? inventoryByDose(data)[request.dose]??0 : 0
  const reservation = request && position>=0 && position<(reservedByDose(data)[request.dose]??0)
  return [
    {id:'identity',label:'Patient identity',passed:Boolean(patient && identityConfirmed),evidence:patient ? `${patient.name} · ${patient.id}${identityConfirmed ? ' · confirmed at collection' : ' · confirmation required'}` : 'Linked patient is missing'},
    {id:'prescription',label:'Prescription',passed:Boolean(request?.prescriptionId),evidence:request?.prescriptionId??'No prescription linked'},
    {id:'approval',label:request?.approvalRoute==='Automatic'?'System eligibility authorization':'Exception review approval',passed:Boolean(request?.status==='Ready to dispense' && request.approvalExpiresAt && validIsoDate(request.approvalExpiresAt) && request.approvalExpiresAt>=today),evidence:`${request?.approvalRoute==='Automatic'?'Eligibility rules':request?.reviewer??'Reviewer not recorded'} · ${request?.approvalExpiresAt??'Authorization expiry missing'}`},
    {id:'dose',label:'Medication and dose',passed:Boolean(request && (request.medication??'Mounjaro')==='Mounjaro' && supportedDoses.includes(request.dose as typeof supportedDoses[number])),evidence:request ? `${request.medication??'Mounjaro'} · ${request.dose}` : 'Request not found'},
    {id:'duplicate',label:'Duplicate dispensing',passed:!data.dispenses.some(item=>item.requestId===requestId),evidence:data.dispenses.some(item=>item.requestId===requestId)?'This request was already dispensed':'No dispensing recorded for this request'},
    {id:'refill',label:'Monthly refill timing',passed:Boolean(refill?.eligible||request?.exceptionApproved),evidence:refill?.lastDispense?`${refill.lastDispense.date} last dispensed · next regular date ${refill.nextEligibleDate}${!refill.eligible&&request?.exceptionApproved?' · reviewer exception approved':''}`:'No previous dispensing recorded'},
    {id:'evidence',label:'Clinical evidence',passed:Boolean(patient && data.assessments.some(item=>item.patientId===patient.id && item.status==='Submitted') && data.labs.some(item=>item.patientId===patient.id && item.test.toLowerCase()==='hba1c' && item.status!=='Pending')),evidence:'Submitted assessment and recorded HbA1c required'},
    {id:'stock',label:'Stock allocation',passed:Boolean(reservation || available>0),evidence:reservation?'One unit reserved for this request':`${available} unreserved units available`},
    {id:'batch',label:'Batch and expiry',passed:candidates.length>0,evidence:candidates[0]?`${candidates[0].batchNumber} · ${candidates[0].centre} · expires ${candidates[0].expiry}`:'No unexpired batch available'},
  ]
}
export function dispenseMedication(data: AppData, role: Role, requestId: string, identityConfirmed: boolean): AppData {
  requirePermission(role,'request:dispense')
  const checks=verifyPharmacyRequest(data,requestId,identityConfirmed)
  const failed=checks.filter(item=>!item.passed)
  if(failed.length) throw new Error(failed.map(item=>`${item.label}: ${item.evidence}`).join('. '))
  const next=decide(data,role,requestId,'dispense')
  const request=next.requests.find(item=>item.id===requestId)!
  return {...next,audit:[{...audit(role,'Pharmacy verification completed','Treatment request',requestId,'Identity attested; prescription, approval, dose, refill, evidence and batch checks passed.'),patientId:request.patientId,metadata:Object.fromEntries(checks.map(item=>[item.id,item.evidence]))},...next.audit]}
}

/** Snapshot medication-only coverage; rehabilitation fees never enter pharmacy collection. */
export function medicationCoverageForRequest(data:AppData,requestId:string):CoverageResult {
  const saved=data.payments?.find(p=>p.requestId===requestId)?.coverage??data.dispenses.find(d=>d.requestId===requestId)?.medicationCoverage
  if(saved)return {...saved}
  const request=data.requests.find(r=>r.id===requestId)
  const patient=data.patients.find(p=>p.id===request?.patientId)
  if(!request||!patient)throw new Error('Patient and prescription records are required.')
  const medication=request.medicationId?data.medications?.find(m=>m.id===request.medicationId):data.medications?.find(m=>m.name===(request.medication??'Mounjaro'))
  if(!medication||!Number.isFinite(medication.unitCostAED)||medication.unitCostAED<0)throw new Error('A valid medication price is required before dispensing.')
  return calculateCoverage(patient.residency??'Visitor',medication.unitCostAED)
}

/** One local commit: any validation failure leaves stock and payment unchanged. */
export function completePharmacyCheckout(data:AppData,role:Role,requestId:string,identityVerified:boolean,method:PaymentRecord['method']):AppData {
  const coverage=medicationCoverageForRequest(data,requestId)
  if(coverage.patientAED>0&&!['Cash','Card'].includes(method))throw new Error('Choose cash or card for the patient amount due.')
  const next=data.dispenses.some(d=>d.requestId===requestId)?data:dispenseMedication(data,role,requestId,identityVerified)
  return recordDispensingPayment(next,role,requestId,method)
}

export function recordDispensingPayment(data:AppData,role:Role,requestId:string,method:PaymentRecord['method']):AppData {
  requirePermission(role,'request:dispense')
  const dispense=data.dispenses.find(item=>item.requestId===requestId)
  const request=data.requests.find(item=>item.id===requestId)
  const patient=data.patients.find(item=>item.id===request?.patientId)
  if(!dispense||!request||!patient||request.status!=='Dispensed')throw new Error('Confirm dispensing before recording payment.')
  if((data.payments??[]).some(item=>item.requestId===requestId))throw new Error('Payment was already recorded for this request.')
  const coverage=medicationCoverageForRequest(data,requestId)
  const amountAED=coverage.patientAED
  if(amountAED>0&&!['Cash','Card'].includes(method))throw new Error('Choose cash or card for the patient amount due.')
  const recordedMethod:PaymentRecord['method']=amountAED===0?'Covered':method
  const paidAt=new Date().toISOString(),id=nextRecordId('PAY'),receiptNumber=nextRecordId('RCT')
  const payment:PaymentRecord={id,requestId,dispenseId:dispense.id,patientId:patient.id,method:recordedMethod,coverage,amountAED,paidAt,receiptNumber}
  return {...data,payments:[payment,...(data.payments??[])],notifications:[{id:nextRecordId('NT'),patientId:patient.id,title:'Dispensing receipt',detail:`Receipt ${receiptNumber} · ${amountAED} AED · ${recordedMethod}`,createdAt:eventTime(),read:false,relatedEntity:'Pharmacy documents',relatedEntityId:requestId},...data.notifications],audit:[audit(role,'Dispensing payment recorded','Treatment request',requestId,`${receiptNumber} · ${amountAED} AED · ${recordedMethod}`),...data.audit]}
}

export function requestStockSupply(data:AppData,role:Role,dose:string,centre:string,quantity:number):AppData {
  requirePermission(role,'inventory:manage')
  if(!supportedDoses.includes(dose as typeof supportedDoses[number])||!data.centres.some(item=>item.name===centre)||!Number.isInteger(quantity)||quantity<1)throw new Error('Select a valid medication strength, centre and positive quantity.')
  if((data.supplyRequests??[]).some(item=>item.dose===dose&&item.centre===centre&&item.status==='Requested'))throw new Error('A supply request is already open for this strength and centre.')
  const item:SupplyRequest={id:nextRecordId('SUP'),dose,centre,quantity,createdAt:new Date().toISOString(),status:'Requested'}
  return {...data,supplyRequests:[item,...(data.supplyRequests??[])],audit:[audit(role,'Stock supply requested','Medication inventory',item.id,`${dose} · ${centre} · ${quantity} units`),...data.audit]}
}

/** Normalized read model. Views of existing records are derived, never separately stored mocks. */
export function domainGraph(data: AppData) {
  const patientFor = (id: string) => data.patients.find(item => item.id === id)
  const centreId = (name: string) => data.centres.find(item=>item.name===name)?.id
  return {
    integratedCarePlans:data.integratedCarePlans??[], rehabilitationCentres:data.rehabilitationCentres??[], rehabilitationPrograms:data.rehabilitationPrograms??[], homeExercises:data.homeExercises??[], patients:data.patients, doctors:data.doctors, reviewers:data.reviewers, pharmacists:data.pharmacists??[], centres:data.centres, emirates:data.emirates??[], medications:data.medications??[],
    assessments:data.assessments.map(item=>({...item,doctorId:data.doctors.find(d=>d.name===item.clinician)?.id})),
    medicalHistory:data.assessments.map(item=>({id:`MH-${item.id}`,patientId:item.patientId,assessmentId:item.id,summary:item.medicalHistory})),
    allergies:data.assessments.map(item=>({id:`AL-${item.id}`,patientId:item.patientId,assessmentId:item.id,summary:item.allergies})),
    prescriptions:data.requests.filter(item=>item.prescriptionId).map(item=>({id:item.prescriptionId!,patientId:item.patientId,requestId:item.id,planId:item.planId,medicationId:data.medications?.find(m=>m.name===(item.medication??'Mounjaro'))?.id,dose:item.dose})),
    eligibilityAssessments:data.patients.map(patient=>({id:`ELG-${patient.id}`,patientId:patient.id,...calculateEligibility(patient,data.labs)})),
    decisionSupportResults:data.patients.map(patient=>({id:`DS-${patient.id}`,patientId:patient.id,rulesVersion:'demo-v1',risk:careRisk(data,patient.id),eligibility:calculateEligibility(patient,data.labs)})),
    reviews:data.audit.filter(item=>/Request approved|Request rejected|Information requested/.test(item.action)).map(item=>({id:item.id,requestId:item.entityId,patientId:item.patientId??data.requests.find(r=>r.id===item.entityId)?.patientId,actor:item.actor,decision:item.newState,reason:item.reason??item.detail,occurredAt:item.occurredAt})),
    pharmacyVerifications:data.audit.filter(item=>item.action==='Pharmacy verification completed').map(item=>({id:item.id,requestId:item.entityId,patientId:item.patientId,checks:item.metadata,actor:item.actor,occurredAt:item.occurredAt})),
    dispensing:data.dispenses.map(item=>({...item,centreId:centreId(item.centre)})),
    inventoryItems:supportedDoses.map(dose=>({id:`INV-${dose.replaceAll(' ','')}`,medicationId:'MED-001',dose,onHand:onHandByDose(data)[dose],reserved:reservedByDose(data)[dose],available:inventoryByDose(data)[dose]})),
    batches:data.batches.map(item=>({...item,centreId:centreId(item.centre),medicationId:'MED-001'})),
    restocks:data.movements.filter(item=>['Receiving','Restock'].includes(item.type)),
    financialRecords:data.financial,
    coverageEstimates:data.financial.map(item=>({id:`COV-${item.id}`,financialRecordId:item.id,patientId:item.patientId,requestId:item.requestId,...calculateCoverage(patientFor(item.patientId)?.residency??'Visitor',item.amountAED),basis:'Mock coverage by registered patient type; no payment processing'})),
    appointments:data.appointments.map(item=>({...item,doctorId:data.doctors.find(d=>d.name===item.doctor)?.id,centreId:centreId(item.centre)})),
    activityEvents:data.audit, auditEvents:data.audit, notifications:data.notifications, exercise:data.exercise,doses:data.doses,
    patientById:patientFor,
  }
}

export function saveCareProgram(data: AppData, role: Role, input: Omit<CareProgram,'id'|'clinicianId'|'status'>): AppData {
  requirePermission(role,'clinical:write')
  requirePatientAccess(data,role,input.patientId)
  if (input.title.trim().length<3 || !input.activities.length || input.activities.some(item=>!item.trim()) || !Number.isInteger(input.weeklySessions) || input.weeklySessions<1 || input.weeklySessions>7 || !validIsoDate(input.reviewDate) || input.reviewDate<new Date().toISOString().slice(0,10)) throw new Error('Enter a programme title, activities, 1–7 weekly sessions and a future review date.')
  const existing=data.carePrograms?.find(item=>item.patientId===input.patientId && item.status==='Active')
  const programme: CareProgram={...input,title:input.title.trim(),activities:input.activities.map(item=>item.trim()),id:existing?.id??nextRecordId('REH'),clinicianId:data.patients.find(item=>item.id===input.patientId)?.doctorId??'DOC-001',status:'Active'}
  const next={...data,carePrograms:[programme,...(data.carePrograms??[]).filter(item=>item.id!==programme.id)]}
  return {...next,...eventBundle(next,role,'Rehabilitation programme updated','Care programme',programme.id,programme.patientId,`${programme.title} · ${programme.weeklySessions} sessions / week`)}
}

export function saveTreatmentDraft(data: AppData, role: Role, patientId: string, dose: string, details: RequestPlanInput, requestId?:string, options: {doctorRationale?:string} = {}): AppData {
  requirePermission(role,'request:submit'); requirePatientAccess(data,role,patientId)
  if(!supportedDoses.includes(dose as typeof supportedDoses[number])) throw new Error('Select a supported medication dose.')
  const current=data.requests.find(item=>item.id===requestId)
  if(requestId && (!current || current.status!=='Draft' || current.patientId!==patientId))throw new Error('Only an existing patient draft can be edited.')
  const id=current?.id??nextRecordId('TR'),planId=current?.planId??nextRecordId('TP'),stamp=new Date().toISOString()
  const plan:TreatmentPlan={...details,id:planId,patientId,medication:'Mounjaro',dose,status:'Draft'}
  const request:TreatmentRequest={...current,id,patientId,planId,dose,status:'Draft',created:stamp.slice(0,10),createdAt:stamp,doctorRationale:options.doctorRationale?.trim()??current?.doctorRationale}
  return {...data,requests:[request,...data.requests.filter(item=>item.id!==id)],treatmentPlans:[plan,...data.treatmentPlans.filter(item=>item.id!==planId)],audit:[{...audit(role,'Treatment draft saved','Treatment request',id,'Draft awaiting complete evidence and submission'),patientId},...data.audit]}
}
export function submitTreatmentDraft(data:AppData,role:Role,requestId:string):AppData {
  requirePermission(role,'request:submit')
  const request=data.requests.find(item=>item.id===requestId)
  const plan=data.treatmentPlans.find(item=>item.id===request?.planId)
  if(!request || request.status!=='Draft' || !plan)throw new Error('Only a linked draft treatment can be submitted.')
  const validated=submitRequest({...data,requests:data.requests.filter(item=>item.id!==requestId),treatmentPlans:data.treatmentPlans.filter(item=>item.id!==plan.id)},role,request.patientId,request.dose,plan,{doctorRationale:request.doctorRationale})
  return {...validated,requests:[{...validated.requests[0],id:requestId,planId:plan.id},...validated.requests.slice(1)],treatmentPlans:[{...validated.treatmentPlans[0],id:plan.id},...validated.treatmentPlans.slice(1)],notifications:[{...validated.notifications[0],relatedEntityId:requestId},...validated.notifications.slice(1)],audit:[{...validated.audit[0],entityId:requestId,previousState:'Draft',newState:validated.requests[0].status},...validated.audit.slice(1)]}
}

// Integrated care is an umbrella record; medication requests keep their own review lifecycle.
export type CoverageResult = { patientType: PatientType; totalAED: number; discountPercent: number; supportAED: number; patientAED: number }
export type RehabilitationCentre = CentreDirectoryDetails & { id:string; name:string; emirate:string; area:string; coordinates:Coordinates; contact:string; status:'Active'|'Inactive'; capacity:number; maxSessions?:number; programIds:string[] }
export type RehabilitationProgram = { id:string; name:string; description:string; sessionCostAED:number; defaultSessions:number }
export type HomeExercise = { id:string; name:string; category:string; instructions:string; frequency:string; durationMinutes:number; repetitions:string; difficulty:string; notes:string }
export type IntegratedCarePlan = {
  id:string; patientId:string; doctorId:string; title:string; createdAt:string; status:'Active'|'Completed';
  medicationId?:string; treatmentRequestId?:string;
  aiPlanScore?:number; aiRecommendations?:string[]; eligibilityResult?:'Eligible'|'Review required'|'Ineligible';
  rehabilitation?:{programId:string;centreId:string;plannedSessions:number;status:'Scheduled'|'In progress'|'Completed';sessions:{id:string;date:string;note:string}[]};
  homeExerciseIds:string[]; followUpDate:string; appointmentId?:string; monitoring:string;
  review:{doctorId:string;confirmedAt:string;rationale:string;eligibilityMet:boolean;criteria:{label:string;passed:boolean;evidence:string}[]};
  costLines:{label:string;amountAED:number}[]; coverage:CoverageResult;
}
export type IntegratedCareInput = {
  patientId:string; title:string; medication?:{requestId?:string;medicationId:string;dose:string;frequency:string;durationDays:number;instructions:string};
  rehabilitation?:{programId:string;centreId:string;plannedSessions:number}; homeExerciseIds:string[];
  startDate:string; followUpDate:string; followUpTime:string; monitoring:string; rationale:string;
}
export function calculateCoverage(patientType: PatientType, treatmentCost: number): CoverageResult {
  if (!['Citizen','Resident','Visitor'].includes(patientType) || !Number.isFinite(treatmentCost) || treatmentCost<0) throw new Error('Valid patient type and non-negative treatment cost are required.')
  const discountPercent = {Citizen:100,Resident:50,Visitor:0}[patientType]
  const totalAED=Math.round(treatmentCost*100)/100
  const supportAED=Math.round(totalAED*discountPercent)/100
  return {patientType,totalAED,discountPercent,supportAED,patientAED:Math.round((totalAED-supportAED)*100)/100}
}
export function regionLocation(emirate:string): Coordinates {
  const regions:Record<string,Coordinates>={'Abu Dhabi':{lat:24.4539,lng:54.3773},Dubai:{lat:25.2048,lng:55.2708},Sharjah:{lat:25.3463,lng:55.4209},Ajman:{lat:25.4052,lng:55.5136},'Ras Al Khaimah':{lat:25.7895,lng:55.9432},Fujairah:{lat:25.1288,lng:56.3265},'Umm Al Quwain':{lat:25.5647,lng:55.5553}}
  return regions[emirate] ?? regions.Dubai
}
export function distanceKm(a:Coordinates,b:Coordinates) {
  const rad=(n:number)=>n*Math.PI/180
  const h=Math.sin(rad(b.lat-a.lat)/2)**2+Math.cos(rad(a.lat))*Math.cos(rad(b.lat))*Math.sin(rad(b.lng-a.lng)/2)**2
  return Math.round(6371*2*Math.atan2(Math.sqrt(h),Math.sqrt(Math.max(0,1-h)))*10)/10
}
export function nearbyRehabilitation(data:AppData,patientId:string,programId?:string) {
  const patient=data.patients.find(p=>p.id===patientId)
  if(!patient)return []
  const origin=patient.location??regionLocation(patient.emirate)
  return (data.rehabilitationCentres??[]).filter(c=>!programId||c.programIds.includes(programId)).map(centre=>({...centre,distanceKm:distanceKm(origin,centre.coordinates),availableSlots:Math.max(0,centre.capacity-(data.integratedCarePlans??[]).filter(plan=>plan.status==='Active'&&plan.rehabilitation?.centreId===centre.id&&plan.rehabilitation.status!=='Completed').length)})).sort((a,b)=>a.distanceKm-b.distanceKm)
}
export function integratedCareEstimate(data:AppData,input:Pick<IntegratedCareInput,'patientId'|'medication'|'rehabilitation'>) {
  const patient=data.patients.find(p=>p.id===input.patientId)
  if(!patient?.residency)throw new Error('Record Citizen, Resident or Visitor before calculating coverage.')
  const costLines:{label:string;amountAED:number}[]=[]
  if(input.medication){const med=data.medications?.find(m=>m.id===input.medication?.medicationId);if(!med)throw new Error('Select a medication from the central catalog.');costLines.push({label:`${med.name} · initial dispensing unit`,amountAED:med.unitCostAED})}
  if(input.rehabilitation){const program=data.rehabilitationPrograms?.find(p=>p.id===input.rehabilitation?.programId);if(!program)throw new Error('Select a rehabilitation program from the central catalog.');costLines.push({label:`${program.name} · ${input.rehabilitation.plannedSessions} sessions`,amountAED:program.sessionCostAED*input.rehabilitation.plannedSessions})}
  return {costLines,coverage:calculateCoverage(patient.residency,costLines.reduce((sum,line)=>sum+line.amountAED,0))}
}
export function integratedCareChecks(data:AppData,input:IntegratedCareInput) {
  const patient=data.patients.find(p=>p.id===input.patientId)
  const eligibility=patient?calculateEligibility(patient,data.labs):null
  const med=data.medications?.find(m=>m.id===input.medication?.medicationId)
  const centre=nearbyRehabilitation(data,input.patientId,input.rehabilitation?.programId).find(c=>c.id===input.rehabilitation?.centreId)
  const today=new Date().toISOString().slice(0,10)
  const checks=[
    {label:'Patient context',passed:Boolean(patient?.residency&&patient.doctorId)},
    {label:'Plan purpose',passed:input.title.trim().length>=3},
    {label:'Care components',passed:Boolean(input.medication||input.rehabilitation)},
    {label:'Medication evidence',passed:!input.medication||Boolean((eligibility?.eligible||input.rationale.trim().length>=8)&&data.assessments.some(a=>a.patientId===input.patientId&&a.status==='Submitted')&&med?.status!=='Unavailable'&&med?.strengths.includes(input.medication.dose)&&(med?.frequencies??['Weekly']).includes(input.medication.frequency)&&Number.isInteger(input.medication.durationDays)&&input.medication.durationDays>=28&&input.medication.durationDays<=365&&input.medication.instructions.trim())},
    {label:'Rehabilitation availability',passed:!input.rehabilitation||Boolean(centre?.status==='Active'&&centre.availableSlots>0&&Number.isInteger(input.rehabilitation.plannedSessions)&&input.rehabilitation.plannedSessions>=1&&input.rehabilitation.plannedSessions<=(centre.maxSessions??80))},
    {label:'Home exercise catalog',passed:new Set(input.homeExerciseIds).size===input.homeExerciseIds.length&&input.homeExerciseIds.every(id=>data.homeExercises?.some(e=>e.id===id))},
    {label:'Follow-up and monitoring',passed:validIsoDate(input.startDate)&&input.startDate>=today&&validIsoDate(input.followUpDate)&&input.followUpDate>=input.startDate&&/^([01]\d|2[0-3]):[0-5]\d$/.test(input.followUpTime)&&input.monitoring.trim().length>=5},
    {label:'Doctor confirmation',passed:input.rationale.trim().length>=8},
  ]
  return checks
}
export function assessCarePlan(data:AppData,input:IntegratedCareInput) {
  const eligibility=treatmentEligibility(data,input.patientId)
  const checks=integratedCareChecks(data,input)
  const medicationValid=!input.medication||checks[3].passed
  const rehabilitationValid=!input.rehabilitation||checks[4].passed
  const score=Math.max(0,Math.min(100,30+(input.medication?15:0)+(input.rehabilitation?15:0)+(input.homeExerciseIds.length?5:0)+(eligibility.eligible?10:0)+(medicationValid?10:0)+(rehabilitationValid?10:0)+(checks[6].passed?5:0)-(checks[2].passed?0:35)))
  const recommendations:string[]=[]
  if(!checks[2].passed)recommendations.push('Select medication or a rehabilitation centre before approval.')
  if(input.medication&&!eligibility.eligible)recommendations.push('Document the clinical exception and obtain independent review before pharmacy.')
  if(input.medication&&!medicationValid)recommendations.push('Review medication evidence, strength, frequency and existing requests.')
  if(input.rehabilitation&&!rehabilitationValid)recommendations.push('Select an available centre and a supported session count.')
  if(input.rehabilitation&&!input.homeExerciseIds.length)recommendations.push('Consider adding prescribed home exercises to support rehabilitation.')
  if(!checks[6].passed)recommendations.push('Review the configured follow-up and monitoring.')
  if(input.rehabilitation?.plannedSessions&&input.rehabilitation.plannedSessions>20)recommendations.push('Review rehabilitation duration at the next clinical visit.')
  if(!recommendations.length)recommendations.push('Continue the documented follow-up and monitor response.')
  return {score,recommendations,eligibilityResult:eligibility.eligible?'Eligible' as const:input.medication?'Review required' as const:'Ineligible' as const,checks}
}
export function createIntegratedCarePlan(data:AppData,role:Role,input:IntegratedCareInput):AppData {
  requirePermission(role,'clinical:write');requirePatientAccess(data,role,input.patientId)
  const failed=integratedCareChecks(data,input).filter(c=>!c.passed)
  if(failed.length)throw new Error(`Complete the care plan: ${failed.map(c=>c.label).join(', ')}.`)
  const patient=data.patients.find(p=>p.id===input.patientId)!
  const doctor=data.doctors.find(d=>d.id===patient.doctorId&&d.status==='Active')
  if(!doctor)throw new Error('An active responsible doctor is required.')
  const id=nextRecordId('ICP'),stamp=new Date().toISOString(),estimate=integratedCareEstimate(data,input)
  let next=data;let requestId:string|undefined
  if(input.medication){
    const med=data.medications!.find(m=>m.id===input.medication!.medicationId)!
    // The supported formulary uses the existing medication review and pharmacy rules.
    if(med.name!=='Mounjaro')throw new Error('This catalog medication is not enabled for pharmacy dispensing.')
    if(input.medication.requestId){
      const existing=data.requests.find(r=>r.id===input.medication!.requestId&&r.patientId===patient.id)
      const treatment=data.treatmentPlans.find(p=>p.id===existing?.planId)
      if(!existing||!treatment||['Draft','Rejected','Completed','Dispensed'].includes(existing.status)||(existing.medicationId??'MED-001')!==med.id||existing.dose!==input.medication.dose||treatment.frequency!==input.medication.frequency||treatment.durationDays!==input.medication.durationDays||treatment.instructions!==input.medication.instructions||(data.integratedCarePlans??[]).some(p=>p.treatmentRequestId===existing.id))throw new Error('Select an unlinked medication request and keep its prescribed details unchanged.')
      requestId=existing.id
    }else{
      next=submitRequest(data,role,patient.id,input.medication.dose,{frequency:input.medication.frequency,durationDays:input.medication.durationDays,startDate:input.startDate,endDate:new Date(Date.parse(`${input.startDate}T12:00:00Z`)+(input.medication.durationDays-1)*86400000).toISOString().slice(0,10),indication:patient.diagnosis,instructions:input.medication.instructions,monitoringPlan:input.monitoring,followUpDate:input.followUpDate},{doctorRationale:input.rationale})
      requestId=next.requests[0].id
    }
    next={...next,requests:next.requests.map(r=>r.id===requestId?{...r,medicationId:med.id,integratedCarePlanId:id}:r)}
  }
  next=saveAppointment(next,role,{status:'Scheduled',patientId:patient.id,doctor:doctor.name,centre:patient.treatmentCentre??doctor.centre,purpose:'Integrated care follow-up',date:input.followUpDate,time:input.followUpTime,notes:input.monitoring})
  const appointmentId=next.appointments[0].id
  const eligibility=calculateEligibility(patient,data.labs)
  const assessment=assessCarePlan(data,input)
  const plan:IntegratedCarePlan={id,patientId:patient.id,doctorId:doctor.id,title:input.title.trim(),createdAt:stamp,status:'Active',medicationId:input.medication?.medicationId,treatmentRequestId:requestId,aiPlanScore:assessment.score,aiRecommendations:assessment.recommendations,eligibilityResult:assessment.eligibilityResult,rehabilitation:input.rehabilitation?{...input.rehabilitation,status:'Scheduled',sessions:[]}:undefined,homeExerciseIds:[...input.homeExerciseIds],followUpDate:input.followUpDate,appointmentId,monitoring:input.monitoring.trim(),review:{doctorId:doctor.id,confirmedAt:stamp,rationale:input.rationale.trim(),eligibilityMet:eligibility.eligible,criteria:eligibility.criteria},...estimate}
  next={...next,integratedCarePlans:[plan,...(next.integratedCarePlans??[])],financial:[{id:nextRecordId('FIN'),patientId:patient.id,requestId:requestId??'',integratedCarePlanId:id,amountAED:estimate.coverage.totalAED,coverage:estimate.coverage,status:'Estimated',assessedAt:stamp},...next.financial]}
  return canonicalize({...next,...eventBundle(next,role,'Integrated care plan confirmed','Integrated care plan',id,patient.id,`${plan.title} · medication ${requestId?next.requests.find(r=>r.id===requestId)?.status:'not included'} · ${plan.homeExerciseIds.length} home exercises`,'Draft','Active',input.rationale)})
}
export function recordRehabilitationSession(data:AppData,role:Role,planId:string,date:string,note:string):AppData {
  requirePermission(role,'clinical:write')
  const plan=data.integratedCarePlans?.find(p=>p.id===planId)
  if(!plan?.rehabilitation||plan.status!=='Active')throw new Error('An active rehabilitation care plan is required.')
  requirePatientAccess(data,role,plan.patientId)
  if(!validIsoDate(date)||date>new Date().toISOString().slice(0,10)||date<plan.createdAt.slice(0,10)||note.trim().length<5)throw new Error('Enter a completed session date within the plan period and a progress note.')
  if(plan.rehabilitation.sessions.length>=plan.rehabilitation.plannedSessions)throw new Error('All prescribed rehabilitation sessions are complete.')
  if(plan.rehabilitation.sessions.some(s=>s.date===date))throw new Error('A rehabilitation session is already recorded for this day.')
  const sessions=[...plan.rehabilitation.sessions,{id:nextRecordId('RHS'),date,note:note.trim()}]
  const next:AppData={...data,integratedCarePlans:data.integratedCarePlans!.map(p=>p.id===planId?{...p,rehabilitation:{...plan.rehabilitation!,sessions,status:sessions.length===plan.rehabilitation!.plannedSessions?'Completed':'In progress'}}:p)}
  return {...next,...eventBundle(next,role,'Rehabilitation session recorded','Integrated care plan',planId,plan.patientId,`${sessions.length}/${plan.rehabilitation.plannedSessions} sessions · ${note}`)}
}
function dispensingFinancialRecords(data:AppData,request:TreatmentRequest,stamp:string):FinancialRecord[] {
  const existing=data.financial.find(f=>f.requestId===request.id)
  const patient=data.patients.find(p=>p.id===request.patientId)!
  if(existing)return data.financial.map(f=>f.id===existing.id?{...f,coverage:calculateCoverage(patient.residency??'Visitor',f.amountAED),assessedAt:stamp,dispensedAt:stamp}:f)
  const amountAED=data.medications?.find(m=>m.id===request.medicationId||m.name===(request.medication??'Mounjaro'))?.unitCostAED??1200
  return [...data.financial,{id:nextRecordId('FIN'),requestId:request.id,patientId:request.patientId,amountAED,coverage:calculateCoverage(patient.residency??'Visitor',amountAED),status:'Estimated',assessedAt:stamp,dispensedAt:stamp}]
}

/** Seed/migration enrichment only; every screen reads these same catalog records. */
export function initializeCareEcosystem(data:AppData):AppData {
  const rehabilitationPrograms=data.rehabilitationPrograms??[
    {id:'RP-PHYSIO',name:'Physiotherapy',description:'Supervised mobility and functional recovery with an assigned therapist.',sessionCostAED:150,defaultSessions:6},
    {id:'RP-RECOVERY',name:'Recovery programme',description:'Individual rehabilitation and gradual return to daily activity.',sessionCostAED:180,defaultSessions:8},
    {id:'RP-FOLLOWUP',name:'Follow-up rehabilitation',description:'Review progress and adapt the prescribed exercise programme.',sessionCostAED:120,defaultSessions:4},
  ]
  const rehabilitationCentres: RehabilitationCentre[]=data.rehabilitationCentres??[
    {id:'RC-AUH',name:'Abu Dhabi Rehabilitation Centre',emirate:'Abu Dhabi',area:'Al Danah',coordinates:{lat:24.466,lng:54.386},contact:'+97125552100',status:'Active' as const,capacity:12,programIds:['RP-PHYSIO','RP-RECOVERY','RP-FOLLOWUP'], nameAr: "مركز أبوظبي لإعادة التأهيل", kind: "Integrated rehabilitation", email: "auh-rehab@example.test", manager: "هند المزروعي", contractReference: "UAE-REHAB-2024-001", contractDate: "2024-03-12", contractStatus: "Active", services: ["Physical therapy", "RehabilitationServices"], maxSessions: 80, notes: "مركز تجريبي للتأهيل ومتابعة الخطط العلاجية.", createdAt: "2024-03-12T08:00:00.000Z"},
    {id:'RC-DXB',name:'Dubai Physiotherapy Centre',emirate:'Dubai',area:'Oud Metha',coordinates:{lat:25.234,lng:55.308},contact:'+97145552101',status:'Active' as const,capacity:10,programIds:['RP-PHYSIO','RP-FOLLOWUP'], nameAr: "مركز دبي للعلاج الطبيعي", kind: "Physiotherapy", email: "dubai-physio@example.test", manager: "يوسف المرزوقي", contractReference: "UAE-REHAB-2024-002", contractDate: "2024-05-25", contractStatus: "Active", services: ["Physical therapy", "RehabilitationServices"], maxSessions: 80, notes: "مركز تجريبي للتأهيل ومتابعة الخطط العلاجية.", createdAt: "2024-05-25T08:00:00.000Z"},
    {id:'RC-SHJ',name:'Sharjah Recovery Centre',emirate:'Sharjah',area:'Al Majaz',coordinates:{lat:25.324,lng:55.389},contact:'+97165552102',status:'Active' as const,capacity:8,programIds:['RP-PHYSIO','RP-RECOVERY'], nameAr: "مركز الشارقة للتعافي", kind: "Rehabilitation", email: "sharjah-rehab@example.test", manager: "مها القاسمي", contractReference: "UAE-REHAB-2024-003", contractDate: "2024-06-14", contractStatus: "Active", services: ["Physical therapy", "RehabilitationServices"], maxSessions: 80, notes: "مركز تجريبي للتأهيل ومتابعة الخطط العلاجية.", createdAt: "2024-06-14T08:00:00.000Z"},
    {id:'RC-AIN',name:'Al Ain Mobility Centre',emirate:'Abu Dhabi',area:'Al Jimi, Al Ain',coordinates:{lat:24.233,lng:55.737},contact:'+97135552103',status:'Active' as const,capacity:6,programIds:['RP-PHYSIO','RP-RECOVERY'], nameAr: "مركز العين للحركة", kind: "Physiotherapy", email: "alain-rehab@example.test", manager: "علي العامري", contractReference: "UAE-REHAB-2024-004", contractDate: "2024-10-02", contractStatus: "Active", services: ["Physical therapy", "RehabilitationServices"], maxSessions: 80, notes: "مركز تجريبي للتأهيل ومتابعة الخطط العلاجية.", createdAt: "2024-10-02T08:00:00.000Z"},
    {id:'RC-RAK',name:'Ras Al Khaimah Rehabilitation Centre',emirate:'Ras Al Khaimah',area:'Al Nakheel',coordinates:{lat:25.797,lng:55.974},contact:'+97175552104',status:'Active' as const,capacity:5,programIds:['RP-PHYSIO','RP-FOLLOWUP'], nameAr: "مركز رأس الخيمة لإعادة التأهيل", kind: "Integrated rehabilitation", email: "rak-rehab@example.test", manager: "شيخة الشحي", contractReference: "UAE-REHAB-2024-005", contractDate: "2024-08-18", contractStatus: "Active", services: ["Physical therapy", "RehabilitationServices"], maxSessions: 80, notes: "مركز تجريبي للتأهيل ومتابعة الخطط العلاجية.", createdAt: "2024-08-18T08:00:00.000Z"},
    {id:'RC-FUJ',name:'Fujairah Recovery Clinic',emirate:'Fujairah',area:'Al Faseel',coordinates:{lat:25.154,lng:56.352},contact:'+97195552105',status:'Inactive' as const,capacity:0,programIds:['RP-RECOVERY'], nameAr: "عيادة الفجيرة للتعافي", kind: "Rehabilitation", email: "fujairah-rehab@example.test", manager: "محمد الشرقي", contractReference: "UAE-REHAB-2024-006", contractDate: "2024-01-03", contractStatus: "Suspended", services: ["RehabilitationServices"], maxSessions: 80, notes: "التعاقد موقوف مؤقتًا؛ لا يستقبل المركز خططًا جديدة.", createdAt: "2024-01-03T08:00:00.000Z"},
  ]
  const homeExercises=data.homeExercises??[
    {id:'HE-WALK',name:'Walking',category:'Lifestyle',instructions:'Follow the pace agreed with your care team; use a level, safe route.',frequency:'3 times per week',durationMinutes:20,repetitions:'As prescribed',difficulty:'Light',notes:'Adapt with your clinician if symptoms occur.'},
    {id:'HE-STRENGTH',name:'Strength training',category:'Strength',instructions:'Use the movements and resistance demonstrated by your therapist.',frequency:'2 times per week',durationMinutes:15,repetitions:'2 sets of 8, if prescribed',difficulty:'Moderate',notes:'Technique and progression are reviewed by the care team.'},
    {id:'HE-FLEX',name:'Flexibility',category:'Flexibility',instructions:'Perform the prescribed gentle stretches within a comfortable range.',frequency:'3 times per week',durationMinutes:10,repetitions:'As demonstrated',difficulty:'Light',notes:'Follow the individual therapist instructions.'},
    {id:'HE-MOBILITY',name:'Mobility programme',category:'Mobility',instructions:'Practice the supported movements selected during assessment.',frequency:'Daily',durationMinutes:10,repetitions:'As prescribed',difficulty:'Light',notes:'Use prescribed support equipment.'},
    {id:'HE-HOME',name:'Home rehabilitation',category:'Recovery',instructions:'Complete the home sequence reviewed with your rehabilitation team.',frequency:'3 times per week',durationMinutes:15,repetitions:'Individual programme',difficulty:'Light',notes:'Review at the scheduled follow-up.'},
  ]
  const patients=data.patients.map(p=>({...p,doctorId:data.doctors.find(d=>d.name===p.assignedDoctor)?.id,location:p.location??regionLocation(p.emirate),area:p.area??`${p.emirate} area centroid`,previousIllnesses:p.previousIllnesses??['No additional previous illness documented'],chronicConditions:p.chronicConditions??[p.diagnosis||'Awaiting clinical assessment'],procedures:p.procedures??[]}))
  const centres=data.centres.map(c=>({...c,coordinates:c.coordinates??(c.id==='CTR-AIN-01'?{lat:24.233,lng:55.737}:regionLocation(c.emirate)),contact:c.contact??`${c.id.toLowerCase()}@example.test`}))
  let next:AppData={...data,careWorkflowVersion:1,patients,centres,rehabilitationPrograms,rehabilitationCentres,homeExercises,integratedCarePlans:[...(data.integratedCarePlans??[])]}
  // Preserve earlier prescribed programmes by linking them into the umbrella record once.
  for(const legacy of data.carePrograms??[]){
    if(next.integratedCarePlans!.some(p=>p.id===`ICP-${legacy.id}`))continue
    const patient=patients.find(p=>p.id===legacy.patientId)!
    const request=data.requests.find(r=>r.patientId===patient.id&&r.status==='Dispensed')
    const centre=nearbyRehabilitation(next,patient.id,'RP-PHYSIO').find(c=>c.status==='Active')!
    const costLines=[{label:'Physiotherapy · 6 sessions',amountAED:900}]
    next.integratedCarePlans!.push({id:`ICP-${legacy.id}`,patientId:patient.id,doctorId:patient.doctorId??legacy.clinicianId,title:legacy.title,createdAt:'2026-09-18T08:00:00.000Z',status:legacy.status,medicationId:request?'MED-001':undefined,treatmentRequestId:request?.id,rehabilitation:{programId:'RP-PHYSIO',centreId:centre.id,plannedSessions:6,status:'In progress',sessions:[{id:`RHS-${legacy.id}`,date:'2026-09-25',note:'Baseline mobility session completed.'}]},homeExerciseIds:['HE-WALK','HE-MOBILITY'],followUpDate:legacy.reviewDate,monitoring:'Review mobility, adherence and response at follow-up.',review:{doctorId:patient.doctorId??legacy.clinicianId,confirmedAt:'2026-09-18T08:00:00.000Z',rationale:'Migrated from the existing prescribed rehabilitation programme.',eligibilityMet:calculateEligibility(patient,data.labs).eligible,criteria:calculateEligibility(patient,data.labs).criteria},costLines,coverage:calculateCoverage(patient.residency??'Visitor',900)})
  }
  // Migrate historical rehabilitation estimates into the same umbrella and financial record.
  // Existing dispensing is a reference, so this never creates a new dispensing or stock movement.
  const legacyIds=new Set((data.carePrograms??[]).map(p=>`ICP-${p.id}`))
  for(const plan of next.integratedCarePlans!.filter(p=>legacyIds.has(p.id))){
    const request=next.requests.find(r=>r.id===plan.treatmentRequestId)
    const estimate=integratedCareEstimate(next,{patientId:plan.patientId,medication:request?{medicationId:request.medicationId??'MED-001',dose:request.dose,frequency:'Weekly',durationDays:84,instructions:''}:undefined,rehabilitation:plan.rehabilitation})
    next={...next,integratedCarePlans:next.integratedCarePlans!.map(p=>p.id===plan.id?{...p,...estimate}:p),requests:next.requests.map(r=>r.id===request?.id?{...r,integratedCarePlanId:plan.id}:r)}
    const existing=next.financial.find(f=>f.integratedCarePlanId===plan.id||Boolean(request&&f.requestId===request.id))
    const financial:FinancialRecord={...(existing??{id:`FIN-${plan.id}`,patientId:plan.patientId,requestId:request?.id??'',status:'Estimated',assessedAt:plan.createdAt}),integratedCarePlanId:plan.id,amountAED:estimate.coverage.totalAED,coverage:estimate.coverage}
    next={...next,financial:existing?next.financial.map(f=>f.id===existing.id?financial:f):[...next.financial,financial]}
  }
  return next
}

export function createOperationalAlert(data:AppData,role:Role,input:Omit<ManualAlert,'id'|'timestamp'>):AppData {
 requirePermission(role,'alerts:manage')
 if(!input.title.trim()||!input.detail.trim())throw new Error('Title and details are required.')
 if(!['Critical','Warning','Info'].includes(input.severity)||!['High','Medium','Low'].includes(input.priority)||!['Inventory','Treatment','Safety','Clinical','Appointments'].includes(input.category))throw new Error('Select valid alert settings.')
 if(input.patientId&&!canReadPatient(data,role,input.patientId))throw new Error('Patient is outside your workspace.')
 if(input.medicationId&&!data.medications?.some(m=>m.id===input.medicationId))throw new Error('Select a valid medication.')
 if(input.centre&&!data.centres.some(c=>c.name===input.centre))throw new Error('Select a valid centre.')
 const item:ManualAlert={...input,title:input.title.trim(),detail:input.detail.trim(),id:nextRecordId('AL'),timestamp:new Date().toISOString()}
 return {...data,manualAlerts:[item,...(data.manualAlerts??[])],audit:[audit(role,'Operational alert created','Operational alert',item.id,item.title),...data.audit]}
}

/** Update the existing care plan without creating a second treatment request. */
export function updateIntegratedCarePlan(data:AppData,role:Role,planId:string,input:{title:string;monitoring:string}):AppData {
 requirePermission(role,'clinical:write')
 const plan=data.integratedCarePlans?.find(p=>p.id===planId)
 if(!plan)throw new Error('Care plan not found.')
 requirePatientAccess(data,role,plan.patientId)
 if(!input.title.trim()||input.monitoring.trim().length<5)throw new Error('Enter a title and monitoring instructions.')
 const next={...data,integratedCarePlans:data.integratedCarePlans!.map(p=>p.id===planId?{...p,title:input.title.trim(),monitoring:input.monitoring.trim()}:p)}
 return {...next,...eventBundle(next,role,'Care plan updated','Integrated care plan',plan.id,plan.patientId,input.monitoring.trim(),plan.title,input.title.trim())}
}
