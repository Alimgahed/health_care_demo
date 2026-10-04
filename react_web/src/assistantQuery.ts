import { assistantScope, assistantLinkAllowed } from './assistantScope'
import { treatmentEligibility, inventoryByDose, type AppData, type Patient, type Role } from './domain'
import { misuseSignals, operationalAlerts, type AdminPage } from './adminAnalytics'

export type AnswerLink={label:string;page:AdminPage;id?:string}
export type DataAnswer={title:string;body:string;facts:string[];links:AnswerLink[];matched:boolean}
const normalize=(value:string)=>value.toLowerCase().normalize('NFKD').replace(/[\u064b-\u065f]/g,'').replace(/[إأآ]/g,'ا').replace(/ى/g,'ي').replace(/ة/g,'ه').replace(/[^\p{L}\p{N}\s-]/gu,' ').replace(/\s+/g,' ').trim()
const includesAny=(q:string,words:string[])=>words.some(word=>q.includes(normalize(word)))
const statusAr:Record<string,string>={Draft:'مسودة','Under review':'قيد المراجعة',Approved:'معتمد','Ready to dispense':'جاهز للصرف',Dispensed:'تم الصرف',Completed:'مكتمل','Needs information':'تحتاج معلومات',Rejected:'مرفوض',Scheduled:'مجدول',Confirmed:'مؤكد',Cancelled:'ملغي',Active:'نشطة',Normal:'طبيعي',Abnormal:'غير طبيعي',Pending:'قيد الانتظار'}
const status=(value:string,ar:boolean)=>ar?statusAr[value]??value:value
const name=(p:Patient,ar:boolean)=>ar?p.nameAr??p.name:p.name
const t=(ar:boolean,en:string,arabic:string)=>ar?arabic:en
const patientLink=(p:Patient,ar:boolean):AnswerLink=>({label:t(ar,'Open patient record','فتح ملف المريض'),page:'Patients',id:`patient:${p.id}`})
const result=(title:string,body:string,facts:string[],links:AnswerLink[]):DataAnswer=>({title,body,facts,links,matched:true})
const patientCues=new Set(['patient','patients','المريض','المريضه','مريض','مريضه'])
const isPatientCue=(token:string)=>patientCues.has(token)||[...patientCues].some(cue=>cue.length>3&&token.endsWith(cue))
const nonNameWords=new Set(['patient','patients','record','profile','file','latest','last','recent','result','results','lab','labs','appointment','appointments','request','requests','treatment','status','for','the','what','who','is','of','and','please','today','upcoming','show','find','get','my','all','patient','المريض','المريضه','مريض','مريضه','ملف','سجل','بيانات','اخر','آخر','تحاليل','تحليل','نتيجه','نتائج','موعد','مواعيد','طلب','طلبات','علاج','حاله','حالة','ايه','ما','عن','من','اليوم','القادم','القادمه','القادمة','اعرض','اريد','عايز','عاوزه','لو','سمحت','لها','له','هما','هو','هي','دبي','ابوظبي','الشارقه','الشارقة','عجمان','الفجيره','الفجيرة'])
function editDistanceAtMostOne(a:string,b:string){
 if(a===b)return true
 if(Math.abs(a.length-b.length)>1)return false
 let i=0,j=0,edits=0
 while(i<a.length&&j<b.length){
  if(a[i]===b[j]){i++;j++;continue}
  if(++edits>1)return false
  if(a.length>b.length)i++
  else if(b.length>a.length)j++
  else{i++;j++}
 }
 return edits+(i<a.length||j<b.length?1:0)<=1
}
function nameTokens(patient:Patient){return [patient.name,patient.nameAr??''].flatMap(value=>normalize(value).split(' ').filter(token=>token.length>2))}
function matchingPatients(data:AppData,q:string,allowTypo:boolean){
 const cueIndex=q.split(' ').findIndex(isPatientCue)
 const identityWords=cueIndex<0?[]:q.split(' ').slice(cueIndex+1).filter(token=>token.length>2&&!nonNameWords.has(token)&&!/^p\d+$/i.test(token)&&!/^\d+$/.test(token))
 const words=(identityWords.length?identityWords:q.split(' ').filter(token=>token.length>2&&!/^p\d+$/i.test(token))).filter(token=>!/^\d+$/.test(token))
 const exact=data.patients.map(patient=>({patient,score:Math.max(...[patient.name,patient.nameAr??''].map(value=>normalize(value).split(' ').filter(token=>token.length>2&&words.includes(token)).length))})).filter(item=>item.score>0&&(!identityWords.length||item.score===identityWords.length))
 if(exact.length){const best=Math.max(...exact.map(item=>item.score));return exact.filter(item=>item.score===best).map(item=>item.patient)}
 if(!allowTypo)return []
 const nameLike=identityWords
 if(!nameLike.length)return []
 return data.patients.filter(patient=>nameLike.every(token=>nameTokens(patient).some(name=>editDistanceAtMostOne(name,token))))
}
function patientCue(q:string){return q.split(' ').some(isPatientCue)}
function identityWordsAfterCue(q:string){
 const tokens=q.split(' '),index=tokens.findIndex(isPatientCue)
 return index<0?[]:tokens.slice(index+1).filter(token=>token.length>2&&!nonNameWords.has(token)&&!/^p\d+$/i.test(token))
}

function answerLegacy(data:AppData,question:string,ar:boolean,role:Role='Admin'):DataAnswer{
 const q=normalize(question)
 if(!q)return {title:t(ar,'Write a question','اكتب سؤالًا'),body:t(ar,'Ask about a patient, request, lab, appointment, care plan, stock or programme activity.','اسأل عن مريض أو طلب أو تحليل أو موعد أو خطة رعاية أو مخزون أو نشاط البرنامج.'),facts:[],links:[],matched:false}
 const patientId=q.match(/\bp\s*\d{3,}\b/i)?.[0].replace(/\s/g,'').toUpperCase()
 const patient=data.patients.find(p=>p.id.toUpperCase()===patientId)??data.patients.find(p=>{const full=normalize(p.name),arabic=normalize(p.nameAr??'');return (full.length>4&&q.includes(full))||(arabic.length>4&&q.includes(arabic))})
 const requestId=q.match(/\btr-[\w-]+/i)?.[0].toUpperCase()
 const request=data.requests.find(r=>r.id.toUpperCase()===requestId)
 if((patientId&&!patient)||(requestId&&!request))return {matched:false,title:t(ar,'Record not found','لم يتم العثور على السجل'),body:t(ar,'Check the identifier or choose a record available in your workspace.','تحقق من الرقم أو اختر سجلًا متاحًا في مساحة عملك.'),facts:[],links:[]}
 const scopedId=patient?.id??request?.patientId
 const asksCount=includesAny(q,['كم','عدد','اجمالي','إجمالي','how many','total'])
 const asksPatients=includesAny(q,['مريض','مرضى','patients','patient'])
 const asksRequests=includesAny(q,['طلب','طلبات','requests','request'])
 if(asksCount&&asksPatients&&asksRequests)return result(t(ar,'Programme counts','أعداد البرنامج'),t(ar,'Current counts from the saved records.','الأعداد الحالية من السجلات المحفوظة.'),[`${t(ar,'Patients','المرضى')}: ${data.patients.length}`,`${t(ar,'Treatment requests','طلبات العلاج')}: ${data.requests.length}`],[{label:t(ar,'Open patients','فتح المرضى'),page:'Patients'},{label:t(ar,'Open requests','فتح الطلبات'),page:'Treatment requests'}])
 const who=scopedId?data.patients.find(p=>p.id===scopedId):undefined
 const links=who?[patientLink(who,ar)]:[]
 const scoped=<T extends {patientId:string}>(items:T[])=>scopedId?items.filter(item=>item.patientId===scopedId):items
 const latest=<T>(items:T[],date:(item:T)=>string)=>[...items].sort((a,b)=>date(b).localeCompare(date(a)))[0]

 if(request||includesAny(q,['طلب','طلبات','request','approval','موافق','صرف العلاج'])){
  const records=request?[request]:scoped(data.requests)
  if(request)return result(t(ar,'Treatment request','طلب العلاج'),`${request.id} · ${who?name(who,ar):request.patientId}`, [t(ar,'Status','الحالة')+': '+status(request.status,ar),t(ar,'Medication / dose','العلاج / الجرعة')+`: ${request.medication??'Mounjaro'} ${request.dose}`,t(ar,'Created','تاريخ الإنشاء')+`: ${request.createdAt?.slice(0,10)??request.created}`],[{label:t(ar,'Open request','فتح الطلب'),page:'Treatment requests',id:request.id},...links])
  const summary=Object.entries(records.reduce<Record<string,number>>((acc,r)=>(acc[r.status]=(acc[r.status]??0)+1,acc),{})).map(([key,count])=>`${status(key,ar)}: ${count}`)
  return result(t(ar,'Treatment requests','طلبات العلاج'),scopedId?t(ar,`Requests linked to ${who?name(who,ar):scopedId}.`,`الطلبات المرتبطة بـ${who?name(who,ar):scopedId}.`):t(ar,'Current counts from saved treatment requests.','الأعداد الحالية من طلبات العلاج المحفوظة.'),[`${t(ar,'Total','الإجمالي')}: ${records.length}`,...summary],[{label:t(ar,'Open requests','فتح الطلبات'),page:'Treatment requests'},...links])
 }
 if(includesAny(q,['تحليل','تحاليل','مختبر','سكر','hba1c','glucose','lab','result'])){
  const labs=scoped(data.labs)
  const wanted=includesAny(q,['سكر','hba1c','glucose'])?labs.filter(l=>/hba1c|glucose|سكر/i.test(l.test)):labs
  const records=[...wanted].sort((a,b)=>b.date.localeCompare(a.date)).slice(0,5)
  return result(t(ar,'Laboratory results','نتائج التحاليل'),scopedId?t(ar,`Recorded results for ${who?name(who,ar):scopedId}.`,`النتائج المسجلة لـ${who?name(who,ar):scopedId}.`):t(ar,'Latest recorded results across patients.','أحدث النتائج المسجلة للمرضى.'),records.length?records.map(l=>`${l.test}: ${l.value} ${l.unit} · ${t(ar,'reference','المرجع')} ${l.reference} · ${l.date} · ${status(l.status,ar)}${!scopedId?` · ${l.patientId}`:''}`):[t(ar,'No matching result is recorded.','لا توجد نتيجة مطابقة مسجلة.')],links.length?links:[{label:t(ar,'Open patients','فتح المرضى'),page:'Patients'}])
 }
 if(includesAny(q,['موعد','مواعيد','appointment','زيارة','visit'])){
  const items=[...scoped(data.appointments)].sort((a,b)=>`${b.date} ${b.time}`.localeCompare(`${a.date} ${a.time}`)).slice(0,5)
  return result(t(ar,'Appointments','المواعيد'),scopedId?t(ar,`Appointments for ${who?name(who,ar):scopedId}.`,`مواعيد ${who?name(who,ar):scopedId}.`):t(ar,'Latest appointments in the schedule.','أحدث المواعيد في الجدول.'),items.length?items.map(a=>`${a.date} ${a.time} · ${a.purpose} · ${status(a.status,ar)}${!scopedId?` · ${a.patientId}`:''}`):[t(ar,'No matching appointment is recorded.','لا يوجد موعد مطابق مسجل.')],[{label:t(ar,'Open appointments','فتح المواعيد'),page:'Appointments'},...links])
 }
 if(includesAny(q,['خطة','خطط','تأهيل','تمارين','care plan','rehabilitation','exercise'])){
  const items=[...(data.integratedCarePlans??[])].filter(p=>!scopedId||p.patientId===scopedId).sort((a,b)=>b.createdAt.localeCompare(a.createdAt)).slice(0,5)
  return result(t(ar,'Integrated care plans','خطط الرعاية المتكاملة'),scopedId?t(ar,`Plans for ${who?name(who,ar):scopedId}.`,`خطط ${who?name(who,ar):scopedId}.`):t(ar,'Recent plans linked to patient records.','أحدث الخطط المرتبطة بملفات المرضى.'),items.length?items.map(p=>`${p.id} · ${p.title} · ${status(p.status,ar)} · ${t(ar,'follow-up','المتابعة')} ${p.followUpDate}${!scopedId?` · ${p.patientId}`:''}`):[t(ar,'No matching care plan is recorded.','لا توجد خطة رعاية مطابقة.')],[{label:t(ar,'Open care plans','فتح خطط الرعاية'),page:'Integrated care plans'},...links])
 }
 if(includesAny(q,['مخزون','دواء','ادوية','أدوية','inventory','stock','batch','دفعة'])){
  if(!['Admin','Pharmacist'].includes(role))return result(t(ar,'Recorded medication','الأدوية المسجلة'),t(ar,'Medication linked to accessible treatment requests.','الأدوية المرتبطة بطلبات العلاج المتاحة لك.'),scoped(data.requests).slice(0,5).map(r=>`${r.patientId} · ${r.medication??'Mounjaro'} · ${r.dose} · ${status(r.status,ar)}`),links)
  const stock=inventoryByDose(data)
  return result(t(ar,'Medication inventory','مخزون الأدوية'),t(ar,'Available stock by strength, derived from current batches and reservations.','المتاح حسب الجرعة، محسوب من الدفعات والحجوزات الحالية.'),Object.entries(stock).map(([dose,count])=>`${dose}: ${count} ${t(ar,'units available','وحدة متاحة')}`),[{label:t(ar,'Open inventory','فتح المخزون'),page:'Inventory'}])
 }
 if(includesAny(q,['تنبيه','تنبيهات','امداد','alert','supply'])){
  const alerts=operationalAlerts(data).filter(a=>(['Admin','Pharmacist'].includes(role)||Boolean(a.patientId))&&!(data.dismissedAlerts??[]).includes(a.id)).filter(a=>!scopedId||a.patientId===scopedId)
  return result(t(ar,'Open alerts','التنبيهات المفتوحة'),`${t(ar,'Current alerts','التنبيهات الحالية')}: ${alerts.length}`,alerts.slice(0,5).map(a=>`${a.title} · ${a.entityId??a.patientId??a.id}`),[{label:t(ar,'Open alerts','فتح التنبيهات'),page:'Alerts'},...links])
 }
 if(includesAny(q,['اساء','إساء','سوء استخدام','misuse','abuse'])){
  const signals=misuseSignals(data).filter(s=>!scopedId||s.patientId===scopedId)
  return result(t(ar,'Misuse review signals','إشارات مراجعة إساءة الاستخدام'),`${t(ar,'Recorded rule-based signals','الإشارات المسجلة من قواعد البرنامج')}: ${signals.length}`,signals.slice(0,5).map(s=>`${s.eventType} · ${s.patientId??s.requestId??s.id}`),[{label:t(ar,'Open misuse review','فتح سجل المراجعة'),page:'Misuse prevention'}])
 }
 if(includesAny(q,['صرف','صيدلية','dispens','pharmacy'])){
  const items=[...scoped(data.dispenses)].sort((a,b)=>b.date.localeCompare(a.date)).slice(0,5)
  return result(t(ar,'Dispensing records','سجلات الصرف'),`${t(ar,'Dispensing records found','عدد سجلات الصرف')}: ${scoped(data.dispenses).length}`,items.map(d=>`${d.date} · ${d.dose} · ${d.centre} · ${d.requestId}`),[{label:t(ar,'Open treatment requests','فتح طلبات العلاج'),page:'Treatment requests'},...links])
 }
 if(includesAny(q,['تكلف','مالي','دعم','cost','finance','coverage'])){
  if(['Doctor','Reviewer'].includes(role))return {matched:false,title:t(ar,'Pharmacy workspace','مساحة الصيدلية'),body:t(ar,'Cost and payment information is handled in the pharmacy workspace.','تُعرض التكلفة والدفع في مساحة الصيدلية.'),facts:[],links:[]}
  const records=scoped(data.financial)
  const amount=records.reduce((sum,r)=>sum+r.amountAED,0)
  return result(t(ar,'Recorded estimates','التقديرات المسجلة'),t(ar,'These are programme estimates, not payments.','هذه تقديرات للبرنامج وليست مبالغ مدفوعة.'),[`${t(ar,'Records','السجلات')}: ${records.length}`,`${t(ar,'Estimated total','الإجمالي التقديري')}: ${amount.toLocaleString(ar?'ar-AE':'en-AE')} AED`],[{label:t(ar,'Open reports','فتح التقارير'),page:'Reports'},...links])
 }
 if(includesAny(q,['المرضى','patients','patient list'])){
  const items=data.patients.slice(0,8)
  return result(t(ar,'Patient registry','سجل المرضى'),`${t(ar,'Total patients','إجمالي المرضى')}: ${data.patients.length}`,items.map(p=>`${name(p,ar)} · ${p.id} · ${p.diagnosis}`),[{label:t(ar,'Open patient registry','فتح سجل المرضى'),page:'Patients'}])
 }
 if(includesAny(q,['طبيب','اطباء','أطباء','doctor','clinician'])){
  return result(t(ar,'Doctors','الأطباء'),`${t(ar,'Registered doctors','الأطباء المسجلون')}: ${data.doctors.length}`,data.doctors.map(d=>`${d.name} · ${d.specialty} · ${d.centre}`),[{label:t(ar,'Open patients','فتح المرضى'),page:'Patients'}])
 }
 if(includesAny(q,['مركز','مراكز','centre','center'])){
  return result(t(ar,'Care centres','مراكز الرعاية'),`${t(ar,'Registered centres','المراكز المسجلة')}: ${data.centres.length}`,data.centres.slice(0,8).map(c=>`${c.name} · ${c.emirate} · ${status(c.status,ar)}`),[{label:t(ar,'Open inventory','فتح المخزون'),page:'Inventory'}])
 }
 if(includesAny(q,['مستند','وثيقة','وثائق','document','file'])){
  const docs=(data.documents??[]).filter(d=>!scopedId||d.patientId===scopedId)
  return result(t(ar,'Patient documents','مستندات المرضى'),`${t(ar,'Documents found','عدد المستندات')}: ${docs.length}`,docs.slice(0,5).map(d=>`${d.title} · ${d.patientId} · ${d.date}`),links.length?links:[{label:t(ar,'Open patients','فتح المرضى'),page:'Patients'}])
 }
 if(includesAny(q,['نشاط','سجل','تدقيق','activity','audit','history'])){
  const events=data.audit.filter(a=>!scopedId||a.patientId===scopedId).slice().sort((a,b)=>(b.occurredAt??'').localeCompare(a.occurredAt??'')).slice(0,5)
  return result(t(ar,'Recent activity','أحدث الأنشطة'),t(ar,'Recorded changes from the shared activity log.','التغييرات المسجلة في سجل الأنشطة المشترك.'),events.map(e=>`${e.action} · ${e.entityId} · ${e.occurredAt?.slice(0,10)??e.time}`),[{label:t(ar,'Open activity log','فتح سجل الأنشطة'),page:'Activity log'}])
 }
 if(who){
  const lab=latest(scoped(data.labs),l=>l.date)
  const appointment=latest(scoped(data.appointments),a=>a.date)
  const dispense=latest(scoped(data.dispenses),d=>d.date)
  return result(t(ar,'Patient record','ملف المريض'),`${name(who,ar)} · ${who.id}`,[`${t(ar,'Diagnosis','التشخيص')}: ${who.diagnosis}`,`${t(ar,'BMI','مؤشر الكتلة')}: ${who.bmi}`,`${t(ar,'Latest lab','آخر تحليل')}: ${lab?`${lab.test} ${lab.value} ${lab.unit}`:'—'}`,`${t(ar,'Last dispensing','آخر صرف')}: ${dispense?.date??'—'}`,`${t(ar,'Latest appointment','آخر موعد')}: ${appointment?.date??'—'}`],links)
 }
 if(includesAny(q,['كم','عدد','اجمالي','إجمالي','overview','summary','dashboard','احصاء','إحصاء'])){
  return result(t(ar,'Programme snapshot','ملخص البرنامج'),t(ar,'Counts calculated from the current local records.','الأعداد محسوبة من السجلات المحلية الحالية.'),[`${t(ar,'Patients','المرضى')}: ${data.patients.length}`,`${t(ar,'Treatment requests','طلبات العلاج')}: ${data.requests.length}`,`${t(ar,'Care plans','خطط الرعاية')}: ${data.integratedCarePlans?.length??0}`,`${t(ar,'Appointments','المواعيد')}: ${data.appointments.length}`,`${t(ar,'Open alerts','التنبيهات المفتوحة')}: ${operationalAlerts(data).filter(a=>(['Admin','Pharmacist'].includes(role)||Boolean(a.patientId))&&!(data.dismissedAlerts??[]).includes(a.id)).length}`],[{label:t(ar,'Open dashboard','فتح لوحة التحكم'),page:'Overview'}])
 }
 const tokens=q.split(' ').filter(word=>word.length>2)
 const searchIndex=[
  ...data.patients.map(p=>({label:`${name(p,ar)} · ${p.id}`,search:`${p.id} ${p.name} ${p.nameAr??''} ${p.diagnosis} ${p.emirate}`,page:'Patients' as AdminPage,id:`patient:${p.id}`})),
  ...data.requests.map(r=>({label:`${r.id} · ${status(r.status,ar)} · ${r.patientId}`,search:`${r.id} ${r.patientId} ${r.status} ${r.medication??''} ${r.dose} ${r.note??''}`,page:'Treatment requests' as AdminPage,id:r.id})),
  ...data.labs.map(l=>({label:`${l.test} ${l.value} ${l.unit} · ${l.patientId}`,search:`${l.test} ${l.value} ${l.unit} ${l.patientId} ${l.source}`,page:'Patients' as AdminPage,id:`patient:${l.patientId}`})),
  ...data.appointments.map(a=>({label:`${a.purpose} · ${a.date} · ${a.patientId}`,search:`${a.purpose} ${a.date} ${a.patientId} ${a.doctor} ${a.centre}`,page:'Appointments' as AdminPage,id:a.id})),
  ...(data.integratedCarePlans??[]).map(p=>({label:`${p.title} · ${p.patientId}`,search:`${p.title} ${p.patientId} ${p.monitoring}`,page:'Integrated care plans' as AdminPage,id:p.id})),
  ...(data.documents??[]).map(d=>({label:`${d.title} · ${d.patientId}`,search:`${d.title} ${d.content} ${d.patientId} ${d.fileName??''}`,page:'Patients' as AdminPage,id:`patient:${d.patientId}`})),
  ...data.audit.map(a=>({label:`${a.action} · ${a.entityId}`,search:`${a.action} ${a.detail} ${a.entityId} ${a.patientId??''}`,page:'Activity log' as AdminPage,id:a.id})),
  ...data.assessments.map(a=>({label:`${a.reason||a.diagnosis} · ${a.patientId}`,search:`${a.reason} ${a.diagnosis} ${a.symptoms} ${a.findings} ${a.patientId}`,page:'Patients' as AdminPage,id:`patient:${a.patientId}`})),
  ...data.vitals.map(v=>({label:`${v.patientId} · BMI ${v.bmi} · ${v.recordedAt.slice(0,10)}`,search:`${v.patientId} ${v.bmi} ${v.systolic} ${v.diastolic} ${v.weightKg}`,page:'Patients' as AdminPage,id:`patient:${v.patientId}`})),
  ...data.dispenses.map(d=>({label:`${d.id} · ${d.dose} · ${d.patientId}`,search:`${d.id} ${d.patientId} ${d.requestId} ${d.centre} ${d.dose} ${d.date}`,page:'Treatment requests' as AdminPage,id:d.requestId})),
  ...data.doctors.map(d=>({label:`${d.name} · ${d.specialty}`,search:`${d.id} ${d.name} ${d.specialty} ${d.centre}`,page:'Patients' as AdminPage,id:d.id})),
  ...data.centres.map(c=>({label:`${c.name} · ${c.emirate}`,search:`${c.id} ${c.name} ${c.emirate} ${c.location}`,page:'Inventory' as AdminPage,id:c.id})),
  ...data.batches.map(b=>({label:`${b.batchNumber} · ${b.dose} · ${b.quantity}`,search:`${b.id} ${b.batchNumber} ${b.dose} ${b.centre} ${b.expiry}`,page:'Inventory' as AdminPage,id:b.id})),
  ...data.financial.map(f=>({label:`${f.id} · ${f.amountAED} AED · ${f.patientId}`,search:`${f.id} ${f.patientId} ${f.requestId} ${f.amountAED}`,page:'Reports' as AdminPage,id:f.id})),
  ...data.notifications.map(n=>({label:`${n.title} · ${n.patientId}`,search:`${n.id} ${n.patientId} ${n.title} ${n.detail}`,page:'Patients' as AdminPage,id:`patient:${n.patientId}`})),
  ...data.exercise.map(e=>({label:`${e.activity} · ${e.date} · ${e.patientId}`,search:`${e.id} ${e.patientId} ${e.activity} ${e.notes}`,page:'Patients' as AdminPage,id:`patient:${e.patientId}`})),
 ]
 const matches=searchIndex.map(item=>({item,score:tokens.filter(word=>normalize(item.search).includes(word)).length})).filter(x=>x.score>0).sort((a,b)=>b.score-a.score).slice(0,5)
 if(matches.length)return result(t(ar,'Matching records','سجلات مطابقة'),t(ar,'These records contain terms from your question. Open a record for full details.','هذه السجلات تحتوي كلمات من سؤالك. افتح السجل للاطلاع على التفاصيل.'),matches.map(x=>x.item.label),matches.map(x=>({label:x.item.label,page:x.item.page,id:x.item.id})))
 return {title:t(ar,'No matching record','لم أجد سجلًا مطابقًا'),body:t(ar,'Try a patient ID such as P999, a request ID, or ask about labs, appointments, care plans, stock or alerts.','جرّب رقم مريض مثل P999 أو رقم طلب، أو اسأل عن التحاليل والمواعيد والخطط والمخزون والتنبيهات.'),facts:[],links:[],matched:false}
}

export type AssistantContext={patientId?:string;requestId?:string}
export type AssistantRecord={id:string;title:string;subtitle?:string;status?:string;values:{label:string;value:string}[];link?:AnswerLink}
export type RichDataAnswer=DataAnswer & {context:AssistantContext;records?:AssistantRecord[];request?:AppData['requests'][number];patient?:Patient;steps?:{label:string;state:'done'|'current'|'pending'}[];suggestions:string[];total?:number}

/** Query the canonical role projection on every turn; there is no assistant-owned dataset. */
export function answerDataQuestion(canonical:AppData,question:string,ar:boolean,role:Role='Admin',context:AssistantContext={},now=new Date()):RichDataAnswer{
 const data=assistantScope(canonical,role)
 const questionDigits=question.replace(/[٠-٩]/g,d=>String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)))
 const q=normalize(questionDigits), day=now.toISOString().slice(0,10)
 const explicitPatient=q.match(/\bp\s*\d+\b/i)?.[0].replace(/\s/g,'').toUpperCase()
 const explicitRequest=q.match(/\btr-[\w-]+/i)?.[0].toUpperCase()
 const exactRequest=data.requests.find(r=>r.id.toUpperCase()===explicitRequest)
 let patient=explicitPatient?data.patients.find(p=>p.id===explicitPatient):undefined
 const make=(a:DataAnswer,extra:Partial<RichDataAnswer>={}):RichDataAnswer=>({...a,context:{patientId:patient?.id},suggestions:[],...extra,links:a.links.filter(l=>assistantLinkAllowed(role,l.page))})
 if((explicitPatient&&!patient)||(explicitRequest&&!exactRequest))return make({title:t(ar,'Record not found','لم أجد السجل'),body:t(ar,'This record is not available in your workspace. Check its identifier.','هذا السجل غير متاح في مساحة عملك. راجع رقم السجل.'),facts:[],links:[],matched:false},{context:{}})
 const matchedNames=!explicitPatient&&!explicitRequest?matchingPatients(data,q,patientCue(q)):[]
 if(matchedNames.length>1)return make(result(t(ar,'Which patient do you mean?','أي مريض تقصد؟'),t(ar,'More than one patient matches that name. Choose a record ID to continue.','وجدت أكثر من مريض بهذا الاسم. اختر رقم الملف للمتابعة.'),[],[]),{patient:undefined,context:{},suggestions:matchedNames.slice(0,5).map(p=>`${name(p,ar)} ${p.id}`)})
 if(!patient&&matchedNames.length===1)patient=matchedNames[0]
 const patientSelectionIntent=includesAny(q,['patient record','patient profile','patient overview','find a patient','ملف المريض','بيانات المريض','تحليل مريض'])
 if(!patient&&!exactRequest&&patientSelectionIntent){
  return make(result(t(ar,'Choose a patient','حدد المريض'),t(ar,'Tell me the patient name or ID. If a name matches more than one record, I will ask you to choose.','اكتب اسم المريض أو رقم ملفه. إذا تطابق الاسم مع أكثر من ملف، سأطلب منك تحديد المريض.'),[],[]),{patient:undefined,context:{},suggestions:data.patients.slice(0,5).map(p=>`${name(p,ar)} ${p.id}`)})
 }
 if(!patient&&!exactRequest&&patientCue(q)&&identityWordsAfterCue(q).length){
  return make({matched:false,title:t(ar,'Patient not found','لم أجد هذا المريض'),body:t(ar,'I could not match that name to an available patient record. Check the spelling or send the patient ID.','لم أتمكن من مطابقة الاسم مع ملف مريض متاح. راجع الاسم أو أرسل رقم الملف.'),facts:[],links:[]},{patient:undefined,context:{}})
 }
 const global=includesAny(q,['كل المرضى','جميع المرضى','كل الطلبات','جميع الطلبات','على مستوى','all patients','all requests','all ','كل ','جميع ','across','programme','النظام','البرنامج'])
 if(!patient&&!global)patient=data.patients.find(p=>p.id===(exactRequest?.patientId??context.patientId))
 const pid=patient?.id
 const ctx:AssistantContext={patientId:pid,requestId:exactRequest?.id??(context.patientId===pid?context.requestId:undefined)}
 const suggestions=pid?[t(ar,`Latest labs for ${pid}`,`آخر التحاليل للمريض ${pid}`),t(ar,`Upcoming appointments for ${pid}`,`المواعيد القادمة للمريض ${pid}`),t(ar,`Treatment eligibility for ${pid}`,`أهلية العلاج للمريض ${pid}`)]:[t(ar,'All treatment requests under review','جميع الطلبات قيد المراجعة'),t(ar,'Upcoming appointments','المواعيد القادمة'),t(ar,'Abnormal lab results','نتائج التحاليل غير الطبيعية')]
 const finish=(a:DataAnswer,extra:Partial<RichDataAnswer>={})=>make(a,{patient,context:ctx,suggestions,...extra})
 const scoped=<T extends {patientId:string}>(items:T[])=>pid?items.filter(x=>x.patientId===pid):items
 const patientName=(id:string)=>{const p=data.patients.find(p=>p.id===id);return p?name(p,ar):id}
 const has=(words:string[])=>includesAny(q,words)
 const labIntent=has(['تحليل','تحاليل','lab','hba1c','glucose','سكر','نتائج','results'])
 const appointmentIntent=has(['موعد','مواعيد','appointment','زيارة','visit'])
 const eligibilityIntent=has(['اهليه','أهلية','مؤهل','يستحق','eligib','criteria','معايير'])
 const planIntent=has(['خطة','خطط','care plan','تمارين','exercise','rehabilitation','تأهيل'])&&!has(['طلب','request'])
 const requestIntent=Boolean(exactRequest)||has(['طلب','طلبات','request','approval','موافق'])||(Boolean(ctx.requestId)&&has(['حالته','حالتها','status','وضعه']))
 const count=has(['كم','عدد','how many','count','total','اجمالي'])
 const next=has(['قادم','القادمة','next','upcoming','الجاي','الجايه'])
 const today=has(['اليوم','today'])
 const date=q.match(/\b\d{4}-\d{2}-\d{2}\b/)?.[0]
 const filteredDate=(d:string)=>today?d.slice(0,10)===day:date?d.slice(0,10)===date:true
 if(/^(مرحبا|اهلا|السلام عليكم|هاي|hello|hi|hey)[ !؟?]*$/.test(q)||has(['ممكن تعمل ايه','تقدر تعمل ايه','what can you do','help me','ساعدني']))return finish(result(t(ar,'How can I help?','كيف أقدر أساعدك؟'),t(ar,'I can find and summarize the records available in your workspace. Ask a question, then follow up about the same patient.','أقدر أبحث وألخص السجلات المتاحة في مساحة عملك. اسأل عن مريض أو طلب، وكمل أسئلتك عن نفس المريض.'),[],[]),{context:{},suggestions})
 if(eligibilityIntent){
  if(!patient)return finish({title:t(ar,'Choose a patient','حدد المريض'),body:t(ar,'Send a patient name or ID so I can check the recorded criteria and dispensing date.','اكتب اسم المريض أو رقمه لمراجعة معايير العلاج وتوقيت الصرف من سجله.'),facts:[],links:[],matched:false},{suggestions:data.patients.slice(0,3).map(p=>`${t(ar,'Treatment eligibility','أهلية العلاج')} ${p.id}`)})
  const e=treatmentEligibility(data,patient.id,day)
  const labels=['عمر المريض 18 سنة أو أكثر','مؤشر كتلة الجسم 30 أو أكثر','تشخيص مناسب مسجل','نتيجة السكر التراكمي متاحة']
  const checks=e.clinical.criteria.map((c,i)=>`${c.passed?'✓':'!'} ${ar?labels[i]:c.label}: ${c.evidence}`)
  return finish(result(t(ar,'Treatment & dispensing eligibility','أهلية العلاج والصرف'),t(ar,`${patientName(patient.id)}: ${e.eligible?'recorded programme criteria met':'clinical review or additional evidence required'}. Professional approval remains required.`,`${patientName(patient.id)}: ${e.eligible?'معايير البرنامج المسجلة مستوفاة':'تحتاج مراجعة أو استكمال البيانات'}. القرار السريري باعتماد المختص.`),[...checks,`${t(ar,'Clinical assessment submitted','تقييم طبي معتمد')}: ${e.assessment?t(ar,'Yes','نعم'):t(ar,'No','لا')}`,`${t(ar,'Last dispensing','آخر صرف')}: ${e.refill.lastDispense?.date??'—'}`,`${t(ar,'Next permitted dispensing','موعد الصرف المسموح')}: ${e.refill.nextEligibleDate??t(ar,'No previous dispensing','لا يوجد صرف سابق')}`,`${t(ar,'Dispensing timing','توقيت الصرف')}: ${e.refill.eligible?t(ar,'Eligible','مستوفٍ'):t(ar,'Not yet due','لم يحن الموعد')}`],[patientLink(patient,ar)]))
 }
 if(labIntent){
  let labs=scoped(data.labs).filter(l=>filteredDate(l.date))
  if(has(['غير طبيعي','غير الطبيعية','مرتف','abnormal','high']))labs=labs.filter(l=>l.status==='Abnormal')
  if(has(['hba1c','تراكمي']))labs=labs.filter(l=>/hba1c/i.test(l.test))
  else if(has(['glucose','سكر الدم']))labs=labs.filter(l=>/glucose/i.test(l.test))
  labs.sort((a,b)=>b.date.localeCompare(a.date))
  const rows=has(['آخر','اخر','latest'])&&!count?labs.slice(0,1):labs
  return finish(result(t(ar,'Laboratory results','نتائج التحاليل'),`${t(ar,'Matching results','النتائج المطابقة')}: ${labs.length}`,rows.map(l=>`${l.test}: ${l.value} ${l.unit} · ${t(ar,'reference','المرجع')} ${l.reference} · ${l.date} · ${status(l.status,ar)}`),patient?[patientLink(patient,ar)]:[{label:t(ar,'Patients','المرضى'),page:'Patients'}]),{total:rows.length,records:rows.map(l=>({id:l.id,title:l.test,subtitle:`${patientName(l.patientId)} · ${l.patientId}`,status:status(l.status,ar),values:[{label:t(ar,'Result','النتيجة'),value:`${l.value} ${l.unit}`},{label:t(ar,'Reference','المرجع'),value:l.reference},{label:t(ar,'Date','التاريخ'),value:l.date}],link:{label:t(ar,'Patient record','ملف المريض'),page:'Patients',id:`patient:${l.patientId}`}}))})
 }
 if(appointmentIntent){
  let items=scoped(data.appointments).filter(a=>filteredDate(a.date))
  if(next)items=items.filter(a=>`${a.date}T${a.time}`>=`${day}T${now.toTimeString().slice(0,5)}`&&['Scheduled','Confirmed'].includes(a.status))
  if(has(['ملغي','cancelled','canceled']))items=items.filter(a=>a.status==='Cancelled')
  items.sort((a,b)=>`${a.date} ${a.time}`.localeCompare(`${b.date} ${b.time}`))
  return finish(result(t(ar,'Appointments','المواعيد'),`${t(ar,'Matching appointments','المواعيد المطابقة')}: ${items.length}`,[],[{label:t(ar,'Open appointments','فتح المواعيد'),page:'Appointments'}]),{total:items.length,records:items.map(a=>({id:a.id,title:patientName(a.patientId),subtitle:a.purpose,status:status(a.status,ar),values:[{label:t(ar,'Date','التاريخ'),value:`${a.date} · ${a.time}`},{label:t(ar,'Doctor','الطبيب'),value:a.doctor},{label:t(ar,'Centre','المركز'),value:a.centre}],link:{label:t(ar,'Open appointment','فتح الموعد'),page:'Appointments',id:a.id}}))})
 }
 if(planIntent){
  const plans=scoped(data.integratedCarePlans??[]).sort((a,b)=>b.createdAt.localeCompare(a.createdAt))
  return finish(result(t(ar,'Integrated care plans','خطط الرعاية المتكاملة'),`${t(ar,'Matching plans','الخطط المطابقة')}: ${plans.length}`,[],[{label:t(ar,'Care plans','خطط الرعاية'),page:'Integrated care plans'}]),{total:plans.length,records:plans.map(p=>({id:p.id,title:p.title,subtitle:`${patientName(p.patientId)} · ${p.patientId}`,status:status(p.status,ar),values:[{label:t(ar,'Follow-up','المتابعة'),value:p.followUpDate},{label:t(ar,'Created','الإنشاء'),value:p.createdAt.slice(0,10)}],link:{label:t(ar,'Open plan','عرض الخطة'),page:'Integrated care plans',id:p.id}}))})
 }
 // Preserve the combined count question, while status-specific requests return actual matching rows.
 if(requestIntent&&!(count&&has(['مرضى','المرضى','patients'])&&!pid)){
  let requests=(exactRequest?[exactRequest]:scoped(data.requests)).filter(r=>filteredDate(r.createdAt??r.created))
  const filters:[string[],string][]=[[['قيد المراجعة','بانتظار المراجعة','under review','pending review'],'Under review'],[['جاهز للصرف','جاهزة للصرف','ready to dispense'],'Ready to dispense'],[['مرفوض','rejected'],'Rejected'],[['معلومات','information'],'Needs information'],[['معتمد','approved'],'Approved'],[['تم الصرف','dispensed'],'Dispensed'],[['مسودة','draft'],'Draft']]
  const wanted=filters.find(([words])=>has(words))?.[1]
  if(wanted&&!exactRequest)requests=requests.filter(r=>r.status===wanted)
  requests.sort((a,b)=>(b.createdAt??b.created).localeCompare(a.createdAt??a.created))
  const single=exactRequest??(pid&&!count&&!wanted&&!has(['كل','جميع','all'])?requests[0]:undefined)
  if(single){
   patient=data.patients.find(p=>p.id===single.patientId)
   const stages=['Submitted','Under review','Approved','Dispensed']
   const active=single.status==='Draft'?0:['Under review','Needs information','Rejected'].includes(single.status)?1:['Approved','Ready to dispense'].includes(single.status)?2:3
   return finish(result(t(ar,'Treatment request status','حالة طلب العلاج'),t(ar,`Here is the recorded status for ${patientName(single.patientId)} (${single.patientId}).`,`إليك حالة طلب العلاج للمريض ${patientName(single.patientId)} (${single.patientId}) بناءً على بيانات النظام.`),[`${t(ar,'Status','الحالة')}: ${status(single.status,ar)}`,`${single.medication??'Mounjaro'} · ${single.dose}`],[{label:`${t(ar,'Treatment request','طلب العلاج')} ${single.id}`,page:'Treatment requests',id:single.id},...(patient?[patientLink(patient,ar)]:[])]),{patient,context:{patientId:single.patientId,requestId:single.id},request:single,steps:stages.map((x,i)=>({label:ar?['تقديم الطلب','المراجعة الطبية','اعتماد الطلب','صرف الدواء'][i]:x,state:i<active||(['Dispensed','Completed'].includes(single.status)&&i===active)?'done':i===active?'current':'pending'}))})
  }
  return finish(result(t(ar,'Treatment requests','طلبات العلاج'),`${t(ar,'Matching requests','طلبات مطابقة')}: ${requests.length}`,count?[`${t(ar,'Total','الإجمالي')}: ${requests.length}`]:[],[{label:t(ar,'Open requests','فتح الطلبات'),page:'Treatment requests'}]),{total:requests.length,records:requests.map(r=>({id:r.id,title:patientName(r.patientId),subtitle:r.id,status:status(r.status,ar),values:[{label:t(ar,'Medication / dose','الدواء / الجرعة'),value:`${r.medication??'Mounjaro'} · ${r.dose}`},{label:t(ar,'Submitted','تاريخ الإرسال'),value:(r.createdAt??r.created).slice(0,10)}],link:{label:t(ar,'Open request','فتح الطلب'),page:'Treatment requests',id:r.id}}))})
 }
 if(patient&&has(['الطبيب','الدكتور','طبيب','doctor','clinician'])){
  const doctor=data.doctors.find(d=>d.id===patient.doctorId||d.name===patient.assignedDoctor)
  return finish(result(t(ar,'Assigned care team','فريق الرعاية المسؤول'),name(patient,ar),doctor?[`${t(ar,'Doctor','الطبيب')}: ${ar?doctor.nameAr??doctor.name:doctor.name}`,`${t(ar,'Specialty','التخصص')}: ${doctor.specialty}`,`${t(ar,'Centre','المركز')}: ${doctor.centre}`]:[t(ar,'No doctor assignment is recorded.','لا يوجد طبيب مسؤول مسجل.')],[patientLink(patient,ar)]))
 }
 const answer=answerLegacy(data,`${questionDigits}${pid&&!explicitPatient&&!explicitRequest?` ${pid}`:''}`,ar,role)
 return finish(answer)
}
