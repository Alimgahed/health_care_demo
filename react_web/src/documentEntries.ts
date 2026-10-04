import type { AppData, CareDocument, LabResult } from './domain'

export type PatientDocumentEntry = { id:string; date:string; document?:CareDocument; lab?:LabResult }
/** Derive missing reports from canonical results, without duplicating files in storage. */
export function patientDocumentEntries(data:AppData,patientId:string):PatientDocumentEntry[] {
 const labs=data.labs.filter(lab=>lab.patientId===patientId)
 const documents=(data.documents??[]).filter(doc=>doc.patientId===patientId)
 const entries:PatientDocumentEntry[]=documents.map(document=>({id:document.id,date:document.date,document,lab:labs.find(lab=>document.labResultId===lab.id||document.id===`DOC-${patientId}-${lab.id}`)}))
 for(const lab of labs) if(!entries.some(entry=>entry.lab?.id===lab.id)) entries.push({id:`report-${lab.id}`,date:lab.date,lab})
 return entries.sort((a,b)=>b.date.localeCompare(a.date)||a.id.localeCompare(b.id))
}
