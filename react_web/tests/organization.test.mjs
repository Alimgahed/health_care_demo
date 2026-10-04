import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'
const url=source=>`data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const domainUrl=url(await readFile(new URL('../src/domain.ts',import.meta.url),'utf8'))
const {seed,nearbyRehabilitation,canonicalize}=await import(domainUrl)
const source=(await readFile(new URL('../src/organizationData.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`)
const {saveDirectoryDoctor,saveDirectoryCentre,directoryCentres}=await import(url(source))
const repository=await import(url((await readFile(new URL('../src/mockRepository.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`)))
const doctor={name:'Dr. Test Directory',nameAr:'طبيب تجريبي',gender:'Male',specialty:'Physiotherapy',licenseReference:'TEST-LICENSE-101',centre:seed.centres[0].name,programmeRole:'Treating physician',qualification:'Specialist',email:'doctor@example.test',phone:'+971501234567',joinedAt:'2026-10-02',contractStatus:'Active',notes:'Test'}
const centre={name:'Test Rehabilitation Centre',nameAr:'مركز تأهيل تجريبي',kind:'Physiotherapy',emirate:seed.centres[0].emirate,location:'Test location',contact:'+971501234568',email:'centre@example.test',manager:'Test manager',contractReference:'TEST-CONTRACT-101',contractDate:'2026-10-02',contractStatus:'Active',services:['Physical therapy'],lat:'24.4539',lng:'54.3773',capacity:20,maxSessions:80,programIds:[seed.rehabilitationPrograms[0].id],pharmacy:'',notes:'Test'}
test('doctor creation, duplicate protection and reassignment keep shared patient links',()=>{
 const data=structuredClone(seed),created=saveDirectoryDoctor(data,'Admin',doctor)
 assert.equal(created.doctors.length,data.doctors.length+1)
 assert.equal(created.audit[0].entityId,created.doctors[0].id)
 assert.throws(()=>saveDirectoryDoctor(created,'Admin',{...doctor,name:'Another doctor'}),/license/)
 assert.throws(()=>saveDirectoryDoctor(data,'Doctor',doctor),/administrators/)
 assert.throws(()=>saveDirectoryDoctor(data,'Admin',{...doctor,centre:'Unknown'}),/centre/)
 const d=data.doctors.find(d=>data.patients.some(p=>p.assignedDoctor===d.name)),nextCentre=data.centres.find(c=>c.name!==d.centre&&c.status==='Active')
 const edited=canonicalize(saveDirectoryDoctor(data,'Admin',{...doctor,name:d.name,licenseReference:d.licenseReference,centre:nextCentre.name},d.id))
 assert.ok(edited.patients.filter(p=>p.assignedDoctor===d.name).every(p=>p.centreId===nextCentre.id&&p.treatmentCentre===nextCentre.name))
})
test('new physiotherapy centre is immediately available to rehabilitation plans and persists',()=>{
 const data=saveDirectoryCentre(seed,'Admin',centre),added=data.rehabilitationCentres[0]
 assert.equal(added.name,centre.name)
 assert.equal(data.centres.length,seed.centres.length)
 assert.equal(directoryCentres(data).length,directoryCentres(seed).length+1)
 assert.ok(nearbyRehabilitation(data,seed.patients[0].id,centre.programIds[0]).some(c=>c.id===added.id))
 assert.throws(()=>saveDirectoryCentre(data,'Admin',centre),/already exists/)
 assert.throws(()=>saveDirectoryCentre(seed,'Admin',{...centre,lat:'NaN'}),/latitude/)
 assert.throws(()=>saveDirectoryCentre(seed,'Admin',{...centre,capacity:0}),/positive/)
 assert.throws(()=>saveDirectoryCentre(seed,'Admin',{...centre,programIds:['UNKNOWN']}),/programmes/)
 assert.throws(()=>saveDirectoryCentre(seed,'Patient',centre),/administrators/)
 const storage=new Map(),descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage')
 Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v)}})
 try{repository.saveMockData(saveDirectoryDoctor(data,'Admin',doctor));const loaded=repository.loadMockData();assert.ok(loaded.doctors.some(d=>d.licenseReference===doctor.licenseReference));assert.deepEqual(loaded.rehabilitationCentres.find(c=>c.id===added.id),added)}finally{if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
})
test('treatment centre creation enters the canonical care directory and invalid saves are atomic',()=>{
 const before=JSON.stringify(seed)
 const created=saveDirectoryCentre(seed,'Admin',{...centre,kind:'Treatment'})
 assert.equal(created.centres.length,seed.centres.length+1)
 assert.equal(created.rehabilitationCentres.length,seed.rehabilitationCentres.length)
 assert.throws(()=>saveDirectoryDoctor(seed,'Admin',{...doctor,joinedAt:'2026-02-31'}),/joining date/)
 assert.throws(()=>saveDirectoryCentre(seed,'Admin',{...centre,services:[]}),/service/)
 assert.equal(JSON.stringify(seed),before)
})

test('shared demo directory has five complete doctors and complete, distinct centre locations',()=>{
 assert.equal(seed.doctors.length,5)
 for(const doctor of seed.doctors){
  for(const key of ['name','nameAr','gender','specialty','licenseReference','centre','centreId','programmeRole','qualification','email','phone','joinedAt','contractStatus']) assert.ok(doctor[key],`${doctor.id}: ${key}`)
  assert.ok(seed.centres.some(c=>c.id===doctor.centreId&&c.name===doctor.centre))
 }
 const centres=directoryCentres(seed)
 for(const centre of centres){
  for(const key of ['name','nameAr','kind','emirate','location','contact','email','manager','contractReference','contractDate','contractStatus']) assert.ok(centre[key],`${centre.id}: ${key}`)
  assert.ok(centre.services.length)
  assert.match(centre.contact,/^\+971\d+$/)
  assert.ok(Number.isFinite(centre.coordinates.lat)&&Number.isFinite(centre.coordinates.lng))
  assert.ok(!Number.isNaN(Date.parse(centre.contractDate)))
  if(centre.source==='rehabilitation'){assert.ok(centre.maxSessions>0);assert.ok(centre.programIds.length)}
 }
 assert.equal(new Set(centres.map(c=>`${c.coordinates.lat},${c.coordinates.lng}`)).size,centres.length)
})

test('old saved directory gains missing details without replacing edits, status or custom locations',()=>{
 const saved=structuredClone(seed)
 saved.doctors=saved.doctors.slice(0,2)
 for(const record of [...saved.doctors,...saved.centres,...saved.rehabilitationCentres]){
  for(const key of ['nameAr','gender','email','phone','manager','contractReference','contractDate','contractStatus','programmeRole','qualification','joinedAt','services','maxSessions']) delete record[key]
 }
 saved.doctors[0].email='edited@example.test'
 saved.doctors[1].status='Inactive'
 saved.centres[0].contractDate=''
 saved.centres[0].contact='ctr-auh-02@example.test'
 saved.centres[0].coordinates={lat:24.4539,lng:54.3773}
 saved.centres[1].manager='Saved manager'
 saved.centres[1].coordinates={lat:24.25,lng:55.73}
 saved.rehabilitationCentres[0].contact='auh-rehab@example.test'
 const descriptor=Object.getOwnPropertyDescriptor(globalThis,'localStorage'),storage=new Map()
 Object.defineProperty(globalThis,'localStorage',{configurable:true,value:{getItem:k=>storage.get(k)??null,setItem:(k,v)=>storage.set(k,v)}})
 try{
  repository.saveMockData(saved)
  const loaded=repository.loadMockData()
  assert.equal(loaded.doctors.length,5)
  assert.equal(loaded.doctors[0].email,'edited@example.test')
  assert.equal(loaded.doctors[1].status,'Inactive')
  assert.equal(loaded.doctors[1].contractStatus,'Suspended')
  assert.equal(loaded.centres[0].contractDate,seed.centres[0].contractDate)
  assert.equal(loaded.centres[0].contact,seed.centres[0].contact)
  assert.deepEqual(loaded.centres[0].coordinates,seed.centres[0].coordinates)
  assert.equal(loaded.centres[1].manager,'Saved manager')
  assert.deepEqual(loaded.centres[1].coordinates,saved.centres[1].coordinates)
  assert.equal(loaded.rehabilitationCentres[0].contact,seed.rehabilitationCentres[0].contact)
  assert.equal(loaded.rehabilitationCentres.at(-1).contractStatus,'Suspended')
  repository.saveMockData(loaded)
  const twice=repository.loadMockData()
  assert.deepEqual(twice.doctors,loaded.doctors)
  assert.deepEqual(twice.centres,loaded.centres)
  assert.deepEqual(twice.rehabilitationCentres,loaded.rehabilitationCentres)
 }finally{if(descriptor)Object.defineProperty(globalThis,'localStorage',descriptor);else delete globalThis.localStorage}
})
