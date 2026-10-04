import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'

const compile = source => `data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const domainUrl = compile(await readFile(new URL('../src/domain.ts',import.meta.url),'utf8'))
const analyticsUrl = compile((await readFile(new URL('../src/adminAnalytics.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`))
const scopeUrl = compile((await readFile(new URL('../src/assistantScope.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`))
const {assistantScope,assistantLinkAllowed}=await import(scopeUrl)
const assistantUrl = compile((await readFile(new URL('../src/assistantQuery.ts',import.meta.url),'utf8')).replace("from './domain'",`from '${domainUrl}'`).replace("from './adminAnalytics'",`from '${analyticsUrl}'`).replace("from './assistantScope'",`from '${scopeUrl}'`))
const {seed,canReadPatient} = await import(domainUrl)
const {answerDataQuestion:ask} = await import(assistantUrl)

test('assistant answers combined counts from current records',()=>{
 const answer=ask(seed,'كم عدد المرضى وطلبات العلاج؟',true)
 assert.equal(answer.matched,true)
 assert.ok(answer.facts.includes(`المرضى: ${seed.patients.length}`))
 assert.ok(answer.facts.includes(`طلبات العلاج: ${seed.requests.length}`))
})
test('assistant scopes lab answers to the named patient and cites recorded values',()=>{
 const answer=ask(seed,'ما آخر تحليل للمريض P999؟',true)
 assert.equal(answer.matched,true)
 assert.ok(answer.facts.some(line=>line.includes('8.5')&&line.includes('4.0–5.6%')))
 assert.ok(answer.links.some(link=>link.id==='patient:P999'))
})
test('assistant retrieves an exact request without inventing its status',()=>{
 const record=seed.requests.find(item=>item.id==='TR-24011')
 const answer=ask(seed,'ما حالة الطلب TR-24011؟',true)
 assert.equal(answer.matched,true)
 assert.ok(answer.facts.some(line=>line.includes(record.dose)))
 assert.ok(answer.links.some(link=>link.id===record.id))
})
test('assistant reports no match for an unknown record',()=>{
 const answer=ask(seed,'P999999',true)
 assert.equal(answer.matched,false)
 assert.equal(answer.facts.length,0)
})

test('patient assistant cannot retrieve another patient or aggregate their evidence',()=>{
 const data=assistantScope({...seed,activePatientId:'P999'},'Patient')
 assert.deepEqual(data.patients.map(p=>p.id),['P999'])
 assert.ok(data.labs.every(l=>l.patientId==='P999'))
 assert.equal(ask(data,'latest lab for P001',false).matched,false)
 assert.deepEqual(ask(data,'latest lab for P001',false).facts,[])
 assert.equal(data.batches.length,0)
 assert.equal(assistantLinkAllowed('Patient','System audit'),false)
})
test('clinical assistant follows assignment changes and never copies inventory or financial totals',()=>{
 const data=assistantScope(seed,'Doctor')
 assert.ok(data.patients.every(p=>canReadPatient(seed,'Doctor',p.id)))
 assert.ok(data.requests.every(r=>data.patients.some(p=>p.id===r.patientId)))
 assert.equal(data.financial.length,0)
 assert.equal(data.batches.length,0)
 assert.equal(assistantScope(seed,'Admin'),seed)
})
test('English treatment questions are not mistaken for request identifiers',()=>{
 const answer=ask(seed,'How many patients and treatment requests?',false)
 assert.equal(answer.matched,true)
 assert.ok(answer.facts.includes(`Patients: ${seed.patients.length}`))
 assert.equal(ask(seed,'What is the status of request TR-NOT-FOUND?',false).matched,false)
})
test('clinical medication answers do not invent an empty inventory or disclose costs',()=>{
 const data=assistantScope(seed,'Doctor')
 assert.equal(ask(data,'medication stock',false,'Doctor').title,'Recorded medication')
 assert.equal(ask(data,'treatment cost',false,'Doctor').matched,false)
})

test('follow-up questions keep the patient, and an explicit new patient replaces context',()=>{
 const first=ask(seed,'ما حالة طلب العلاج للمريض P999؟',true)
 assert.equal(first.context.patientId,'P999')
 assert.equal(first.request.patientId,'P999')
 const labs=ask(seed,'وآخر تحليل له؟',true,'Admin',first.context)
 assert.ok(labs.records.every(r=>r.subtitle.includes('P999')))
 const other=ask(seed,'latest labs for P001',false,'Admin',first.context)
 assert.equal(other.context.patientId,'P001')
 assert.ok(other.records.every(r=>r.subtitle.includes('P001')))
})
test('an explicit female patient name replaces stale context and asks before resolving duplicate names',()=>{
 const answer=ask(seed,'آخر تحليل للمريضة سارة',true,'Admin',{patientId:'P999'})
 assert.equal(answer.title,'أي مريض تقصد؟')
 assert.equal(answer.context.patientId,undefined)
 assert.ok(answer.suggestions.some(option=>option.endsWith('P002')))
 assert.ok(answer.suggestions.some(option=>option.endsWith('P006')))
 const selected=ask(seed,'P006',true,'Admin',answer.context)
 const labs=ask(seed,'وآخر تحليل لها؟',true,'Admin',selected.context)
 assert.equal(labs.context.patientId,'P006')
 assert.ok(labs.records.every(record=>record.subtitle.includes('P006')))
})
test('Arabic first-name transcription resolves to explicit candidates, never the previous patient',()=>{
 const answer=ask(seed,'ما موعد المريض عالي؟',true,'Admin',{patientId:'P999'})
 assert.equal(answer.title,'أي مريض تقصد؟')
 assert.equal(answer.context.patientId,undefined)
 assert.ok(answer.suggestions.length>0)
 assert.ok(answer.suggestions.every(option=>/P\d{3}/.test(option)))
})
test('an unknown named patient does not silently inherit the previous patient context',()=>{
 const answer=ask(seed,'آخر تحليل للمريضة سارة الخيالية',true,'Admin',{patientId:'P999'})
 assert.equal(answer.matched,false)
 assert.equal(answer.title,'لم أجد هذا المريض')
 assert.equal(answer.context.patientId,undefined)
 assert.deepEqual(answer.facts,[])
})
test('generic patient lookup opens a record picker instead of choosing a default patient',()=>{
 const answer=ask(seed,'ملف المريض',true,'Admin',{patientId:'P999'})
 assert.equal(answer.title,'حدد المريض')
 assert.equal(answer.context.patientId,undefined)
 assert.ok(answer.suggestions.length>0)
})
test('all-record questions clear previous patient context and status filters use actual rows',()=>{
 const answer=ask(seed,'جميع الطلبات قيد المراجعة',true,'Admin',{patientId:'P999'})
 assert.equal(answer.total,seed.requests.filter(r=>r.status==='Under review').length)
 assert.equal(answer.context.patientId,undefined)
 assert.ok(answer.records.every(r=>r.status==='قيد المراجعة'))
})
test('abnormal results filter recorded statuses and update when canonical data changes',()=>{
 const before=ask(seed,'Abnormal lab results',false)
 const edited={...seed,labs:[...seed.labs,{...seed.labs[0],id:'NEW-LAB',status:'Abnormal',value:9.9}]}
 const after=ask(edited,'Abnormal lab results',false)
 assert.equal(after.total,before.total+1)
 assert.ok(after.records.some(r=>r.id==='NEW-LAB'&&r.values.some(v=>v.value.includes('9.9'))))
})
test('upcoming appointments sort chronologically and exclude cancelled and past visits',()=>{
 const now=new Date('2026-10-03T08:00:00Z')
 const base=seed.appointments[0]
 const data={...seed,appointments:[{...base,id:'future-2',date:'2026-10-05',status:'Confirmed'},{...base,id:'past',date:'2026-10-02',status:'Confirmed'},{...base,id:'cancelled',date:'2026-10-06',status:'Cancelled'},{...base,id:'future-1',date:'2026-10-04',status:'Scheduled'}]}
 const answer=ask(data,'upcoming appointments',false,'Admin',{},now)
 assert.deepEqual(answer.records.map(r=>r.id),['future-1','future-2'])
})
test('eligibility uses shared clinical rules and monthly dispensing date',()=>{
 const answer=ask(seed,'أهلية العلاج للمريض P999',true,'Admin',{},new Date('2026-10-03T12:00:00Z'))
 assert.equal(answer.context.patientId,'P999')
 assert.ok(answer.facts.some(f=>f.includes('موعد الصرف المسموح')))
 assert.ok(answer.body.includes('المختص'))
})
test('public assistant query enforces role scope even with unscoped input and stale context',()=>{
 const answer=ask({...seed,activePatientId:'P999'},'latest labs for P001',false,'Patient',{patientId:'P001'})
 assert.equal(answer.matched,false)
 assert.deepEqual(answer.facts,[])
 assert.deepEqual(answer.context,{})
})
test('Arabic digits identify patients and nonexistent IDs never inherit an old patient',()=>{
 assert.equal(ask(seed,'المريض P٩٩٩',true).context.patientId,'P999')
 assert.equal(ask(seed,'P987654321',true,'Admin',{patientId:'P999'}).matched,false)
})
test('ambiguous names ask for clarification instead of choosing a patient',()=>{
 const a={...seed.patients[0],id:'P501',name:'Test Shared Name',nameAr:'اختبار اسم مشترك'}
 const b={...a,id:'P502'}
 const answer=ask({...seed,patients:[a,b]},'اسم مشترك',true)
 assert.equal(answer.suggestions.length,2)
 assert.equal(answer.request,undefined)
 assert.equal(answer.context.patientId,undefined)
})
test('a completed dispense marks all journey steps complete and cites the exact request',()=>{
 const r=seed.requests[0]
 const data={...seed,requests:[{...r,status:'Dispensed'}]}
 const answer=ask(data,`request ${r.id}`,false)
 assert.ok(answer.steps.every(s=>s.state==='done'))
 assert.equal(answer.links[0].id,r.id)
})
test('asking for the doctor of a patient does not return the entire directory',()=>{
 const answer=ask(seed,'Who is the doctor for P999?',false)
 assert.equal(answer.title,'Assigned care team')
 assert.equal(answer.context.patientId,'P999')
 assert.ok(answer.facts.length<=3)
})
test('duplicate complete names require an ID even when a prior patient is in context',()=>{
 const a={...seed.patients[0],id:'P501',name:'Test Shared Name',nameAr:'اختبار اسم مشترك'}
 const b={...a,id:'P502'}
 const answer=ask({...seed,patients:[a,b]},'اختبار اسم مشترك',true,'Admin',{patientId:'P501'})
 assert.equal(answer.suggestions.length,2)
 assert.equal(answer.context.patientId,undefined)
 assert.equal(ask({...seed,patients:[a,b]},'اختبار اسم مشترك P502',true).context.patientId,'P502')
})
