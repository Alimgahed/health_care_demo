import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'

const source = await readFile(new URL('../src/domain.ts', import.meta.url), 'utf8')
const javascript = ts.transpile(source, { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 })
const domainUrl = `data:text/javascript;base64,${Buffer.from(javascript).toString('base64')}`
const domain = await import(domainUrl)
const analyticsSource = (await readFile(new URL('../src/adminAnalytics.ts', import.meta.url), 'utf8')).replace("from './domain'", `from '${domainUrl}'`)
const analyticsJavascript = ts.transpile(analyticsSource, { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 })
const analytics = await import(`data:text/javascript;base64,${Buffer.from(analyticsJavascript).toString('base64')}`)
const copySeed = () => structuredClone(domain.seed)
const date = (daysFromNow) => new Date(Date.now() + daysFromNow * 86400000).toISOString().slice(0, 10)
const plan = { frequency: 'Weekly', durationDays: 84, startDate: date(0), endDate: date(83), followUpDate: date(28), indication: 'Type 2 diabetes', instructions: 'Use once weekly as prescribed.', monitoringPlan: 'Review glucose and tolerance.' }

test('screenshot seed contains the 150-patient programme and matching P999 identity', () => {
  assert.equal(domain.seed.patients.length, 150)
  const p999 = domain.seed.patients[0]
  assert.equal(p999.id, 'P999')
  assert.equal(p999.name, 'Ahmed Al Mansoori')
  assert.equal(p999.emiratesId, '784-1990-1234567-1')
  assert.equal(p999.bmi, 39.2)
  assert.equal(p999.currentDose, '10 mg')
  assert.equal(domain.seed.labs.find(item => item.patientId === 'P999')?.value, 8.5)
  assert.equal(domain.seed.labs.find(item => item.patientId === 'P012')?.value, 7.3)
  assert.equal(domain.seed.notifications.find(item => item.id === 'NT-018')?.patientId, 'P010')
  assert.equal(domain.seed.patients.find(item => item.id === 'P012')?.assignedDoctor, 'Dr. Laila Hassan')
  for (const planRecord of domain.seed.treatmentPlans) {
    const actualDays = (Date.parse(`${planRecord.endDate}T00:00:00Z`) - Date.parse(`${planRecord.startDate}T00:00:00Z`)) / 86400000 + 1
    assert.equal(actualDays, planRecord.durationDays, `${planRecord.id} dates should match its duration`)
  }
})

test('eligibility is calculated from age, BMI, diagnosis and current lab evidence', () => {
  const data = copySeed()
  const patient = data.patients.find(item => item.id === 'P999')
  assert.equal(domain.calculateEligibility(patient, data.labs).eligible, true)
  assert.equal(domain.calculateEligibility({ ...patient, bmi: 24 }, data.labs).eligible, false)
  assert.equal(domain.calculateEligibility(patient, data.labs.filter(item => item.patientId !== patient.id)).eligible, false)
})

test('request submission validates clinical evidence and creates a linked plan, notification and audit event', () => {
  const data = copySeed()
  data.requests = data.requests.filter(item => item.patientId !== 'P010')
  assert.throws(() => domain.submitRequest({ ...data, assessments: data.assessments.filter(item => item.patientId !== 'P010') }, 'Doctor', 'P010', '5 mg', plan), /clinical assessment/i)
  const next = domain.submitRequest(data, 'Doctor', 'P010', '5 mg', plan)
  assert.equal(next.requests[0].status, 'Ready to dispense')
  assert.equal(next.requests[0].approvalRoute, 'Automatic')
  assert.equal(next.treatmentPlans[0].id, next.requests[0].planId)
  assert.equal(next.treatmentPlans[0].patientId, 'P010')
  assert.equal(next.notifications[0].patientId, 'P010')
  assert.equal(next.audit[0].action, 'Request automatically authorized')
})

test('review approval and pharmacy dispensing update the canonical request, plan, batch, stock and patient records', () => {
  let data = copySeed()
  data.requests = data.requests.filter(item => item.patientId !== 'P010')
  data = domain.submitRequest(data, 'Doctor', 'P010', '5 mg', plan)
  const requestId = data.requests[0].id
  assert.equal(data.requests[0].status, 'Ready to dispense')
  assert.equal(data.treatmentPlans[0].status, 'Pharmacy ready')
  const beforeStock = domain.onHandByDose(data)['5 mg']
  const beforeBatch = data.batches.find(item => item.dose === '5 mg').quantity
  data = domain.decide(data, 'Pharmacist', requestId, 'dispense')
  assert.equal(data.requests[0].status, 'Dispensed')
  assert.equal(data.treatmentPlans[0].status, 'Dispensed')
  assert.equal(domain.onHandByDose(data)['5 mg'], beforeStock - 1)
  assert.equal(data.batches.find(item => item.dose === '5 mg').quantity, beforeBatch - 1)
  assert.equal(data.dispenses[0].patientId, 'P010')
  assert.equal(data.patients.find(item => item.id === 'P010').treatmentStatus, 'Active')
  assert.equal(data.movements[0].type, 'Dispensing')
  assert.equal(data.financial[0].status, 'Estimated')
  assert.equal(data.notifications[0].title, 'Medication dispensed')
  assert.throws(() => domain.decide(data, 'Pharmacist', requestId, 'dispense'), /approved/i)
})

test('dispensing rejects expired batches and reviewers cannot bypass status transitions', () => {
  let data = copySeed()
  data.requests = data.requests.filter(item => item.patientId !== 'P010')
  data = domain.submitRequest(data, 'Doctor', 'P010', '5 mg', plan)
  const id = data.requests[0].id
  data.batches = data.batches.map(item => item.dose === '5 mg' ? { ...item, expiry: '2020-01-01' } : item)
  assert.throws(() => domain.decide(data, 'Pharmacist', id, 'dispense'), /unexpired/i)
  assert.throws(() => domain.decide(copySeed(), 'Pharmacist', 'TR-24018', 'dispense'), /approved/i)
})

test('review actions require a reason and returned requests need a clinician resubmission', () => {
  let data = copySeed()
  assert.throws(() => domain.decide(data, 'Reviewer', 'TR-24018', 'reject', 'no'), /8 characters/i)
  data = domain.decide(data, 'Reviewer', 'TR-24018', 'information', 'Updated renal panel required')
  assert.equal(data.requests.find(item => item.id === 'TR-24018').status, 'Needs information')
  assert.throws(() => domain.decide(data, 'Reviewer', 'TR-24018', 'approve'), /doctor must resubmit/i)
  data = domain.resubmitRequest(data, 'Doctor', 'TR-24018', 'Renal panel reviewed and attached')
  assert.equal(data.requests.find(item => item.id === 'TR-24018').status, 'Under review')
  assert.equal(data.treatmentPlans.find(item => item.id === 'TP-8801').status, 'Under review')
})

test('inventory restocking enforces permissions, expiry and batch uniqueness', () => {
  const data = copySeed()
  const before = domain.inventoryByDose(data)['2.5 mg']
  const stocked = domain.restock(data, 'Pharmacist', '2.5 mg', 7, 'UAE-TEST-01', date(180), 'Abu Dhabi Primary Care Centre 2', 'Gulf Medical Supply LLC', date(0))
  assert.equal(domain.inventoryByDose(stocked)['2.5 mg'], before + 7)
  assert.equal(stocked.batches[0].quantity, 7)
  assert.equal(stocked.movements[0].type, 'Restock')
  assert.throws(() => domain.restock(stocked, 'Pharmacist', '2.5 mg', 7, 'UAE-TEST-01', date(180), 'Abu Dhabi Primary Care Centre 2', 'Gulf Medical Supply LLC', date(0)), /already exists/i)
  assert.throws(() => domain.restock(data, 'Reviewer', '2.5 mg', 7, 'UAE-TEST-02', date(180), 'Abu Dhabi Primary Care Centre 2', 'Gulf Medical Supply LLC', date(0)), /cannot/i)
  assert.throws(() => domain.restock(data, 'Admin', '2.5 mg', 7, 'UAE-TEST-03', date(-1), 'Abu Dhabi Primary Care Centre 2', 'Gulf Medical Supply LLC', date(0)), /expir/i)
})

test('vitals calculate BMI, labs update evidence and role permissions are enforced', () => {
  const data = copySeed()
  const next = domain.recordVitals(data, 'Doctor', 'P999', { weightKg: 100, heightCm: 175, systolic: 120, diastolic: 78, heartRate: 70 })
  assert.equal(next.vitals[0].bmi, 32.7)
  assert.equal(next.patients.find(item => item.id === 'P999').bmi, 32.7)
  assert.throws(() => domain.recordVitals(data, 'Patient', 'P999', { weightKg: 100, heightCm: 175, systolic: 120, diastolic: 78, heartRate: 70 }), /cannot/i)
  const labbed = domain.recordLab(next, 'Doctor', 'P999', { test: 'HbA1c', value: 7.2, unit: '%', reference: '4.0–5.6%', status: 'Abnormal', date: date(0), source: 'Clinic', interpretation: 'Above range' })
  assert.equal(labbed.patients.find(item => item.id === 'P999').latestLab, 'HbA1c · 7.2%')
  assert.equal(labbed.notifications[0].title, 'Lab result recorded')
})

test('appointments reject conflicts and closed appointment transitions', () => {
  const data = copySeed()
  const appointment = { patientId: 'P010', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Follow-up', date: date(15), time: '15:45', status: 'Scheduled', notes: '' }
  const next = domain.saveAppointment(data, 'Doctor', appointment)
  assert.equal(next.appointments[0].status, 'Scheduled')
  assert.equal(next.audit[0].action, 'Appointment scheduled')
  assert.throws(() => domain.saveAppointment(next, 'Doctor', { ...appointment, patientId: 'P010' }), /already has an appointment/i)
  assert.throws(() => domain.changeAppointmentStatus(next, 'Doctor', next.appointments[0].id, 'Completed'), /future appointment/i)
  const pastAppointment = { ...next, appointments: next.appointments.map(item => ({ ...item, date: date(-1) })) }
  const done = domain.changeAppointmentStatus(pastAppointment, 'Doctor', next.appointments[0].id, 'Completed')
  assert.throws(() => domain.changeAppointmentStatus(done, 'Doctor', next.appointments[0].id, 'Cancelled'), /already closed/i)
  assert.throws(() => domain.saveAppointment(data, 'Patient', appointment), /cannot/i)
})

test('patient activity and dose logging enforce role, dispensing and duplicate-day rules', () => {
  let data = copySeed()
  const activity = domain.recordExercise(data, 'Patient', 'P999', { activity: 'Walking', durationMinutes: 25, intensity: 'Moderate', date: date(0), notes: '' })
  assert.equal(activity.exercise[0].patientId, 'P999')
  assert.throws(() => domain.recordExercise(data, 'Doctor', 'P999', { activity: 'Walking', durationMinutes: 25, intensity: 'Moderate', date: date(0), notes: '' }), /cannot/i)
  const noDispensedRequest = { ...data, requests: data.requests.filter(item => item.patientId !== 'P999') }
  assert.throws(() => domain.recordDose(noDispensedRequest, 'Patient', 'P999'), /no active medication request/i)
  data = domain.recordDose(data, 'Patient', 'P999')
  assert.equal(data.doses[0].patientId, 'P999')
  assert.equal(data.audit[0].action, 'Dose recorded')
  assert.throws(() => domain.recordDose(data, 'Patient', 'P999'), /already been recorded/i)
})

test('adherence is derived from recent dose records and capped at 100 percent', () => {
  const data = copySeed()
  data.doses = Array.from({ length: 5 }, (_, index) => ({ id: `DO-TEST-${index}`, patientId: 'P999', requestId: 'TR-24008', dose: '10 mg', recordedAt: new Date(Date.now() - index * 7 * 86400000).toISOString(), status: 'Taken' }))
  assert.equal(domain.adherenceFor(data, 'P999'), 100)
  data.doses = data.doses.slice(0, 2)
  assert.equal(domain.adherenceFor(data, 'P999'), 50)
})

test('inventory is derived from valid batches, with expiry excluded from usable stock', () => {
  const data = copySeed()
  assert.equal('stock' in data, false)
  assert.equal(domain.inventoryByDose(data)['10 mg'], 7)
  data.batches = data.batches.map(item => item.dose === '10 mg' ? { ...item, expiry: date(-1) } : item)
  assert.equal(domain.inventoryByDose(data)['10 mg'], 0)
})

test('pharmacy-ready requests reserve stock and available inventory updates with the same request state', () => {
  const data = copySeed()
  assert.equal(domain.onHandByDose(data)['5 mg'], 25)
  assert.equal(domain.reservedByDose(data)['5 mg'], 2)
  assert.equal(domain.inventoryByDose(data)['5 mg'], 23)
  data.requests = data.requests.map(item => item.id === 'TR-24015' ? { ...item, status: 'Dispensed' } : item)
  assert.equal(domain.reservedByDose(data)['5 mg'], 1)
  assert.equal(domain.inventoryByDose(data)['5 mg'], 24)
})

test('review approval requires current eligibility, supported treatment and a complete dated plan', () => {
  const data = copySeed()
  const approved = domain.decide(data, 'Reviewer', 'TR-24018', 'approve')
  const request = approved.requests.find(item => item.id === 'TR-24018')
  assert.equal(request.status, 'Ready to dispense')
  assert.equal(request.prescriptionId, 'RX-24018')
  assert.ok(request.approvalExpiresAt)
  const missingAssessment = { ...copySeed(), assessments: copySeed().assessments.filter(item => item.patientId !== 'P010') }
  assert.throws(() => domain.decide(missingAssessment, 'Reviewer', 'TR-24018', 'approve'), /assessment/i)
  const missingLab = { ...copySeed(), labs: copySeed().labs.filter(item => item.patientId !== 'P010') }
  assert.throws(() => domain.decide(missingLab, 'Reviewer', 'TR-24018', 'approve'), /HbA1c/i)
  const unsupported = copySeed()
  unsupported.requests = unsupported.requests.map(item => item.id === 'TR-24018' ? { ...item, dose: '11 mg' } : item)
  assert.throws(() => domain.decide(unsupported, 'Reviewer', 'TR-24018', 'approve'), /unsupported/i)
  const invalidDates = copySeed()
  invalidDates.treatmentPlans = invalidDates.treatmentPlans.map(item => item.id === 'TP-8801' ? { ...item, endDate: '2026-12-25' } : item)
  assert.throws(() => domain.decide(invalidDates, 'Reviewer', 'TR-24018', 'approve'), /duration or date range/i)
})

test('pharmacy verification blocks missing prescription, expired approval, wrong patient, empty stock and early refill', () => {
  const missingPrescription = copySeed()
  missingPrescription.requests = missingPrescription.requests.map(item => item.id === 'TR-24015' ? { ...item, prescriptionId: undefined } : item)
  assert.throws(() => domain.decide(missingPrescription, 'Pharmacist', 'TR-24015', 'dispense'), /prescription/i)
  const expiredApproval = copySeed()
  expiredApproval.requests = expiredApproval.requests.map(item => item.id === 'TR-24015' ? { ...item, approvalExpiresAt: '2020-01-01' } : item)
  assert.throws(() => domain.decide(expiredApproval, 'Pharmacist', 'TR-24015', 'dispense'), /expired/i)
  const missingPatient = copySeed()
  missingPatient.requests = missingPatient.requests.map(item => item.id === 'TR-24015' ? { ...item, patientId: 'P-NOT-FOUND' } : item)
  assert.throws(() => domain.decide(missingPatient, 'Pharmacist', 'TR-24015', 'dispense'), /patient record is missing/i)
  const noStock = copySeed()
  noStock.batches = noStock.batches.map(item => item.dose === '5 mg' ? { ...item, quantity: 0 } : item)
  assert.throws(() => domain.decide(noStock, 'Pharmacist', 'TR-24015', 'dispense'), /unexpired.*batch/i)
  let refill = copySeed()
  refill.requests = refill.requests.filter(item => item.patientId !== 'P010')
  refill = domain.submitRequest(refill, 'Doctor', 'P010', '5 mg', plan)
  const id = refill.requests[0].id
  refill.dispenses = [{ id: 'DSP-RECENT', requestId: 'TR-OLD', patientId: 'P010', centre: 'Dubai Central Pharmacy', date: date(-7), dispensedAt: new Date(Date.now() - 7 * 86400000).toISOString(), dose: '5 mg' }, ...refill.dispenses]
  assert.throws(() => domain.decide(refill, 'Pharmacist', id, 'dispense'), /monthly refill interval/i)
})

test('patient role is limited to the own profile for clinical, activity and medication data', () => {
  const data = copySeed()
  assert.equal(domain.canReadPatient(data, 'Patient', 'P999'), true)
  assert.equal(domain.canReadPatient(data, 'Patient', 'P001'), false)
  assert.equal(domain.canReadPatient(data, 'Doctor', 'P999'), true)
  assert.equal(domain.canReadPatient(data, 'Doctor', 'P001'), true)
  assert.equal(domain.canReadPatient(data, 'Doctor', 'P003'), false)
  assert.equal(domain.canReadPatient(data, 'Reviewer', 'P010'), true)
  assert.throws(() => domain.recordDose(data, 'Patient', 'P001'), /own patient profile/i)
  assert.throws(() => domain.recordExercise(data, 'Patient', 'P001', { activity: 'Walking', durationMinutes: 20, intensity: 'Light', date: date(0), notes: '' }), /own patient profile/i)
  assert.throws(() => domain.recordDose(data, 'Patient', 'P999', date(1)), /only be recorded for today/i)
})

test('restocking validates quantity, centre, supplier, receipt date and records an audit event', () => {
  const data = copySeed()
  const stocked = domain.restock(data, 'Admin', '5 mg', 4, 'UAE-TRACE-02', date(120), 'Dubai Central Pharmacy', 'Gulf Medical Supply LLC', date(0))
  assert.equal(stocked.batches[0].source, 'Gulf Medical Supply LLC')
  assert.equal(stocked.batches[0].receivedAt, date(0))
  assert.equal(stocked.audit[0].action, 'Inventory restocked')
  assert.throws(() => domain.restock(data, 'Admin', '5 mg', -1, 'UAE-TRACE-03', date(120), 'Dubai Central Pharmacy', 'Gulf Medical Supply LLC', date(0)), /quantity/i)
  assert.throws(() => domain.restock(data, 'Admin', '5 mg', 1, 'UAE-TRACE-04', date(120), 'Unknown centre', 'Supplier', date(0)), /existing programme treatment centre/i)
  assert.throws(() => domain.restock(data, 'Admin', '5 mg', 1, 'UAE-TRACE-05', date(120), 'Dubai Central Pharmacy', '', date(0)), /supplier\/source/i)
  assert.throws(() => domain.restock(data, 'Admin', '5 mg', 1, 'UAE-TRACE-06', date(120), 'Dubai Central Pharmacy', 'Supplier', date(1)), /receipt date/i)
})

test('notifications can be read by the recipient and alerts are role-gated and auditable', () => {
  const data = copySeed()
  data.notifications = [{ id: 'NT-OTHER', patientId: 'P010', title: 'Private update', detail: 'Care team note', createdAt: 'now', read: false }, { id: 'NT-999', patientId: 'P999', title: 'Patient update', detail: 'Own profile note', createdAt: 'now', read: false }, ...data.notifications]
  assert.throws(() => domain.markNotificationRead(data, 'Patient', 'NT-OTHER'), /own patient profile/i)
  const readOne = domain.markNotificationRead(data, 'Patient', 'NT-999')
  assert.equal(readOne.notifications.find(item => item.id === 'NT-999').read, true)
  const readAll = domain.markNotificationsRead(data, 'Patient')
  assert.equal(readAll.notifications.find(item => item.id === 'NT-OTHER').read, false)
  assert.equal(readAll.notifications.find(item => item.id === 'NT-999').read, true)
  assert.throws(() => domain.dismissAlert(data, 'Reviewer', 'stock-5 mg'), /cannot/i)
  const dismissed = domain.dismissAlert(data, 'Admin', 'stock-5 mg')
  assert.ok(dismissed.dismissedAlerts.includes('stock-5 mg'))
  assert.equal(dismissed.audit[0].action, 'Alert dismissed')
  assert.ok(domain.markAlertRead(dismissed, 'Admin', 'stock-5 mg').readAlerts.includes('stock-5 mg'))
})

test('invalid clinical and appointment data are blocked at the domain layer', () => {
  const data = copySeed()
  assert.throws(() => domain.recordVitals(data, 'Doctor', 'P999', { weightKg: 75, heightCm: 170, systolic: 110, diastolic: 120, heartRate: 70 }), /clinically plausible/i)
  assert.throws(() => domain.recordLab(data, 'Doctor', 'P999', { test: 'HbA1c', value: 6, unit: '%', reference: '', status: 'Abnormal', date: '2026-02-30', source: 'Lab', interpretation: '' }), /valid collection date/i)
  const appointment = { patientId: 'P010', doctor: 'Dr. Laila Hassan', centre: 'Dubai Primary Care Centre 4', purpose: 'Follow-up', date: date(15), time: '15:45', status: 'Scheduled', notes: '' }
  assert.throws(() => domain.saveAppointment(data, 'Doctor', { ...appointment, centre: 'Unknown clinic' }), /existing programme treatment centre/i)
})

test('doctor directory changes synchronize patient centre assignments and audit before and after state', () => {
  const data = copySeed()
  const updated = domain.updateDoctorProfile(data, 'Admin', 'DOC-001', { centre: 'Sharjah Health Centre', status: 'Inactive' })
  assert.equal(updated.doctors.find(item => item.id === 'DOC-001').centre, 'Sharjah Health Centre')
  assert.equal(updated.doctors.find(item => item.id === 'DOC-001').status, 'Inactive')
  assert.ok(updated.patients.filter(item => item.assignedDoctor === 'Dr. Laila Hassan').every(item => item.treatmentCentre === 'Sharjah Health Centre'))
  assert.equal(updated.audit[0].previousState, 'Active · Dubai Primary Care Centre 4')
  assert.equal(updated.audit[0].newState, 'Inactive · Sharjah Health Centre')
  assert.throws(() => domain.updateDoctorProfile(data, 'Doctor', 'DOC-001', { centre: 'Sharjah Health Centre', status: 'Active' }), /cannot perform/i)
})

test('centre status and safety review changes are permissioned and recorded separately', () => {
  const data = copySeed()
  const inactive = domain.updateCentreStatus(data, 'Admin', 'CTR-AJM-01', 'Inactive')
  assert.equal(inactive.centres.find(item => item.id === 'CTR-AJM-01').status, 'Inactive')
  assert.equal(inactive.audit[0].entity, 'Treatment centre')
  assert.equal(inactive.audit[0].previousState, 'Active')
  assert.throws(() => domain.updateCentreStatus(data, 'Reviewer', 'CTR-AJM-01', 'Inactive'), /cannot perform/i)
  assert.throws(() => domain.restock(inactive, 'Admin', '5 mg', 1, 'UAE-INACTIVE-CENTRE', date(120), 'Ajman Medical Centre', 'Supplier', date(0)), /treatment centre that is active/i)
  const signal = { id: 'SIG-TEST', eventType: 'Early refill pattern', severity: 'Warning', evidence: 'Two records are less than 28 days apart.', timestamp: new Date().toISOString(), patientId: 'P999', requestId: 'TR-24008' }
  const reviewed = domain.setAbuseReviewStatus(data, 'Admin', signal, 'Under Review')
  assert.equal(reviewed.abuseReviews[0].status, 'Under Review')
  assert.equal(reviewed.audit[0].entity, 'Safety review')
  assert.equal(reviewed.audit[0].previousState, 'New')
  assert.equal(reviewed.audit[0].newState, 'Under Review')
})

test('admin alert and misuse views derive their counts and signals from canonical records', () => {
  const data = copySeed()
  const alerts = analytics.operationalAlerts(data, Date.parse('2026-10-01T12:00:00.000Z'))
  assert.ok(alerts.some(item => item.id === 'stock-10 mg'))
  assert.ok(alerts.some(item => item.id === 'expiry-BT-4'))
  assert.ok(alerts.some(item => item.id === 'request-TR-24018'))
  assert.equal(analytics.misuseSignals(data).length, 2)
  data.requests.push({ ...data.requests.find(item => item.id === 'TR-24018'), id: 'TR-DUPLICATE' })
  const flags = analytics.misuseSignals(data)
  assert.equal(flags[0].id, 'duplicate-active-P010')
  assert.equal(flags[0].patientId, 'P010')
})

test('enriched scenarios reconcile every batch movement and all patient/request/plan references', () => {
  const data=copySeed()
  for(const batch of data.batches) assert.equal(data.movements.filter(item=>item.batchId===batch.id).reduce((n,item)=>n+item.quantity,0),batch.quantity,batch.id)
  for(const request of data.requests){assert.ok(data.patients.some(item=>item.id===request.patientId));assert.ok(data.treatmentPlans.some(item=>item.id===request.planId && item.patientId===request.patientId && item.dose===request.dose))}
  for(const dose of data.doses) assert.ok(data.requests.some(item=>item.id===dose.requestId && item.patientId===dose.patientId))
  for(const notification of data.notifications) assert.ok(data.patients.some(item=>item.id===notification.patientId))
  assert.equal(domain.calculateEligibility(data.patients.find(p=>p.id==='P006'),data.labs).eligible,false)
  assert.ok(data.labs.filter(item=>item.status!=='Pending' && item.test==='HbA1c').every(item=>item.value>=4 && item.value<=15))
})
test('shared verification blocks identity and early refill without changing inventory',()=>{
  const data=copySeed(); const before=JSON.stringify(data)
  assert.equal(domain.verifyPharmacyRequest(data,'TR-24015',false).find(c=>c.id==='identity').passed,false)
  assert.throws(()=>domain.dispenseMedication(data,'Pharmacist','TR-24015',false),/identity/i)
  assert.throws(()=>domain.dispenseMedication(data,'Pharmacist','TR-P009-REFILL',true),/refill/i)
  assert.equal(JSON.stringify(data),before)
  const next=domain.dispenseMedication(data,'Pharmacist','TR-24015',true)
  assert.ok(next.audit.some(item=>item.action==='Pharmacy verification completed' && item.patientId==='P012' && item.metadata.identity))
  assert.equal(next.dispenses.length,data.dispenses.length+1)
  assert.throws(()=>domain.dispenseMedication(next,'Pharmacist','TR-24015',true),/duplicate|approval/i)
})
test('approval release and completion have explicit role and lifecycle guards',()=>{
  let data=copySeed()
  assert.throws(()=>domain.releaseToPharmacy(data,'Doctor','TR-24017'),/cannot/i)
  data=domain.releaseToPharmacy(data,'Reviewer','TR-24017')
  assert.equal(data.requests.find(r=>r.id==='TR-24017').status,'Ready to dispense')
  assert.throws(()=>domain.releaseToPharmacy(data,'Reviewer','TR-24017'),/approved/i)
  assert.throws(()=>domain.completeTreatment(data,'Reviewer','TR-24008','Follow-up completed.'),/cannot/i)
  assert.throws(()=>domain.completeTreatment(data,'Doctor','TR-24008','short'),/8 characters/i)
  data=domain.completeTreatment(data,'Doctor','TR-24008','Follow-up completed and plan reviewed.')
  assert.equal(data.requests.find(r=>r.id==='TR-24008').status,'Completed')
  assert.equal(data.treatmentPlans.find(r=>r.id==='TP-8781').status,'Completed')
})
test('full care journey remains linked from clinical evidence to dispensing, dose, exercise and reports',()=>{
  let data=copySeed()
  data=domain.recordVitals(data,'Doctor','P999',{weightKg:108,heightCm:175,systolic:122,diastolic:78,heartRate:72})
  data=domain.recordLab(data,'Doctor','P999',{test:'HbA1c',value:7.2,unit:'%',reference:'Demo',status:'Abnormal',date:date(0),source:'Demo lab',interpretation:'Reviewed by clinician'})
  data=domain.saveAssessment(data,'Doctor',{patientId:'P999',reason:'Follow-up',diagnosis:'Type 2 diabetes',symptoms:'None',medicalHistory:'Reviewed',medications:'Reviewed',allergies:'None recorded',findings:'Evidence reviewed',notes:'Continue follow-up',status:'Submitted'})
  data=domain.submitRequest(data,'Doctor','P999','5 mg',plan)
  const request=data.requests[0]
  assert.equal(request.status,'Ready to dispense')
  data=domain.dispenseMedication(data,'Pharmacist',request.id,true)
  data=domain.recordDose(data,'Patient','P999')
  data=domain.recordExercise(data,'Patient','P999',{activity:'Home exercise',durationMinutes:15,intensity:'Light',date:date(0),notes:'Completed'})
  data=domain.saveAppointment(data,'Doctor',{patientId:'P999',doctor:'Dr. Laila Hassan',centre:'Dubai Primary Care Centre 4',purpose:'Follow-up',date:date(14),time:'14:30',status:'Scheduled',notes:'Review response'})
  data=domain.canonicalize(data)
  const graph=domain.domainGraph(data)
  assert.equal(data.doses[0].requestId,request.id)
  assert.ok(graph.pharmacyVerifications.some(item=>item.requestId===request.id))
  assert.ok(graph.prescriptions.some(item=>item.requestId===request.id && item.medicationId==='MED-001'))
  assert.ok(graph.coverageEstimates.some(item=>item.requestId===request.id && item.totalAED===item.supportAED+item.patientAED))
  assert.ok(domain.patientJourney(data,'P999').every(item=>item.complete))
  assert.equal(new Set(data.audit.map(item=>item.id)).size,data.audit.length)
  assert.equal(new Set(data.notifications.map(item=>item.id)).size,data.notifications.length)
})
test('registration uses one ID across care assignment and audit and rejects unauthorized writes',()=>{
  const input={name:'Hana Al Ali',age:38,sex:'Female',emirate:'Dubai',centreId:'CTR-DXB-04',doctorId:'DOC-001'}
  assert.throws(()=>domain.registerPatient(copySeed(),'Patient',input),/cannot/i)
  const data=domain.canonicalize(domain.registerPatient(copySeed(),'Admin',input));const person=data.patients.at(-1)
  assert.equal(person.doctorId,'DOC-001');assert.equal(person.centreId,'CTR-DXB-04');assert.equal(person.eligibility,'Review required')
  const missing=domain.calculateEligibility(person,data.labs).missing
  assert.ok(missing.some(item=>item.label==='BMI at or above 30'))
  assert.equal(data.audit[0].patientId,person.id)
})
test('patient intake creates linked clinical evidence, appointment and uploaded document without inventing treatment',()=>{
  const source=copySeed()
  const intake={patient:{name:'Mariam Al Suwaidi',nameAr:'مريم السويدي',age:42,sex:'Female',residency:'Citizen',nationality:'Emirati',emiratesId:'784-1984-7654321-3',centreId:'CTR-DXB-04',doctorId:'DOC-001',diagnosis:'Type 2 diabetes',previousIllnesses:['Gestational diabetes'],chronicConditions:['Type 2 diabetes'],procedures:[{name:'Appendectomy',date:'2020-01-10',note:'Recovered'}]},vitals:{weightKg:95,heightCm:165,systolic:122,diastolic:78,heartRate:74},labs:[{test:'HbA1c',value:7.8,unit:'%',reference:'4.0–5.6',status:'Abnormal',date:date(0),source:'Clinic lab',interpretation:'Elevated'}],assessment:{reason:'New patient intake',diagnosis:'Type 2 diabetes',symptoms:'Fatigue',medicalHistory:'Reviewed',medications:'None',allergies:'None',findings:'Exam documented',notes:'Follow-up planned',status:'Submitted'},appointment:{purpose:'Initial follow-up',date:date(10),time:'13:15',notes:'Review results'},documents:[{title:'Lab report',content:'HbA1c report',fileName:'report.pdf',mimeType:'application/pdf',dataUrl:'data:application/pdf;base64,JVBERi0=',sizeBytes:8}]}
  const next=domain.canonicalize(domain.registerPatientWithIntake(source,'Doctor',intake))
  const patient=next.patients.at(-1)
  assert.equal(patient.nameAr,'مريم السويدي')
  assert.equal(patient.emiratesId,intake.patient.emiratesId)
  assert.equal(patient.bmi,34.9)
  assert.equal(patient.eligibility,'Meets clinical criteria')
  for(const key of ['vitals','labs','assessments','appointments','documents']) assert.ok(next[key].some(record=>record.patientId===patient.id),key)
  assert.equal(next.documents.at(-1).fileName,'report.pdf')
  assert.equal(next.requests.filter(record=>record.patientId===patient.id).length,0)
  assert.equal(next.dispenses.filter(record=>record.patientId===patient.id).length,0)
  assert.equal(next.patients.find(record=>record.id===patient.id).treatmentStatus,'No active plan')
  assert.throws(()=>domain.registerPatientWithIntake(source,'Admin',{...intake,patient:{...intake.patient,emiratesId:'784-1990-1234567-1'}}),/already exists/i)
  assert.throws(()=>domain.registerPatientWithIntake(source,'Doctor',{...intake,patient:{...intake.patient,doctorId:'DOC-002'}}),/own assignment/i)
  assert.equal(source.patients.length,150)
})
test('every seeded patient has a downloadable report based on that patient’s lab evidence',()=>{
  const data=copySeed()
  for(const patient of data.patients){
    const report=data.documents.find(document=>document.patientId===patient.id&&document.title.includes('laboratory report'))
    const lab=data.labs.filter(item=>item.patientId===patient.id).sort((a,b)=>b.date.localeCompare(a.date))[0]
    assert.ok(report,patient.id)
    assert.equal(report.date,lab.date)
    assert.ok(decodeURIComponent(report.dataUrl).includes(`Patient / المريض: ${patient.name} (${patient.id})`))
    assert.ok(decodeURIComponent(report.dataUrl).includes(`Test / التحليل: ${lab.test}`))
  }
})
test('clinician lab upload keeps the result and source document on one patient record',()=>{
  let data=copySeed()
  data=domain.recordLab(data,'Doctor','P999',{test:'Fasting glucose',value:132,unit:'mg/dL',reference:'70–100',status:'Abnormal',date:date(0),source:'Uploaded report',interpretation:'Clinician verified simulated extraction'})
  data=domain.attachPatientDocument(data,'Doctor','P999',{title:'Fasting glucose laboratory report',content:'132 mg/dL · clinician verified',fileName:'glucose.png',mimeType:'image/png',dataUrl:'data:image/png;base64,iVBORw0KGgo=',sizeBytes:10,labResultId:data.labs[0].id})
  assert.equal(data.labs[0].patientId,'P999')
  assert.equal(data.documents.at(-1).patientId,'P999')
  assert.equal(data.documents.at(-1).fileName,'glucose.png')
  assert.equal(data.documents.at(-1).labResultId,data.labs[0].id)
  assert.equal(data.labs.filter(item=>item.patientId==='P001'&&item.test==='Fasting glucose').length,0)
  assert.throws(()=>domain.attachPatientDocument(data,'Patient','P999',{title:'x',fileName:'x.png',mimeType:'image/png',dataUrl:'data:image/png;base64,AA==',sizeBytes:1}),/cannot/i)
})
test('non-finite vitals, activity durations and access to another doctors appointment are rejected',()=>{
  const data=copySeed()
  assert.throws(()=>domain.recordVitals(data,'Doctor','P999',{weightKg:NaN,heightCm:175,systolic:120,diastolic:80,heartRate:72}),/plausible/i)
  assert.throws(()=>domain.recordExercise(data,'Patient','P999',{activity:'Walking',durationMinutes:NaN,intensity:'Light',date:date(0),notes:''}),/valid activity/i)
  data.appointments.push({id:'OTHER',patientId:'P003',doctor:'Dr. Omar Khalid',centre:'Abu Dhabi Primary Care Centre 2',purpose:'Review',date:date(2),time:'08:00',status:'Scheduled',notes:''})
  assert.throws(()=>domain.changeAppointmentStatus(data,'Doctor','OTHER','Cancelled'),/cannot access/i)
})
test('current evidence takes newest collection date rather than insertion order',()=>{
  const data=copySeed(),patient=data.patients[0]
  const labs=[{...data.labs[0],date:'2026-01-01',value:9},{...data.labs[0],date:'2026-09-25',value:7}]
  assert.match(domain.calculateEligibility(patient,labs).criteria.at(-1).evidence,/7 %/)
})

test('rehabilitation assignments are patient scoped, validated and synchronized with notifications',()=>{
 const input={patientId:'P999',title:'Supported mobility',activities:['Home exercise','Walking'],weeklySessions:3,reviewDate:date(14)}
 assert.throws(()=>domain.saveCareProgram(copySeed(),'Patient',input),/cannot/i)
 assert.throws(()=>domain.saveCareProgram(copySeed(),'Doctor',{...input,weeklySessions:0}),/weekly sessions/i)
 const data=domain.saveCareProgram(copySeed(),'Doctor',input)
 assert.equal(data.carePrograms.filter(item=>item.patientId==='P999').length,1)
 assert.equal(data.carePrograms[0].clinicianId,'DOC-001')
 assert.equal(data.notifications[0].patientId,'P999')
 assert.equal(data.audit[0].entityId,data.carePrograms[0].id)
})

test('draft submission preserves patient, request and plan identifiers and enforces evidence',()=>{
 let data=copySeed();data.requests=data.requests.filter(item=>item.patientId!=='P010')
 data=domain.saveTreatmentDraft(data,'Doctor','P010','5 mg',plan)
 const request=data.requests[0],planId=request.planId
 assert.equal(request.status,'Draft')
 assert.throws(()=>domain.submitTreatmentDraft(data,'Patient',request.id),/cannot/i)
 const next=domain.submitTreatmentDraft(data,'Doctor',request.id)
 assert.equal(next.requests[0].id,request.id);assert.equal(next.requests[0].status,'Ready to dispense')
 assert.equal(next.treatmentPlans[0].id,planId);assert.equal(next.notifications[0].relatedEntityId,request.id)
 assert.equal(next.audit[0].entityId,request.id)
 assert.equal(next.requests.filter(item=>item.id===request.id).length,1)
})

test('adherence follows the dispensed prescription schedule and excludes future dose records',()=>{
  const data=copySeed(); const request=data.requests.find(item=>item.patientId==='P999' && item.status==='Dispensed')
  const treatment=data.treatmentPlans.find(item=>item.id===request.planId)
  data.doses=[{id:'D-SCHEDULE',patientId:'P999',requestId:request.id,dose:request.dose,recordedAt:new Date().toISOString()}, {id:'D-FUTURE',patientId:'P999',requestId:request.id,dose:request.dose,recordedAt:new Date(Date.now()+86400000).toISOString()}]
  treatment.frequency='Daily';assert.equal(domain.adherenceFor(data,'P999'),4)
  treatment.frequency='Every 2 weeks';assert.equal(domain.adherenceFor(data,'P999'),50)
  treatment.frequency='Weekly';assert.equal(domain.adherenceFor(data,'P999'),25)
})

test('coverage applies the exact Citizen, Resident and Visitor rules centrally',()=>{
  for(const [type,discount,patientAmount] of [['Citizen',100,0],['Resident',50,500],['Visitor',0,1000]]){
    const result=domain.calculateCoverage(type,1000)
    assert.equal(result.discountPercent,discount);assert.equal(result.patientAED,patientAmount)
    assert.equal(result.patientAED+result.supportAED,result.totalAED)
  }
  assert.throws(()=>domain.calculateCoverage('Unknown',1000),/valid/i)
  assert.throws(()=>domain.calculateCoverage('Resident',NaN),/valid/i)
  assert.throws(()=>domain.calculateCoverage('Citizen',-1),/valid/i)
  assert.equal(domain.calculateCoverage('Resident',1000.05).patientAED,500.02)
})
const integratedInput=()=>({patientId:'P001',title:'Integrated metabolic recovery',medication:{medicationId:'MED-001',dose:'5 mg',frequency:'Weekly',durationDays:84,instructions:'Use only according to the approved prescription.'},rehabilitation:{programId:'RP-PHYSIO',centreId:'RC-AUH',plannedSessions:6},homeExerciseIds:['HE-STRENGTH','HE-WALK','HE-FLEX'],startDate:date(0),followUpDate:date(14),followUpTime:'15:45',monitoring:'Review medication response and mobility progress.',rationale:'Clinical evidence and functional goals reviewed with the patient.'})
test('P001 resident integrated care cycle stays linked through review, dispensing, rehabilitation and patient activity',()=>{
  let data=copySeed();assert.equal(data.patients.find(p=>p.id==='P001').residency,'Resident')
  // Keep this review-path fixture inside the monthly refill window as time advances.
  data.dispenses=data.dispenses.map(d=>d.patientId==='P001'?{...d,date:date(-2),dispensedAt:`${date(-2)}T10:00:00.000Z`}:d)
  assert.equal(domain.nearbyRehabilitation(data,'P001','RP-PHYSIO')[0].id,'RC-AUH')
  const stock=domain.onHandByDose(data)['5 mg']
  data=domain.createIntegratedCarePlan(data,'Doctor',integratedInput())
  const plan=data.integratedCarePlans[0],request=data.requests.find(r=>r.id===plan.treatmentRequestId),financial=data.financial.find(f=>f.integratedCarePlanId===plan.id)
  assert.equal(plan.patientId,'P001');assert.equal(plan.doctorId,'DOC-001');assert.equal(request.integratedCarePlanId,plan.id)
  assert.equal(request.status,'Under review');assert.equal(plan.homeExerciseIds.length,3)
  assert.equal(plan.coverage.totalAED,2100);assert.equal(plan.coverage.patientAED,1050)
  assert.equal(data.appointments.find(a=>a.id===plan.appointmentId).patientId,'P001')
  data=domain.decide(data,'Reviewer',request.id,'approve','Clinical evidence and integrated plan reviewed.')
  data=domain.canonicalize(domain.dispenseMedication(data,'Pharmacist',request.id,true))
  assert.equal(domain.onHandByDose(data)['5 mg'],stock-1)
  assert.equal(data.financial.filter(f=>f.integratedCarePlanId===plan.id).length,1)
  assert.equal(data.financial.find(f=>f.id===financial.id).coverage.patientAED,1050)
  assert.ok(data.financial.find(f=>f.id===financial.id).dispensedAt)
  assert.ok(data.dispenses.some(d=>d.requestId===request.id&&d.patientId==='P001'))
  data=domain.recordRehabilitationSession(data,'Doctor',plan.id,date(0),'Mobility session completed with good participation.')
  assert.equal(data.integratedCarePlans.find(p=>p.id===plan.id).rehabilitation.sessions.length,1)
  assert.throws(()=>domain.recordRehabilitationSession(data,'Doctor',plan.id,date(0),'Duplicate session should be rejected.'),/already/i)
  data={...data,activePatientId:'P001'}
  data=domain.recordExercise(data,'Patient','P001',{activity:'Walking',durationMinutes:20,intensity:'Light',date:date(0),notes:'Prescribed walk completed.',integratedCarePlanId:plan.id,exerciseId:'HE-WALK'})
  assert.equal(data.exercise[0].integratedCarePlanId,plan.id)
  assert.ok(data.notifications.some(n=>n.relatedEntityId===plan.id&&n.patientId==='P001'))
  assert.ok(domain.domainGraph(data).integratedCarePlans.some(p=>p.id===plan.id))
  assert.throws(()=>domain.recordExercise(data,'Patient','P999',{activity:'Walking',durationMinutes:20,intensity:'Light',date:date(0),notes:''}),/own/i)
})
test('care plan validation is atomic for capacity, unknown exercises, inactive centers and missing confirmation',()=>{
  const data=copySeed(),before=JSON.stringify(data)
  assert.throws(()=>domain.createIntegratedCarePlan(data,'Patient',integratedInput()),/cannot/i)
  for(const input of [ {...integratedInput(),rationale:''}, {...integratedInput(),homeExerciseIds:['NOT-A-PROGRAM']}, {...integratedInput(),rehabilitation:{programId:'RP-RECOVERY',centreId:'RC-FUJ',plannedSessions:6}}, {...integratedInput(),rehabilitation:{programId:'RP-PHYSIO',centreId:'RC-AUH',plannedSessions:NaN}} ]) assert.throws(()=>domain.createIntegratedCarePlan(data,'Doctor',input),/complete/i)
  assert.equal(JSON.stringify(data),before)
  const full=copySeed();full.rehabilitationCentres.find(c=>c.id==='RC-AUH').capacity=0
  assert.throws(()=>domain.createIntegratedCarePlan(full,'Doctor',integratedInput()),/availability/i)
})
test('care plans without medication support all patient types without creating a phantom request',()=>{
  for(const [patientType,expected] of [['Citizen',0],['Resident',450],['Visitor',900]]){
    const data=copySeed();data.patients.find(p=>p.id==='P001').residency=patientType
    const input={...integratedInput(),medication:undefined}
    const next=domain.createIntegratedCarePlan(data,'Doctor',input)
    assert.equal(next.requests.length,data.requests.length)
    assert.equal(next.integratedCarePlans[0].coverage.patientAED,expected)
    assert.equal(next.integratedCarePlans[0].treatmentRequestId,undefined)
  }
})

test('focused care plan stores decision support and accepts eighty rehabilitation sessions',()=>{
  const data=copySeed()
  const input={...integratedInput(),medication:undefined,homeExerciseIds:[],rehabilitation:{programId:'RP-PHYSIO',centreId:'RC-AUH',plannedSessions:80}}
  const assessment=domain.assessCarePlan(data,input)
  assert.ok(domain.assessCarePlan(data,{...input,homeExerciseIds:['HE-WALK']}).score>assessment.score)
  const next=domain.createIntegratedCarePlan(data,'Doctor',input)
  const plan=next.integratedCarePlans[0]
  assert.equal(plan.rehabilitation.plannedSessions,80)
  assert.equal(plan.aiPlanScore,assessment.score)
  assert.deepEqual(plan.aiRecommendations,assessment.recommendations)
  assert.equal(next.requests.length,data.requests.length)
  assert.ok(next.audit.some(item=>item.entityId===plan.id))
  assert.ok(next.notifications.some(item=>item.relatedEntityId===plan.id))
  assert.equal(domain.integratedCareChecks(data,{...input,rehabilitation:undefined})[2].passed,false)
})

test('medication frequencies are validated against the central catalog',()=>{
  const data=copySeed()
  const input={...integratedInput(),medication:{...integratedInput().medication,frequency:'Daily'}}
  assert.equal(domain.integratedCareChecks(data,input)[3].passed,false)
  assert.throws(()=>domain.createIntegratedCarePlan(data,'Doctor',input),/Medication evidence/i)
})

test('an existing medication request joins a care plan without a second prescription or review',()=>{
  const input=integratedInput()
  let data=domain.submitRequest(copySeed(),'Doctor','P001','5 mg',{...plan,instructions:input.medication.instructions},{doctorRationale:'Early refill clinically justified for this patient.'})
  const request=data.requests[0],treatment=data.treatmentPlans.find(p=>p.id===request.planId)
  input.medication={requestId:request.id,medicationId:'MED-001',dose:request.dose,frequency:treatment.frequency,durationDays:treatment.durationDays,instructions:treatment.instructions}
  const next=domain.createIntegratedCarePlan(data,'Doctor',input)
  assert.equal(next.requests.length,data.requests.length)
  assert.equal(next.treatmentPlans.length,data.treatmentPlans.length)
  assert.equal(next.integratedCarePlans[0].treatmentRequestId,request.id)
  assert.equal(next.requests.find(r=>r.id===request.id).status,request.status)
  assert.throws(()=>domain.createIntegratedCarePlan(next,'Doctor',{...input,followUpTime:'12:30'}),/unlinked/i)
  assert.throws(()=>domain.createIntegratedCarePlan(data,'Doctor',{...input,medication:{...input.medication,dose:'10 mg'}}),/unchanged/i)
})

test('all patient categories retain exact coverage through medication approval and dispensing',()=>{
  for(const [patientType,discount,patientAmount] of [['Citizen',100,0],['Resident',50,1050],['Visitor',0,2100]]){
    let data=copySeed();data.patients.find(p=>p.id==='P001').residency=patientType
  // Keep this review-path fixture inside the monthly refill window as time advances.
  data.dispenses=data.dispenses.map(d=>d.patientId==='P001'?{...d,date:date(-2),dispensedAt:`${date(-2)}T10:00:00.000Z`}:d)
    data=domain.createIntegratedCarePlan(data,'Doctor',integratedInput())
    const care=data.integratedCarePlans[0]
    data=domain.decide(data,'Reviewer',care.treatmentRequestId,'approve','Clinical evidence reviewed for demonstration.')
    data=domain.dispenseMedication(data,'Pharmacist',care.treatmentRequestId,true)
    const estimate=data.financial.find(f=>f.integratedCarePlanId===care.id)
    assert.equal(estimate.coverage.discountPercent,discount)
    assert.equal(estimate.coverage.patientAED,patientAmount)
    assert.deepEqual(estimate.coverage,care.coverage)
    assert.equal(data.financial.filter(f=>f.requestId===care.treatmentRequestId).length,1)
  }
})

test('historical rehabilitation migration reconciles coverage once without dispensing stock twice',()=>{
  const data=copySeed(),next=domain.initializeCareEcosystem(data),again=domain.initializeCareEcosystem(next)
  for(const legacy of data.carePrograms){
    const care=again.integratedCarePlans.find(p=>p.id===`ICP-${legacy.id}`)
    const financial=again.financial.filter(f=>f.integratedCarePlanId===care.id)
    assert.equal(financial.length,1)
    assert.deepEqual(financial[0].coverage,care.coverage)
    assert.equal(again.requests.find(r=>r.id===care.treatmentRequestId).integratedCarePlanId,care.id)
  }
  assert.deepEqual(again.batches,data.batches)
  assert.equal(again.dispenses.length,data.dispenses.length)
  assert.equal(again.financial.length,next.financial.length)
})

test('care-plan follow-up rescheduling and completion update the patient context',()=>{
  let data=domain.createIntegratedCarePlan(copySeed(),'Doctor',{...integratedInput(),medication:undefined})
  const care=data.integratedCarePlans[0],appointment=data.appointments.find(a=>a.id===care.appointmentId)
  data=domain.saveAppointment(data,'Doctor',{...appointment,date:date(16)})
  assert.equal(data.integratedCarePlans.find(p=>p.id===care.id).followUpDate,date(16))
  // Advance the appointment fixture into the past before recording attendance.
  data.appointments.find(a=>a.id===appointment.id).date=date(-1)
  data=domain.changeAppointmentStatus(data,'Doctor',appointment.id,'Completed')
  assert.equal(data.patients.find(p=>p.id==='P001').lastFollowup,date(-1))
  assert.equal(data.appointments.find(a=>a.id===appointment.id).status,'Completed')
  assert.ok(data.notifications.some(n=>n.relatedEntityId===appointment.id))
})


test('monthly dispensing interval uses a calendar month, including shorter months', () => {
  const data=copySeed()
  data.dispenses=[{id:'D',patientId:'P010',requestId:'OLD',date:'2026-01-31',dose:'5 mg',centre:'Test'}]
  assert.equal(domain.refillEligibility(data,'P010','2026-02-27').eligible,false)
  assert.equal(domain.refillEligibility(data,'P010','2026-02-27').nextEligibleDate,'2026-02-28')
  assert.equal(domain.refillEligibility(data,'P010','2026-02-28').eligible,true)
  data.dispenses[0].date='2024-01-31'
  assert.equal(domain.refillEligibility(data,'P010','2024-02-28').nextEligibleDate,'2024-02-29')
})

test('early refill requires doctor rationale, independent reviewer reason and pharmacy safety verification',()=>{
  let data=copySeed()
  data.requests=data.requests.filter(item=>item.patientId!=='P001')
  data.dispenses=data.dispenses.map(d=>d.patientId==='P001'?{...d,date:date(-2),dispensedAt:`${date(-2)}T10:00:00.000Z`}:d)
  assert.equal(domain.treatmentEligibility(data,'P001').refill.eligible,false)
  assert.throws(()=>domain.submitRequest(data,'Doctor','P001','5 mg',plan),/doctor rationale/i)
  data=domain.submitRequest(data,'Doctor','P001','5 mg',plan,{doctorRationale:'Early refill is clinically necessary after dose loss.'})
  const request=data.requests[0]
  assert.equal(request.status,'Under review')
  assert.equal(request.approvalRoute,'Exception review')
  assert.equal(request.doctorRationale,'Early refill is clinically necessary after dose loss.')
  assert.throws(()=>domain.decide(data,'Reviewer',request.id,'approve'),/reviewer exception approval/i)
  assert.throws(()=>domain.decide(data,'Pharmacist',request.id,'dispense'),/approved/i)
  data=domain.decide(data,'Reviewer',request.id,'approve','Documented early refill exception accepted.')
  assert.equal(data.requests[0].status,'Ready to dispense')
  assert.equal(data.requests[0].exceptionApproved,true)
  assert.equal(domain.verifyPharmacyRequest(data,request.id,true).find(x=>x.id==='refill').passed,true)
  data=domain.dispenseMedication(data,'Pharmacist',request.id,true)
  assert.equal(data.requests[0].status,'Dispensed')
  assert.equal(data.dispenses[0].requestId,request.id)
})

test('canonical patient records keep distinct Arabic names after migration', () => {
  const data=copySeed()
  const older={...data,patients:data.patients.map(p=>p.id==='P010'?{...p,nameAr:'مستفيد البرنامج'}:p)}
  const repaired=domain.canonicalize(older)
  assert.equal(repaired.patients.find(p=>p.id==='P010').nameAr,'مريم الكعبي')
  assert.equal(repaired.patients.find(p=>p.id==='P999').nameAr,'أحمد المنصوري')
})

test('pharmacy payment follows a confirmed dispense, uses medication coverage, and creates one patient receipt', () => {
  let data = copySeed()
  data.requests = data.requests.filter(item => item.patientId !== 'P010')
  data = domain.submitRequest(data, 'Doctor', 'P010', '5 mg', plan)
  const requestId = data.requests[0].id
  assert.throws(() => domain.recordDispensingPayment(data, 'Pharmacist', requestId, 'Cash'), /Confirm dispensing/)
  data = domain.dispenseMedication(data, 'Pharmacist', requestId, true)
  const beforeStock = domain.onHandByDose(data)['5 mg']
  data = domain.recordDispensingPayment(data, 'Pharmacist', requestId, 'Card')
  const payment = data.payments[0]
  const patient = data.patients.find(item => item.id === 'P010')
  const price = data.medications.find(item => item.name === data.requests[0].medication).unitCostAED
  assert.equal(payment.amountAED, domain.calculateCoverage(patient.residency, price).patientAED)
  assert.equal(payment.dispenseId, data.dispenses[0].id)
  assert.equal(data.notifications[0].patientId, patient.id)
  assert.equal(data.notifications[0].title, 'Dispensing receipt')
  assert.equal(domain.onHandByDose(data)['5 mg'], beforeStock)
  assert.throws(() => domain.recordDispensingPayment(data, 'Pharmacist', requestId, 'Cash'), /already recorded/)
})

test('pharmacist supply request is stored once in the shared inventory model and audited', () => {
  const initial = copySeed()
  const centre = initial.centres.find(item => item.pharmacy === 'Dubai Central Pharmacy').name
  const next = domain.requestStockSupply(initial, 'Pharmacist', '10 mg', centre, 8)
  assert.equal(next.supplyRequests[0].dose, '10 mg')
  assert.equal(next.supplyRequests[0].centre, centre)
  assert.equal(next.supplyRequests[0].quantity, 8)
  assert.equal(next.audit[0].entityId, next.supplyRequests[0].id)
  assert.deepEqual(next.batches, initial.batches)
  assert.throws(() => domain.requestStockSupply(next, 'Pharmacist', '10 mg', centre, 8), /already open/)
  assert.throws(() => domain.requestStockSupply(initial, 'Patient', '10 mg', centre, 8), /cannot perform/)
})

test('150 demo patients include mixed portraits and complete linked intake records for the 99 additions',()=>{
 const data=copySeed()
 assert.equal(new Set(data.patients.map(p=>p.id)).size,150)
 assert.deepEqual([...new Set(data.patients.map(p=>p.demoPortrait.collection))].sort(),['emirati','everyday'])
 for(const patient of data.patients){
  assert.ok(patient.demoPortrait.slot>=0&&patient.demoPortrait.slot<16)
  assert.equal(patient.demoPortrait.slot>=8,patient.sex==='Female')
 }
 const added=data.patients.filter(p=>Number(p.id.slice(1))>=51&&p.id!=='P999')
 assert.equal(added.length,99)
 assert.equal(new Set(added.map(p=>p.name)).size,99)
 for(const p of added){
  assert.ok(p.nameAr&&p.age>=18&&p.doctorId&&p.centreId)
  assert.equal(data.labs.filter(l=>l.patientId===p.id).length,3)
  assert.ok(data.vitals.some(v=>v.patientId===p.id))
  assert.ok(data.assessments.some(a=>a.patientId===p.id&&a.status==='Submitted'))
  assert.ok(data.appointments.some(a=>a.patientId===p.id))
  assert.ok(data.documents.some(d=>d.patientId===p.id))
 }
})

test('clinical exception survives draft save, edit and submission before reviewer approval and dispensing', () => {
  let data=copySeed()
  const patientId='P051'
  data.patients=data.patients.map(p=>p.id===patientId?{...p,bmi:24}:p)
  const rationale='مراجعة استثنائية موثقة لاختبار المسار التجريبي.'
  data=domain.saveTreatmentDraft(data,'Doctor',patientId,'5 mg',plan,undefined,{doctorRationale:rationale})
  const draftId=data.requests[0].id
  data=domain.saveTreatmentDraft(data,'Doctor',patientId,'5 mg',{...plan,instructions:'Updated prescription instructions.'},draftId)
  assert.equal(data.requests[0].doctorRationale,rationale)
  data=domain.submitTreatmentDraft(data,'Doctor',draftId)
  assert.equal(data.requests[0].id,draftId)
  assert.equal(data.requests[0].status,'Under review')
  assert.equal(data.requests[0].approvalRoute,'Exception review')
  assert.equal(data.requests[0].doctorRationale,rationale)
  assert.equal(data.notifications[0].relatedEntityId,draftId)
  assert.throws(()=>domain.decide(data,'Doctor',draftId,'approve','Cannot self approve this exception.'),/cannot|permission|review/i)
  assert.throws(()=>domain.dispenseMedication(data,'Pharmacist',draftId,true),/ready|approved|authorization/i)
  data=domain.decide(data,'Reviewer',draftId,'approve','تمت مراجعة الاستثناء والموافقة في الاختبار التجريبي.')
  assert.equal(data.requests[0].status,'Ready to dispense')
  assert.equal(data.requests[0].exceptionApproved,true)
  data=domain.dispenseMedication(data,'Pharmacist',draftId,true)
  assert.equal(data.requests[0].status,'Dispensed')
  assert.equal(data.dispenses[0].requestId,draftId)
})

test('an exception rationale does not bypass missing assessment or pending laboratory evidence', () => {
  const data=copySeed()
  const options={doctorRationale:'Documented clinical exception for independent review.'}
  assert.throws(()=>domain.submitRequest({...data,assessments:data.assessments.filter(a=>a.patientId!=='P051')},'Doctor','P051','5 mg',plan,options),/clinical assessment/i)
  assert.throws(()=>domain.submitRequest({...data,labs:data.labs.map(l=>l.patientId==='P051'?{...l,status:'Pending'}:l)},'Doctor','P051','5 mg',plan,options),/HbA1c/i)
})

test('covered pharmacy checkout issues a zero receipt atomically and preserves the price snapshot',()=>{
 let data=copySeed();data.requests=data.requests.filter(r=>r.patientId!=='P010');data.patients=data.patients.map(p=>p.id==='P010'?{...p,residency:'Citizen'}:p)
 data=domain.submitRequest(data,'Doctor','P010','5 mg',plan);const id=data.requests[0].id,stock=domain.onHandByDose(data)['5 mg']
 assert.throws(()=>domain.completePharmacyCheckout(data,'Pharmacist',id,false,'Covered'),/identity/i)
 assert.equal(domain.onHandByDose(data)['5 mg'],stock)
 const done=domain.completePharmacyCheckout(data,'Pharmacist',id,true,'Covered')
 assert.equal(done.payments[0].amountAED,0);assert.equal(done.payments[0].method,'Covered');assert.equal(domain.onHandByDose(done)['5 mg'],stock-1)
 assert.equal(done.notifications[0].relatedEntity,'Pharmacy documents')
 const snapshot=done.payments[0].coverage
 done.medications=done.medications.map(m=>({...m,unitCostAED:9999}));done.patients=done.patients.map(p=>({...p,residency:'Visitor'}))
 assert.deepEqual(domain.medicationCoverageForRequest(done,id),snapshot)
 assert.throws(()=>domain.completePharmacyCheckout(done,'Pharmacist',id,true,'Cash'),/already recorded/)
})
test('cash and card collect only the medication share, rejecting Covered for a balance',()=>{
 for(const method of ['Cash','Card']){
 let data=copySeed();data.requests=data.requests.filter(r=>r.patientId!=='P010');data.patients=data.patients.map(p=>p.id==='P010'?{...p,residency:'Resident'}:p)
 data=domain.submitRequest(data,'Doctor','P010','5 mg',plan);const id=data.requests[0].id
 assert.throws(()=>domain.completePharmacyCheckout(data,'Pharmacist',id,true,'Covered'),/cash or card/)
 const done=domain.completePharmacyCheckout(data,'Pharmacist',id,true,method)
 assert.equal(done.payments[0].method,method);assert.equal(done.payments[0].amountAED,done.payments[0].coverage.totalAED*.5)
 }
})
test('invalid prices cannot become free dispensing and checkout cannot be submitted by a patient',()=>{
 let data=copySeed();data.requests=data.requests.filter(r=>r.patientId!=='P010');data=domain.submitRequest(data,'Doctor','P010','5 mg',plan);const id=data.requests[0].id
 assert.throws(()=>domain.completePharmacyCheckout(data,'Patient',id,true,'Cash'),/cannot perform/)
 data.medications=data.medications.map(m=>({...m,unitCostAED:NaN}))
 assert.throws(()=>domain.completePharmacyCheckout(data,'Pharmacist',id,true,'Cash'),/valid medication price/)
})
