import { canReadPatient, type AppData, type Role } from './domain'
import type { AdminPage } from './adminAnalytics'

/** Projection of the canonical repository, never a second mock dataset. */
export function assistantScope(data: AppData, role: Role): AppData {
 if(role==='Admin')return data
 const ids=new Set(data.patients.filter(p=>canReadPatient(data,role,p.id)).map(p=>p.id))
 const scoped=<T extends {patientId:string}>(items:T[])=>items.filter(item=>ids.has(item.patientId))
 const inventory=role==='Pharmacist'
 return {...data,manualAlerts:(data.manualAlerts??[]).filter(a=>a.patientId?ids.has(a.patientId):inventory&&a.category==='Inventory'),patients:data.patients.filter(p=>ids.has(p.id)),requests:scoped(data.requests),treatmentPlans:scoped(data.treatmentPlans),dispenses:scoped(data.dispenses),doses:scoped(data.doses),financial:role==='Doctor'||role==='Reviewer'?[]:scoped(data.financial),payments:scoped(data.payments??[]),notifications:scoped(data.notifications),vitals:scoped(data.vitals),labs:scoped(data.labs),assessments:scoped(data.assessments),appointments:scoped(data.appointments),exercise:scoped(data.exercise),integratedCarePlans:scoped(data.integratedCarePlans??[]),documents:scoped(data.documents??[]),audit:data.audit.filter(a=>a.patientId&&ids.has(a.patientId)),batches:inventory?data.batches:[],movements:inventory?data.movements:[],supplyRequests:inventory?data.supplyRequests:[],abuseReviews:[],savedReports:[],reportSchedules:[]}
}
export function assistantLinkAllowed(role:Role,page:AdminPage){
 if(role==='Admin')return true
 if(role==='Patient')return ['Patients','Treatment requests','Appointments','Integrated care plans','Activity log','Overview'].includes(page)
 return ['Patients','Treatment requests','Integrated care plans','Overview'].includes(page)||(role==='Doctor'&&page==='Appointments')||(role==='Pharmacist'&&['Inventory','Alerts'].includes(page))
}
