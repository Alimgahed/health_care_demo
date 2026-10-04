import { adherenceFor, inventoryByDose, supportedDoses, type AppData, type AbuseReviewRecord } from './domain'

export type AdminPage = 'Integrated care plans' | 'Continuous care' | 'Overview' | 'Geographic analytics' | 'Patients' | 'Treatment requests' | 'Inventory' | 'Alerts' | 'Activity log' | 'Smart assistant' | 'Data assistant' | 'Misuse prevention' | 'Reports' | 'Doctor management' | 'Treatment center management' | 'System audit' | 'Doctor portal' | 'Distribution portal' | 'Patient portal' | 'Clinical care' | 'Appointments' | 'Dispensing'

export type OperationalAlert = { id: string; severity: 'Critical' | 'Warning' | 'Info'; category: string; title: string; detail: string; page: AdminPage; entityId?: string; patientId?: string; timestamp: string }
export type MisuseSignal = Omit<AbuseReviewRecord, 'status' | 'updatedAt'>

const isoDate = (time: number) => new Date(time).toISOString().slice(0, 10)

export function operationalAlerts(data: AppData, clock = Date.now()): OperationalAlert[] {
  const today = isoDate(clock)
  const inSixtyDays = isoDate(clock + 60 * 86400000)
  const inThreeDays = isoDate(clock + 3 * 86400000)
  const stock = inventoryByDose(data)
  return [
    ...(data.manualAlerts??[]).map(item=>({...item,page:'Alerts' as const,entityId:item.id})),
    ...Object.entries(stock).filter(([, quantity]) => quantity < 12).map(([dose, quantity]) => ({ id: `stock-${dose}`, severity: quantity < 5 ? 'Critical' as const : 'Warning' as const, category: 'Inventory', title: quantity < 5 ? 'Critical stock level' : 'Low stock level', detail: `${dose} · ${quantity} units available`, page: 'Inventory' as const, timestamp: today })),
    ...data.requests.filter(item => item.status === 'Needs information' || item.status === 'Under review' || item.status === 'Rejected').map(item => ({ id: `request-${item.id}`, severity: item.status === 'Rejected' || item.status === 'Needs information' ? 'Warning' as const : 'Info' as const, category: 'Treatment', title: item.status === 'Needs information' ? 'Information requested' : item.status === 'Rejected' ? 'Treatment request rejected' : 'Clinical review pending', detail: `${item.id} · ${data.patients.find(patient => patient.id === item.patientId)?.name ?? item.patientId}${item.note ? ` · ${item.note}` : ''}`, page: 'Treatment requests' as const, entityId: item.id, patientId: item.patientId, timestamp: item.createdAt ?? today })),
    ...data.requests.filter(item => item.status === 'Under review' && item.createdAt && clock - new Date(item.createdAt).getTime() > 48 * 3600000).map(item => ({ id: `overdue-${item.id}`, severity: 'Warning' as const, category: 'Treatment', title: 'Review pending over 48 hours', detail: `${item.id} · ${data.patients.find(patient => patient.id === item.patientId)?.name ?? item.patientId}`, page: 'Treatment requests' as const, entityId: item.id, patientId: item.patientId, timestamp: item.createdAt ?? today })),
    ...data.requests.filter(item => item.status === 'Ready to dispense' && (!item.prescriptionId || !item.approvalExpiresAt || item.approvalExpiresAt < today || !supportedDoses.includes(item.dose as typeof supportedDoses[number]))).map(item => ({ id: `safety-${item.id}`, severity: 'Critical' as const, category: 'Safety', title: 'Pharmacy verification issue', detail: `${item.id} · prescription, approval date or supported dose needs review`, page: 'Treatment requests' as const, entityId: item.id, patientId: item.patientId, timestamp: item.createdAt ?? today })),
    ...data.requests.filter(item => item.status === 'Ready to dispense' && item.approvalExpiresAt && item.approvalExpiresAt < today).map(item => ({ id: `approval-expired-${item.id}`, severity: 'Critical' as const, category: 'Safety', title: 'Treatment approval expired', detail: `${item.id} · renew clinical review before dispensing`, page: 'Treatment requests' as const, entityId: item.id, patientId: item.patientId, timestamp: item.createdAt ?? today })),
    ...data.batches.filter(item => item.quantity > 0 && item.expiry <= inSixtyDays).map(item => ({ id: `expiry-${item.id}`, severity: item.expiry <= today ? 'Critical' as const : 'Warning' as const, category: 'Inventory', title: item.expiry <= today ? 'Expired medication batch' : 'Medication batch expiring', detail: `${item.batchNumber} · ${item.dose} · ${item.quantity} units · expires ${item.expiry}`, page: 'Inventory' as const, entityId: item.id, timestamp: item.expiry })),
    ...data.appointments.filter(item => ['Scheduled', 'Confirmed'].includes(item.status) && item.date >= today && item.date <= inThreeDays).map(item => ({ id: `appointment-${item.id}`, severity: 'Info' as const, category: 'Appointments', title: 'Appointment coming up', detail: `${item.date} ${item.time} · ${data.patients.find(patient => patient.id === item.patientId)?.name ?? item.patientId} · ${item.purpose}`, page: 'Appointments' as const, entityId: item.id, patientId: item.patientId, timestamp: `${item.date}T${item.time}` })),
    ...data.patients.filter(patient => patient.treatmentStatus === 'Active' && adherenceFor(data, patient.id) < 50).map(patient => ({ id: `adherence-${patient.id}`, severity: 'Warning' as const, category: 'Clinical', title: 'Low recorded adherence', detail: `${patient.name} · ${patient.id} · ${adherenceFor(data, patient.id)}% in the last 28 days`, page: 'Patients' as const, entityId: patient.id, patientId: patient.id, timestamp: today })),
    ...data.audit.filter(item => /duplicate|early refill|invalid prescription|safety check/i.test(item.action)).map(item => ({ id: `safety-event-${item.id}`, severity: 'Warning' as const, category: 'Safety', title: item.action, detail: `${item.entityId} · ${item.detail}`, page: item.entity === 'Treatment request' ? 'Treatment requests' as const : 'Activity log' as const, entityId: item.entityId, patientId: item.patientId, timestamp: item.occurredAt ?? item.time })),
  ]
}

export function misuseSignals(data: AppData): MisuseSignal[] {
  const signals: MisuseSignal[] = data.audit.filter(item=>/Duplicate dispensing attempt blocked|Early refill blocked/.test(item.action)).map(item=>({id:`attempt-${item.id}`,eventType:item.action,severity:'Warning',evidence:item.detail,timestamp:item.occurredAt??'',patientId:item.patientId,requestId:item.entityId}))
  const active = data.requests.filter(item => ['Under review', 'Approved', 'Ready to dispense'].includes(item.status))
  const byPatient = new Map<string, typeof active>()
  for (const request of active) byPatient.set(request.patientId, [...(byPatient.get(request.patientId) ?? []), request])
  for (const [patientId, requests] of byPatient) {
    if (requests.length > 1) signals.push({ id: `duplicate-active-${patientId}`, eventType: 'Multiple active treatment requests', severity: 'Warning', evidence: `${requests.length} open requests: ${requests.map(item => item.id).join(', ')}`, timestamp: requests.map(item => item.createdAt ?? '').sort().at(-1) || '', patientId, requestId: requests[0].id })
  }
  for (const request of data.requests) {
    if (!supportedDoses.includes(request.dose as typeof supportedDoses[number])) signals.push({ id: `unsupported-dose-${request.id}`, eventType: 'Unsupported dose', severity: 'Critical', evidence: `${request.dose} is not one of the configured programme strengths.`, timestamp: request.createdAt ?? '', patientId: request.patientId, requestId: request.id })
    if (request.status === 'Ready to dispense' && !request.prescriptionId) signals.push({ id: `missing-prescription-${request.id}`, eventType: 'Missing prescription', severity: 'Critical', evidence: 'The pharmacy queue has no linked prescription identifier.', timestamp: request.createdAt ?? '', patientId: request.patientId, requestId: request.id })
    if (request.status === 'Ready to dispense' && request.approvalExpiresAt && request.approvalExpiresAt < isoDate(Date.now())) signals.push({ id: `expired-approval-${request.id}`, eventType: 'Expired approval', severity: 'Critical', evidence: `Approval expired on ${request.approvalExpiresAt}; a current review is required.`, timestamp: request.createdAt ?? '', patientId: request.patientId, requestId: request.id })
  }
  const dispensesByRequest = new Map<string, typeof data.dispenses>()
  const dispensesByPatient = new Map<string, typeof data.dispenses>()
  for (const dispense of data.dispenses) {
    dispensesByRequest.set(dispense.requestId, [...(dispensesByRequest.get(dispense.requestId) ?? []), dispense])
    dispensesByPatient.set(dispense.patientId, [...(dispensesByPatient.get(dispense.patientId) ?? []), dispense])
    const linked = data.requests.find(item => item.id === dispense.requestId)
    if (linked && linked.patientId !== dispense.patientId) signals.push({ id: `identity-mismatch-${dispense.id}`, eventType: 'Patient identity mismatch', severity: 'Critical', evidence: `Dispense lists ${dispense.patientId}; linked request ${linked.id} belongs to ${linked.patientId}.`, timestamp: dispense.dispensedAt ?? dispense.date, patientId: dispense.patientId, requestId: dispense.requestId })
  }
  for (const [requestId, records] of dispensesByRequest) if (records.length > 1) signals.push({ id: `duplicate-dispense-${requestId}`, eventType: 'Duplicate dispensing record', severity: 'Critical', evidence: `${records.length} dispensing records are linked to request ${requestId}.`, timestamp: records[0].dispensedAt ?? records[0].date, patientId: records[0].patientId, requestId })
  for (const [patientId, records] of dispensesByPatient) {
    const ordered = records.map(item => ({ ...item, time: new Date(item.dispensedAt ?? item.date).getTime() })).sort((a, b) => b.time - a.time)
    if (ordered.length > 1 && ordered[0].dose === ordered[1].dose && ordered[0].time - ordered[1].time < 28 * 86400000) signals.push({ id: `early-refill-${patientId}-${ordered[0].id}`, eventType: 'Early refill pattern', severity: 'Warning', evidence: `Two ${ordered[0].dose} dispensing records are less than 28 days apart.`, timestamp: ordered[0].dispensedAt ?? ordered[0].date, patientId, requestId: ordered[0].requestId })
  }
  for (const patient of data.patients) {
    const doses = data.doses.filter(item => item.patientId === patient.id).map(item => new Date(item.recordedAt).getTime()).filter(Number.isFinite).sort((a, b) => b - a)
    if (doses.length > 1 && doses[0] - doses[1] < 5 * 86400000) signals.push({ id: `dose-frequency-${patient.id}-${doses[0]}`, eventType: 'Dose frequency flagged for review', severity: 'Warning', evidence: 'Two dose logs were recorded less than five days apart; confirm the schedule with the care team.', timestamp: new Date(doses[0]).toISOString(), patientId: patient.id, requestId: data.doses.find(item => item.patientId === patient.id && new Date(item.recordedAt).getTime() === doses[0])?.requestId })
  }
  for (const batch of data.batches.filter(item => item.quantity < 0)) signals.push({ id: `stock-anomaly-${batch.id}`, eventType: 'Inventory quantity anomaly', severity: 'Critical', evidence: `Batch ${batch.batchNumber} has negative quantity ${batch.quantity}.`, timestamp: batch.receivedAt })
  return signals.sort((a, b) => ({ Critical: 0, Warning: 1, Info: 2 }[a.severity] - { Critical: 0, Warning: 1, Info: 2 }[b.severity]) || b.timestamp.localeCompare(a.timestamp))
}

export function reviewStateFor(data: AppData, signalId: string): AbuseReviewRecord['status'] {
  return data.abuseReviews.find(item => item.id === signalId)?.status ?? 'New'
}
