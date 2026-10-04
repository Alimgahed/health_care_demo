import { DoctorAppointments } from './DoctorAppointments'
import { useState, type FormEvent } from 'react'
import './WorkflowViews.css'
import { recordExercise, type AppData, type Role } from './domain'

type Update = (next: AppData) => void
const today = () => new Date().toISOString().slice(0, 10)

export {ClinicalWorkspace} from './ClinicalAssessment'

export function AppointmentsWorkspace({data,role,onUpdate,arabic=false}:{data:AppData;role:Role;onUpdate:Update;arabic?:boolean}) {
 const [query,setQuery]=useState('')
 return <DoctorAppointments key={role} data={data} role={role} arabic={arabic} query={query} onQuery={setQuery} onUpdate={onUpdate}/>
}

export function PatientActivity({ data, role, patientId, onUpdate }: { data: AppData; role: Role; patientId: string; onUpdate: Update }) {
  const [draft, setDraft] = useState({ activity: 'Walking', durationMinutes: 30, intensity: 'Moderate' as const, date: today(), notes: '' })
  const [feedback, setFeedback] = useState('')
  const assignedPlan=data.integratedCarePlans?.filter(p=>p.patientId===patientId&&p.status==='Active').sort((a,b)=>b.createdAt.localeCompare(a.createdAt))[0]
  const assignedExercises=data.homeExercises?.filter(e=>assignedPlan?.homeExerciseIds.includes(e.id))??[]
  const records = data.exercise.filter(item => item.patientId === patientId)
  const minutesThisMonth = records.filter(item => item.date.slice(0, 7) === today().slice(0, 7)).reduce((sum, item) => sum + item.durationMinutes, 0)
  const submit = (event: FormEvent) => { event.preventDefault(); try { onUpdate(recordExercise(data, role, patientId, {...draft,...(assignedExercises.some(e=>e.name===draft.activity)?{integratedCarePlanId:assignedPlan?.id,exerciseId:assignedExercises.find(e=>e.name===draft.activity)?.id}:{})})); setFeedback('Activity saved to your progress history.') } catch (error) { setFeedback(error instanceof Error ? error.message : 'Activity could not be recorded.') } }
  return <div className="workflow-stack"><section className="workflow-summary panel"><div><small>Activity this month</small><b>{minutesThisMonth} min</b></div><div><small>Recorded sessions</small><b>{records.length}</b></div><div><small>Activity types</small><b>{new Set(records.map(item => item.activity)).size}</b></div><div><small>Latest entry</small><b>{records[0]?.date ?? 'No activity'}</b></div></section>{feedback && <div className="workflow-feedback" role="status">{feedback}<button onClick={() => setFeedback('')} aria-label="Dismiss message">×</button></div>}<div className="workflow-columns"><section className="panel workflow-card"><div className="panel-head"><div><h2>Record an activity</h2><p>Log movement to follow your activity over time.</p></div></div><form className="form-grid compact" onSubmit={submit}><label>Activity<select value={draft.activity} onChange={event => setDraft({ ...draft, activity: event.target.value })}>{[...new Set([...assignedExercises.map(e=>e.name),'Walking','Home exercise','Supported mobility','Running','Cycling','Gym','Swimming','Other'])].map(item => <option key={item}>{item}</option>)}</select></label><label>Duration (minutes)<input type="number" min="1" max="1440" value={draft.durationMinutes} onChange={event => setDraft({ ...draft, durationMinutes: Number(event.target.value) })} required/></label><label>Intensity<select value={draft.intensity} onChange={event => setDraft({ ...draft, intensity: event.target.value as typeof draft.intensity })}><option>Light</option><option>Moderate</option><option>Vigorous</option></select></label><label>Date<input type="date" max={today()} value={draft.date} onChange={event => setDraft({ ...draft, date: event.target.value })} required/></label><label className="span-all">Notes<input value={draft.notes} onChange={event => setDraft({ ...draft, notes: event.target.value })} placeholder="Optional note"/></label><button className="button primary span-all" type="submit">Save activity</button></form></section><section className="panel workflow-card"><div className="panel-head"><div><h2>Activity history</h2><p>Records linked to your care programme profile.</p></div></div>{records.length ? records.map(item => <div className="workflow-history" key={item.id}><b>{item.activity} · {item.durationMinutes} min</b><span>{item.date} · {item.intensity} intensity{item.integratedCarePlanId?` · ${item.integratedCarePlanId}`:''}</span>{item.notes && <small>{item.notes}</small>}</div>) : <div className="empty-state"><b>No activity recorded yet</b><span>Your saved sessions will appear here.</span></div>}</section></div></div>
}
