import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import ts from 'typescript'
const moduleUrl = source => `data:text/javascript;base64,${Buffer.from(ts.transpile(source,{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022})).toString('base64')}`
const load = name => readFile(new URL(`../src/${name}.ts`,import.meta.url),'utf8')
let source = await load('ArabicCatalogue')
for(const name of ['CareTranslations','CareWorkflowTranslations','AdminTranslations','ReportTranslations']) source = source.replace(`from './${name}'`, `from '${moduleUrl(await load(name))}'`)
const catalogue = await import(moduleUrl(source))
const { localizeArabic } = await import(moduleUrl(await load('ArabicText')))
const ar = text => localizeArabic(text,catalogue)
test('administrator dashboard has complete Arabic headings and dynamic forecasts',()=>{
  for(const text of ["Here’s the complete picture",'Patient outcome predictions','Select a month to inspect the recorded activity.','4 of 7 strengths in stock','2 low-stock strengths · 1 unavailable.','Scheduled commitments over the next 60 days.','May: 2 new patients · 1 treatment starts · 0 completed plans','9 patients with usable trends','72 registered in the last 90 days ÷ 90 × 30.']) assert.doesNotMatch(ar(text),/[a-z]/i,text)
})
test('audit notices translate without altering linked record identifiers',()=>{
  assert.equal(ar('Existing DSP-DEMO-P001 found. No additional stock or dispensing transaction was committed.'),'يوجد سجل سابق برقم DSP-DEMO-P001. لم تُسجل أي حركة إضافية للمخزون أو صرف الدواء.')
  assert.equal(ar('5 mg · UAE-10mg-2026-A · P999'),'5 ملغ · UAE-10mg-2026-A · P999')
  assert.equal(ar('10:30 AM'),'10:30 ص')
})
test('shared bilingual patient records can override names without changing stored values',()=>{
  const original='Ali Al Hammadi · P051 · Review lab results'
  const phrases=new Map(catalogue.phrases).set('Ali Al Hammadi','علي الحمادي')
  const translated=localizeArabic(original,{...catalogue,phrases,orderedPhrases:[...phrases].sort(([a],[b])=>b.length-a.length)})
  assert.equal(translated,'علي الحمادي · P051 · مراجعة نتائج التحاليل')
  assert.equal(original,'Ali Al Hammadi · P051 · Review lab results')
})
