import {canReadPatient,type AppData,type Role} from './domain'
import {misuseSignals} from './adminAnalytics'
import {alertsWorkspaceData} from './alertsWorkspaceData'
export function navigationBadges(data:AppData,role:Role):Record<string,number>{
 const requests=data.requests.filter(r=>canReadPatient(data,role,r.patientId))
 return {
  'Treatment requests':requests.filter(r=>role==='Doctor'?r.status==='Needs information':r.status==='Under review').length,
  Dispensing:requests.filter(r=>r.status==='Ready to dispense').length,
  Alerts:alertsWorkspaceData(data,role).filter(r=>r.state!=='Handled').length,
  'Activity log':role==='Admin'?data.audit.filter(r=>!data.activityEventStates?.[r.id]?.read).length:0,
  'Misuse prevention':role==='Admin'?misuseSignals(data).filter(r=>!['Resolved','Dismissed'].includes(data.abuseReviews.find(review=>review.id===r.id)?.status??'New')).length:0,
 }
}
