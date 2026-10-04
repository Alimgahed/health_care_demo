import { operationalAlerts, type OperationalAlert } from './adminAnalytics'
import { canReadPatient, type AppData, type Role } from './domain'
export type AlertState='Unread'|'Read'|'Information'|'Handled'
export function alertsWorkspaceData(data:AppData,role:Role,clock=Date.now()) {
 return operationalAlerts(data,clock).filter(a=>role==='Admin'||a.category==='Inventory'||Boolean(a.patientId&&canReadPatient(data,role,a.patientId))||data.manualAlerts?.some(m=>m.id===a.id&&!m.patientId)).map(alert=>{
  const manual=data.manualAlerts?.find(m=>m.id===alert.id)
  const request=data.requests.find(r=>r.id===alert.entityId)
  const batch=data.batches.find(b=>b.id===alert.entityId)
  const patient=data.patients.find(p=>p.id===(alert.patientId??request?.patientId))
  const appointment=data.appointments.find(a=>a.id===alert.entityId)
  const latest=data.requests.filter(r=>r.patientId===patient?.id).sort((a,b)=>(b.createdAt??b.created).localeCompare(a.createdAt??a.created))[0]
  const dose=request?.dose??batch?.dose??(alert.id.startsWith('stock-')?alert.id.slice(6):latest?.dose)
  const medication=manual?.medicationId?data.medications?.find(m=>m.id===manual.medicationId)?.name:request?.medication??latest?.medication??(dose?data.medications?.[0]?.name:undefined)
  const centre=manual?.centre??batch?.centre??appointment?.centre??data.doctors.find(d=>d.id===patient?.doctorId||d.name===patient?.assignedDoctor)?.centre
  const state:AlertState=data.dismissedAlerts?.includes(alert.id)?'Handled':request?.status==='Needs information'?'Information':data.readAlerts?.includes(alert.id)?'Read':'Unread'
  const priority=manual?.priority??({Critical:'High',Warning:'Medium',Info:'Low'} as const)[alert.severity]
  return {...alert,medication,dose,centre,patientName:patient?.name,patientNameAr:patient?.nameAr,state,priority}
 })
}
export type WorkspaceAlert=ReturnType<typeof alertsWorkspaceData>[number]
export const alertTypeIcon=(category:OperationalAlert['category'])=>({Inventory:'box',Treatment:'file',Safety:'decision',Clinical:'activity',Appointments:'calendar'}[category]??'bell')
