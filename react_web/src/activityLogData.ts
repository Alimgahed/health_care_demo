import type { AppData, AuditEvent, Role } from './domain'
import type { AdminPage } from './adminAnalytics'
export type ActivityStatus = 'Unread' | 'Action' | 'Information' | 'Handled'
export type ActivityRow = AuditEvent & { category:string; severity:'High'|'Medium'|'Low'; status:ActivityStatus; read:boolean; centre:string; patientName:string; patientNameAr:string; timestamp:number; target?:AdminPage; targetId?:string }
export function activityLogRows(data:AppData):ActivityRow[] {
 return data.audit.map(event=>{
  const request=data.requests.find(r=>r.id===event.entityId)
  const dispense=data.dispenses.find(r=>r.id===event.entityId)
  const appointment=data.appointments.find(r=>r.id===event.entityId)
  const carePlan=data.integratedCarePlans?.find(r=>r.id===event.entityId)
  const patientId=event.patientId??request?.patientId??dispense?.patientId??appointment?.patientId??carePlan?.patientId??(event.entity==='Patient'?event.entityId:undefined)
  const patient=data.patients.find(p=>p.id===patientId)
  const batch=data.batches.find(b=>b.id===event.entityId||b.batchNumber===event.entityId)
  const movement=data.movements.find(m=>m.id===event.entityId)
  const context=`${event.action} ${event.entity}`
  const category=batch||movement||/inventory|stock|batch/i.test(context)?'Inventory':/appointment/i.test(context)?'Appointments':/adherence|dose|exercise/i.test(context)?'Adherence':/request|prescription|dispens|care plan/i.test(context)?'Treatment':/safety|abuse/i.test(context)?'Safety':'Clinical'
  const blocked=/blocked|prevented|duplicate|invalid|failed/i.test(event.action)
  const information=event.newState==='Needs information'||/information requested|missing information/i.test(event.action)
  const pending=blocked||['Under review','Ready to dispense'].includes(event.newState??'')||/request submitted/i.test(event.action)
  const flags=data.activityEventStates?.[event.id]
  const read=Boolean(flags?.read)
  const status:ActivityStatus=flags?.handled?'Handled':!read?'Unread':information?'Information':pending?'Action':'Handled'
  const severity=blocked?'High':information||pending?'Medium':'Low'
  const target:AdminPage|undefined=request?'Treatment requests':appointment?'Appointments':batch||movement?'Inventory':carePlan?'Integrated care plans':patient?'Patients':undefined
  return {...event,patientId,category,severity,status,read,centre:dispense?.centre??appointment?.centre??batch?.centre??movement?.centre??patient?.treatmentCentre??'',patientName:patient?.name??'',patientNameAr:patient?.nameAr??'',timestamp:Number.isFinite(Date.parse(event.occurredAt??''))?Date.parse(event.occurredAt!):0,target,targetId:request?.id??(target==='Patients'?patient?.id:undefined)}
 })
}
export function updateActivityState(data:AppData,role:Role,ids:string[],action:'read'|'unread'|'handled'):AppData {
 if(role!=='Admin')throw new Error('Only administrators can update activity follow-up.')
 const known=new Set(data.audit.map(row=>row.id))
 if(ids.some(id=>!known.has(id)))throw new Error('Activity event not found.')
 const states={...data.activityEventStates}
 for(const id of ids)states[id]={...states[id],read:action!=='unread',handled:action==='handled'||(action==='read'&&Boolean(states[id]?.handled))}
 return {...data,activityEventStates:states}
}
