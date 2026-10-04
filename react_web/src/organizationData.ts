import { can, updateDoctorProfile, type AppData, type Role, type DoctorProfile, type ContractStatus, type CentreDirectoryDetails, type CareCentre, type RehabilitationCentre } from './domain'
export type DoctorInput = { name:string;nameAr:string;gender:'Male'|'Female'|'';specialty:string;licenseReference:string;centre:string;programmeRole:string;qualification:string;email:string;phone:string;joinedAt:string;contractStatus:ContractStatus;notes:string }
export type CentreInput = {name:string;nameAr:string;kind:NonNullable<CentreDirectoryDetails['kind']>;emirate:string;location:string;contact:string;email:string;manager:string;contractReference:string;contractDate:string;contractStatus:ContractStatus;services:string[];lat:string;lng:string;capacity:number;maxSessions:number;programIds:string[];pharmacy:string;notes:string}
export type DirectoryCentre = CentreDirectoryDetails & {id:string;name:string;emirate:string;location:string;status:'Active'|'Inactive';contact:string;coordinates?:{lat:number;lng:number};pharmacy:string;capacity?:number;maxSessions?:number;programIds:string[];source:'care'|'rehabilitation';patients:number}
export const contractState=(row:{status:'Active'|'Inactive';contractStatus?:ContractStatus}):ContractStatus=>row.contractStatus??(row.status==='Active'?'Active':'Suspended')
export function directoryCentres(data:AppData):DirectoryCentre[] {
 return [...data.centres.map(c=>({...c,kind:c.kind??'Treatment',source:'care' as const,contact:c.contact??'',programIds:[],patients:data.patients.filter(p=>p.centreId===c.id||p.treatmentCentre===c.name).length})),...(data.rehabilitationCentres??[]).map(c=>({...c,kind:c.kind??'Rehabilitation',source:'rehabilitation' as const,location:c.area,pharmacy:'',patients:new Set(data.integratedCarePlans?.filter(p=>p.status==='Active'&&p.rehabilitation?.centreId===c.id).map(p=>p.patientId)).size}))]
}
const required=(value:string,label:string)=>{if(!value.trim())throw new Error(`${label} is required.`);if(value.trim().length>500)throw new Error(`${label} is too long.`);return value.trim()}
const validDate=(value:string)=>/^\d{4}-\d{2}-\d{2}$/.test(value)&&Number.isFinite(Date.parse(value))&&new Date(value).toISOString().slice(0,10)===value
function checkContact(email:string,phone:string){if(email&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))throw new Error('Enter a valid email address.');if(!/^[+\d\s()-]{7,25}$/.test(phone))throw new Error('Enter a valid contact number.')}
function authorize(role:Role){if(!can(role,'organization:manage'))throw new Error('Only administrators can manage the directory.')}
function audit(data:AppData,action:string,entity:string,id:string,name:string,previousState:string|undefined,newState:string){const stamp=new Date().toISOString();return {...data,audit:[{id:`EV-${crypto.randomUUID()}`,actor:'Admin' as const,action,entity,entityId:id,detail:name,occurredAt:stamp,time:stamp.slice(11,16),previousState,newState},...data.audit]}}
export function saveDirectoryDoctor(data:AppData,role:Role,input:DoctorInput,id?:string):AppData {
 authorize(role)
 const current=id?data.doctors.find(d=>d.id===id):undefined
 if(id&&!current)throw new Error('Doctor record not found.')
 const name=required(input.name,'Doctor name'),license=required(input.licenseReference,'License reference')
 required(input.specialty,'Specialty');required(input.programmeRole,'Programme role')
 if(current&&(current.name!==name||current.licenseReference!==license))throw new Error('Name and license reference cannot be changed after registration.')
 if(data.doctors.some(d=>d.id!==id&&d.licenseReference.toLowerCase()===license.toLowerCase()))throw new Error('A doctor with this license already exists.')
 if(data.doctors.some(d=>d.id!==id&&d.name.toLowerCase()===name.toLowerCase()))throw new Error('A doctor with this name already exists.')
 if(!data.centres.some(c=>c.name===input.centre&&(c.status==='Active'||current?.centre===c.name)))throw new Error('Select an active treatment centre.')
 if(!['Active','Pending','Suspended'].includes(input.contractStatus))throw new Error('Select a valid contract status.')
 if(!['Male','Female'].includes(input.gender))throw new Error('Select a valid gender.')
 if(!validDate(input.joinedAt))throw new Error('Enter a valid joining date.')
 checkContact(input.email.trim(),input.phone.trim())
 const stamp=new Date().toISOString(),status=input.contractStatus==='Active'?'Active':'Inactive'
 const saved:DoctorProfile={...current,...input,gender:input.gender==='Male'?'Male':'Female',name,licenseReference:license,specialty:input.specialty.trim(),email:input.email.trim(),phone:input.phone.trim(),id:current?.id??`DOC-${crypto.randomUUID()}`,status,createdAt:current?.createdAt??stamp,updatedAt:stamp,centreId:data.centres.find(c=>c.name===input.centre)?.id}
 const updated=current?updateDoctorProfile(data,role,current.id,{centre:saved.centre,status}):data
 const next={...updated,doctors:current?updated.doctors.map(d=>d.id===id?saved:d):[saved,...updated.doctors]}
 return current?next:audit(next,'Doctor added','Doctor',saved.id,saved.name,undefined,status)
}
export function saveDirectoryCentre(data:AppData,role:Role,input:CentreInput,id?:string):AppData {
 authorize(role)
 const existing=directoryCentres(data),current=id?existing.find(c=>c.id===id):undefined
 if(id&&!current)throw new Error('Treatment centre not found.')
 const name=required(input.name,'Centre name');required(input.location,'Location');required(input.contractReference,'Contract reference');required(input.manager,'Centre manager')
 if(current&&current.name!==name)throw new Error('Centre name cannot be changed after registration.')
 if(existing.some(c=>c.id!==id&&(c.name.toLowerCase()===name.toLowerCase()||c.contractReference?.toLowerCase()===input.contractReference.trim().toLowerCase())))throw new Error('A centre with this name or contract already exists.')
 if(!data.centres.some(c=>c.emirate===input.emirate))throw new Error('Select an existing emirate.')
 if(!['Treatment','Physiotherapy','Rehabilitation','Integrated rehabilitation'].includes(input.kind)||!['Active','Pending','Suspended'].includes(input.contractStatus))throw new Error('Select a valid centre type and status.')
 const rehab=current?current.source==='rehabilitation':input.kind!=='Treatment'
 if(current&&((current.source==='care'&&input.kind!=='Treatment')||(current.source==='rehabilitation'&&input.kind==='Treatment')))throw new Error('The centre directory cannot be changed after registration.')
 if(!validDate(input.contractDate))throw new Error('Enter a valid contract date.')
 checkContact(input.email.trim(),input.contact.trim())
 const lat=Number(input.lat),lng=Number(input.lng)
 if(!input.lat.trim()||!input.lng.trim()||!Number.isFinite(lat)||!Number.isFinite(lng)||Math.abs(lat)>90||Math.abs(lng)>180)throw new Error('Enter valid latitude and longitude.')
 if(!input.services.length)throw new Error('Select at least one service.')
 if(rehab&&(!Number.isInteger(input.capacity)||input.capacity<1||!Number.isInteger(input.maxSessions)||input.maxSessions<1||!input.programIds.length||input.programIds.some(id=>!data.rehabilitationPrograms?.some(p=>p.id===id))))throw new Error('Enter positive capacity and session limits, and select supported programmes.')
 const used=current?.source==='rehabilitation'?(data.integratedCarePlans??[]).filter(p=>p.status==='Active'&&p.rehabilitation?.centreId===current.id&&p.rehabilitation.status!=='Completed').length:0
 if(rehab&&input.capacity<used)throw new Error('Capacity cannot be lower than the current assigned patient count.')
 if(current?.source==='care'&&current.status==='Active'&&input.contractStatus!=='Active'&&data.centres.filter(c=>c.status==='Active').length<=1)throw new Error('At least one treatment centre must remain active.')
 const stamp=new Date().toISOString(),status=input.contractStatus==='Active'?'Active' as const:'Inactive' as const
 const details:CentreDirectoryDetails={nameAr:input.nameAr,kind:input.kind,contractStatus:input.contractStatus,contractReference:input.contractReference.trim(),contractDate:input.contractDate,email:input.email.trim(),manager:input.manager.trim(),services:[...new Set(input.services)],notes:input.notes,createdAt:current?.createdAt??stamp}
 const centreId=id??`${rehab?'RC':'CTR'}-${crypto.randomUUID()}`
 let next:AppData
 if(rehab){const saved:RehabilitationCentre={...data.rehabilitationCentres?.find(c=>c.id===id),...details,id:centreId,name,emirate:input.emirate,area:input.location.trim(),coordinates:{lat,lng},contact:input.contact.trim(),status,capacity:input.capacity,maxSessions:input.maxSessions,programIds:[...new Set(input.programIds)]};next={...data,rehabilitationCentres:id?data.rehabilitationCentres?.map(c=>c.id===id?saved:c):[saved,...data.rehabilitationCentres??[]]}}
 else {const saved:CareCentre={...data.centres.find(c=>c.id===id),...details,id:centreId,name,emirate:input.emirate,location:input.location.trim(),coordinates:{lat,lng},contact:input.contact.trim(),status,pharmacy:input.pharmacy.trim()};next={...data,centres:id?data.centres.map(c=>c.id===id?saved:c):[saved,...data.centres]}}
 return audit(next,id?'Treatment centre updated':'Treatment centre added',rehab?'Rehabilitation centre':'Treatment centre',centreId,name,current?.status,status)
}
