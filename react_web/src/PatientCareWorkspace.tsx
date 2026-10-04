import { lazy, Suspense } from 'react'
import { canReadPatient, type AppData, type Role } from './domain'
import type { AdminPage } from './adminAnalytics'
import { CareIcon } from './CareIcon'
import { PatientAvatar } from './PatientAvatar'
import { DoctorCarePlans } from './DoctorCarePlans'
const CarePlanDetail=lazy(()=>import('./CarePlanDetail').then(m=>({default:m.CarePlanDetail})))
import './PatientCareWorkspace.css'
import './TreatmentEligibility.css'
const ClinicalWorkspace = lazy(() => import('./WorkflowViews').then(m => ({ default: m.ClinicalWorkspace })))
const TreatmentEligibility=lazy(()=>import('./TreatmentEligibility').then(m=>({default:m.TreatmentEligibility})))
import {localizeArabic} from './ArabicText'
import * as catalogue from './ArabicCatalogue'
export function PatientCareWorkspace({data,role,arabic,page,onNavigate,onUpdate,onCreateRequest,onPatient,context,onContext}:{context:{patientId:string;planId:string|null};onContext:(value:{patientId:string;planId:string|null})=>void;data:AppData;role:Role;arabic:boolean;page:AdminPage;onNavigate:(page:AdminPage,id?:string)=>void;onUpdate:(data:AppData)=>void;onCreateRequest:(id:string)=>void;onPatient:(id:string,section?:'Analysis')=>void}) {
  const t=(en:string,ar:string)=>arabic?ar:en
  const patients=data.patients.filter(p=>canReadPatient(data,role,p.id))
  const patientId=context.patientId,details=context.planId
  const local=(v:string)=>arabic?localizeArabic(v,catalogue):v
  const selectPlan=(id:string,planId?:string)=>onContext({patientId:id,planId:planId??data.integratedCarePlans?.find(p=>p.patientId===id)?.id??null})
  const clear=()=>onContext({patientId:'',planId:null})
  const patient=patients.find(p=>p.id===patientId)
  const active=page==='Clinical care'?0:page==='Smart assistant'?1:2
  const tabs=[{page:'Clinical care',en:'Medical assessment',ar:'التقييم الطبي',icon:'stethoscope'},{page:'Smart assistant',en:'Treatment eligibility',ar:'أهلية العلاج',icon:'decision'},{page:'Integrated care plans',en:'Plan & follow-up',ar:'الخطة والمتابعة',icon:'care-plan'}] as const
  function switchTab(index:number) { onNavigate(tabs[index].page) }

  return <div className="patient-care-workspace" dir={arabic?'rtl':'ltr'}>
    <header className="care-workspace-heading"><div><h1><CareIcon name="care-plan"/>{t('Patient care','رعاية المريض')}</h1><p>{t('Assessment, eligibility and care follow-up in one patient workspace.','التقييم الطبي وأهلية العلاج وخطة الرعاية والمتابعة في مكان واحد.')}</p></div>{patient&&<button className="button secondary" onClick={()=>onPatient(patient.id)}>{t('Open patient file','فتح ملف المريض')}</button>}</header>
    {patient?<section className="care-workspace-summary" data-no-localize><div className="cw-identity"><PatientAvatar patient={patient} arabic={arabic}/><div><small>{t('Patient','المريض')}</small><h2>{arabic?patient.nameAr??local(patient.name):patient.name}</h2><small>{patient.id} · {local(patient.diagnosis)}</small></div></div>{[[t('Record number','رقم الملف'),patient.id,'patients'],[t('Age','العمر'),`${patient.age} ${t('years','سنة')}`,'calendar'],[t('Sex','النوع'),local(patient.sex??'—'),'user'],[t('Primary diagnosis','التشخيص الرئيسي'),local(patient.diagnosis),'file']].map(([label,value,icon])=><div className="cw-fact" key={label}><CareIcon name={icon}/><div><small>{label}</small><b>{value}</b></div></div>)}<span className="cw-status">{local(patient.treatmentStatus??'Not recorded')}</span></section>:<section className="panel care-workspace-context"><label>{t('Patient','المريض')}<select aria-label={t('Care workspace patient','مريض مساحة الرعاية')} value="" onChange={e=>onContext({patientId:e.target.value,planId:null})}><option value="">{t('All patients · choose a patient for assessment','كل المرضى · اختر مريضًا للتقييم')}</option>{patients.map(p=><option key={p.id} value={p.id}>{arabic?p.nameAr??p.name:p.name} · {p.id}</option>)}</select></label></section>}
    <div className="care-workspace-tabs" role="tablist" aria-label={t('Patient care sections','أقسام رعاية المريض')}>{tabs.map((tab,index)=><button key={tab.page} role="tab" id={`care-tab-${index}`} aria-selected={active===index} aria-controls={`care-panel-${index}`} tabIndex={active===index?0:-1} onClick={()=>switchTab(index)} onKeyDown={e=>{let next=index;if(e.key==='Home')next=0;else if(e.key==='End')next=2;else if(e.key==='ArrowRight')next=(index+(arabic?2:1))%3;else if(e.key==='ArrowLeft')next=(index+(arabic?1:2))%3;else return;e.preventDefault();switchTab(next);document.getElementById(`care-tab-${next}`)?.focus()}}><CareIcon name={tab.icon}/>{t(tab.en,tab.ar)}</button>)}</div>
    <Suspense fallback={<p role="status">{t('Loading patient care…','جارٍ تحميل رعاية المريض…')}</p>}>
      <section role="tabpanel" id="care-panel-0" aria-labelledby="care-tab-0" hidden={active!==0}>{patient?<ClinicalWorkspace key={patient.id} selectedPatientId={patient.id} data={data} role={role} arabic={arabic} onUpdate={onUpdate} onPatient={id=>onPatient(id,'Analysis')}/>:<p className="panel care-workspace-empty">{t('Choose a patient above to record the medical assessment.','اختر المريض بالأعلى لتسجيل التقييم الطبي.')}</p>}</section>
      <section role="tabpanel" id="care-panel-1" aria-labelledby="care-tab-1" hidden={active!==1}>{patient?<TreatmentEligibility data={data} role={role} patientId={patient.id} planId={details} arabic={arabic} onRequest={id=>onNavigate('Treatment requests',id)} onInventory={()=>onNavigate('Inventory')} onPlan={()=>{selectPlan(patient.id,details??undefined);onNavigate('Integrated care plans')}} onBack={()=>{clear();onNavigate('Integrated care plans')}} onCreateRequest={()=>onCreateRequest(patient.id)}/>:<p className="panel care-workspace-empty">{t('Choose a patient above to review treatment eligibility.','اختر المريض بالأعلى لمراجعة أهلية العلاج.')}</p>}</section>
      <section role="tabpanel" id="care-panel-2" aria-labelledby="care-tab-2" hidden={active!==2}>{details&&patient?<CarePlanDetail data={data} role={role} arabic={arabic} planId={details} onUpdate={onUpdate} onBack={clear} onPatient={onPatient} onRequest={id=>onNavigate('Treatment requests',id)}/>:<DoctorCarePlans key={patient?.id??'all'} data={data} role={role} arabic={arabic} patientId={patient?.id} embedded onUpdate={onUpdate} onCreateRequest={onCreateRequest} onPatient={selectPlan}/>}</section>
    </Suspense>
  </div>
}
