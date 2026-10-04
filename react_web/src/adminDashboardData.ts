import { inventoryByDose, supportedDoses, type AppData } from './domain'
import { operationalAlerts } from './adminAnalytics'

const day = 86_400_000
const dateKey = (date: Date) => date.toISOString().slice(0, 10)

/** A derived view of the application's repository. No separate dashboard fixtures. */
export function adminDashboardData(data: AppData, now = new Date(), months = 6, horizon = 30) {
  const today = dateKey(now)
  const end = dateKey(new Date(now.getTime() + horizon * day))
  const since = dateKey(new Date(now.getTime() - 29 * day))
  const enrollmentSince = dateKey(new Date(now.getTime() - 89 * day))
  const stock = inventoryByDose(data)
  const strengths = supportedDoses.map(dose => ({ dose, quantity: stock[dose] ?? 0 }))
  const available = strengths.filter(item => item.quantity > 0).length
  const availability = strengths.length ? Math.round(available / strengths.length * 100) : 0
  const pending = data.requests.filter(item => ['Under review', 'Needs information'].includes(item.status))
  const upcoming = data.appointments.filter(item => ['Scheduled', 'Confirmed'].includes(item.status) && item.date >= today)
  const visits = upcoming.filter(item => item.date <= end)
  const recentDispenses = data.dispenses.filter(item => (item.dispensedAt ?? item.date).slice(0, 10) >= since && (item.dispensedAt ?? item.date).slice(0, 10) <= today)
  const enrollment = data.patients.filter(item => item.registeredAt && item.registeredAt.slice(0, 10) >= enrollmentSince && item.registeredAt.slice(0, 10) <= today).length
  const expectedEnrollment = Math.round(enrollment / 90 * horizon)
  const expectedDispenses = Math.round(recentDispenses.length / 30 * horizon)
  const stockRisks = strengths.map(item => {
    const recent = recentDispenses.filter(record => record.dose === item.dose).length
    const demand = Math.ceil(recent / 30 * horizon)
    return { ...item, demand, atRisk: demand > item.quantity }
  }).filter(item => item.atRisk)
  const planMilestones = data.treatmentPlans.filter(item => ['Dispensed', 'Approved', 'Pharmacy ready'].includes(item.status) && item.endDate >= today && item.endDate <= end)
  const alerts = operationalAlerts(data, now.getTime()).filter(item => !(data.dismissedAlerts ?? []).includes(item.id))
  const journey = Array.from({ length: months }, (_, index) => {
    const month = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - months + index + 1, 1))
    const key = dateKey(month).slice(0, 7)
    return {
      key,
      label: month.toLocaleDateString('en', { month: 'short', timeZone: 'UTC' }),
      registered: data.patients.filter(item => item.registeredAt?.startsWith(key) && item.registeredAt.slice(0,10) <= today).length,
      started: data.treatmentPlans.filter(item => ['Dispensed', 'Completed'].includes(item.status) && item.startDate.startsWith(key) && item.startDate <= today).length,
      completed: data.treatmentPlans.filter(item => item.status === 'Completed' && item.endDate.startsWith(key) && item.endDate <= today).length,
    }
  })
  const requests = [
    { label: 'Drafts', count: data.requests.filter(item => item.status === 'Draft').length, tone: 'blue' },
    { label: 'In review', count: pending.length, tone: 'amber' },
    { label: 'Approved / ready', count: data.requests.filter(item => ['Approved', 'Ready to dispense'].includes(item.status)).length, tone: 'teal' },
    { label: 'Rejected', count: data.requests.filter(item => item.status === 'Rejected').length, tone: 'rose' },
  ]
  return {
    patients: data.patients.length, active: data.patients.filter(item => item.treatmentStatus === 'Active').length,
    pending: pending.length, upcoming: upcoming.length, visits: visits.length, availability, available,
    centres: data.centres.filter(item => item.status === 'Active').length,
    pharmacies: new Set(data.centres.filter(item => item.status === 'Active' && item.pharmacy).map(item => item.pharmacy)).size,
    rehabilitation: data.rehabilitationCentres?.filter(item => item.status === 'Active').length ?? 0,
    strengths, units: strengths.reduce((sum, item) => sum + item.quantity, 0),
    lowStock: strengths.filter(item => item.quantity > 0 && item.quantity < 12).length,
    outOfStock: strengths.filter(item => item.quantity === 0).length,
    alerts, journey, requests, outcomes: patientOutcomeForecast(data, now, horizon), enrollment, expectedEnrollment, expectedDispenses,
    stockRisks, recentDispenses: recentDispenses.length, planMilestones: planMilestones.length,
    activity: [...data.audit].sort((a, b) => (b.occurredAt ?? '').localeCompare(a.occurredAt ?? '')).slice(0, 4),
  }
}


/** Descriptive extrapolation of mock observations, never a probability or diagnosis.
 * WHO adult BMI categories: https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight
 * The freshness, observation interval and linear projection are demo assumptions.
 */
export function patientOutcomeForecast(data: AppData, now: Date, horizon: number) {
  const today = dateKey(now)
  const end = dateKey(new Date(now.getTime() + horizon * day))
  const adults = data.patients.filter(patient => patient.age >= 18)
  const trends = adults.flatMap(patient => {
    const records = data.vitals.filter(item => item.patientId === patient.id &&
      Number.isFinite(Date.parse(item.recordedAt)) && Date.parse(item.recordedAt) <= now.getTime() &&
      Number.isFinite(item.bmi) && item.bmi > 0 && Number.isFinite(item.weightKg) && item.weightKg > 0)
      .sort((a,b) => Date.parse(b.recordedAt) - Date.parse(a.recordedAt))
    const latest = records[0]
    if (!latest || now.getTime() - Date.parse(latest.recordedAt) > 90 * day) return []
    const previous = records.find(item => {
      const interval = Date.parse(latest.recordedAt) - Date.parse(item.recordedAt)
      return interval >= 14 * day && interval <= 180 * day && Math.abs(item.heightCm - latest.heightCm) < 1
    })
    if (!previous) return []
    const interval = (Date.parse(latest.recordedAt) - Date.parse(previous.recordedAt)) / day
    const elapsed = (now.getTime() - Date.parse(latest.recordedAt)) / day + horizon
    const projectedBmi = latest.bmi + (latest.bmi - previous.bmi) / interval * elapsed
    const projectedWeight = latest.weightKg + (latest.weightKg - previous.weightKg) / interval * elapsed
    // Do not extrapolate physically implausible values into a positive outcome.
    if (projectedBmi < 10 || projectedBmi > 80 || projectedWeight < 20 || projectedWeight > 400) return []
    return [{patientId:patient.id, bmi:latest.bmi, projectedBmi, projectedWeight,
      weight:latest.weightKg, active:patient.treatmentStatus === 'Active'}]
  })
  const nonObese = trends.filter(item => item.bmi < 30)
  const treated = trends.filter(item => item.active && item.bmi >= 25)
  const completions = new Set(data.treatmentPlans.filter(plan =>
    adults.some(patient => patient.id === plan.patientId) &&
    ['Dispensed','Approved','Pharmacy ready'].includes(plan.status) &&
    plan.startDate <= today && plan.endDate >= today && plan.endDate <= end).map(plan => plan.patientId))
  return {
    adults:adults.length, assessable:trends.length, missingHistory:adults.length-trends.length,
    obesityEligible:nonObese.length,
    newObesity:nonObese.length ? nonObese.filter(item => item.projectedBmi >= 30).length : null,
    improvementEligible:treated.length,
    improving:treated.length ? treated.filter(item => item.projectedWeight < item.weight && item.projectedBmi >= 18.5).length : null,
    belowObesity:treated.length ? treated.filter(item => item.bmi >= 30 && item.projectedBmi < 30 && item.projectedBmi >= 18.5).length : null,
    expectedCompletions:completions.size,
  }
}
