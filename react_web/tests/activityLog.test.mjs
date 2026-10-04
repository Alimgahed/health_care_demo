import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'
const moduleUrl = source => `data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const domainUrl=moduleUrl(await readFile(new URL('../src/domain.ts',import.meta.url),'utf8'))
const {seed}=await import(domainUrl)
const {activityLogRows,updateActivityState}=await import(moduleUrl(await readFile(new URL('../src/activityLogData.ts',import.meta.url),'utf8')))
const repositorySource=(await readFile(new URL('../src/mockRepository.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`)
const repository=await import(moduleUrl(repositorySource))
test('activity rows retain every audit event and join the patient and inventory by ID',()=>{
 const data=structuredClone(seed)
 const request=data.requests[0],patient=data.patients.find(p=>p.id===request.patientId),batch=data.batches[0]
 data.audit=[{id:'A',actor:'Doctor',action:'Request submitted',entity:'Treatment request',entityId:request.id,time:'10:00',occurredAt:'2026-10-02T10:00:00Z',detail:'Submitted',newState:'Under review'}, {id:'B',actor:'Pharmacist',action:'Inventory reduced',entity:'Medication batch',entityId:batch.batchNumber,time:'11:00',detail:'One unit'}, {id:'C',actor:'Admin',action:'Configuration changed',entity:'System',entityId:'SYSTEM',time:'12:00',detail:'Updated'}]
 const rows=activityLogRows(data)
 assert.equal(rows.length,data.audit.length)
 assert.equal(rows[0].patientName,patient.name)
 assert.equal(rows[0].centre,patient.treatmentCentre)
 assert.equal(rows[0].target,'Treatment requests')
 assert.equal(rows[1].category,'Inventory')
 assert.equal(rows[1].centre,batch.centre)
 assert.equal(rows[1].timestamp,0)
 assert.equal(rows[2].target,undefined)
 patient.name='Updated patient'
 assert.equal(activityLogRows(data)[0].patientName,'Updated patient')
})
test('read and follow-up state preserves original audit evidence and stays in shared storage',()=>{
 const data=structuredClone(seed)
 data.audit=[{...data.audit[0],id:'A',newState:'Needs information',action:'Information requested'}]
 const snapshot=JSON.stringify(data.audit)
 assert.equal(activityLogRows(data)[0].status,'Unread')
 const read=updateActivityState(data,'Admin',['A'],'read')
 assert.equal(activityLogRows(read)[0].status,'Information')
 const handled=updateActivityState(read,'Admin',['A'],'handled')
 assert.equal(activityLogRows(handled)[0].status,'Handled')
 assert.equal(JSON.stringify(handled.audit),snapshot)
 const storage=new Map(),descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage')
 Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,value)}})
 try{repository.saveMockData(handled);assert.deepEqual(repository.loadMockData().activityEventStates,handled.activityEventStates)}finally{if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
 assert.equal(activityLogRows(updateActivityState(handled,'Admin',['A'],'unread'))[0].status,'Unread')
 assert.throws(()=>updateActivityState(data,'Doctor',['A'],'handled'),/administrators/)
 assert.throws(()=>updateActivityState(data,'Admin',['UNKNOWN'],'read'),/not found/)
})
const analyticsUrl=moduleUrl((await readFile(new URL('../src/adminAnalytics.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`))
const alertsUrl=moduleUrl((await readFile(new URL('../src/alertsWorkspaceData.ts',import.meta.url),'utf8')).replace("from './adminAnalytics'",`from '${analyticsUrl}'`).replace("from './domain'",`from '${domainUrl}'`))
const {navigationBadges}=await import(moduleUrl((await readFile(new URL('../src/navigationBadges.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`).replace("from './adminAnalytics'",`from '${analyticsUrl}'`).replace("from './alertsWorkspaceData'",`from '${alertsUrl}'`)))
test('real business changes increase the admin stream badge and acknowledgement does not create recursive events',async()=>{
 const {updateCentreStatus}=await import(domainUrl)
 const data=structuredClone(seed),before=navigationBadges(data,'Admin')
 const next=updateCentreStatus(data,'Admin',data.centres[0].id,data.centres[0].status==='Active'?'Inactive':'Active')
 assert.equal(navigationBadges(next,'Admin')['Activity log'],before['Activity log']+1)
 const read=updateActivityState(next,'Admin',[next.audit[0].id],'read')
 assert.equal(navigationBadges(read,'Admin')['Activity log'],before['Activity log'])
 assert.equal(read.audit.length,next.audit.length)
 assert.equal(navigationBadges(next,'Doctor')['Activity log'],0)
})
test('request badges derive from the current review queue',()=>{
 const data=structuredClone(seed)
 assert.equal(navigationBadges(data,'Admin')['Treatment requests'],data.requests.filter(r=>r.status==='Under review').length)
 const request=data.requests.find(r=>r.status==='Under review')
 const before=navigationBadges(data,'Admin')['Treatment requests']
 request.status='Rejected'
 assert.equal(navigationBadges(data,'Admin')['Treatment requests'],before-1)
})
test('updating a care plan preserves its linked request and records the exact plan change',async()=>{
 const {updateIntegratedCarePlan}=await import(domainUrl)
 const data=structuredClone(seed),plan=data.integratedCarePlans[0]
 const next=updateIntegratedCarePlan(data,'Admin',plan.id,{title:'Follow-up and movement',monitoring:'Review mobility and adherence at the next visit.'})
 assert.equal(next.integratedCarePlans.find(p=>p.id===plan.id).title,'Follow-up and movement')
 assert.equal(next.requests,data.requests)
 assert.equal(next.audit[0].entityId,plan.id)
 assert.equal(next.audit[0].patientId,plan.patientId)
 assert.equal(next.audit[0].previousState,plan.title)
 assert.throws(()=>updateIntegratedCarePlan(data,'Patient',plan.id,{title:'Test',monitoring:'Valid monitoring'}))
 assert.throws(()=>updateIntegratedCarePlan(data,'Admin',plan.id,{title:'',monitoring:'Valid monitoring'}))
})
