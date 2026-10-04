import { PatientAvatar } from './PatientAvatar'
import { useState } from 'react'
import { saveTreatmentDraft, submitTreatmentDraft, canReadPatient, careRisk, patientJourney, type AppData, type Role } from './domain'
import { operationalAlerts, type AdminPage } from './adminAnalytics'

import { CareIcon } from './CareIcon'
export { CareIcon } from './CareIcon'

export function CareJourney({ data, patientId }: { data: AppData; patientId: string }) {
  return <ol className="care-journey" aria-label="Patient care journey">{patientJourney(data, patientId).map((step, i) => <li key={step.label} className={step.complete ? 'done' : ''}><span>{step.complete ? '✓' : i + 1}</span><b>{step.label}</b><small>{step.complete ? 'Recorded' : 'Next / pending'}</small></li>)}</ol>
}
export function RiskPanel({ data, patientId }: { data: AppData; patientId: string }) {
  const risk = careRisk(data, patientId)
  return <section className="risk-panel"><div><CareIcon name="Clinical care"/><h3>Preventive care signals</h3><span className="status needs-information">{risk.level}</span></div><p>Transparent demonstration rules, not a predictive model or diagnosis.</p>{risk.reasons.length ? <ul>{risk.reasons.map(reason => <li key={reason}>{reason}</li>)}</ul> : <p>No configured review threshold is triggered. Continue the agreed follow-up.</p>}</section>
}
export function OperationsHome({ data, role, onNavigate, onPatient }: { data: AppData; role: Role; onNavigate: (page: AdminPage, id?: string) => void; onPatient: (id: string) => void }) {
  const patients = data.patients.filter(item => canReadPatient(data, role, item.id))
  const requests = data.requests.filter(item => patients.some(patient => patient.id === item.patientId))
  const work = requests.filter(item => role === 'Pharmacist' ? item.status === 'Ready to dispense' : role === 'Reviewer' ? ['Under review','Approved'].includes(item.status) : ['Needs information','Under review'].includes(item.status))
  const alerts = operationalAlerts(data).filter(item => role === 'Admin' || role === 'Pharmacist' && item.category === 'Inventory' || patients.some(patient => patient.id === item.patientId)).filter(item => !(data.dismissedAlerts ?? []).includes(item.id))
  const title = role === 'Admin' ? 'Every handoff. One care record.' : role === 'Doctor' ? 'Clinical care, with the full picture.' : role === 'Reviewer' ? 'Clear evidence. Accountable decisions.' : 'Safe dispensing starts with verification.'
  const subtitle = role === 'Admin' ? 'Follow care delivery from the first assessment to long-term follow-up.' : role === 'Doctor' ? 'Review your patients, close evidence gaps and coordinate the next step.' : role === 'Reviewer' ? 'Review the clinical record and rationale before authorizing treatment.' : 'Verify identity, prescription, approval, refill timing and batch availability.'
  const queue = role === 'Pharmacist' ? 'Dispensing' : 'Treatment requests'
  return <div className={`ecosystem-home role-${role.toLowerCase()}`}>
    <section className="care-command"><div><span className="command-label">{role === 'Admin' ? 'Unified care operations' : `${role} workspace`}</span><h2>{title}</h2><p>{subtitle}</p><button className="button primary" onClick={() => onNavigate(queue)}> {role === 'Pharmacist' ? 'Open verification queue' : 'Open treatment requests'} <span aria-hidden="true">↗</span></button></div><div className="command-pulse"><CareIcon name="Clinical care"/><strong>{work.length}</strong><span>{role === 'Pharmacist' ? 'ready for verification' : 'care handoffs to review'}</span><small>From shared programme records</small></div></section>
    <div className="care-kpis">{[
      ['Patients in scope', patients.length, 'Patients'],
      ['Active treatment', patients.filter(item => item.treatmentStatus === 'Active').length, 'Patients'],
      ['Awaiting review', requests.filter(item => item.status === 'Under review').length, 'Treatment requests'],
      ['Pharmacy ready', requests.filter(item => item.status === 'Ready to dispense').length, role === 'Pharmacist' ? 'Dispensing' : 'Treatment requests'],
    ].map(([label,value,page]) => <button key={label} onClick={() => onNavigate(page as AdminPage)}><span>{label}</span><b>{value}</b><small>View linked records <span>↗</span></small></button>)}</div>
    <section className="panel pathway-panel"><div className="panel-head"><div><h2>Connected patient journey</h2><p>Evidence moves with the patient. Authorized professionals own every decision.</p></div><span className="workflow-badge">One shared record</span></div><div className="population-pathway">{[
      ['Clinical evidence',data.assessments.filter(item => item.status === 'Submitted' && patients.some(p => p.id === item.patientId)).length,'Patients'],
      ['Medical review',requests.filter(item => ['Under review','Needs information'].includes(item.status)).length,'Treatment requests'],
      ['Pharmacy',requests.filter(item => ['Approved','Ready to dispense'].includes(item.status)).length,queue],
      ['Dispensed',data.dispenses.filter(item => patients.some(p => p.id === item.patientId)).length,role === 'Pharmacist' ? 'Inventory' : 'Patients'],
      [role==='Doctor'?'Care plans':'Ongoing care',data.integratedCarePlans?.filter(item => item.status === 'Active' && patients.some(p => p.id === item.patientId)).length ?? 0,role==='Doctor'?'Integrated care plans':'Continuous care'],
    ].map(([label,value,target], index) => <button key={label} onClick={() => onNavigate(target as AdminPage)}><span className="pathway-number">{index+1}</span><b>{label}</b><strong>{value}</strong><small>Linked records</small></button>)}</div></section>
    <div className="operations-split"><section className="panel"><div className="panel-head"><div><h2>{role === 'Reviewer' ? 'Decisions awaiting your review' : role === 'Pharmacist' ? 'Collection and safety queue' : 'Care team worklist'}</h2><p>Prioritize the next accountable action.</p></div><button className="text-link" onClick={() => onNavigate(queue)}>View queue</button></div><div className="worklist">{work.slice(0,5).map(item => { const patient = data.patients.find(p => p.id === item.patientId)!; return <article key={item.id}><button className="work-patient" onClick={() => onPatient(patient.id)}><PatientAvatar patient={patient} className="mini-avatar"/><span><b>{patient.name}</b><small>{patient.id} · {item.id}</small></span></button><span className={`status ${item.status.toLowerCase().replaceAll(' ','-')}`}>{item.status}</span><button className="button quiet" onClick={() => onNavigate(queue,item.id)}>{role === 'Pharmacist' ? 'Verify' : 'Review'}</button></article> })}{!work.length && <div className="empty-state"><b>Your current queue is clear</b><span>New care handoffs will appear here.</span></div>}</div></section>
    <section className="panel priority-panel"><div className="panel-head"><div><h2>Priority signals</h2><p>Safety, evidence and continuity of care</p></div><span className="attention-count">{alerts.length} open</span></div>{alerts.sort((a,b) => ({Critical:0,Warning:1,Info:2}[a.severity] - {Critical:0,Warning:1,Info:2}[b.severity])).slice(0,4).map(item => <button className="priority-item" key={item.id} onClick={() => onNavigate(item.page,item.entityId)}><span className={`signal-dot ${item.severity.toLowerCase()}`}/><span><b>{item.title}</b><small>{item.detail}</small></span><span>›</span></button>)}</section></div>
    <section className="panel recent-care"><div className="panel-head"><div><h2>Recent care activity</h2><p>Traceable actions across the programme</p></div>{role === 'Admin' && <button className="text-link" onClick={() => onNavigate('Activity log')}>View activity log</button>}</div><div className="care-event-grid">{data.audit.filter(item => role === 'Admin' || item.actor === role || patients.some(p => p.id === item.patientId)).sort((a,b)=>(b.occurredAt??'').localeCompare(a.occurredAt??'')).slice(0,4).map(item => <article key={item.id}><span>{item.actor}</span><b>{item.action}</b><p>{role==='Doctor'&&document.documentElement.lang==='ar'?'حدث سريري مسجل في ملف المريض. راجع السجل للتفاصيل.':item.detail}</p><small>{item.entityId} · {item.time}</small></article>)}</div></section>
  </div>
}
export function DraftPlanEditor({data,role,requestId,onUpdate}:{data:AppData;role:Role;requestId:string;onUpdate:(data:AppData)=>void}) {
  const request=data.requests.find(item=>item.id===requestId)!
  const original=data.treatmentPlans.find(item=>item.id===request.planId)!
  const [draft,setDraft]=useState(original)
  const [feedback,setFeedback]=useState('')
  function save(submit=false){try{let next=saveTreatmentDraft(data,role,request.patientId,request.dose,draft,requestId);if(submit)next=submitTreatmentDraft(next,role,requestId);onUpdate(next);setFeedback('Treatment draft saved')}catch(error){setFeedback((error as Error).message)}}
  return <section className="draft-editor"><h3>Edit treatment draft</h3><form className="form-grid compact" onSubmit={event=>{event.preventDefault();save(true)}}><label>Frequency<select value={draft.frequency} onChange={e=>setDraft({...draft,frequency:e.target.value})}><option>Weekly</option><option>Daily</option><option>Every 2 weeks</option></select></label><label>Duration (days)<input type="number" min={28} max={365} value={draft.durationDays} onChange={e=>setDraft({...draft,durationDays:Number(e.target.value)})} required/></label>{([['startDate','Start date'],['endDate','End date'],['followUpDate','Follow-up date'],['indication','Indication'],['instructions','Instructions'],['monitoringPlan','Monitoring plan']] as const).map(([key,label])=><label key={key}>{label}<input type={key.toLowerCase().includes('date')?'date':'text'} value={draft[key]} onChange={e=>setDraft({...draft,[key]:e.target.value})} required/></label>)}{feedback&&<p className="inline-warning span-all" role="status">{feedback}</p>}<button type="button" className="button quiet" onClick={()=>save()}>Save treatment draft</button><button type="submit" className="button primary">Submit draft for review</button></form></section>
}
