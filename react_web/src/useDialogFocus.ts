import { useEffect, useRef } from 'react'

/** Keep keyboard navigation inside a dialog and restore the invoking control. */
export function useDialogFocus(open: boolean, onClose: () => void) {
 const ref=useRef<HTMLElement>(null)
 const close=useRef(onClose)
 useEffect(()=>{close.current=onClose},[onClose])
 useEffect(()=>{
  if(!open||!ref.current)return
  const dialog=ref.current
  const previous=document.activeElement as HTMLElement|null
  const controls=()=>Array.from(dialog.querySelectorAll<HTMLElement>('button:not(:disabled),input:not(:disabled),select:not(:disabled),textarea:not(:disabled),a[href],[tabindex="0"]')).filter(el=>el.getClientRects().length>0)
  controls()[0]?.focus()
  const keydown=(event:KeyboardEvent)=>{
   if(event.key==='Escape'){event.preventDefault();event.stopPropagation();close.current()}
   if(event.key==='Tab'){
    const items=controls();const first=items[0];const last=items.at(-1)
    if(!first){event.preventDefault();return}
    if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus()}
    else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus()}
   }
  }
  dialog.addEventListener('keydown',keydown)
  return ()=>{dialog.removeEventListener('keydown',keydown);if(previous?.isConnected)previous.focus()}
 },[open])
 return ref
}
