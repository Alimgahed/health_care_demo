import type { Patient } from './domain'
import './PatientAvatar.css'

/** Illustrative portraits belong only to the seeded demo records. */
export function PatientAvatar({patient,className='',arabic=false}:{patient?:Patient;className?:string;arabic?:boolean}) {
 const name=patient?(arabic?patient.nameAr??patient.name:patient.name):''
 const portrait=patient?.demoPortrait
 const slot=portrait?.slot
 const seeded=Boolean(portrait)
 return <span className={`patient-avatar ${className}`} aria-hidden="true" title={seeded?(arabic?'صورة توضيحية لشخصية افتراضية':'Illustrative fictional portrait'):undefined}>
  {name.split(' ').filter(Boolean).slice(0,2).map(part=>part[0]).join('')||'—'}
  {slot!==undefined&&<span className="patient-avatar-photo" style={{backgroundImage:`url('/images/${portrait?.collection==='emirati'?'demo-emirati-portraits':'demo-patient-portraits'}.png')`,backgroundPosition:`${slot%4*100/3}% ${Math.floor(slot/4)*100/3}%`}}/>}
 </span>
}
