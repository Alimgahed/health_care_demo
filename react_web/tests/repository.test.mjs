import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'

const domainSource = await readFile(new URL('../src/domain.ts', import.meta.url), 'utf8')
const domainJavascript = ts.transpile(domainSource, { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 })
const domainUrl = `data:text/javascript;base64,${Buffer.from(domainJavascript).toString('base64')}`
const domain = await import(domainUrl)
const repositorySource = (await readFile(new URL('../src/mockRepository.ts', import.meta.url), 'utf8')).replace("from './domain'", `from '${domainUrl}'`)
const repositoryJavascript = ts.transpile(repositorySource, { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 })
const repositoryUrl = `data:text/javascript;base64,${Buffer.from(repositoryJavascript).toString('base64')}`
const repository = await import(repositoryUrl)

test('repository migrates saved v4 data while repairing seeded links and preserving user state', () => {
  const storage = new Map()
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, 'localStorage')
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem(key) { return storage.get(key) ?? null },
    setItem(key, value) { storage.set(key, String(value)) },
  } })
  try {
    const saved = structuredClone(domain.seed)
    delete saved.doctors
    delete saved.reviewers
    delete saved.centres
    delete saved.abuseReviews
    saved.patients.find(item => item.id === 'P012').assignedDoctor = 'Dr. Omar Khalid'
    saved.requests.find(item => item.id === 'TR-24018').status = 'Needs information'
    saved.treatmentPlans.find(item => item.id === 'TP-8791').endDate = '2026-12-24'
    saved.labs.find(item => item.patientId === 'P012').value = 1
    saved.notifications.find(item => item.id === 'NT-018').patientId = 'P999'
    saved.notifications.find(item => item.id === 'NT-018').read = true
    storage.set('healthcare-state-v4', JSON.stringify(saved))

    const migrated = repository.loadMockData()
    assert.equal(migrated.patients.find(item => item.id === 'P012').assignedDoctor, 'Dr. Laila Hassan')
    assert.equal(migrated.requests.find(item => item.id === 'TR-24018').status, 'Needs information')
    assert.equal(migrated.treatmentPlans.find(item => item.id === 'TP-8791').endDate, '2026-12-23')
    assert.equal(migrated.labs.find(item => item.patientId === 'P012').value, 7.3)
    const notification = migrated.notifications.find(item => item.id === 'NT-018')
    assert.equal(notification.patientId, 'P010')
    assert.equal(notification.read, true)
    repository.saveMockData(migrated)
    assert.ok(storage.has('healthcare-state-v7'))
  } finally {
    if (descriptor) Object.defineProperty(globalThis, 'localStorage', descriptor)
    else delete globalThis.localStorage
  }
})

test('v6 repository preserves administrator-managed doctor and centre relationships', () => {
  const storage = new Map()
  const descriptor = Object.getOwnPropertyDescriptor(globalThis, 'localStorage')
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem(key) { return storage.get(key) ?? null },
    setItem(key, value) { storage.set(key, String(value)) },
  } })
  try {
    const saved = structuredClone(domain.seed)
    saved.doctors[0].centre = 'Sharjah Health Centre'
    saved.doctors[0].status = 'Inactive'
    saved.patients.filter(item => item.assignedDoctor === 'Dr. Laila Hassan').forEach(item => { item.treatmentCentre = 'Sharjah Health Centre' })
    storage.set('healthcare-state-v6', JSON.stringify(saved))
    const loaded = repository.loadMockData()
    assert.equal(loaded.doctors[0].centre, 'Sharjah Health Centre')
    assert.equal(loaded.doctors[0].status, 'Inactive')
    assert.ok(loaded.patients.filter(item => item.assignedDoctor === 'Dr. Laila Hassan').every(item => item.treatmentCentre === 'Sharjah Health Centre'))
  } finally {
    if (descriptor) Object.defineProperty(globalThis, 'localStorage', descriptor)
    else delete globalThis.localStorage
  }
})

test('v7 preserves edited evidence, care programmes, documents and normalized relationships',()=>{
  const storage=new Map();const descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage')
  Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,String(value))}})
  try{
    const saved=structuredClone(domain.seed);saved.labs.find(item=>item.id==='LB-P999-A1C').value=7.7
    saved.treatmentPlans.find(item=>item.id==='TP-P999-HISTORY').dose='10 mg'
    saved.documents[0].content='Updated clinical summary';saved.documents[0].fileName='summary.pdf';saved.documents[0].mimeType='application/pdf';saved.documents[0].dataUrl='data:application/pdf;base64,JVBERi0=';saved.documents[0].sizeBytes=8;saved.carePrograms[0].weeklySessions=4
    repository.saveMockData(saved);const loaded=repository.loadMockData()
    assert.equal(loaded.labs.find(item=>item.id==='LB-P999-A1C').value,7.7)
    assert.equal(loaded.documents[0].content,'Updated clinical summary');assert.equal(loaded.documents[0].dataUrl,'data:application/pdf;base64,JVBERi0=');assert.equal(loaded.carePrograms[0].weeklySessions,4)
    assert.equal(loaded.patients[0].doctorId,'DOC-001')
    assert.equal(loaded.treatmentPlans.find(item=>item.id==='TP-P999-HISTORY').dose,'5 mg')
  }finally{if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
})

test('integrated plans, catalog edits, selected patient and cross-portal links survive reload',()=>{
  const storage=new Map(),descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage')
  Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,String(value))}})
  try{
    const date=days=>new Date(Date.now()+days*86400000).toISOString().slice(0,10)
    let saved=structuredClone(domain.seed)
    saved=domain.createIntegratedCarePlan(saved,'Doctor',{patientId:'P001',title:'Recovery and follow-up',homeExerciseIds:['HE-WALK'],rehabilitation:{programId:'RP-PHYSIO',centreId:'RC-AUH',plannedSessions:6},startDate:date(0),followUpDate:date(14),followUpTime:'15:45',monitoring:'Review progress and adherence.',rationale:'Goals reviewed with the patient.'})
    const plan=saved.integratedCarePlans[0]
    saved.activePatientId='P001';saved.homeExercises[0].instructions='Preserved clinician-reviewed instructions.'
    repository.saveMockData(saved);const loaded=repository.loadMockData()
    assert.equal(loaded.activePatientId,'P001')
    assert.deepEqual(loaded.integratedCarePlans.find(p=>p.id===plan.id),JSON.parse(JSON.stringify(plan)))
    assert.equal(loaded.homeExercises[0].instructions,saved.homeExercises[0].instructions)
    assert.equal(loaded.financial.filter(f=>f.integratedCarePlanId===plan.id).length,1)
    assert.equal(loaded.appointments.find(a=>a.id===plan.appointmentId).patientId,'P001')
    assert.equal(loaded.patients.find(p=>p.id==='P001').residency,'Resident')
  }finally{if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
})

test('expanding an existing 51-patient v7 demo preserves edits and remains idempotent',()=>{
 const storage=new Map()
 const descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage')
 Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,String(value))}})
 try {
  const saved=structuredClone(domain.seed)
  const oldIds=new Set(saved.patients.slice(0,51).map(p=>p.id))
  for(const key of ['patients','labs','vitals','assessments','appointments','documents']) saved[key]=saved[key].filter(item=>oldIds.has(key==='patients'?item.id:item.patientId))
  saved.patients[0].name='Saved patient name'
  delete saved.patients[0].demoPortrait
  saved.labs[0].value=7.1
  saved.documents.push({id:'USER-UPLOAD',patientId:'P999',title:'User file',date:'2026-10-02',authorId:'DOC-001',content:'Preserved content',dataUrl:'data:text/plain;charset=utf-8,saved'})
  repository.saveMockData(saved)
  const loaded=repository.loadMockData()
  assert.equal(loaded.patients.length,150)
  assert.equal(loaded.patients[0].name,'Saved patient name')
  assert.equal(loaded.labs[0].value,7.1)
  assert.equal(loaded.documents.find(d=>d.id==='USER-UPLOAD').content,'Preserved content')
  assert.ok(loaded.patients.every(p=>p.demoPortrait))
  repository.saveMockData(loaded)
  const again=repository.loadMockData()
  for(const key of ['patients','labs','vitals','assessments','appointments','documents']) assert.equal(again[key].length,loaded[key].length,key)
 } finally {if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
})

test('report snapshots and schedule preferences survive repository reload',()=>{
 const storage=new Map(),descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage')
 Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,String(value))}})
 try {
  const data=structuredClone(domain.seed)
  data.savedReports=[{id:'REPORT-TEST',name:'Saved report',type:'requests',generatedAt:'2026-10-02T12:00:00Z',generatedBy:'Admin',filters:{from:'2026-09-01',to:'2026-09-30',scope:'All',programme:'All',category:'All',type:'All'},rows:[{requestId:'SNAPSHOT-1',status:'Under review'}]}]
  data.reportSchedules[0].enabled=true
  repository.saveMockData(data)
  const loaded=repository.loadMockData()
  assert.deepEqual(loaded.savedReports,data.savedReports)
  assert.equal(loaded.reportSchedules[0].enabled,true)
  data.requests[0].status='Rejected'
  assert.equal(loaded.savedReports[0].rows[0].status,'Under review')
 } finally {if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
})

test('workspace loading can be aborted when navigation changes', async () => {
 const controller = new AbortController()
 const pending = repository.readMockWorkspace('Patients', controller.signal)
 controller.abort()
 await assert.rejects(pending, { name: 'AbortError' })
 await repository.readMockWorkspace('Inventory')
})
test('an already cancelled workspace never resolves as a successful load', async () => {
 const controller = new AbortController()
 controller.abort()
 await assert.rejects(repository.readMockWorkspace('assistant', controller.signal), { name: 'AbortError' })
})
