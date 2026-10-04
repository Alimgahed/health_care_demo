import { useEffect, useMemo, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { CareIcon } from './CareIcon'
import type { AppData } from './domain'
import { pharmacyDocumentModel, type PharmacyDocumentKind } from './pharmacyDocumentModel'
import { pharmacyDocumentPages, pharmacyPdf } from './PharmacyDocumentPdf'
import './PharmacyCheckout.css'

export function PharmacyDocumentPreview({data,requestId,kind,arabic,onClose}:{data:AppData;requestId:string;kind:PharmacyDocumentKind;arabic:boolean;onClose:()=>void}){
 const dialog=useRef<HTMLDialogElement>(null),[pages,setPages]=useState<HTMLCanvasElement[]>([]),[error,setError]=useState('')
 const t=(en:string,ar:string)=>arabic?ar:en
 const model=useMemo(()=>pharmacyDocumentModel(data,requestId,kind,arabic),[data,requestId,kind,arabic])
 useEffect(()=>{let cancelled=false;pharmacyDocumentPages(model).then(result=>{if(!cancelled)setPages(result)}).catch(e=>{if(!cancelled)setError(e.message)});return()=>{cancelled=true}},[model])
 useEffect(()=>{const previous=document.activeElement as HTMLElement|null;dialog.current?.showModal();const cleanup=()=>document.body.classList.remove('pharmacy-printing');window.addEventListener('afterprint',cleanup);return()=>{cleanup();window.removeEventListener('afterprint',cleanup);previous?.focus()}},[])
 const print=async()=>{try{await Promise.all(Array.from(dialog.current?.querySelectorAll('img')??[]).map(img=>img.decode()));document.body.classList.add('pharmacy-printing');window.print()}catch{setError(t('Unable to prepare printing. Please download the PDF.','تعذر تجهيز الطباعة. يمكنك تنزيل ملف PDF.'))}}
 const download=()=>{const url=URL.createObjectURL(pharmacyPdf(pages)),link=document.createElement('a');link.href=url;link.download=`${requestId}-${kind}.pdf`;link.click();setTimeout(()=>URL.revokeObjectURL(url),60000)}
 return createPortal(<dialog ref={dialog} className="pharmacy-document-overlay" dir={arabic?'rtl':'ltr'} onCancel={onClose} aria-labelledby="pharmacy-document-title" data-no-localize><div className="pharmacy-document-toolbar"><h2 id="pharmacy-document-title">{kind==='receipt'?t('Dispensing receipt','إيصال صرف الدواء'):t('Medical prescription','الوصفة الطبية')}</h2><div><button className="pd-outline" disabled={!pages.length} onClick={download}><CareIcon name="download"/>{t('Download PDF','تنزيل PDF')}</button><button className="pd-primary" disabled={!pages.length} onClick={print}><CareIcon name="printer"/>{t('Print','طباعة')}</button><button className="pd-outline" onClick={onClose} autoFocus>{t('Close','إغلاق')}</button></div></div>{error?<p role="alert">{error}</p>:!pages.length?<p role="status">{t('Preparing your document…','جارٍ تجهيز المستند…')}</p>:<div className="pharmacy-document-pages"><div className="pharmacy-document-transcript"><p>{model.number} · {model.date}</p>{model.sections.map(section=><section key={section.title}><h3>{section.title}</h3><dl>{section.rows.map(([label,value])=><div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}</dl></section>)}<p>{model.footer}</p></div>{pages.map((page,i)=><img key={i} src={page.toDataURL('image/png')} alt={`${kind==='receipt'?t('Receipt','الإيصال'):t('Prescription','الوصفة')} — ${i+1}`} />)}</div>}</dialog>,document.body)
}
export function PharmacyPatientDocuments({data,patientId,arabic}:{data:AppData;patientId:string;arabic:boolean}){
 const [selected,setSelected]=useState<{requestId:string;kind:PharmacyDocumentKind}|null>(null)
 const payments=data.payments?.filter(p=>p.patientId===patientId)??[]
 if(!payments.length)return null
 const t=(en:string,ar:string)=>arabic?ar:en
 return <section className="pharmacy-patient-documents" dir={arabic?'rtl':'ltr'} data-no-localize><h3><CareIcon name="receipt"/> {t('Prescriptions & receipts','الوصفات وإيصالات الصرف')}</h3>{payments.map(p=><article key={p.id}><div><strong>{p.receiptNumber}</strong><small>{p.paidAt.slice(0,10)} · {data.requests.find(r=>r.id===p.requestId)?.medication} · {p.amountAED===0?t('Fully covered','مغطى بالكامل'):`${p.amountAED.toFixed(2)} AED`}</small></div><div><button className="pd-outline" onClick={()=>setSelected({requestId:p.requestId,kind:'prescription'})}><CareIcon name="file"/>{t('Prescription','الوصفة')}</button><button className="pd-outline" onClick={()=>setSelected({requestId:p.requestId,kind:'receipt'})}><CareIcon name="receipt"/>{t('Receipt','الإيصال')}</button></div></article>)}{selected&&<PharmacyDocumentPreview {...selected} data={data} arabic={arabic} onClose={()=>setSelected(null)}/>}</section>
}
