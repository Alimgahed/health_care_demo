import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'
import ts from 'typescript'
const source=await readFile(new URL('../src/documentEntries.ts',import.meta.url),'utf8')
const {patientDocumentEntries}=await import(`data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext})).toString('base64')}`)
test('reports follow saved lab values, avoid duplicates, retain uploads and isolate patients',()=>{
 const lab={id:'L1',patientId:'P1',value:7.5,date:'2026-10-01',status:'Abnormal'}
 const data={labs:[lab,{id:'L2',patientId:'P1',value:0,date:'2026-10-02',status:'Pending'},{id:'L3',patientId:'P2',value:8,date:'2026-10-01'}],documents:[{id:'DOC-P1-L1',patientId:'P1',date:'2026-10-01',content:'old value 8.5'},{id:'UPLOADED',patientId:'P1',date:'2026-10-02',dataUrl:'data:application/pdf;base64,original'},{id:'OTHER',patientId:'P2',date:'2026-10-02',labResultId:'L2'}]}
 const entries=patientDocumentEntries(data,'P1')
 assert.equal(entries.length,3)
 assert.equal(entries.find(e=>e.lab?.id==='L1').lab.value,7.5)
 assert.equal(entries.find(e=>e.lab?.id==='L2').lab.status,'Pending')
 assert.equal(entries.find(e=>e.id==='UPLOADED').document.dataUrl,'data:application/pdf;base64,original')
 assert.ok(!entries.some(e=>e.id==='OTHER'||e.lab?.patientId==='P2'))
 assert.equal(data.documents.length,3)
})
