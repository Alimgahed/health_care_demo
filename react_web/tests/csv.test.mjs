import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'
const source=await readFile(new URL('../src/csvExport.ts',import.meta.url),'utf8')
const javascript=ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})
const {serializeCsv}=await import(`data:text/javascript;base64,${Buffer.from(javascript).toString('base64')}`)
test('CSV keeps Arabic, quotes, multiline content and numeric values while escaping formula text',()=>{
  const csv=serializeCsv([{patient:'أحمد',note:'He said "review"\nNext visit',quantity:-2},{patient:'=HYPERLINK("x")',note:' +SUM(1,2)',quantity:3}])
  assert.ok(csv.startsWith('\ufeff'))
  assert.ok(csv.includes('"أحمد"'))
  assert.ok(csv.includes('"He said ""review""\nNext visit"'))
  assert.ok(csv.includes('"-2"'))
  assert.ok(csv.includes('"\'=HYPERLINK(""x"")"'))
  assert.ok(csv.includes('"\' +SUM(1,2)"'))
  assert.equal(serializeCsv([]),'')
})
