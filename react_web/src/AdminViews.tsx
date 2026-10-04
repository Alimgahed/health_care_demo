import { CareIcon } from './CareIcon'
import { PatientAvatar } from './PatientAvatar'
import { useState } from 'react'
import { calculateEligibility, inventoryByDose, type AbuseReviewRecord, type AppData } from './domain'
import { misuseSignals, operationalAlerts, reviewStateFor, type AdminPage, type MisuseSignal } from './adminAnalytics'

type Navigate = (page: AdminPage, selection?: string) => void
const requestPage: AdminPage = 'Treatment requests'
const patientPage: AdminPage = 'Patients'
const inventoryPage: AdminPage = 'Inventory'
const toneFor = (severity: string) => severity.toLowerCase()

function Metric({ label, value, note, onClick, tone = 'blue' }: { label: string; value: string | number; note: string; onClick?: () => void; tone?: string }) {
  const content = <><span className={`admin-metric-mark ${tone}`}/><span className="admin-metric-copy"><small>{label}</small><b>{value}</b><em>{note}</em></span></>
  return onClick ? <button className="admin-metric panel" onClick={onClick}>{content}<span className="admin-metric-open">›</span></button> : <article className="admin-metric panel">{content}</article>
}

function StatusTrack({ data, onNavigate }: { data: AppData; onNavigate: Navigate }) {
  const rows: { label: string; count: number; page: AdminPage; tone: string }[] = [
    { label: 'Draft', count: data.requests.filter(item => item.status === 'Draft').length, page: requestPage, tone: 'quiet' },
    { label: 'Submitted', count: data.audit.filter(item => item.action === 'Request submitted').length, page: requestPage, tone: 'blue' },
    { label: 'Under review', count: data.requests.filter(item => item.status === 'Under review').length, page: requestPage, tone: 'blue' },
    { label: 'Needs information', count: data.requests.filter(item => item.status === 'Needs information').length, page: requestPage, tone: 'amber' },
    { label: 'Approved', count: data.requests.filter(item => item.status === 'Approved').length, page: requestPage, tone: 'green' },
    { label: 'Rejected', count: data.requests.filter(item => item.status === 'Rejected').length, page: requestPage, tone: 'red' },
    { label: 'Pharmacy ready', count: data.requests.filter(item => item.status === 'Ready to dispense').length, page: requestPage, tone: 'green' },
    { label: 'Dispensed', count: data.dispenses.length, page: 'Distribution portal', tone: 'green' },
    { label: 'Completed', count: data.treatmentPlans.filter(item => item.status === 'Completed').length, page: 'Doctor portal', tone: 'quiet' },
  ]
  const peak = Math.max(1, ...rows.map(item => item.count))
  return <div className="admin-status-list">{rows.map(item => <button key={item.label} onClick={() => onNavigate(item.page)}><span>{item.label}</span><span className="admin-status-track"><i className={item.tone} style={{ width: `${item.count / peak * 100}%` }}/></span><b>{item.count}</b></button>)}</div>
}

export function AdminCommandDashboard({ data, onNavigate }: { data: AppData; onNavigate: Navigate }) {
  const alerts = operationalAlerts(data).filter(item => !(data.dismissedAlerts ?? []).includes(item.id))
  const stock = inventoryByDose(data)
  const pending = data.requests.filter(item => ['Under review', 'Needs information'].includes(item.status)).length
  const approved = data.requests.filter(item => ['Approved', 'Ready to dispense', 'Dispensed'].includes(item.status)).length
  const measures = [
    ['Total patients', data.patients.length, 'Shared patient registry', patientPage, 'blue'],
    ['Active treatments', data.patients.filter(item => item.treatmentStatus === 'Active').length, 'Current active plans', 'Doctor portal', 'green'],
    ['Pending requests', pending, 'Review and evidence queue', requestPage, 'amber'],
    ['Under review', data.requests.filter(item => item.status === 'Under review').length, 'Awaiting reviewer decision', requestPage, 'blue'],
    ['Approved', approved, 'Approved or handed to pharmacy', requestPage, 'green'],
    ['Rejected', data.requests.filter(item => item.status === 'Rejected').length, 'Current request status', requestPage, 'red'],
    ['Needs information', data.requests.filter(item => item.status === 'Needs information').length, 'Returned to care team', requestPage, 'amber'],
    ['Pharmacy ready', data.requests.filter(item => item.status === 'Ready to dispense').length, 'Awaiting safety verification', 'Distribution portal', 'green'],
    ['Dispensed', data.dispenses.length, 'Recorded transactions', 'Distribution portal', 'green'],
    ['Completed treatments', data.treatmentPlans.filter(item => item.status === 'Completed').length, 'Plans marked complete', 'Doctor portal', 'blue'],
    ['Active doctors', data.doctors.filter(item => item.status === 'Active').length, 'Programme directory', 'Doctor management', 'blue'],
    ['Active reviewers', data.reviewers.filter(item => item.status === 'Active').length, 'Clinical review team', 'Treatment requests', 'violet'],
    ['Treatment centres', data.centres.filter(item => item.status === 'Active').length, 'Open participating sites', 'Treatment center management', 'blue'],
    ['Inventory items', new Set(data.batches.map(item => item.dose)).size, 'Medication strengths held', inventoryPage, 'blue'],
    ['Low stock items', Object.values(stock).filter(value => value < 12).length, 'Below reorder point', inventoryPage, 'amber'],
    ['Expiring batches', alerts.filter(item => /batch expiring|expired medication batch/i.test(item.title)).length, 'Within 60 days or expired', 'Alerts', 'amber'],
    ['Safety alerts', alerts.filter(item => item.category === 'Safety' || item.category === 'Clinical').length, 'Current rule-based signals', 'Alerts', 'red'],
    ['Unresolved alerts', alerts.length, 'Open operational signals', 'Alerts', 'amber'],
  ] as const
  const recent = data.audit.slice().sort((a, b) => (b.occurredAt ?? '').localeCompare(a.occurredAt ?? '')).slice(0, 7)
  return <div className="admin-view-stack">
    <section className="admin-kpi-grid">{measures.map(([label, value, note, page, tone]) => <Metric key={label} label={label} value={value} note={note} tone={tone} onClick={() => onNavigate(page)}/>)}</section>
    <div className="admin-command-grid">
      <section className="panel admin-section"><div className="admin-section-heading"><div><span className="admin-section-kicker">Treatment pathway</span><h2>Request lifecycle</h2><p>Counts are calculated from current programme requests and records.</p></div><button className="text-link" onClick={() => onNavigate(requestPage)}>Open requests ›</button></div><StatusTrack data={data} onNavigate={onNavigate}/></section>
      <section className="panel admin-section"><div className="admin-section-heading"><div><span className="admin-section-kicker">Operational stream</span><h2>Recent programme activity</h2><p>State changes recorded across care teams.</p></div><button className="text-link" onClick={() => onNavigate('Activity log')}>Live log ›</button></div>{recent.length ? <div className="admin-feed">{recent.map(item => <article key={item.id}><span className={`admin-feed-dot ${toneFor(item.actor)}`}/><div><b>{item.action}</b><small>{item.detail}</small><em>{item.actor} · {item.entity} · {item.entityId}</em></div><time>{item.time}</time></article>)}</div> : <div className="empty-state"><b>No activity recorded</b><span>Care team actions will appear here.</span></div>}</section>
    </div>
    <section className="admin-portal-strip"><div><span className="admin-section-kicker">Connected workspaces</span><h2>Care teams work from the same patient and inventory records.</h2></div><button onClick={() => onNavigate('Doctor portal')}>Doctor portal <span>›</span></button><button onClick={() => onNavigate('Distribution portal')}>Distribution portal <span>›</span></button><button onClick={() => onNavigate('Patient portal')}>Patient portal <span>›</span></button></section>
  </div>
}

export function GeographicAnalytics({ data, onNavigate }: { data: AppData; onNavigate: Navigate }) {
  const [emirate, setEmirate] = useState('All')
  const [centre, setCentre] = useState('All')
  const alertRows = operationalAlerts(data)
  const filteredCentres = data.centres.filter(item => (emirate === 'All' || item.emirate === emirate) && (centre === 'All' || item.name === centre))
  const centreStats = filteredCentres.map(site => {
    const patients = data.patients.filter(item => item.treatmentCentre === site.name)
    const patientIds = new Set(patients.map(item => item.id))
    const requests = data.requests.filter(item => patientIds.has(item.patientId))
    const onHand = data.batches.filter(item => item.centre === site.name && item.expiry > new Date().toISOString().slice(0, 10)).reduce((sum, item) => sum + item.quantity, 0)
    const reserved = requests.filter(item => item.status === 'Ready to dispense').length
    const siteAlerts = alertRows.filter(item => (item.patientId && patientIds.has(item.patientId)) || data.batches.some(batch => batch.centre === site.name && item.entityId === batch.id)).length
    return { site, patients, patientIds, requests, onHand, available: Math.max(0, onHand - reserved), active: patients.filter(item => item.treatmentStatus === 'Active').length, pending: requests.filter(item => ['Under review', 'Needs information'].includes(item.status)).length, approved: requests.filter(item => ['Approved', 'Ready to dispense'].includes(item.status)).length, dispensed: data.dispenses.filter(item => item.centre === site.name).length, alerts: siteAlerts }
  })
  const totals = centreStats.reduce((sum, item) => ({ patients: sum.patients + item.patients.length, active: sum.active + item.active, pending: sum.pending + item.pending, dispensed: sum.dispensed + item.dispensed, stock: sum.stock + item.available, alerts: sum.alerts + item.alerts }), { patients: 0, active: 0, pending: 0, dispensed: 0, stock: 0, alerts: 0 })
  const emirateRows = [...new Set(data.centres.map(item => item.emirate))].filter(name => emirate === 'All' || name === emirate).map(name => ({ name, patients: data.patients.filter(item => item.emirate === name).length, centres: data.centres.filter(item => item.emirate === name).length, active: data.patients.filter(item => item.emirate === name && item.treatmentStatus === 'Active').length })).sort((a, b) => b.patients - a.patients)
  return <div className="admin-view-stack">
    <div className="admin-filter-bar"><label>Emirate<select value={emirate} onChange={event => { setEmirate(event.target.value); setCentre('All') }}><option>All</option>{[...new Set(data.centres.map(item => item.emirate))].map(item => <option key={item}>{item}</option>)}</select></label><label>Treatment centre<select value={centre} onChange={event => setCentre(event.target.value)}><option>All</option>{data.centres.filter(item => emirate === 'All' || item.emirate === emirate).map(item => <option key={item.id}>{item.name}</option>)}</select></label><span>Mock programme geography · not national health statistics</span></div>
    <section className="executive-kpis"><Metric label="Patients in scope" value={totals.patients} note="Current patient profiles"/><Metric label="Active treatments" value={totals.active} note="Active patient plans" tone="green"/><Metric label="Pending requests" value={totals.pending} note="Review or evidence needed" tone="amber"/><Metric label="Available stock" value={totals.stock} note="Units at listed centres" tone="blue"/></section>
    <div className="geo-layout"><section className="panel admin-section geo-regions"><div className="admin-section-heading"><div><span className="admin-section-kicker">UAE programme coverage</span><h2>Patients by emirate</h2><p>Ranked from mock patient records, with active centre counts.</p></div></div><div className="geo-region-list">{emirateRows.map(item => <button key={item.name} className={emirate === item.name ? 'selected' : ''} onClick={() => { setEmirate(item.name); setCentre('All') }}><span className="geo-region-symbol"><CareIcon name="pin"/></span><span className="geo-region-copy"><b>{item.name}</b><small>{item.centres} centres · {item.active} active treatments</small></span><span className="geo-region-bar"><i style={{ width: `${item.patients / Math.max(1, ...emirateRows.map(value => value.patients)) * 100}%` }}/></span><strong>{item.patients}</strong></button>)}</div></section>
      <section className="panel admin-section"><div className="admin-section-heading"><div><span className="admin-section-kicker">Centre level</span><h2>Service activity</h2><p>Request and stock values follow patient and batch centre links.</p></div></div><div className="table-wrap admin-table"><table><thead><tr><th>Centre</th><th>Patients</th><th>Active</th><th>Pending</th><th>Approved</th><th>Dispensed</th><th>Available</th><th>Alerts</th></tr></thead><tbody>{centreStats.map(item => <tr key={item.site.id}><td><button className="table-link" onClick={() => onNavigate('Treatment center management', item.site.id)}>{item.site.name}<small>{item.site.emirate}</small></button></td><td>{item.patients.length}</td><td>{item.active}</td><td>{item.pending}</td><td>{item.approved}</td><td>{item.dispensed}</td><td>{item.available}</td><td>{item.alerts}</td></tr>)}</tbody></table>{centreStats.length === 0 && <div className="empty-state"><b>No centres in this filter</b><span>Choose another emirate.</span></div>}</div><div className="geo-total-row"><span>Filtered centre activity</span><b>{totals.dispensed} dispenses</b><b>{totals.alerts} open signals</b></div></section></div>
  </div>
}

export function SmartAssistant({data,onNavigate,canViewInventory=false,arabic=false,selectedPatientId}:{selectedPatientId?:string;data:AppData;onNavigate:Navigate;canViewInventory?:boolean;arabic?:boolean}){
 const ar=arabic
 const t=(en:string,arabic:string)=>ar?arabic:en
 const [patientId,setPatientId]=useState(data.patients[0]?.id??'')
 const patient=data.patients.find(p=>p.id===(selectedPatientId??patientId))??data.patients[0]
 if(!patient)return <section className="panel admin-section"><div className="empty-state">{t('No patient records available','لا توجد ملفات مرضى')}</div></section>
 const evidence=calculateEligibility(patient,data.labs)
 const latestLab=data.labs.filter(l=>l.patientId===patient.id).sort((a,b)=>b.date.localeCompare(a.date))[0]
 const activeRequest=data.requests.find(r=>r.patientId===patient.id&&['Under review','Approved','Ready to dispense'].includes(r.status))
 const recentDispense=data.dispenses.filter(d=>d.patientId===patient.id).sort((a,b)=>(b.dispensedAt??b.date).localeCompare(a.dispensedAt??a.date))[0]
 const criteriaLabels:Record<string,string>={'BMI at or above 30':'مؤشر كتلة الجسم ٣٠ أو أكثر','HbA1c in eligible range':'السكر التراكمي ضمن النطاق المطلوب','Recorded diagnosis':'تشخيص مسجل','Adult patient':'مريض بالغ'}
 return <div className="admin-view-stack"><section className="assistant-banner"><span className="assistant-symbol"><CareIcon name="Decision support"/></span><div><span className="admin-section-kicker">{t('RULE-BASED DECISION SUPPORT','دعم قرار مبني على معايير واضحة')}</span><h2>{t('Eligibility checks & clinical alerts','فحص الأهلية والتنبيهات الطبية')}</h2><p>{t('Uses the assessments and results saved in Clinical care to check programme eligibility and flag missing evidence. These are transparent demo rules; the doctor reviews the evidence and decides.','تستخدم التقييمات والنتائج المحفوظة في الرعاية السريرية لفحص أهلية العلاج وتنبيهك للبيانات الناقصة. الفحص مبني على قواعد تجريبية واضحة؛ الطبيب يراجع الأدلة ويتخذ القرار.')}</p></div><span className="assistant-status">{t('Doctor decides','الطبيب يقرر')}</span></section>
 {!selectedPatientId&&<div className="assistant-patient-select"><PatientAvatar patient={patient} arabic={arabic}/><label>{t('Patient record','ملف المريض')}<select disabled={!!selectedPatientId} value={patient.id} onChange={e=>setPatientId(e.target.value)}>{data.patients.map(p=><option key={p.id} value={p.id}>{ar?p.nameAr??p.name:p.name} · {p.id}</option>)}</select></label><button className="button secondary" onClick={()=>onNavigate(patientPage,`patient:${patient.id}`)}>{t('Open patient file','فتح ملف المريض')}</button></div>}
 <div className="geo-layout assistant-layout"><section className="panel admin-section"><div className="admin-section-heading"><div><span className="admin-section-kicker">{t('ELIGIBILITY CRITERIA','معايير الأهلية')}</span><h2>{ar?patient.nameAr??patient.name:patient.name} · {patient.id}</h2><p>{patient.age} {t('years','سنة')} · {patient.diagnosis}</p></div><span className={`eligibility-pill ${evidence.eligible?'met':'watch'}`}>{evidence.eligible?t('Criteria met','المعايير مستوفاة'):t('Review required','تحتاج مراجعة')}</span></div><div className="assistant-evidence">{evidence.criteria.map(item=><article key={item.label}><span className={item.passed?'passed':'needs-review'}><CareIcon name={item.passed?'check':'alert'}/></span><div><b>{ar?criteriaLabels[item.label]??item.label:item.label}</b><small>{ar?(item.passed?'المعيار مستوفٍ وفق البيانات المسجلة':'المعيار غير مستوفٍ أو يحتاج تحققًا'):item.evidence}</small></div></article>)}</div><div className="assistant-context-grid"><div><small>{t('Latest lab','آخر تحليل')}</small><b>{latestLab?`${latestLab.test} · ${latestLab.value} ${latestLab.unit} · ${latestLab.date}`:t('No lab on file','لا يوجد تحليل مسجل')}</b></div><div><small>{t('Current request','الطلب الحالي')}</small><b>{activeRequest?`${activeRequest.id} · ${ar?'قيد المعالجة':activeRequest.status}`:t('No active request','لا يوجد طلب نشط')}</b></div><div><small>{t('Current treatment','العلاج الحالي')}</small><b>{patient.currentDose??t('None recorded','لا يوجد علاج مسجل')}</b></div><div><small>{t('Last dispensing','آخر صرف')}</small><b>{recentDispense?recentDispense.date:t('No dispensing record','لا يوجد صرف مسجل')}</b></div></div></section>
 <section className="panel admin-section"><div className="admin-section-heading"><div><span className="admin-section-kicker">{t('REVIEW CONTEXT','سياق المراجعة')}</span><h2>{t('What needs attention?','ما الذي يحتاج انتباهًا؟')}</h2></div></div><div className="assistant-warning-list">{evidence.criteria.filter(item=>!item.passed).map(item=><div key={item.label}><span>!</span>{ar?criteriaLabels[item.label]??'معيار يحتاج مراجعة':item.label}</div>)}{ar?evidence.warnings.length>0&&<div><span>!</span>{evidence.warnings.length} تحذير من قواعد البرنامج؛ راجع ملف المريض ومصدر التحليل.</div>:evidence.warnings.map(item=><div key={item}><span>!</span>{item}</div>)}{evidence.criteria.every(item=>item.passed)&&!evidence.warnings.length&&<div><span><CareIcon name="check"/></span>{t('No unmet criteria in the recorded evidence.','لا توجد معايير غير مستوفاة في الأدلة المسجلة.')}</div>}</div><div className="assistant-actions"><button onClick={()=>onNavigate('Treatment requests')}>{t('Review treatment requests','مراجعة طلبات العلاج')} ›</button>{canViewInventory&&<button onClick={()=>onNavigate(inventoryPage)}>{t('Check inventory','فحص المخزون')} ›</button>}</div></section></div></div>
}

export function MisusePrevention({ data, onReview }: { data: AppData; onReview: (signal: MisuseSignal, status: AbuseReviewRecord['status']) => void }) {
  const [query, setQuery] = useState('')
  const [severity, setSeverity] = useState('All')
  const [status, setStatus] = useState('All')
  const [kind, setKind] = useState('All')
  const signals = misuseSignals(data)
  const records = signals.map(signal => ({ ...signal, status: reviewStateFor(data, signal.id) })).filter(item => (severity === 'All' || item.severity === severity) && (status === 'All' || item.status === status) && (kind === 'All' || item.eventType === kind) && `${item.eventType} ${item.evidence} ${item.patientId ?? ''} ${item.requestId ?? ''}`.toLowerCase().includes(query.toLowerCase()))
  const openCount = records.filter(item => !['Resolved', 'Dismissed'].includes(item.status)).length
  return <div className="admin-view-stack"><section className="assistant-banner misuse-banner"><span className="assistant-symbol"><CareIcon name="decision"/></span><div><span className="admin-section-kicker">Operational safety monitoring</span><h2>Records flagged for review</h2><p>Rule-based signals show evidence and status; they do not imply intent or accuse a patient.</p></div><strong className="misuse-open-count">{openCount}<small>open flags</small></strong></section>
    <section className="panel admin-section"><div className="admin-filter-bar misuse-filters"><label>Search<input value={query} onChange={event => setQuery(event.target.value)} placeholder="Patient, request or evidence"/></label><label>Event type<select value={kind} onChange={event => setKind(event.target.value)}><option>All</option>{[...new Set(signals.map(item => item.eventType))].map(item => <option key={item}>{item}</option>)}</select></label><label>Severity<select value={severity} onChange={event => setSeverity(event.target.value)}><option>All</option><option>Critical</option><option>Warning</option><option>Info</option></select></label><label>Review status<select value={status} onChange={event => setStatus(event.target.value)}><option>All</option><option>New</option><option>Under Review</option><option>Resolved</option><option>Dismissed</option></select></label></div>
      {records.length ? <div className="misuse-list">{records.map(item => <article key={item.id}><div className={`misuse-severity ${toneFor(item.severity)}`}>{item.severity}</div><div className="misuse-copy"><b>{item.eventType}</b><span>{item.evidence}</span><small>{item.patientId ? `Patient ${item.patientId}` : 'Inventory'}{item.requestId ? ` · ${item.requestId}` : ''} · {item.timestamp ? new Date(item.timestamp).toLocaleString('en-AE') : 'Timestamp unavailable'}</small></div><span className={`misuse-state ${toneFor(item.status)}`}>{item.status}</span><div className="misuse-actions"><button onClick={() => onReview(item, 'Under Review')} disabled={item.status === 'Under Review'}>Review</button><button onClick={() => onReview(item, 'Resolved')} disabled={item.status === 'Resolved'}>Resolve</button><button onClick={() => onReview(item, 'Dismissed')} disabled={item.status === 'Dismissed'}>Dismiss</button></div></article>)}</div> : <div className="empty-state"><b>{signals.length ? 'No flagged records match these filters' : 'No review flags detected'}</b><span>{signals.length ? 'Clear a filter to see current rule-based findings.' : 'No duplicate, refill-timing, prescription or inventory anomaly was found in the current mock records.'}</span></div>}
      <p className="report-footnote">Signals are recalculated from canonical requests, dispense records, dose logs and inventory. Review decisions are saved to the audit history.</p>
    </section></div>
}

export function SystemAudit({ data }: { data: AppData }) {
  const [query, setQuery] = useState('')
  const [role, setRole] = useState('All')
  const [entity, setEntity] = useState('All')
  const [action, setAction] = useState('All')
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const entities = [...new Set(data.audit.map(item => item.entity))].sort()
  const actions = [...new Set(data.audit.map(item => item.action))].sort()
  const records = data.audit.filter(item => { const date = (item.occurredAt ?? '').slice(0, 10); return (role === 'All' || item.actor === role) && (entity === 'All' || item.entity === entity) && (action === 'All' || item.action === action) && (!from || !date || date >= from) && (!to || !date || date <= to) && `${item.actor} ${item.action} ${item.entity} ${item.entityId} ${item.patientId ?? ''} ${item.detail} ${item.reason ?? ''} ${item.previousState ?? ''} ${item.newState ?? ''}`.toLowerCase().includes(query.toLowerCase()) }).sort((a, b) => (b.occurredAt ?? '').localeCompare(a.occurredAt ?? ''))
  return <div className="admin-view-stack"><section className="admin-audit-intro"><div><span className="admin-section-kicker">Governance and traceability</span><h2>System audit</h2><p>Review recorded state changes, actors, entities, reasons and before/after values. Operational event browsing remains in Live activity log.</p></div><b>{records.length}<small>matching events</small></b></section>
    <section className="panel admin-section"><div className="admin-filter-bar audit-filters"><label>Search<input value={query} onChange={event => setQuery(event.target.value)} placeholder="Actor, action, entity, patient or reason"/></label><label>Role<select value={role} onChange={event => setRole(event.target.value)}><option>All</option>{(['Admin', 'Doctor', 'Reviewer', 'Pharmacist', 'Patient'] as const).map(item => <option key={item}>{item}</option>)}</select></label><label>Entity<select value={entity} onChange={event => setEntity(event.target.value)}><option>All</option>{entities.map(item => <option key={item}>{item}</option>)}</select></label><label>Action<select value={action} onChange={event => setAction(event.target.value)}><option>All</option>{actions.map(item => <option key={item}>{item}</option>)}</select></label><label>From<input type="date" value={from} onChange={event => setFrom(event.target.value)} max={to || undefined}/></label><label>To<input type="date" value={to} onChange={event => setTo(event.target.value)} min={from || undefined}/></label></div>
      <div className="table-wrap admin-table audit-table"><table><thead><tr><th>Timestamp</th><th>Actor / role</th><th>Action</th><th>Entity</th><th>Patient / request</th><th>Previous state</th><th>New state</th><th>Reason / details</th></tr></thead><tbody>{records.map(item => <tr key={item.id}><td>{item.occurredAt ? new Date(item.occurredAt).toLocaleString('en-AE') : item.time}</td><td>{item.actor}</td><td>{item.action}</td><td>{item.entity} · {item.entityId}</td><td>{item.patientId ?? data.requests.find(row => row.id === item.entityId)?.patientId ?? '—'}</td><td>{item.previousState ?? '—'}</td><td>{item.newState ?? '—'}</td><td>{item.reason ?? item.detail}{item.metadata && Object.keys(item.metadata).length ? ` · ${Object.entries(item.metadata).map(([key, value]) => `${key}: ${value}`).join(', ')}` : ''}</td></tr>)}</tbody></table>{records.length === 0 && <div className="empty-state"><b>No audit events match these filters</b><span>Clear a filter or choose another date range.</span></div>}</div>
    </section></div>
}

export function MisuseReviewAction(data: AppData, signal: MisuseSignal, status: AbuseReviewRecord['status']) { return { ...signal, status, current: reviewStateFor(data, signal.id) } }
