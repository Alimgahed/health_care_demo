import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'

const moduleUrl = source => `data:text/javascript;base64,${Buffer.from(ts.transpile(source, {module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const domainUrl = moduleUrl(await readFile(new URL('../src/domain.ts', import.meta.url), 'utf8'))
const analyticsUrl = moduleUrl((await readFile(new URL('../src/adminAnalytics.ts', import.meta.url), 'utf8')).replace("from './domain'", `from '${domainUrl}'`))
const dashboardUrl = moduleUrl((await readFile(new URL('../src/adminDashboardData.ts', import.meta.url), 'utf8')).replace("from './domain'", `from '${domainUrl}'`).replace("from './adminAnalytics'", `from '${analyticsUrl}'`))
const { seed, inventoryByDose } = await import(domainUrl)
const { adminDashboardData, patientOutcomeForecast } = await import(dashboardUrl)
const now = new Date('2026-10-02T12:00:00Z')

test('admin dashboard reconciles shared inventory and responds to repository edits', () => {
  const data = structuredClone(seed)
  const before = adminDashboardData(data, now)
  assert.equal(before.patients, data.patients.length)
  assert.equal(before.units, Object.values(inventoryByDose(data)).reduce((a,b) => a+b,0))
  data.patients.push({...data.patients[0],id:'NEW-PATIENT',registeredAt:'2026-10-02'})
  data.requests.push({...data.requests[0],id:'NEW-REQUEST',status:'Under review'})
  data.centres[0].status = 'Inactive'
  const after = adminDashboardData(data, now)
  assert.equal(after.patients, before.patients+1)
  assert.equal(after.pending, before.pending+1)
  assert.equal(after.centres, before.centres-1)
  assert.equal(after.enrollment, before.enrollment+1)
  assert.equal(after.journey.at(-1).registered, before.journey.at(-1).registered+1)
})

test('outlook excludes future observations, cancelled visits and inactive plan milestones', () => {
  const data = structuredClone(seed)
  data.patients = [{...data.patients[0], registeredAt:'2026-09-02'}, {...data.patients[1],registeredAt:'2026-10-03'}]
  data.dispenses = [{...data.dispenses[0],date:'2026-09-20',dispensedAt:'2026-09-20T12:00:00Z'}, {...data.dispenses[0],id:'FUTURE',dispensedAt:'2026-10-03T12:00:00Z'}]
  data.appointments = ['Scheduled','Confirmed','Cancelled','Completed'].map((status,i) => ({...data.appointments[0],id:`VISIT-${i}`,date:'2026-10-10',status}))
  data.treatmentPlans = ['Approved','Dispensed','Completed','Rejected','Draft'].map((status,i) => ({...data.treatmentPlans[0],id:`PLAN-${i}`,endDate:'2026-10-12',status}))
  const short = adminDashboardData(data, now, 6, 30)
  const long = adminDashboardData(data, now, 3, 90)
  assert.equal(short.enrollment,1)
  assert.equal(short.recentDispenses,1)
  assert.equal(short.expectedDispenses,1)
  assert.equal(long.expectedDispenses,3)
  assert.equal(short.visits,2)
  assert.equal(short.planMilestones,2)
  assert.equal(long.journey.length,3)
  assert.equal(short.journey.at(-1).registered,0)
})

test('empty repository returns finite zero metrics and dismissed alerts disappear', () => {
  const empty = Object.fromEntries(Object.keys(seed).map(key => [key, Array.isArray(seed[key]) ? [] : seed[key]]))
  const stats = adminDashboardData(empty, now)
  assert.equal(stats.patients,0)
  assert.equal(stats.availability,0)
  assert.equal(stats.expectedEnrollment,0)
  assert.equal(stats.expectedDispenses,0)
  assert.equal(stats.planMilestones,0)
  assert.equal(stats.journey.every(row => row.registered === 0 && row.started === 0 && row.completed === 0),true)
  empty.dismissedAlerts = stats.alerts.map(item => item.id)
  assert.equal(adminDashboardData(empty, now).alerts.length,0)
})

test('stock forecast detects a shortfall against available inventory', () => {
  const data = structuredClone(seed)
  data.requests = []
  data.batches = [{...data.batches[0],dose:'5 mg',quantity:2,expiry:'2099-12-31'}]
  data.dispenses = Array.from({length:3}, (_,i) => ({...data.dispenses[0],id:`DISPENSE-${i}`,dose:'5 mg',dispensedAt:'2026-09-20T12:00:00Z'}))
  const result = adminDashboardData(data, now)
  assert.deepEqual(result.stockRisks,[{dose:'5 mg',quantity:2,demand:3,atRisk:true}])
  data.batches[0].quantity = 10
  assert.equal(adminDashboardData(data, now).stockRisks.length,0)
})


test('patient outcome estimates use longitudinal records and the chosen window', () => {
  const data = structuredClone(seed)
  data.patients = [
    {...data.patients[0],id:'RISING',age:40,treatmentStatus:'No active plan'},
    {...data.patients[0],id:'IMPROVING',age:40,treatmentStatus:'Active'},
    {...data.patients[0],id:'ALREADY',age:40,treatmentStatus:'No active plan'},
  ]
  const vital = (patientId, bmi, date) => ({...seed.vitals[0],patientId,bmi,weightKg:bmi*3,recordedAt:date})
  data.vitals = [
    vital('RISING',29,'2026-09-02T12:00:00Z'),vital('RISING',29.5,'2026-10-02T12:00:00Z'),
    vital('IMPROVING',31,'2026-09-02T12:00:00Z'),vital('IMPROVING',30.5,'2026-10-02T12:00:00Z'),
    vital('ALREADY',32,'2026-09-02T12:00:00Z'),vital('ALREADY',33,'2026-10-02T12:00:00Z'),
    vital('RISING',40,'2027-01-01T12:00:00Z'),
  ]
  const short = patientOutcomeForecast(data,now,30)
  const longer = patientOutcomeForecast(data,now,90)
  assert.equal(short.newObesity,1)
  assert.equal(short.obesityEligible,1)
  assert.equal(short.improving,1)
  assert.equal(short.belowObesity,0)
  assert.equal(longer.belowObesity,1)
  assert.equal(short.assessable,3)
  // A new shared observation must change the forecast, without editing any dashboard data.
  data.vitals.find(item => item.patientId === 'RISING' && item.bmi === 29.5).bmi = 28.5
  assert.equal(patientOutcomeForecast(data,now,90).newObesity,0)
})

test('insufficient, stale, minor and implausible outcome histories do not become predictions', () => {
  const data = structuredClone(seed)
  data.patients = [{...data.patients[0],age:40,id:'P'},{...data.patients[0],id:'CHILD',age:15}]
  const vital = (patientId,bmi,recordedAt) => ({...seed.vitals[0],patientId,bmi,recordedAt})
  data.vitals = [vital('P',29,'2026-09-01'),vital('CHILD',29,'2026-09-01'),vital('CHILD',29.9,'2026-10-01')]
  assert.equal(patientOutcomeForecast(data,now,90).newObesity,null)
  assert.equal(patientOutcomeForecast(data,now,90).missingHistory,1)
  data.vitals = [vital('P',29,'2026-05-01'),vital('P',29.9,'2026-06-01')]
  assert.equal(patientOutcomeForecast(data,now,90).assessable,0)
  data.vitals = [vital('P',29,'2026-09-25'),vital('P',29.9,'2026-10-01')]
  assert.equal(patientOutcomeForecast(data,now,90).assessable,0)
  data.vitals = [vital('P',50,'2026-09-01'),vital('P',10,'2026-10-01')]
  assert.equal(patientOutcomeForecast(data,now,90).assessable,0)
})

test('planned outcome completion counts patients once and excludes future starts and closed plans', () => {
  const data = structuredClone(seed)
  data.patients = [{...data.patients[0],id:'A'},{...data.patients[0],id:'B'}]
  const plan = (id,patientId,status,startDate='2026-09-01') => ({...seed.treatmentPlans[0],id,patientId,status,startDate,endDate:'2026-10-20'})
  data.treatmentPlans = [plan('1','A','Dispensed'),plan('2','A','Approved'),plan('3','B','Completed'),plan('4','B','Approved','2026-10-15'),plan('5','UNKNOWN','Dispensed')]
  assert.equal(patientOutcomeForecast(data,now,30).expectedCompletions,1)
})
