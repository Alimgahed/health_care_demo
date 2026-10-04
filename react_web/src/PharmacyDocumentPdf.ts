import logoUrl from './assets/healthcare-logo.png'
import type { PharmacyDocumentModel } from './pharmacyDocumentModel'

export async function pharmacyDocumentPages(model:PharmacyDocumentModel):Promise<HTMLCanvasElement[]> {
 await document.fonts?.ready
 const logo=new Image();logo.src=logoUrl;await logo.decode()
 const pages:HTMLCanvasElement[]=[]
 let canvas:HTMLCanvasElement,ctx!:CanvasRenderingContext2D,y=0
 const x=model.arabic?1140:100
 const text=(value:string,atY:number,size=25,bold=false,color='#244b50')=>{ctx.fillStyle=color;ctx.font=`${bold?700:400} ${size}px Tahoma, Arial, sans-serif`;ctx.textAlign=model.arabic?'right':'left';ctx.direction=model.arabic?'rtl':'ltr';ctx.fillText(value,x,atY)}
 const page=()=>{canvas=document.createElement('canvas');canvas.width=1240;canvas.height=1754;ctx=canvas.getContext('2d')!;pages.push(canvas);ctx.fillStyle='#fff';ctx.fillRect(0,0,1240,1754);ctx.fillStyle='#087e70';ctx.fillRect(0,0,1240,16);const width=120,height=120*logo.height/logo.width;ctx.drawImage(logo,model.arabic?100:1020,62,width,height);text(model.arabic?'هيلث كير · رعاية متكاملة':'HEALTH CARE · INTEGRATED CARE',100,24,true,'#087e70');text(model.title,174,48,true,'#123e43');text(`${model.number}  •  ${model.date.replace('T',' ').slice(0,19)+(model.date.endsWith('Z')?' UTC':'')}`,222,23);ctx.fillStyle='#deebe7';ctx.fillRect(100,250,1040,2);y=302}
 const wrap=(value:string,size:number)=>{ctx.font=`700 ${size}px Tahoma, Arial, sans-serif`;const lines:string[]=[];let line='';for(const word of value.split(/\s+/)){const next=line?`${line} ${word}`:word;if(ctx.measureText(next).width>1020&&line){lines.push(line);line=''}if(ctx.measureText(word).width>1020){for(const char of word){if(ctx.measureText(line+char).width>1020){lines.push(line);line=''}line+=char}}else line=line?`${line} ${word}`:word}if(line)lines.push(line);return lines}
 page()
 for(const section of model.sections){if(y>1400)page();ctx.fillStyle='#eef7f4';ctx.fillRect(84,y-30,1072,52);text(section.title,y+5,26,true,'#087e70');y+=58;for(const [label,value]of section.rows){const lines=wrap(value,25);if(y+Math.min(lines.length,3)*34+48>1580)page();text(label,y,21,false,'#617d80');y+=25;for(const line of lines){if(y>1570)page();text(line,y,25,true);y+=28}y+=6}y+=10}
 pages.forEach((p,i)=>{ctx=p.getContext('2d')!;ctx.fillStyle='#deebe7';ctx.fillRect(100,1630,1040,2);text(model.footer,1672,18,false,'#617d80');text(`${i+1} / ${pages.length}`,1710,18,false,'#617d80')})
 return pages
}
export function pharmacyPdf(pages:HTMLCanvasElement[]):Blob {
 const ascii=(s:string)=>new TextEncoder().encode(s),parts:Uint8Array[]=[ascii('%PDF-1.4\n')],offsets=[0]
 const add=(id:number,body:Uint8Array[])=>{offsets[id]=parts.reduce((n,p)=>n+p.length,0);parts.push(ascii(`${id} 0 obj\n`),...body,ascii('\nendobj\n'))}
 add(1,[ascii('<< /Type /Catalog /Pages 2 0 R >>')]);add(2,[ascii(`<< /Type /Pages /Kids [${pages.map((_,i)=>`${3+i*3} 0 R`).join(' ')}] /Count ${pages.length} >>`)])
 pages.forEach((page,i)=>{const id=3+i*3,jpeg=Uint8Array.from(atob(page.toDataURL('image/jpeg',.95).split(',')[1]),c=>c.charCodeAt(0));add(id,[ascii(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /XObject << /Im0 ${id+1} 0 R >> >> /Contents ${id+2} 0 R >>`)]);add(id+1,[ascii(`<< /Type /XObject /Subtype /Image /Width ${page.width} /Height ${page.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\nstream\n`),jpeg,ascii('\nendstream')]);const content=ascii('q\n595 0 0 842 0 0 cm\n/Im0 Do\nQ\n');add(id+2,[ascii(`<< /Length ${content.length} >>\nstream\n`),content,ascii('endstream')])})
 const xref=parts.reduce((n,p)=>n+p.length,0),count=offsets.length
 parts.push(ascii(`xref\n0 ${count}\n0000000000 65535 f \n${offsets.slice(1).map(n=>`${String(n).padStart(10,'0')} 00000 n \n`).join('')}trailer\n<< /Size ${count} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`))
 return new Blob(parts as BlobPart[],{type:'application/pdf'})
}
