import { CareIcon } from './CareIcon'
import { useMemo, useState } from 'react'
import type { AppData, CareDocument, LabResult, Role } from './domain'
import { PatientLabIntake } from './PatientEvidenceUpload'
import { downloadLabReport, labReportPreview } from './LabReport'
import './PatientLabResults.css'

type Props={data:AppData;patientId:string;role:Role;arabic:boolean;onUpdate:(next:AppData)=>void}
const translations:Record<string,string>={HbA1c:'السكر التراكمي','Fasting glucose':'سكر صائم',Creatinine:'الكرياتينين',Cholesterol:'الكوليسترول','Glucose (Fasting)':'سكر صائم','Cholesterol (LDL)':'الكوليسترول الضار',Triglycerides:'الدهون الثلاثية',HDL:'الكوليسترول النافع'}
export function PatientLabResults({data,patientId,role,arabic,onUpdate}:Props){
 const [adding,setAdding]=useState(false)
 const [selected,setSelected]=useState<string>('')
 const [feedback,setFeedback]=useState('')
 const t=(en:string,ar:string)=>arabic?ar:en
 const patient=data.patients.find(p=>p.id===patientId)!
 const labs=useMemo(()=>data.labs.filter(l=>l.patientId===patientId).sort((a,b)=>b.date.localeCompare(a.date)),[data.labs,patientId])
 const lab=labs.find(item=>item.id===selected)??labs[0]
 const doc=lab?(data.documents??[]).find(item=>item.patientId===patientId&&(item.labResultId===lab.id||item.id===`DOC-${patientId}-${lab.id}`)):undefined
 const status=(value:LabResult['status'])=>arabic?({Normal:'طبيعي',Abnormal:'غير طبيعي',Pending:'قيد الانتظار'}[value]):value
 const testName=(value:string)=>arabic?translations[value]??value:value
 const original=Boolean(doc?.dataUrl&&(doc.mimeType?.startsWith('image/')||doc.mimeType==='application/pdf'))
 const preview=lab&&!original?labReportPreview(patient,lab,arabic):undefined
 return <div className="lab-workspace">
  <section className="lab-header"><div><span className="lab-eyebrow">{t('PATIENT LABORATORY','تحاليل المريض')}</span><h2>{t('Results & source reports','النتائج والتقارير الأصلية')}</h2><p>{t('Review the recorded result beside its source. The PDF is generated from the same saved values.','راجع النتيجة المسجلة بجانب مصدرها. يُنشأ ملف PDF من القيم المحفوظة نفسها.')}</p></div>{['Doctor','Admin'].includes(role)&&<button className="button primary" onClick={()=>setAdding(!adding)}>{adding?t('Close','إغلاق'):t('+ Add lab result','+ إضافة تحليل')}</button>}</section>
  {adding&&<PatientLabIntake data={data} patientId={patientId} role={role} arabic={arabic} onUpdate={onUpdate} onClose={()=>{setAdding(false);setFeedback(t('Result and source report saved.','تم حفظ النتيجة والتقرير المرفق.'))}}/>}
  {feedback&&<p className="workflow-feedback" role="status">{feedback}</p>}
  {lab?<div className="lab-layout"><div className="lab-result-list">{labs.map(item=>{const attached=(data.documents??[]).some(d=>d.patientId===patientId&&(d.labResultId===item.id||d.id===`DOC-${patientId}-${item.id}`)&&(d.mimeType?.startsWith('image/')||d.mimeType==='application/pdf'));return <button className={`lab-result-item ${item.id===lab.id?'selected':''}`} key={item.id} onClick={()=>setSelected(item.id)}><span><b>{testName(item.test)}</b><small>{item.date} · {attached?t('Source attached','المصدر مرفق'):t('Demo record','بيانات تجريبية')}</small></span><strong>{item.status==='Pending'?t('Pending','قيد الانتظار'):<>{item.value} <small>{item.unit}</small></>}</strong><em className={item.status.toLowerCase()}>{status(item.status)}</em></button>})}</div>
  <section className="lab-detail"><div className="lab-detail-head"><div><span className="lab-eyebrow">{t('SELECTED RESULT','النتيجة المحددة')}</span><h3>{testName(lab.test)}</h3><small>{lab.date} · {lab.id}</small></div><span className={`lab-result-state ${lab.status.toLowerCase()}`}>{status(lab.status)}</span></div><div className="lab-facts"><div><small>{t('Result','النتيجة')}</small><b>{lab.status==='Pending'?t('Pending','قيد الانتظار'):<>{lab.value} <span>{lab.unit}</span></>}</b></div><div><small>{t('Reference range','النطاق المرجعي')}</small><b dir="auto">{lab.reference||'—'}</b></div><div><small>{t('Source','المصدر')}</small><b dir="auto">{lab.source||'—'}</b></div></div>{lab.interpretation&&<p className="lab-interpretation"><strong>{t('Recorded interpretation','التفسير المسجل')}</strong><span dir="auto">{lab.interpretation}</span></p>}<button className="button secondary" onClick={()=>downloadLabReport(patient,lab,arabic)}><CareIcon name="download"/>{t('Download result PDF','تنزيل PDF للنتيجة')}</button></section>
  <section className="lab-source"><div className="lab-detail-head"><div><span className="lab-eyebrow">{t('SOURCE DOCUMENT','المستند المرفق')}</span><h3>{original?t('Original report','التقرير الأصلي'):t('Recorded-data preview','معاينة البيانات المسجلة')}</h3></div>{original&&doc?.dataUrl&&<a className="lab-open-source" href={doc.dataUrl} target="_blank" rel="noreferrer" download={doc.fileName||undefined}>{t('Open / download','فتح / تنزيل')}</a>}</div><ReportPreview doc={original?doc:undefined} fallback={preview} arabic={arabic}/>{!original&&<p className="lab-source-note">{t('No original file was stored for this demo result. This preview is generated from the saved values.','لا يوجد ملف أصلي محفوظ لهذه النتيجة التجريبية. هذه معاينة منشأة من القيم المسجلة.')}</p>}</section></div>:<div className="empty-state"><b>{t('No lab results yet','لا توجد نتائج تحاليل بعد')}</b></div>}
 </div>
}
function ReportPreview({doc,fallback,arabic}:{doc?:CareDocument;fallback?:string;arabic:boolean}){if(doc?.dataUrl?.startsWith('data:image/'))return <img className="lab-preview-image" src={doc.dataUrl} alt={arabic?'صورة التقرير المرفق':'Attached laboratory report'}/>;if(doc?.dataUrl?.startsWith('data:application/pdf'))return <iframe className="lab-preview-frame" src={doc.dataUrl} title={arabic?'التقرير المرفق':'Attached report'}/>;if(doc?.dataUrl?.startsWith('data:text/plain')){let content='';try{content=decodeURIComponent(escape(atob(doc.dataUrl.split(',')[1])))}catch{content=doc.content}return <pre className="lab-preview-text" dir="auto">{content}</pre>}return fallback?<img className="lab-preview-image" src={fallback} alt={arabic?'معاينة من القيم المسجلة':'Preview from recorded values'}/>:null}
