import { adherenceFor, calculateCoverage, inventoryByDose, type AppData, type ReportFilters } from './domain'
import type { CsvRow } from './csvExport'

export type ReportKey = 'care-plans' | 'rehabilitation' | 'patients' | 'requests' | 'review' | 'approvals' | 'rejections' | 'information' | 'dispensing' | 'inventory' | 'low-stock' | 'expiring' | 'adherence' | 'appointments' | 'financial' | 'audit' | 'activity'
export const reportChoices: { id: ReportKey; label: string; source: string }[] = [
 {id:'care-plans',label:'Integrated care plans',source:'Doctor-confirmed care plans, linked medication requests, rehabilitation and follow-up.'},
 {id:'rehabilitation',label:'Rehabilitation progress',source:'Prescribed sessions and completed progress from the integrated care plan.'},
  { id: 'patients', label: 'Patient overview', source: 'Patient registry, clinical evidence, treatment status and recent adherence.' },
  { id: 'requests', label: 'Treatment requests', source: 'Canonical treatment requests and linked patient/plan records.' },
  { id: 'review', label: 'Review performance', source: 'Reviewer decisions in the audit trail; processing time uses submitted and decision timestamps.' },
  { id: 'approvals', label: 'Treatment approvals', source: 'Requests approved for pharmacy, including requests already dispensed.' },
  { id: 'rejections', label: 'Rejections', source: 'Requests with a recorded rejected state and reviewer rationale.' },
  { id: 'information', label: 'Missing information', source: 'Requests returned to the clinician for required evidence.' },
  { id: 'dispensing', label: 'Pharmacy dispensing', source: 'Dispensing transactions, batch and patient references.' },
  { id: 'inventory', label: 'Inventory', source: 'Current medication batch records; available totals exclude expired stock.' },
  { id: 'low-stock', label: 'Low stock', source: 'Medication strengths below the 12 unit reorder point.' },
  { id: 'expiring', label: 'Expiring medication', source: 'Batches expiring within 60 days or already expired.' },
  { id: 'adherence', label: 'Adherence', source: 'Dose records from the last 28 days against a four-dose weekly plan.' },
  { id: 'appointments', label: 'Appointments', source: 'Shared appointment schedule and lifecycle state.' },
  { id: 'financial', label: 'Financial / coverage', source: 'Coverage by registered patient type: Citizen 100%, Resident 50%, Visitor 0%.' },
  { id: 'audit', label: 'Audit', source: 'Canonical audit events with actor, entity and state transitions.' },
  { id: 'activity', label: 'Operational activity', source: 'Activity events recorded in the shared audit stream.' },
]

export function sourceReportRows(data: AppData, report: ReportKey, now: number): CsvRow[] {
  const stock = inventoryByDose(data)
  const patient = (id: string) => data.patients.find(item => item.id === id)
  const dateOnly = (value?: string) => value ? value.slice(0, 10) : ''
  return (() => {
    if (report === 'care-plans'||report==='rehabilitation') return (data.integratedCarePlans??[]).filter(p=>report!=='rehabilitation'||p.rehabilitation).map(p=>({date:p.createdAt.slice(0,10),carePlanId:p.id,patientId:p.patientId,patient:patient(p.patientId)?.name,emirate:patient(p.patientId)?.emirate,medicationRequest:p.treatmentRequestId,rehabilitationCenter:data.rehabilitationCentres?.find(c=>c.id===p.rehabilitation?.centreId)?.name,rehabilitationProgram:data.rehabilitationPrograms?.find(r=>r.id===p.rehabilitation?.programId)?.name,plannedSessions:p.rehabilitation?.plannedSessions,completedSessions:p.rehabilitation?.sessions.length,homeExerciseCount:p.homeExerciseIds.length,followUp:p.followUpDate,...calculateCoverage(patient(p.patientId)?.residency??'Visitor',p.costLines.reduce((n,l)=>n+l.amountAED,0)),status:p.status}))
    if (report === 'patients') return data.patients.map(item => ({ date: item.registeredAt, patientId: item.id, name: item.name, emirate: item.emirate, residency: item.residency, diagnosis: item.diagnosis, bmi: item.bmi, latestLab: item.latestLab, eligibility: item.eligibility, status: item.treatmentStatus, adherencePercent: adherenceFor(data, item.id) }))
    if (report === 'requests') return data.requests.map(item => ({ date: dateOnly(item.createdAt), requestId: item.id, patient: patient(item.patientId)?.name, patientId: item.patientId, emirate: patient(item.patientId)?.emirate, doctor: patient(item.patientId)?.assignedDoctor ?? data.assessments.find(value => value.patientId === item.patientId)?.clinician ?? 'Dr. Laila Hassan', medication: item.medication ?? 'Mounjaro', dose: item.dose, eligibility: patient(item.patientId)?.eligibility, status: item.status, reason: item.note }))
    if (report === 'review' || report === 'audit' || report === 'activity') return data.audit.filter(item => report !== 'review' || /Request approved|Request rejected|Information requested/.test(item.action)).map(item => {
      const request = data.requests.find(value => value.id === item.entityId)
      const submittedAt = request?.createdAt ? new Date(request.createdAt).getTime() : NaN
      const decidedAt = item.occurredAt ? new Date(item.occurredAt).getTime() : NaN
      const processingHours = Number.isFinite(submittedAt) && Number.isFinite(decidedAt) && decidedAt >= submittedAt ? Math.round((decidedAt - submittedAt) / 360000) / 10 : undefined
      return { date: dateOnly(item.occurredAt), actor: item.actor, action: item.action, entity: item.entity, recordId: item.entityId, patientId:item.patientId ?? request?.patientId, patient: patient(item.patientId ?? request?.patientId ?? '')?.name, emirate: patient(item.patientId ?? request?.patientId ?? '')?.emirate, previousState: item.previousState, newState: item.newState, reason: item.reason, processingHours }
    })
    if (report === 'approvals') return data.requests.filter(item => ['Approved','Ready to dispense','Dispensed','Completed'].includes(item.status)).map(item => ({ date: dateOnly(item.createdAt), requestId: item.id, patient: patient(item.patientId)?.name, emirate: patient(item.patientId)?.emirate, medication: item.medication ?? 'Mounjaro', dose: item.dose, reviewer: item.reviewer, approvalExpiresAt: item.approvalExpiresAt, status: item.status }))
    if (report === 'rejections') return data.requests.filter(item => item.status === 'Rejected').map(item => ({ date: dateOnly(item.createdAt), requestId: item.id, patient: patient(item.patientId)?.name, emirate: patient(item.patientId)?.emirate, medication: item.medication ?? 'Mounjaro', dose: item.dose, reviewer: item.reviewer, reason: item.note, status: item.status }))
    if (report === 'information') return data.requests.filter(item => item.status === 'Needs information').map(item => ({ date: dateOnly(item.createdAt), requestId: item.id, patient: patient(item.patientId)?.name, emirate: patient(item.patientId)?.emirate, medication: item.medication ?? 'Mounjaro', dose: item.dose, requestedEvidence: item.note, status: item.status }))
    if (report === 'dispensing') return data.dispenses.map(item => ({ date: dateOnly(item.dispensedAt) || dateOnly(item.date), dispenseId: item.id, requestId: item.requestId, patient: patient(item.patientId)?.name, patientId: item.patientId, emirate: patient(item.patientId)?.emirate, medication: 'Mounjaro', dose: item.dose, centre: item.centre, batch: data.batches.find(batch => batch.id === item.batchId)?.batchNumber }))
    if (report === 'inventory') return data.batches.map(item => ({ date: item.receivedAt, batch: item.batchNumber, medication: 'Mounjaro', dose: item.dose, quantity: item.quantity, availableForStrength: stock[item.dose], centre: item.centre, source: item.source, expiry: item.expiry, status: item.expiry < new Date(now).toISOString().slice(0, 10) ? 'Expired' : item.quantity === 0 ? 'Depleted' : 'Available' }))
    if (report === 'low-stock') return Object.entries(stock).filter(([, quantity]) => quantity < 12).map(([dose, quantity]) => ({ date: new Date(now).toISOString().slice(0, 10), medication: 'Mounjaro', dose, availableUnits: quantity, reorderPoint: 12, status: quantity < 5 ? 'Critical' : 'Reorder needed' }))
    if (report === 'expiring') return data.batches.filter(item => item.quantity > 0 && item.expiry <= new Date(now + 60 * 86400000).toISOString().slice(0, 10)).map(item => ({ date: item.expiry, batch: item.batchNumber, medication: 'Mounjaro', dose: item.dose, quantity: item.quantity, centre: item.centre, source: item.source, expiry: item.expiry, status: item.expiry < new Date(now).toISOString().slice(0, 10) ? 'Expired' : 'Expiring soon' }))
    if (report === 'adherence') return data.patients.map(item => ({ date: item.registeredAt, patientId: item.id, patient: item.name, emirate: item.emirate, diagnosis: item.diagnosis, dosesLast28Days: data.doses.filter(dose => dose.patientId === item.id && new Date(dose.recordedAt).getTime() <= now && now - new Date(dose.recordedAt).getTime() <= 28 * 86400000).length, adherencePercent: adherenceFor(data, item.id), status: item.treatmentStatus }))
    if (report === 'appointments') return data.appointments.map(item => ({ date: item.date, appointmentId: item.id, patient: patient(item.patientId)?.name, patientId: item.patientId, emirate: patient(item.patientId)?.emirate, purpose: item.purpose, doctor: item.doctor, centre: item.centre, time: item.time, status: item.status }))
    if (report === 'financial') return data.financial.map(item => ({ date: dateOnly(item.assessedAt), requestId: item.requestId, patientId:item.patientId, patient: patient(item.patientId)?.name, emirate: patient(item.patientId)?.emirate, integratedCarePlanId:item.integratedCarePlanId, ...calculateCoverage(patient(item.patientId)?.residency??'Visitor',item.amountAED), status: item.status }))
    return []
  })() as CsvRow[]
}

export const reportGroup = (key: string) => ({patients:'Patients',adherence:'Patients',appointments:'Patients',requests:'Treatment',review:'Treatment',approvals:'Treatment',rejections:'Treatment',information:'Treatment','care-plans':'Treatment',rehabilitation:'Treatment',dispensing:'Inventory',inventory:'Inventory','low-stock':'Inventory',expiring:'Inventory',financial:'Financial',audit:'Safety & Compliance',activity:'Safety & Compliance'}[key] ?? 'Custom Reports')
export const isReportKey = (key: string): key is ReportKey => reportChoices.some(item => item.id === key)

/** All report views, exports and saved snapshots pass through this shared selector. */
export function reportRows(data: AppData, key: ReportKey, filters: ReportFilters, now: number) {
  return sourceReportRows(data,key,now).map((row): CsvRow => {
    const request = data.requests.find(item => item.id === row.requestId || item.id === row.recordId)
    const patient = data.patients.find(item => item.id === (row.patientId ?? request?.patientId))
    const centre = String(row.centre ?? patient?.treatmentCentre ?? '')
    const emirate = String(row.emirate ?? patient?.emirate ?? data.centres.find(item => item.name === centre)?.emirate ?? '')
    return {...row,patientId:patient?.id ?? row.patientId,centre,emirate,programme:patient?.diagnosis ?? '',category:patient?.residency ?? ''}
  }).filter(row => {
    const date = String(row.date ?? '').slice(0,10)
    return (!filters.from || Boolean(date) && date >= filters.from) && (!filters.to || Boolean(date) && date <= filters.to) &&
      (filters.scope === 'All' || row.centre === filters.scope || row.emirate === filters.scope) &&
      (filters.programme === 'All' || row.programme === filters.programme) &&
      (filters.category === 'All' || row.category === filters.category)
  })
}

export function defaultReportFilters(now: Date): ReportFilters {
  return {from:new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth()-2,1)).toISOString().slice(0,10),to:now.toISOString().slice(0,10),scope:'All',programme:'All',category:'All',type:'All'}
}
export function previousReportFilters(filters: ReportFilters): ReportFilters {
  if (!filters.from || !filters.to) return {...filters,from:'',to:''}
  const start = Date.parse(filters.from), end = Date.parse(filters.to)
  const previousEnd = start-86400000
  return {...filters,from:new Date(previousEnd-(end-start)).toISOString().slice(0,10),to:new Date(previousEnd).toISOString().slice(0,10)}
}
const approved = (row: CsvRow) => ['Approved','Ready to dispense','Dispensed','Completed'].includes(String(row.status))
export function reportOverview(data: AppData, filters: ReportFilters, now: Date, interval: 'Monthly'|'Weekly' = 'Monthly') {
  const rows = (key: ReportKey) => reportRows(data,key,filters,now.getTime())
  const requests = rows('requests')
  const patients = rows('patients')
  const financial = rows('financial')
  const dispensing = rows('dispensing')
  const centres = data.centres.filter(centre => centre.status === 'Active' && (filters.scope==='All'||filters.scope===centre.name||filters.scope===centre.emirate) &&
    ((filters.programme==='All'&&filters.category==='All') || data.patients.some(patient => patient.treatmentCentre===centre.name && (filters.programme==='All'||patient.diagnosis===filters.programme)&&(filters.category==='All'||patient.residency===filters.category))))
  const totals = [patients.length,requests.length,requests.filter(approved).length,dispensing.length,centres.length,financial.reduce((total,row)=>total+Number(row.totalAED??0),0)]
  const previous = previousReportFilters(filters)
  const prevRows = (key: ReportKey) => reportRows(data,key,previous,now.getTime())
  const prevRequests = prevRows('requests')
  const prior = [prevRows('patients').length,prevRequests.length,prevRequests.filter(approved).length,prevRows('dispensing').length,centres.length,prevRows('financial').reduce((total,row)=>total+Number(row.totalAED??0),0)]
  const first = filters.from ? new Date(`${filters.from}T00:00:00Z`) : new Date(Date.UTC(now.getUTCFullYear(),0,1))
  const last = filters.to ? new Date(`${filters.to}T00:00:00Z`) : now
  const bucketDate = (value:string) => {const date=new Date(`${value.slice(0,10)}T00:00:00Z`);if(interval==='Monthly')return value.slice(0,7);date.setUTCDate(date.getUTCDate()-((date.getUTCDay()+6)%7));return date.toISOString().slice(0,10)}
  const trend: {key:string;label:string;submitted:number;review:number;approved:number;rejected:number}[]=[]
  const cursor = new Date(first)
  if(interval==='Monthly') cursor.setUTCDate(1)
  else cursor.setUTCDate(cursor.getUTCDate()-((cursor.getUTCDay()+6)%7))
  while(cursor<=last && trend.length<160) {
    const key=bucketDate(cursor.toISOString().slice(0,10))
    const bucket=requests.filter(row=>String(row.date).slice(0,10)&&bucketDate(String(row.date))===key)
    trend.push({key,label:cursor.toLocaleDateString('en',{month:'short',...(interval==='Weekly'?{day:'numeric' as const}:{}),timeZone:'UTC'}),submitted:bucket.length,review:bucket.filter(row=>['Under review','Needs information'].includes(String(row.status))).length,approved:bucket.filter(approved).length,rejected:bucket.filter(row=>row.status==='Rejected').length})
    if(interval==='Monthly')cursor.setUTCMonth(cursor.getUTCMonth()+1);else cursor.setUTCDate(cursor.getUTCDate()+7)
  }
  const group = (field:string) => Object.entries(requests.reduce<Record<string,number>>((counts,row)=>{const name=String(row[field]||'Unassigned');counts[name]=(counts[name]??0)+1;return counts},{})).map(([name,count])=>({name,count})).sort((a,b)=>b.count-a.count||a.name.localeCompare(b.name))
  const sparkSeries = [patients,requests,requests.filter(approved),dispensing,[],financial].map((records,index)=>trend.map(bucket=>records.filter(row=>row.date&&bucketDate(String(row.date))===bucket.key).reduce((sum,row)=>sum+(index===5?Number(row.totalAED??0):1),0)))
  return {totals,prior,trend,sparkSeries,programmes:group('programme'),centres:group('centre'),requests,patients,financial,dispensing}
}
