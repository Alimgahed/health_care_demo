import type { LabResult, Patient } from './domain'

function reportCanvas(patient:Patient, lab:LabResult, arabic:boolean){
  const canvas=document.createElement('canvas')
  canvas.width=1240;canvas.height=1754
  const ctx=canvas.getContext('2d')!
  const text=(value:string,x:number,y:number,size=28,bold=false,color='#183a4b')=>{ctx.fillStyle=color;ctx.font=`${bold?'700':'400'} ${size}px Arial, Tahoma, sans-serif`;ctx.textAlign=arabic?'right':'left';ctx.direction=arabic?'rtl':'ltr';ctx.fillText(value,x,y,1050)}
  const left=arabic?1110:130
  ctx.fillStyle='#fff';ctx.fillRect(0,0,1240,1754)
  ctx.fillStyle='#0c776b';ctx.fillRect(0,0,1240,17)
  text(arabic?'تقرير نتائج التحاليل':'Laboratory results report',left,145,51,true)
  text(arabic?'بيانات تجريبية · للاستخدام التوضيحي فقط':'DEMONSTRATION DATA · FOR PRESENTATION ONLY',left,198,23,false,'#607d88')
  ctx.strokeStyle='#d9e5e8';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(130,250);ctx.lineTo(1110,250);ctx.stroke()
  const label=(ar:string,en:string,y:number,value:string)=>{text(arabic?ar:en,left,y,22,false,'#67818d');text(value,left,y+43,31,true)}
  label('المريض','Patient',320,arabic?(patient.nameAr??patient.name):patient.name)
  label('رقم الملف / رقم التحليل','Patient ID / Laboratory accession',445,`${patient.id} / ${lab.id}`)
  label('تاريخ العينة','Collection date',570,lab.date)
  label('نوع التحليل','Test',695,lab.test)
  ctx.fillStyle='#f0f8f5';ctx.fillRect(105,765,1030,225)
  text(arabic?'النتيجة':'Result',arabic?1080:160,825,24,false,'#476e68')
  text(lab.status==='Pending'?(arabic?'قيد الانتظار':'Pending'):`${lab.value} ${lab.unit}`,arabic?1080:160,915,69,true,'#0c776b')
  label('النطاق المرجعي','Reference range',1075,lab.reference||'—')
  label('الحالة','Status',1210,arabic?({Normal:'طبيعي',Abnormal:'غير طبيعي',Pending:'قيد الانتظار'}[lab.status]):lab.status)
  label('المصدر','Source',1345,lab.source||'—')
  ctx.beginPath();ctx.moveTo(130,1450);ctx.lineTo(1110,1450);ctx.stroke()
  text(arabic?'التفسير المسجل':'Recorded interpretation',left,1505,22,false,'#67818d')
  text(lab.status==='Pending'?(arabic?'العينة قيد المعالجة؛ لم تصدر نتيجة نهائية.':'Sample processing; no final result has been issued.'):lab.interpretation||'—',left,1555,25)
  text(arabic?'هذا التقرير يعرض البيانات المسجلة فقط. راجع المستند الأصلي قبل القرار السريري.':'This copy reflects recorded data. Check the source document before clinical decisions.',left,1655,19,false,'#657f89')
  return canvas
}

export function labReportPreview(patient:Patient,lab:LabResult,arabic:boolean){return reportCanvas(patient,lab,arabic).toDataURL('image/jpeg',.88)}

function ascii(value:string){return new TextEncoder().encode(value)}
function join(parts:Uint8Array[]){const size=parts.reduce((n,p)=>n+p.length,0);const output=new Uint8Array(size);let offset=0;for(const p of parts){output.set(p,offset);offset+=p.length}return output}
export function pdfFromJpeg(jpeg:Uint8Array,width:number,height:number){
  const pieces:Uint8Array[]=[ascii('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n')]
  const offsets=[0]
  const add=(id:number,body:Uint8Array)=>{offsets[id]=pieces.reduce((n,p)=>n+p.length,0);pieces.push(ascii(`${id} 0 obj\n`),body,ascii('\nendobj\n'))}
  add(1,ascii('<< /Type /Catalog /Pages 2 0 R >>'))
  add(2,ascii('<< /Type /Pages /Kids [3 0 R] /Count 1 >>'))
  add(3,ascii('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>'))
  add(4,join([ascii(`<< /Type /XObject /Subtype /Image /Width ${width} /Height ${height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\nstream\n`),jpeg,ascii('\nendstream')]))
  const content=ascii('q\n595 0 0 842 0 0 cm\n/Im0 Do\nQ\n')
  add(5,join([ascii(`<< /Length ${content.length} >>\nstream\n`),content,ascii('endstream')]))
  const xref=pieces.reduce((n,p)=>n+p.length,0)
  pieces.push(ascii(`xref\n0 6\n0000000000 65535 f \n${offsets.slice(1).map(n=>`${String(n).padStart(10,'0')} 00000 n \n`).join('')}trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`))
  return join(pieces)
}
export function labReportPdf(patient:Patient,lab:LabResult,arabic:boolean){
  const canvas=reportCanvas(patient,lab,arabic)
  const jpeg=Uint8Array.from(atob(canvas.toDataURL('image/jpeg',.92).split(',')[1]),char=>char.charCodeAt(0))
  const bytes=pdfFromJpeg(jpeg,canvas.width,canvas.height)
  return new Blob([bytes.buffer as ArrayBuffer],{type:'application/pdf'})
}
export function downloadLabReport(patient:Patient,lab:LabResult,arabic:boolean){
  const url=URL.createObjectURL(labReportPdf(patient,lab,arabic))
  const link=document.createElement('a');link.href=url;link.download=`${patient.id}-${lab.test.replace(/[^a-z0-9-]/gi,'-')}-${lab.date}.pdf`;link.click()
  setTimeout(()=>URL.revokeObjectURL(url),60000)
}
