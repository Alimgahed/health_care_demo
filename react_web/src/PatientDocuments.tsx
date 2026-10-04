import { PharmacyPatientDocuments } from './PharmacyDocumentViews'
import { useMemo, useState } from 'react'
import type { AppData, Patient } from './domain'
import { CareIcon } from './CareIcon'
import { downloadLabReport, labReportPreview } from './LabReport'
import { patientDocumentEntries } from './documentEntries'

export function PatientDocuments({data,patient,arabic}:{data:AppData;patient:Patient;arabic:boolean}) {
 const [preview,setPreview]=useState('')
 const entries=useMemo(()=>patientDocumentEntries(data,patient.id),[data,patient.id])
 const selected=entries.find(entry=>entry.id===preview)
 const image=useMemo(()=>selected?.lab?labReportPreview(patient,selected.lab,arabic):undefined,[selected,patient,arabic])
 const t=(en:string,ar:string)=>arabic?ar:en
 return <>
  <PharmacyPatientDocuments data={data} patientId={patient.id} arabic={arabic}/>
  <p className="document-demo-note">{t('Demonstration records. Every recorded lab result has a PDF generated from its saved values; uploaded source files remain available separately.','سجلات تجريبية. لكل تحليل مسجّل تقرير PDF يُنشأ من قيمه المحفوظة، مع إتاحة الملفات الأصلية المرفوعة بشكل منفصل.')}</p>
  <div className="p360-documents">{entries.map(({id,date,document:doc,lab})=>{
   const title=lab?t(`${lab.test} laboratory report`,`تقرير تحليل ${lab.test}`):doc?.id==='DOC-P999-CARE'?t('Shared care summary','ملخص الرعاية المشتركة'):doc?.title??''
   const filename=lab?`${patient.id}-${lab.test.replace(/[^a-z0-9-]/gi,'-')}-${lab.date}.pdf`:doc?.fileName??doc?.id
   const generatedSeedText=lab&&doc?.mimeType==='text/plain'&&doc.id===`DOC-${patient.id}-${lab.id}`
   const source=doc?.dataUrl&&!generatedSeedText?doc.dataUrl:undefined
   const previewable=Boolean(lab||doc?.content||source?.startsWith('data:image/')||source?.startsWith('data:application/pdf'))
   const details=lab?lab.status==='Pending'?t('Result pending — no final value has been reported.','النتيجة قيد الانتظار — لم تُسجّل قيمة نهائية بعد.'):`${lab.value} ${lab.unit} · ${lab.reference} · ${lab.source}`:doc?.content
   return <div className="p360-document-entry" key={id}><article className="p360-document">
    <div className="p360-document-icon"><CareIcon name={lab?'Analysis':'Documents'}/></div>
    <div className="p360-document-main"><div className="p360-document-title"><h3 data-no-localize dir="auto">{title}</h3><span>{lab?t('Generated PDF','تقرير PDF مُنشأ'):t('Clinical document','مستند سريري')}</span></div><p dir="auto" data-no-localize>{details}</p><div className="p360-document-meta"><span>{date}</span><span data-no-localize dir="ltr">{filename}</span></div></div>
    <div className="p360-document-actions">{previewable&&<button aria-expanded={preview===id} aria-controls={`preview-${id}`} onClick={()=>setPreview(preview===id?'':id)}><CareIcon name="eye"/>{preview===id?t('Close preview','إغلاق المعاينة'):t('Preview','معاينة')}</button>}{lab&&<button onClick={()=>downloadLabReport(patient,lab,arabic)}><CareIcon name="download"/>{t('Download PDF','تنزيل PDF')}</button>}{source&&<a href={source} download={doc?.fileName??doc?.title}><CareIcon name="download"/>{lab?t('Source file','الملف الأصلي'):t('Download','تنزيل')}</a>}</div>
   </article>{preview===id&&<div id={`preview-${id}`} className="patient-document-preview">{image?<img src={image} alt={t(`${title} for ${patient.name}`,`${title} للمريض ${patient.nameAr??patient.name}`)}/>:source?.startsWith('data:image/')?<img src={source} alt={title}/>:source?.startsWith('data:application/pdf')?<iframe src={source} title={title}/>:<pre dir="auto">{doc?.content}</pre>}</div>}</div>
  })}{!entries.length&&<p className="p360-empty">{t('No documents or lab results are recorded yet.','لا توجد مستندات أو تحاليل مسجلة بعد.')}</p>}</div>
 </>
}
