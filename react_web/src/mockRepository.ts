import { initializeCareEcosystem, canonicalize, regionLocation, seed, type AppData } from './domain'

const CURRENT_STORAGE_KEY = 'healthcare-state-v7'
const LEGACY_STORAGE_KEYS = ['healthcare-state-v6', 'healthcare-state-v5', 'healthcare-state-v4', 'healthcare-state-v3']

type SavedData = Partial<AppData> & { stock?: Record<string, number> }

function mergeById<T extends { id: string }>(base: T[], saved?: T[]) {
  const merged = base.map(item => ({ ...item, ...saved?.find(savedItem => savedItem.id === item.id) }))
  return [...merged, ...(saved ?? []).filter(item => !base.some(baseItem => baseItem.id === item.id))]
}

/** Backfill the original demo directory without resetting edited or newly added records. */
function mergeDirectory<T extends { id: string; status: string; contractStatus?: string }>(base: T[], saved?: T[]): T[] {
  return mergeById(base, saved).map(item => {
    const defaults = base.find(record => record.id === item.id)
    const previous = saved?.find(record => record.id === item.id)
    if (!defaults || !previous) return item
    const result: Record<string, unknown> = { ...item }
    for (const [key, value] of Object.entries(defaults)) {
      if (result[key] == null || result[key] === '' || (Array.isArray(result[key]) && result[key].length === 0)) result[key] = value
    }
    if (!previous.contractStatus) result.contractStatus = previous.status === 'Active' ? 'Active' : 'Suspended'
    // Earlier fixtures stored an email in the telephone field and emirate centroids as centre locations.
    const old = previous as T & { contact?: string; coordinates?: { lat: number; lng: number }; emirate?: string; contractReference?: string }
    const baseline = defaults as typeof old
    if (old.contact?.endsWith('@example.test') && old.contact === (item.id.startsWith('CTR-') ? `${item.id.toLowerCase()}@example.test` : (defaults as T & {email?: string}).email)) result.contact = baseline.contact
    const centroid = item.id === 'CTR-AIN-01' ? { lat: 24.233, lng: 55.737 } : regionLocation(old.emirate ?? '')
    if (item.id.startsWith('CTR-') && !old.contractReference && old.coordinates?.lat === centroid.lat && old.coordinates?.lng === centroid.lng) result.coordinates = baseline.coordinates
    return result as T
  })
}

/** Browser-only POC repository boundary. Replace this adapter with API calls when a backend is introduced. */
export function loadMockData(): AppData {
  try {
    const currentRaw = localStorage.getItem(CURRENT_STORAGE_KEY)
    const raw = currentRaw ?? LEGACY_STORAGE_KEYS.map(key => localStorage.getItem(key)).find(Boolean)
    if (!raw) return structuredClone(seed)
    const saved = JSON.parse(raw) as SavedData
    const savedOrganizationState = Boolean(saved.doctors && saved.centres)
    const batches = saved.batches?.length
      ? mergeById(seed.batches, saved.batches)
      : seed.batches.map(batch => ({ ...batch, quantity: saved.stock?.[batch.dose] ?? batch.quantity }))
    const patients = mergeById(seed.patients, saved.patients).map(merged => {
      const savedPatient=saved.patients?.find(patient=>patient.id===merged.id)
      const legacyIndex=Number(merged.id.slice(1))-10
      const baselinePatient=seed.patients.find(patient=>patient.id===merged.id)
      const repairSex=legacyIndex>=0&&legacyIndex<41&&!savedPatient?.demoPortrait&&savedPatient?.name===baselinePatient?.name
      const item=repairSex?{...merged,sex:baselinePatient!.sex}:merged
      const baseline = seed.patients.find(patient => patient.id === item.id)
      if (item.id==='P001' && !saved.careWorkflowVersion) return {...item,registeredAt:item.registeredAt??baseline?.registeredAt,residency:'Resident' as const,nationality:'Jordanian',assignedDoctor:'Dr. Laila Hassan',doctorId:'DOC-001'}
      return baseline ? { ...item, registeredAt:item.registeredAt??baseline.registeredAt, assignedDoctor: savedOrganizationState ? item.assignedDoctor ?? baseline.assignedDoctor : baseline.assignedDoctor, treatmentCentre: savedOrganizationState ? item.treatmentCentre ?? baseline.treatmentCentre : baseline.treatmentCentre } : item
    })
    const treatmentPlans = mergeById(seed.treatmentPlans, saved.treatmentPlans).map(item => {
      const baseline = seed.treatmentPlans.find(plan => plan.id === item.id)
      // Repair the immutable demonstration history without replacing edited current plans.
      if (item.id === 'TP-P999-HISTORY' && item.status === 'Completed' && item.dose === '10 mg' && saved.requests?.find(request=>request.planId===item.id)?.dose === '5 mg') return { ...item, dose: '5 mg' }
      return baseline && !currentRaw ? { ...item, ...baseline, status: item.status } : item
    })
    const labs = mergeById(seed.labs, !currentRaw ? saved.labs?.filter(item=>item.id !== 'LB-P006-A1C') : saved.labs).map(item => {
      const baseline = seed.labs.find(lab => lab.id === item.id)
      return baseline && !currentRaw ? { ...item, ...baseline } : item
    })
    const notifications = mergeById(seed.notifications, saved.notifications).map(item => {
      const baseline = seed.notifications.find(notification => notification.id === item.id)
      return baseline ? { ...item, patientId: baseline.patientId, relatedEntity: baseline.relatedEntity, relatedEntityId: baseline.relatedEntityId } : item
    })
    return canonicalize(initializeCareEcosystem({
      careWorkflowVersion: saved.careWorkflowVersion,
      manualAlerts: saved.manualAlerts ?? [],
      savedReports: saved.savedReports ?? [],
      activityEventStates: saved.activityEventStates ?? {},
      reportSchedules: mergeById(seed.reportSchedules ?? [], saved.reportSchedules),
      activePatientId:saved.activePatientId,
      activeDoctorId:saved.activeDoctorId??seed.activeDoctorId,
      integratedCarePlans: saved.integratedCarePlans,
      rehabilitationCentres: mergeDirectory(seed.rehabilitationCentres ?? [],saved.rehabilitationCentres),
      rehabilitationPrograms: mergeById(seed.rehabilitationPrograms ?? [],saved.rehabilitationPrograms),
      homeExercises: mergeById(seed.homeExercises ?? [],saved.homeExercises),
      pharmacists: mergeById(seed.pharmacists ?? [], saved.pharmacists),
      supplyRequests: saved.supplyRequests ?? [],
      medications: mergeById(seed.medications ?? [], saved.medications),
      emirates: mergeById(seed.emirates ?? [], saved.emirates),
      carePrograms: mergeById(seed.carePrograms ?? [], saved.carePrograms),
      documents: mergeById(seed.documents ?? [], saved.documents),
      patients,
      doctors: mergeDirectory(seed.doctors, saved.doctors),
      reviewers: mergeById(seed.reviewers, saved.reviewers),
      centres: mergeDirectory(seed.centres, saved.centres),
      abuseReviews: saved.abuseReviews ?? [],
      requests: mergeById(seed.requests, saved.requests),
      treatmentPlans,
      dispenses: mergeById(seed.dispenses, saved.dispenses),
      audit: mergeById(seed.audit, saved.audit),
      doses: mergeById(seed.doses, saved.doses),
      financial: mergeById(seed.financial, saved.financial),
      payments: saved.payments ?? [],
      notifications,
      vitals: mergeById(seed.vitals, saved.vitals),
      labs,
      assessments: mergeById(seed.assessments, saved.assessments),
      appointments: mergeById(seed.appointments, saved.appointments),
      exercise: mergeById(seed.exercise, saved.exercise),
      batches,
      movements: mergeById(seed.movements, saved.movements),
      dismissedAlerts: saved.dismissedAlerts ?? [],
      readAlerts: saved.readAlerts ?? [],
    }))
  } catch {
    return structuredClone(seed)
  }
}

export function saveMockData(data: AppData) {
  localStorage.setItem(CURRENT_STORAGE_KEY, JSON.stringify(data))
}

/** Simulates local repository latency, without fetching or duplicating mock records. */
export function readMockWorkspace(workspace: string, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const abort = () => { clearTimeout(timer); reject(new DOMException('Read cancelled', 'AbortError')) }
    const delay = workspace.includes('assistant') ? 520 : 320
    const timer = setTimeout(() => { signal?.removeEventListener('abort', abort); resolve() }, delay)
    if (signal?.aborted) abort()
    else signal?.addEventListener('abort', abort, { once: true })
  })
}

/** Keep other open portals in sync with the same persisted demo model. */
export function subscribeMockData(onChange:(data:AppData)=>void) {
 const listener=(event:StorageEvent)=>{if(event.storageArea===localStorage&&event.key===CURRENT_STORAGE_KEY&&event.newValue)onChange(loadMockData())}
 window.addEventListener('storage',listener)
 return ()=>window.removeEventListener('storage',listener)
}
