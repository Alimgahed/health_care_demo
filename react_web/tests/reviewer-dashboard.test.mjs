import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'
const moduleUrl = source => `data:text/javascript;base64,${Buffer.from(ts.transpile(source, {module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const domainUrl = moduleUrl(await readFile(new URL('../src/domain.ts', import.meta.url),'utf8'))
const analyticsUrl = moduleUrl((await readFile(new URL('../src/adminAnalytics.ts', import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`))
const selectorUrl = moduleUrl((await readFile(new URL('../src/reviewerDashboardData.ts', import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`).replace("from './adminAnalytics'",`from '${analyticsUrl}'`))
const {seed} = await import(domainUrl)
const {reviewerDashboardData} = await import(selectorUrl)
const now = new Date('2026-10-03T08:00:00Z')
function fixture(){const data=structuredClone(seed);data.requests=[{...data.requests[0],id:'REQ',patientId:data.patients[0].id,status:'Under review',createdAt:'2026-10-01T10:00:00Z'}];return data}
test('reviewer scope and linked counts follow shared request state without altering the source',()=>{
 const data=fixture(), before=structuredClone(data), first=reviewerDashboardData(data,now)
 assert.equal(first.patients.length,1);assert.equal(first.waiting.length,1);assert.equal(first.ready.length,0)
 assert.ok(first.alerts.every(a=>a.patientId===data.patients[0].id));assert.deepEqual(data,before)
 data.requests[0].status='Ready to dispense'
 const next=reviewerDashboardData(data,now);assert.equal(next.waiting.length,0);assert.equal(next.ready.length,1)
})
test('30-day chart excludes out-of-range and draft requests and respects status selection',()=>{
 const data=fixture(), r=data.requests[0]
 data.requests.push({...r,id:'OLD',createdAt:'2026-09-03T10:00:00Z'},{...r,id:'FUTURE',createdAt:'2026-10-04T10:00:00Z'},{...r,id:'DRAFT',status:'Draft'},{...r,id:'APPROVED',status:'Approved'})
 const sum=status=>reviewerDashboardData(data,now,status).trend.reduce((n,r)=>n+r.count,0)
 assert.equal(sum('All'),2);assert.equal(sum('Under review'),1);assert.equal(sum('Approved'),1)
})
test('upcoming appointments exclude past times, cancellations, completed visits and other patients',()=>{
 const data=fixture(), a={...data.appointments[0],patientId:data.patients[0].id,date:'2026-10-03',status:'Confirmed'}
 data.appointments=[{...a,id:'PAST',time:'11:00'},{...a,id:'NEXT',time:'13:00'},{...a,id:'CANCEL',time:'14:00',status:'Cancelled'},{...a,id:'DONE',time:'15:00',status:'Completed'},{...a,id:'OTHER',time:'16:00',patientId:data.patients[1].id}]
 assert.deepEqual(reviewerDashboardData(data,now).appointments.map(a=>a.id),['NEXT'])
 data.requests=[];const empty=reviewerDashboardData(data,now);assert.equal(empty.patients.length,0);assert.equal(empty.alerts.length,0);assert.equal(empty.latest.length,0);assert.ok(empty.trend.every(r=>r.count===0))
})
