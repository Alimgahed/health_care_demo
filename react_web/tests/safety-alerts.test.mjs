import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'
import ts from 'typescript'
const compile=source=>`data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const source=path=>readFile(new URL(`../src/${path}.ts`,import.meta.url),'utf8')
const domainUrl=compile(await source('domain'))
const analyticsUrl=compile((await source('adminAnalytics')).replace("from './domain'",`from '${domainUrl}'`))
const viewUrl=compile((await source('alertsWorkspaceData')).replace("from './domain'",`from '${domainUrl}'`).replace("from './adminAnalytics'",`from '${analyticsUrl}'`))
const {seed,createOperationalAlert,markAlertRead,dismissAlert}=await import(domainUrl)
const {operationalAlerts}=await import(analyticsUrl)
const {alertsWorkspaceData}=await import(viewUrl)
const draft={title:'Supply follow-up',detail:'Verify receipt with the centre.',category:'Inventory',severity:'Warning',priority:'High',centre:seed.centres[0].name,medicationId:seed.medications[0].id}
test('new alerts, read and handled states derive from the shared repository and audit',()=>{
 const data=createOperationalAlert(structuredClone(seed),'Admin',draft)
 const id=data.manualAlerts[0].id
 assert.ok(operationalAlerts(data).some(a=>a.id===id))
 let row=alertsWorkspaceData(data,'Admin').find(a=>a.id===id)
 assert.equal(row.medication,seed.medications[0].name)
 assert.equal(row.centre,seed.centres[0].name)
 assert.equal(row.priority,'High')
 assert.equal(row.state,'Unread')
 const read=markAlertRead(data,'Admin',id)
 assert.equal(alertsWorkspaceData(read,'Admin').find(a=>a.id===id).state,'Read')
 const handled=dismissAlert(read,'Admin',id)
 assert.equal(alertsWorkspaceData(handled,'Admin').find(a=>a.id===id).state,'Handled')
 assert.ok(handled.audit.some(a=>a.entityId===id&&a.action==='Operational alert created'))
 assert.equal(seed.manualAlerts?.length??0,0)
})
test('alert creation validates permissions and shared entity references',()=>{
 assert.throws(()=>createOperationalAlert(seed,'Patient',draft))
 assert.throws(()=>createOperationalAlert(seed,'Admin',{...draft,medicationId:'missing'}))
 assert.throws(()=>createOperationalAlert(seed,'Admin',{...draft,title:' '}))
 assert.throws(()=>createOperationalAlert(seed,'Admin',{...draft,severity:'unknown'}))
})
test('treatment alert location and medication follow the linked patient and request',()=>{
 const data=structuredClone(seed)
 const request=data.requests.find(r=>r.status==='Under review')
 request.medication='Changed medication'
 const row=alertsWorkspaceData(data,'Admin').find(a=>a.id===`request-${request.id}`)
 assert.equal(row.medication,'Changed medication')
 assert.equal(row.dose,request.dose)
 assert.equal(row.patientId,request.patientId)
})
const repositoryUrl=compile((await source('mockRepository')).replace("from './domain'",`from '${domainUrl}'`))
const {loadMockData,saveMockData}=await import(repositoryUrl)
test('manual alert details and disposition survive reload',()=>{
 const original=Object.getOwnPropertyDescriptor(globalThis,'localStorage');const storage=new Map()
 Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,value)}})
 try{const data=createOperationalAlert(structuredClone(seed),'Admin',draft);const id=data.manualAlerts[0].id;saveMockData(dismissAlert(data,'Admin',id));const restored=loadMockData();assert.equal(restored.manualAlerts[0].title,draft.title);assert.ok(restored.dismissedAlerts.includes(id))}finally{if(original)Object.defineProperty(globalThis,'localStorage',original);else delete globalThis.localStorage}
})
