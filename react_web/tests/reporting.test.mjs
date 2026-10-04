import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'
const moduleUrl = source => `data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const domainUrl=moduleUrl(await readFile(new URL('../src/domain.ts',import.meta.url),'utf8'))
const reportingUrl=moduleUrl((await readFile(new URL('../src/reporting.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`))
const {seed}=await import(domainUrl)
const {reportRows,reportOverview,previousReportFilters}=await import(reportingUrl)
const now=new Date('2026-10-02T12:00:00Z')
const filters={from:'2026-01-01',to:'2026-10-02',scope:'All',programme:'All',category:'All',type:'All'}

test('report metrics, chart and programme distribution reconcile with export rows',()=>{
 const data=structuredClone(seed)
 const report=reportOverview(data,filters,now)
 const rows=reportRows(data,'requests',filters,now.getTime())
 assert.equal(report.totals[1],rows.length)
 assert.equal(report.trend.reduce((n,row)=>n+row.submitted,0),rows.length)
 assert.equal(report.programmes.reduce((n,row)=>n+row.count,0),rows.length)
 assert.equal(report.centres.reduce((n,row)=>n+row.count,0),rows.length)
 assert.equal(report.totals[5],reportRows(data,'financial',filters,now.getTime()).reduce((n,row)=>n+row.totalAED,0))
 data.requests.push({...data.requests[0],id:'NEW-REPORT-REQUEST',createdAt:'2026-10-02T00:00:00Z',status:'Approved'})
 const updated=reportOverview(data,filters,now)
 assert.equal(updated.totals[1],report.totals[1]+1)
 assert.equal(updated.totals[2],report.totals[2]+1)
})

test('location, programme and category filters follow patient IDs, not duplicate names',()=>{
 const data=structuredClone(seed)
 data.patients=[{...data.patients[0],id:'A',name:'Same name',emirate:'Dubai',treatmentCentre:'Dubai Central Pharmacy',diagnosis:'Type 2 diabetes',residency:'Citizen'},
 {...data.patients[0],id:'B',name:'Same name',emirate:'Sharjah',treatmentCentre:'Sharjah Health Centre',diagnosis:'Weight management',residency:'Resident'}]
 data.requests=[{...data.requests[0],id:'RA',patientId:'A',createdAt:'2026-09-10'},{...data.requests[0],id:'RB',patientId:'B',createdAt:'2026-09-10'}]
 const scoped={...filters,scope:'Dubai Central Pharmacy',programme:'Type 2 diabetes',category:'Citizen'}
 assert.deepEqual(reportRows(data,'requests',scoped,now.getTime()).map(row=>row.requestId),['RA'])
 assert.equal(reportOverview(data,scoped,now).totals[1],1)
 assert.equal(reportRows(data,'requests',{...scoped,category:'Resident'},now.getTime()).length,0)
 assert.equal(reportRows(data,'requests',{...filters,scope:'Sharjah'},now.getTime())[0].patientId,'B')
})

test('period filters exclude undated records and previous period is equal length',()=>{
 const data=structuredClone(seed)
 data.requests=[{...data.requests[0],id:'IN',createdAt:'2026-09-01'},{...data.requests[0],id:'BEFORE',createdAt:'2026-08-31'},{...data.requests[0],id:'AFTER',createdAt:'2026-10-01'},{...data.requests[0],id:'UNKNOWN',createdAt:undefined}]
 const range={...filters,from:'2026-09-01',to:'2026-09-30'}
 assert.deepEqual(reportRows(data,'requests',range,now.getTime()).map(row=>row.requestId),['IN'])
 const previous=previousReportFilters(range)
 assert.equal(previous.from,'2026-08-02')
 assert.equal(previous.to,'2026-08-31')
 const weekly=reportOverview(data,range,now,'Weekly')
 assert.equal(weekly.trend.reduce((n,row)=>n+row.submitted,0),1)
 const fullRange=reportOverview(data,{...filters,from:'2023-10-03'},now,'Weekly')
 assert.equal(fullRange.trend.reduce((n,row)=>n+row.submitted,0),3)
})

test('empty report scope has finite zero counts and no fabricated programme categories',()=>{
 const result=reportOverview(seed,{...filters,scope:'Missing centre'},now)
 assert.deepEqual(result.totals,[0,0,0,0,0,0])
 assert.equal(result.programmes.length,0)
 assert.equal(result.centres.length,0)
 assert.ok(result.trend.every(row=>row.submitted===0))
})
