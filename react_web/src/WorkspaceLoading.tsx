import { useEffect, useState, type ReactNode } from 'react'
import { readMockWorkspace } from './mockRepository'
import './WorkspaceLoading.css'

import { skeletonFor, type SkeletonKind } from './workspacePresentation'
export function Skeleton({kind='table', arabic=false}: {kind?:SkeletonKind;arabic?:boolean}) {
 return <section className={`workspace-skeleton skeleton-${kind}`} role="status" aria-live="polite" aria-busy="true" aria-label={arabic?'جارٍ تحميل السجلات':'Loading records'}>
  <span className="sr-only">{arabic?'جارٍ تجهيز بيانات مساحة العمل…':'Preparing workspace records…'}</span>
  <div aria-hidden="true"><div className="sk-heading"><i className="shimmer sk-title"/><i className="shimmer sk-subtitle"/></div>
  <div className="sk-kpis">{Array.from({length:4},(_,i)=><div className="sk-card" key={i}><i className="shimmer sk-circle"/><div><i className="shimmer sk-label"/><i className="shimmer sk-number"/></div></div>)}</div>
  {kind==='dashboard'||kind==='map'?<div className="sk-panels"><div className={`sk-card sk-chart ${kind==='map'?'sk-map':''}`}>{[40,65,48,82,58,95].map((h,i)=><i key={i} className="shimmer" style={{height:`${h}%`}}/>)}</div><div className="sk-card sk-list">{Array.from({length:5},(_,i)=><i key={i} className="shimmer sk-row"/>)}</div></div>:<div className="sk-card sk-list">{Array.from({length:kind==='assistant'?3:6},(_,i)=><div className="sk-record" key={i}>{kind!=='table'&&<i className="shimmer sk-circle"/>}<i className="shimmer sk-row"/><i className="shimmer sk-label"/></div>)}</div>}
  </div>
 </section>
}
/** Only gates navigation; data continues to come from the live canonical AppData. */
export function WorkspaceLoading({workspace,arabic,children}:{workspace:string;arabic:boolean;children:ReactNode}) {
 const [loaded,setLoaded]=useState('')
 const [failed,setFailed]=useState(false)
 const [attempt,setAttempt]=useState(0)
 useEffect(()=>{
  const controller=new AbortController()
  readMockWorkspace(workspace,controller.signal).then(()=>{setLoaded(workspace);setFailed(false)}).catch(error=>{if(error.name!=='AbortError')setFailed(true)})
  return ()=>controller.abort()
 },[workspace,attempt])
 if(failed)return <section className="panel empty-state" role="alert"><h2>{arabic?'تعذر تحميل مساحة العمل':'Unable to load workspace'}</h2><button onClick={()=>{setFailed(false);setAttempt(n=>n+1)}}>{arabic?'إعادة المحاولة':'Try again'}</button></section>
 return loaded===workspace?children:<Skeleton kind={skeletonFor(workspace)} arabic={arabic}/>
}
