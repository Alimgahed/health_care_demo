import { CareIcon } from './CareIcon'
import { useEffect, useMemo, useRef, useState } from 'react'
import { distanceKm, nearbyRehabilitation, regionLocation, type AppData, type Coordinates } from './domain'
import uaeCareBanner from './assets/geographic/uae-care-banner.png'
import abuDhabiCentre from './assets/geographic/abu-dhabi-centre.png'
import alAinCentre from './assets/geographic/al-ain-centre.png'
import dubaiCentre from './assets/geographic/dubai-centre.png'
import sharjahCentre from './assets/geographic/sharjah-centre.png'
import rasAlKhaimahCentre from './assets/geographic/ras-al-khaimah-centre.png'
import fujairahCentre from './assets/geographic/fujairah-centre.png'
import './GeographicCare.css'

type Kind='Rehabilitation'|'Pharmacy'|'Treatment center'|'Patient area'
type Point={id:string;name:string;kind:Kind;coordinates:Coordinates;area:string;emirate:string;available?:number;status?:string}
const colors:Record<Kind,string>={Rehabilitation:'#069c78',Pharmacy:'#1686ed','Treatment center':'#f39b15','Patient area':'#a72fe3'}
const centreImages:Record<string,string>={'RC-AUH':abuDhabiCentre,'RC-AIN':alAinCentre,'RC-DXB':dubaiCentre,'RC-SHJ':sharjahCentre,'RC-RAK':rasAlKhaimahCentre,'RC-FUJ':fujairahCentre}
const tileSize=256
const world=(point:Coordinates,zoom:number)=>{const scale=tileSize*2**zoom;const lat=Math.max(-85.0511,Math.min(85.0511,point.lat))*Math.PI/180;return {x:(point.lng+180)/360*scale,y:(1-Math.log(Math.tan(lat)+1/Math.cos(lat))/Math.PI)/2*scale}}
function OSMMap({points,origin,selected,onSelect,arabic}:{points:Point[];origin:Coordinates;selected:string;onSelect:(id:string)=>void;arabic:boolean}){
 const [zoom,setZoom]=useState(7),[camera,setCamera]=useState({selection:'',coordinates:{lat:25.05,lng:55.35}}),[size,setSize]=useState({width:760,height:480}),[enabled,setEnabled]=useState<Kind[]>(['Rehabilitation','Pharmacy','Treatment center','Patient area']),[full,setFull]=useState(false)
 const mapRef=useRef<HTMLDivElement>(null),drag=useRef<{x:number;y:number;center:Coordinates}|null>(null)
 useEffect(()=>{const node=mapRef.current;if(!node)return;const observer=new ResizeObserver(entries=>{const box=entries[0]?.contentRect;if(box)setSize({width:box.width,height:box.height})});observer.observe(node);return()=>observer.disconnect()},[])
 const selectedPoint=points.find(point=>point.id===selected)
 const center=selected!==camera.selection&&selectedPoint?selectedPoint.coordinates:camera.coordinates
 const setCenter=(coordinates:Coordinates)=>setCamera({selection:selected,coordinates})
 const centerWorld=world(center,zoom)
 const startX=Math.floor((centerWorld.x-size.width/2)/tileSize),endX=Math.ceil((centerWorld.x+size.width/2)/tileSize)
 const startY=Math.floor((centerWorld.y-size.height/2)/tileSize),endY=Math.ceil((centerWorld.y+size.height/2)/tileSize)
 const tiles=[];for(let x=startX;x<=endX;x++)for(let y=startY;y<=endY;y++)if(x>=0&&y>=0&&x<2**zoom&&y<2**zoom)tiles.push({x,y,left:x*tileSize-centerWorld.x+size.width/2,top:y*tileSize-centerWorld.y+size.height/2})
 const position=(p:Coordinates)=>{const xy=world(p,zoom);return {left:xy.x-centerWorld.x+size.width/2,top:xy.y-centerWorld.y+size.height/2}}
 const visible=points.filter(point=>enabled.includes(point.kind))
 const fitNetwork=()=>{
  if(!visible.length)return
  const projected=visible.map(point=>world(point.coordinates,0))
  const minX=Math.min(...projected.map(p=>p.x)),maxX=Math.max(...projected.map(p=>p.x)),minY=Math.min(...projected.map(p=>p.y)),maxY=Math.max(...projected.map(p=>p.y))
  const scale=Math.min(Math.max(1,size.width-100)/Math.max(.01,maxX-minX),Math.max(1,size.height-160)/Math.max(.01,maxY-minY))
  setZoom(Math.max(5,Math.min(11,Math.floor(Math.log2(scale)))))
  setCenter({lng:(minX+maxX)/2/tileSize*360-180,lat:Math.atan(Math.sinh(Math.PI*(1-2*(minY+maxY)/2/tileSize)))*180/Math.PI})
 }
 const pan=(dx:number,dy:number)=>{const scale=tileSize*2**zoom;const w=world(center,zoom);const x=w.x+dx,y=w.y+dy;setCenter({lng:x/scale*360-180,lat:Math.atan(Math.sinh(Math.PI*(1-2*y/scale)))*180/Math.PI})}
 const layerLabel=(kind:Kind)=>arabic?({Rehabilitation:'مراكز التأهيل',Pharmacy:'الصيدليات','Treatment center':'مراكز العلاج','Patient area':'نطاق المريض'} as Record<Kind,string>)[kind]:kind
 return <div className={`geo-map-shell ${full?'geo-map-full':''}`}><div className="geo-map-head"><div><h2>{arabic?'شبكة الرعاية في الإمارات':'UAE care network'}</h2><p>{arabic?'استكشف مراكز التأهيل والعلاج والصيدليات على خريطة حقيقية.':'Explore rehabilitation, treatment centres and pharmacies on a real map.'}</p></div><button onClick={()=>setFull(!full)}>{full?(arabic?'تصغير':'Exit full screen'):(arabic?'ملء الشاشة':'Full screen')} ⤢</button></div><div className="geo-map-canvas" ref={mapRef} onPointerDown={event=>{if((event.target as HTMLElement).closest('button,a,input,label'))return;drag.current={x:event.clientX,y:event.clientY,center};event.currentTarget.setPointerCapture(event.pointerId)}} onPointerMove={event=>{if(!drag.current)return;const scale=tileSize*2**zoom;const w=world(drag.current.center,zoom);const x=w.x+drag.current.x-event.clientX,y=w.y+drag.current.y-event.clientY;setCenter({lng:x/scale*360-180,lat:Math.atan(Math.sinh(Math.PI*(1-2*y/scale)))*180/Math.PI})}} onPointerUp={()=>{drag.current=null}} onPointerCancel={()=>{drag.current=null}}>
   {tiles.map(tile=><img key={`${zoom}-${tile.x}-${tile.y}`} className="geo-tile" src={`https://tile.openstreetmap.org/${zoom}/${tile.x}/${tile.y}.png`} alt="" draggable={false} loading="lazy" style={{left:tile.left,top:tile.top}}/>)}
   {origin&&<div className="geo-patient-radius" style={position(origin)}/>}
   {visible.map(point=>{const spot=position(point.coordinates);return <button key={point.id} type="button" className={`geo-marker ${selected===point.id?'selected':''}`} title={`${point.name} · ${point.area}`} aria-label={`${layerLabel(point.kind)}: ${point.name}`} style={{left:spot.left,top:spot.top,background:colors[point.kind]}} onClick={()=>{onSelect(point.id);setCenter(point.coordinates)}}><CareIcon name={point.kind==='Patient area'?'Patients':point.kind==='Pharmacy'?'Medication':point.kind==='Treatment center'?'building':'Rehabilitation'}/></button>})}
   {selectedPoint&&enabled.includes(selectedPoint.kind)&&<div className="geo-selected-pin" style={position(selectedPoint.coordinates)}>{selectedPoint.name}</div>}
   <div className="geo-layers">{(Object.keys(colors) as Kind[]).map(kind=><label key={kind}><input type="checkbox" checked={enabled.includes(kind)} onChange={()=>setEnabled(list=>list.includes(kind)?list.filter(item=>item!==kind):[...list,kind])}/><i style={{background:colors[kind]}}/>{layerLabel(kind)}</label>)}</div>
   <div className="geo-map-tools"><button aria-label={arabic?'عرض جميع المواقع':'Fit all locations'} title={arabic?'عرض جميع المواقع':'Fit all locations'} onClick={fitNetwork}>⤢</button><button aria-label={arabic?'تكبير':'Zoom in'} onClick={()=>setZoom(Math.min(11,zoom+1))}><CareIcon name="plus"/></button><button aria-label={arabic?'تصغير':'Zoom out'} onClick={()=>setZoom(Math.max(5,zoom-1))}>−</button><button aria-label={arabic?'موقع المريض':'Center patient'} onClick={()=>setCenter(origin)}><CareIcon name="pin"/></button></div>
   <div className="geo-map-count">{arabic?'عرض':'Showing'} {visible.length} {arabic?'موقعًا':'locations'}</div><a className="geo-attribution" href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">© OpenStreetMap contributors</a>
  </div><div className="geo-map-bottom"><span>{arabic?'مواقع تجريبية تقريبية · لا تُعرض عناوين المرضى الدقيقة':'Approximate demo locations · no exact patient addresses'}</span><div><button onClick={()=>pan(-100,0)}>←</button><button onClick={()=>pan(0,-100)}>↑</button><button onClick={()=>pan(0,100)}>↓</button><button onClick={()=>pan(100,0)}>→</button></div></div></div>
}
export function GeographicCareNetwork({data,arabic=false}:{data:AppData;arabic?:boolean}){
 const [patientId,setPatientId]=useState(data.patients.find(p=>p.id==='P001')?.id??data.patients[0]?.id??'')
 const [draftEmirate,setDraftEmirate]=useState('All'),[draftKind,setDraftKind]=useState('All'),[emirate,setEmirate]=useState('All'),[kind,setKind]=useState('All'),[selected,setSelected]=useState(''),[showAll,setShowAll]=useState(false)
 const patient=data.patients.find(p=>p.id===patientId)
 const origin=patient?.location??regionLocation(patient?.emirate??'Abu Dhabi')
 const rehab=nearbyRehabilitation(data,patientId)
 const points=useMemo<Point[]>(()=>[
  ...(data.rehabilitationCentres??[]).map(c=>({id:c.id,name:c.name,kind:'Rehabilitation',coordinates:c.coordinates,area:c.area,emirate:c.emirate,status:c.status,available:rehab.find(item=>item.id===c.id)?.availableSlots} as Point)),
  ...data.centres.map(c=>({id:c.id,name:c.name,kind:c.name.includes('Pharmacy')?'Pharmacy':'Treatment center',coordinates:c.coordinates??regionLocation(c.emirate),area:c.location,emirate:c.emirate,status:c.status} as Point)),
  ...data.centres.filter(c=>Boolean(c.pharmacy)&&c.pharmacy!==c.name).map(c=>({id:`PH-${c.id}`,name:c.pharmacy,kind:'Pharmacy',coordinates:{lat:(c.coordinates??regionLocation(c.emirate)).lat-.025,lng:(c.coordinates??regionLocation(c.emirate)).lng+.025},area:c.location,emirate:c.emirate,status:c.status} as Point)),
  {id:`PAT-${patientId}`,name:arabic?patient?.nameAr??patient?.name??patientId:patient?.name??patientId,kind:'Patient area',coordinates:origin,area:patient?.area??patient?.emirate??'',emirate:patient?.emirate??''} as Point
 ],[data.rehabilitationCentres,data.centres,rehab,patientId,patient,origin,arabic])
 const shown=points.filter(p=>p.kind==='Patient area'||(emirate==='All'||p.emirate===emirate)&&(kind==='All'||p.kind===kind))
 const listed=shown.filter(p=>p.kind==='Rehabilitation').sort((a,b)=>distanceKm(origin,a.coordinates)-distanceKm(origin,b.coordinates))
 const active=points.filter(p=>p.kind!=='Patient area'&&p.status==='Active')
 const nearest=active.filter(p=>p.kind==='Rehabilitation').sort((a,b)=>distanceKm(origin,a.coordinates)-distanceKm(origin,b.coordinates))[0]
 const average=active.length?active.reduce((sum,p)=>sum+distanceKm(origin,p.coordinates),0)/active.length:0
 const emirates=[...new Set(points.filter(p=>p.kind!=='Patient area').map(p=>p.emirate))].sort()
 const labelKind=(value:Kind)=>arabic?({Rehabilitation:'تأهيل',Pharmacy:'صيدلية','Treatment center':'مركز علاج','Patient area':'موقع المريض'} as Record<Kind,string>)[value]:value
 return <div className="geo-page" dir={arabic?'rtl':'ltr'}><div className="geo-hero"><img className="geo-hero-image" src={uaeCareBanner} alt="" aria-hidden="true"/><div className="geo-crumb">{arabic?'البرنامج / التحليلات الجغرافية':'Programme / Geographic analytics'}</div><div className="geo-hero-main"><div><span>{arabic?'رؤى لرعاية أفضل':'Insights for better care'}</span><h1>{arabic?'التحليلات الجغرافية':'Geographic analytics'}</h1><p>{arabic?'اكتشف مراكز التأهيل والصيدليات ومراكز العلاج القريبة من موقع المريض المسجل.':'Find nearby rehabilitation, pharmacies and treatment centres from the shared care record.'}</p></div></div></div>
 <div className="geo-stats"><article><i><CareIcon name="building"/></i><div><small>{arabic?'إجمالي المراكز':'Total centres'}</small><b>{points.filter(p=>p.kind!=='Patient area').length}</b><span>{arabic?'في شبكة الرعاية':'Across the network'}</span></div></article><article><i><CareIcon name="building"/></i><div><small>{arabic?'المراكز النشطة':'Active centres'}</small><b>{active.length}</b><span>{arabic?'متاحة حاليًا':'Currently available'}</span></div></article><article><i><CareIcon name="pin"/></i><div><small>{arabic?'أقرب مركز':'Nearest centre'}</small><b>{nearest?distanceKm(origin,nearest.coordinates).toFixed(1):'—'} {arabic?'كم':'km'}</b><span>{nearest?.area??'—'}</span></div></article><article><i><CareIcon name="pin"/></i><div><small>{arabic?'متوسط المسافة':'Average distance'}</small><b>{average.toFixed(1)} {arabic?'كم':'km'}</b><span>{arabic?'لكل المراكز النشطة':'For active centres'}</span></div></article></div>
 <div className="geo-filters"><label>{arabic?'موقع المريض':'Patient location'}<select value={patientId} onChange={e=>{setPatientId(e.target.value);setSelected('')}}>{data.patients.map(p=><option key={p.id} value={p.id}>{arabic?p.nameAr??p.name:p.name} · {p.id} · {p.emirate}</option>)}</select></label><label>{arabic?'الإمارة':'Emirate'}<select value={draftEmirate} onChange={e=>setDraftEmirate(e.target.value)}><option value="All">{arabic?'جميع الإمارات':'All emirates'}</option>{emirates.map(value=><option key={value}>{value}</option>)}</select></label><label>{arabic?'نوع المركز':'Centre type'}<select value={draftKind} onChange={e=>setDraftKind(e.target.value)}><option value="All">{arabic?'جميع الأنواع':'All types'}</option>{(['Rehabilitation','Pharmacy','Treatment center'] as Kind[]).map(value=><option value={value} key={value}>{labelKind(value)}</option>)}</select></label><button onClick={()=>{setEmirate(draftEmirate);setKind(draftKind);setSelected('')}}>☷ {arabic?'تطبيق الفلاتر':'Apply filters'}</button></div>
 <div className="geo-content"><OSMMap key={patientId} points={shown} origin={origin} selected={selected} onSelect={setSelected} arabic={arabic}/><aside className="geo-nearby"><header><div><h2>{arabic?'مراكز التأهيل القريبة':'Nearby rehabilitation'}</h2><p>{arabic?'مرتبة حسب المسافة من موقع المريض التقريبي.':'Sorted by distance from the approximate patient location.'}</p></div><button onClick={()=>setShowAll(!showAll)}>{showAll?arabic?'عرض أقل':'Show less':arabic?'عرض الكل':'View all'} →</button></header><div className="geo-nearby-list">{listed.slice(0,showAll?undefined:4).map(c=><button className={`geo-centre ${selected===c.id?'selected':''}`} key={c.id} onClick={()=>setSelected(c.id)}><span className="geo-centre-art"><img src={centreImages[c.id]??abuDhabiCentre} alt="" loading="lazy"/></span><span className="geo-centre-copy"><b>{c.name}</b><em>{labelKind(c.kind)}</em><small>{c.area} · {c.emirate}</small><small className="geo-places">● {c.available??0} {arabic?'أماكن متاحة':'available places'}</small></span><span className="geo-centre-distance">{distanceKm(origin,c.coordinates).toFixed(1)} {arabic?'كم':'km'}<strong>›</strong></span></button>)}{!listed.length&&<p className="geo-no-results">{arabic?'لا توجد مراكز تأهيل تطابق الفلاتر.':'No rehabilitation centres match the filters.'}</p>}</div></aside></div></div>
}
