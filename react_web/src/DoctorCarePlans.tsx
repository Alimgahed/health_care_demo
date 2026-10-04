import { PatientAvatar } from './PatientAvatar'
import { CareIcon } from './CareIcon'
import { useMemo, useState } from 'react'
import { can, canReadPatient, type AppData, type Role } from './domain'
import { CarePlanDialog } from './CarePlanViews'
import './DoctorCarePlans.css'

export function DoctorCarePlans({data,role,arabic,onUpdate,onPatient,onCreateRequest,patientId,embedded=false}:{patientId?:string;embedded?:boolean;data:AppData;role:Role;arabic:boolean;onUpdate:(data:AppData)=>void;onPatient:(id:string,planId?:string)=>void;onCreateRequest?:(id:string)=>void}) {
  const [query,setQuery]=useState('')
  const [status,setStatus]=useState('All')
  const [doctor,setDoctor]=useState('All')
  const [from,setFrom]=useState('')
  const [to,setTo]=useState('')
  const [page,setPage]=useState(1)
  const [pageSize,setPageSize]=useState(10)
  const [creating,setCreating]=useState(false)
  const [selectedPatient,setSelectedPatient]=useState('')
  const [message,setMessage]=useState('')
  const t=(en:string,ar:string)=>arabic?ar:en
  const all=(data.integratedCarePlans??[]).filter(plan=>canReadPatient(data,role,plan.patientId)&&(!patientId||plan.patientId===patientId))
  const doctors=[...new Set(all.map(plan=>plan.doctorId))]
  const filtered=useMemo(()=>all.filter(plan=>{
    const patient=data.patients.find(item=>item.id===plan.patientId)
    const text=`${patient?.name??''} ${patient?.nameAr??''} ${patient?.id??''} ${plan.id} ${plan.title}`.toLowerCase()
    return text.includes(query.trim().toLowerCase())&&(status==='All'||plan.status===status)&&(doctor==='All'||plan.doctorId===doctor)&&(!from||plan.followUpDate>=from)&&(!to||plan.followUpDate<=to)
  }).sort((a,b)=>b.createdAt.localeCompare(a.createdAt)),[all,query,status,doctor,from,to,data.patients])
  const pages=Math.max(1,Math.ceil(filtered.length/pageSize))
  const visible=filtered.slice((Math.min(page,pages)-1)*pageSize,Math.min(page,pages)*pageSize)
  const counts={active:all.filter(plan=>plan.status==='Active').length,completed:all.filter(plan=>plan.status==='Completed').length}
  const openCreate=()=>{const patient=data.patients.find(item=>canReadPatient(data,role,item.id)&&(!patientId||item.id===patientId));if(patient){setSelectedPatient(patient.id);setCreating(true)}}
  return <div className="dcp" dir={arabic?'rtl':'ltr'}>
    <div className="dcp-heading"><div><div className="dcp-crumb">{t('Programme / Integrated care plans','البرنامج / خطط الرعاية المتكاملة')}</div>{embedded?<h2>{t('Plan & follow-up','الخطة والمتابعة')}</h2>:<h1><CareIcon name="Care plan"/> {t('Integrated care plans','خطط الرعاية المتكاملة')}</h1>}<p>{t('Coordinate medication, rehabilitation, home exercises and follow-up in one plan per patient.','نسق الدواء والتأهيل والتمارين المنزلية والمتابعة في خطة واحدة لكل مريض.')}</p></div>{can(role,'clinical:write')&&<button className="dcp-create" onClick={openCreate}><CareIcon name="plus"/> {t('Create care plan','إنشاء خطة رعاية')}</button>}</div>
    {message&&<p role="status" className="workflow-feedback">{message}</p>}
    <div className="dcp-stats">{[[t('Total care plans','إجمالي خطط الرعاية'),all.length,'Care plan','blue'],[t('Active plans','خطط نشطة'),counts.active,'Active','green'],[t('Under review','قيد المراجعة'),0,'Under review','amber'],[t('Completed','مكتملة'),counts.completed,'Completed','cyan'],[t('Paused','متوقفة'),0,'Paused','red']].map(([label,value,icon,tone])=><div className={`dcp-stat ${tone}`} key={String(label)}><span className="dcp-stat-icon"><CareIcon name={String(icon)}/></span><div><span>{label}</span><strong>{value}</strong></div></div>)}</div>
    <div className="dcp-filters"><label>{t('Search','بحث')}<input value={query} onChange={e=>{setQuery(e.target.value);setPage(1)}} placeholder={t('Search patient or plan number…','ابحث بالمريض أو رقم الخطة…')}/></label><label>{t('Status','الحالة')}<select value={status} onChange={e=>{setStatus(e.target.value);setPage(1)}}><option value="All">{t('All','الكل')}</option><option value="Active">{t('Active','نشطة')}</option><option value="Completed">{t('Completed','مكتملة')}</option></select></label><label>{t('Doctor','الطبيب')}<select value={doctor} onChange={e=>{setDoctor(e.target.value);setPage(1)}}><option value="All">{t('All','الكل')}</option>{doctors.map(id=><option key={id} value={id}>{data.doctors.find(item=>item.id===id)?.name??id}</option>)}</select></label><label>{t('Next follow-up from','المتابعة القادمة من')}<input type="date" value={from} onChange={e=>{setFrom(e.target.value);setPage(1)}}/></label><label>{t('To','إلى')}<input type="date" min={from||undefined} value={to} onChange={e=>{setTo(e.target.value);setPage(1)}}/></label><button onClick={()=>{setQuery('');setStatus('All');setDoctor('All');setFrom('');setTo('');setPage(1)}}>{t('Reset','إعادة ضبط')} <CareIcon name="reset"/></button></div>
    <section className="dcp-panel"><h2>{filtered.length} {t('care plans','خطة رعاية')}</h2><div className="dcp-scroll"><table><thead><tr>{[t('Patient','المريض'),t('Plan number','رقم الخطة'),t('Treatment & rehabilitation','العلاج والتأهيل'),t('Medication','الدواء'),t('Home exercises','التمارين المنزلية'),t('Next follow-up','المتابعة القادمة'),t('Status','الحالة'),t('Progress','التقدم'),t('Action','الإجراء')].map(label=><th key={label}>{label}</th>)}</tr></thead><tbody>{visible.map(plan=>{
      const patient=data.patients.find(item=>item.id===plan.patientId)
      const request=data.requests.find(item=>item.id===plan.treatmentRequestId)
      const medication=data.medications?.find(item=>item.id===plan.medicationId)
      const rehab=data.rehabilitationPrograms?.find(item=>item.id===plan.rehabilitation?.programId)
      const sessions=plan.rehabilitation?.sessions.length??0
      const total=plan.rehabilitation?.plannedSessions??0
      const progress=plan.status==='Completed'?100:total?Math.round(sessions/total*100):0
      return <tr key={plan.id}><td><div className="dcp-patient-identity"><PatientAvatar patient={patient} arabic={arabic}/><div><b>{arabic?patient?.nameAr??patient?.name:patient?.name}</b><small>{patient?.id} · {patient?.age} {t('years','سنة')}</small></div></div></td><td dir="ltr">{plan.id}</td><td><span className="dcp-tag">• {t('Medication','علاج دوائي')}: {medication?.name??request?.medication??t('None','لا يوجد')}</span><span className="dcp-tag">• {t('Rehabilitation','تأهيل')}: {rehab?.name??t('None','لا يوجد')}</span></td><td><b>{medication?.name??request?.medication??'—'}</b><small>{request?.dose??'—'}</small></td><td><span className="dcp-exercise"><CareIcon name="walk"/> {plan.homeExerciseIds.length} {t('home exercises','تمارين منزلية')}</span></td><td dir="ltr">{plan.followUpDate}</td><td><span className={`dcp-status ${plan.status.toLowerCase()}`}>{plan.status==='Active'?t('Active','نشطة'):t('Completed','مكتملة')}</span></td><td><b>{progress}%</b><div className="dcp-progress"><span style={{width:`${progress}%`}}/></div></td><td><button className="dcp-open" onClick={()=>onPatient(plan.patientId,plan.id)}><CareIcon name="eye"/> {t('View plan','عرض الخطة')}</button></td></tr>
    })}</tbody></table>{!visible.length&&<div className="dcp-empty">{t('No matching care plans','لا توجد خطط رعاية مطابقة')}</div>}</div><footer className="dcp-footer"><div><button disabled={page<=1} onClick={()=>setPage(page-1)}>‹</button><b>{Math.min(page,pages)}</b><button disabled={page>=pages} onClick={()=>setPage(page+1)}>›</button><span>{t('of','من')} {filtered.length} {t('care plans','خطة رعاية')}</span></div><label>{t('Show','عرض')} <select value={pageSize} onChange={e=>{setPageSize(Number(e.target.value));setPage(1)}}><option>10</option><option>20</option><option>50</option></select> {t('per page','لكل صفحة')}</label></footer></section>
    {creating&&<CarePlanDialog data={data} role={role} patientId={selectedPatient} onClose={()=>setCreating(false)} onSaved={next=>{onUpdate(next);setCreating(false);setMessage(t('Care plan saved','تم حفظ خطة الرعاية'))}} onCreateRequest={id=>{setCreating(false);onCreateRequest?.(id)}}/>}
  </div>
}
