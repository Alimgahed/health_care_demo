import { canReadPatient, type AppData, type RequestStatus } from './domain'
import { operationalAlerts } from './adminAnalytics'

/** All overview projections use the same repository and reviewer access boundary. */
export function reviewerDashboardData(data: AppData, now: Date, status: RequestStatus | 'All' = 'All') {
  const patients = data.patients.filter(p => canReadPatient(data, 'Reviewer', p.id))
  const ids = new Set(patients.map(p => p.id))
  const requests = data.requests.filter(r => ids.has(r.patientId))
  const active = patients.filter(p => p.treatmentStatus === 'Active')
  const waiting = requests.filter(r => r.status === 'Under review')
  const ready = requests.filter(r => r.status === 'Ready to dispense')
  const evidence = [...new Set(data.assessments.filter(a => ids.has(a.patientId) && a.status === 'Submitted').map(a => a.patientId))]
  const review = requests.filter(r => ['Under review', 'Needs information'].includes(r.status))
  const dispensed = [...new Set(data.dispenses.filter(d => ids.has(d.patientId)).map(d => d.patientId))]
  const ongoing = [...new Set((data.integratedCarePlans ?? []).filter(p => ids.has(p.patientId) && p.status === 'Active').map(p => p.patientId))]
  const today = now.toLocaleDateString('en-CA', { timeZone: 'Asia/Dubai' })
  const clock = now.toLocaleTimeString('en-GB', { timeZone: 'Asia/Dubai', hour: '2-digit', minute: '2-digit', hour12: false })
  const end = Date.parse(`${today}T00:00:00Z`)
  const days = Array.from({ length: 30 }, (_, i) => {
    const day = new Date(end - (29 - i) * 86400000).toISOString().slice(0, 10)
    return { day, count: requests.filter(r => r.status !== 'Draft' && (status === 'All' || r.status === status) && (r.createdAt ?? r.created).slice(0, 10) === day).length }
  })
  const trend = Array.from({ length: 6 }, (_, i) => ({ from: days[i * 5].day, to: days[i * 5 + 4].day, count: days.slice(i * 5, i * 5 + 5).reduce((n, d) => n + d.count, 0) }))
  const latest = [...requests].filter(r => r.status !== 'Draft').map(request => {
    const event = data.audit.filter(e => e.entityId === request.id && e.actor === 'Reviewer' && e.occurredAt).sort((a, b) => b.occurredAt!.localeCompare(a.occurredAt!))[0]
    return { request, date: event?.occurredAt ?? request.createdAt ?? request.created }
  }).sort((a, b) => b.date.localeCompare(a.date)).slice(0, 4)
  const appointments = data.appointments.filter(a => ids.has(a.patientId) && ['Scheduled', 'Confirmed'].includes(a.status) && (a.date > today || a.date === today && a.time >= clock)).sort((a, b) => `${a.date}T${a.time}`.localeCompare(`${b.date}T${b.time}`))
  const alerts = operationalAlerts(data, now.getTime()).filter(a => a.patientId && ids.has(a.patientId) && !data.dismissedAlerts?.includes(a.id)).sort((a, b) => ({ Critical: 0, Warning: 1, Info: 2 }[a.severity] - { Critical: 0, Warning: 1, Info: 2 }[b.severity]) || b.timestamp.localeCompare(a.timestamp))
  return { patients, active, requests, waiting, ready, evidence, review, dispensed, ongoing, trend, latest, appointments, alerts }
}
