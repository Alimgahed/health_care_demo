import { lazy, Suspense, useEffect, useRef, useState } from 'react'
import type { FormEvent } from 'react'
import type { AppData, Role } from './domain'
import { LoginIcon, type LoginIconName } from './LoginIcon'
import logo from './assets/healthcare-logo.png'
import { brandName } from './brand'
import hospital from './assets/login-hospital-atrium.png'
import assistant from './assets/login-ai-assistant.png'
import './LoginGate.css'

const DoctorDashboard = lazy(() => import('./DoctorDashboard').then(module => ({ default: module.DoctorDashboard })))

type Portal = { role: Role; ar: string; en: string; icon: LoginIconName }
const portals: Portal[] = [
  { role: 'Patient', ar: 'المريض', en: 'Patient', icon: 'patient' },
  { role: 'Doctor', ar: 'الطبيب', en: 'Doctor', icon: 'doctor' },
  { role: 'Pharmacist', ar: 'الصيدلي', en: 'Pharmacist', icon: 'pharmacy' },
  { role: 'Reviewer', ar: 'المراجع', en: 'Reviewer', icon: 'reviewer' },
  { role: 'Admin', ar: 'الإدارة', en: 'Admin', icon: 'admin' },
]
const services: { icon: LoginIconName; ar: string; en: string; detailAr: string; detailEn: string }[] = [
  { icon: 'patient', ar: 'المرضى', en: 'Patients', detailAr: 'سجل موحد ورعاية متصلة', detailEn: 'One connected care record' },
  { icon: 'lab', ar: 'التحاليل والنتائج', en: 'Labs & results', detailAr: 'نتائج واضحة في وقتها', detailEn: 'Clear results, in time' },
  { icon: 'request', ar: 'طلبات العلاج', en: 'Treatment requests', detailAr: 'مراجعة واعتماد العلاج', detailEn: 'Review and approve care' },
  { icon: 'calendar', ar: 'المواعيد', en: 'Appointments', detailAr: 'الزيارات والمتابعة', detailEn: 'Visits and follow-up' },
  { icon: 'activity', ar: 'الرعاية السريرية', en: 'Clinical care', detailAr: 'متابعة المؤشرات الصحية', detailEn: 'Track health indicators' },
  { icon: 'pharmacy', ar: 'صرف الأدوية', en: 'Pharmacy', detailAr: 'الوصفة والمخزون معًا', detailEn: 'Prescriptions and stock' },
  { icon: 'clinic', ar: 'العيادات', en: 'Clinics', detailAr: 'رعاية متخصصة وزيارات متصلة', detailEn: 'Specialist care, connected visits' },
]
const benefits: { icon: LoginIconName; ar: string; en: string; subAr: string; subEn: string }[] = [
  { icon: 'team', ar: 'كفاءة أعلى', en: 'More efficient', subAr: 'للفرق الطبية', subEn: 'For care teams' },
  { icon: 'clock', ar: 'سرعة أكبر', en: 'Faster service', subAr: 'في كل خطوة', subEn: 'At every step' },
  { icon: 'shield', ar: 'أمان وموثوقية', en: 'Trusted data', subAr: 'لجميع البيانات', subEn: 'Across the system' },
  { icon: 'chart', ar: 'قرارات أدق', en: 'Clearer decisions', subAr: 'برؤى ذكية', subEn: 'With smart insights' },
]

/** Render the same dashboard and shared records used inside the application. */
function DashboardPreview({ data, arabic }: { data: AppData; arabic: boolean }) {
  const frame = useRef<HTMLDivElement>(null)
  const [scale, setScale] = useState(0.32)
  useEffect(() => {
    const element = frame.current
    if (!element) return
    const observer = new ResizeObserver(([entry]) => setScale(entry.contentRect.width / 1200))
    observer.observe(element)
    return () => observer.disconnect()
  }, [])
  return <figure className="login-dashboard-preview">
    <div className="login-dashboard-monitor">
      <div className="login-dashboard-viewport" ref={frame} role="img" aria-label={arabic ? 'معاينة لوحة تحكم الطبيب من النظام' : 'Preview of the application doctor dashboard'}>
        <div className="login-dashboard-live" style={{ transform: `scale(${scale})` }} inert aria-hidden="true" dir={arabic ? 'rtl' : 'ltr'}>
          <aside className="login-dashboard-sidebar"><img src={logo} alt=""/><strong>{brandName(arabic)}</strong>{(['dashboard', 'patient', 'request', 'calendar', 'activity', 'pharmacy'] as LoginIconName[]).map((icon, index) => <div key={icon} className={index === 0 ? 'active' : ''}><LoginIcon name={icon}/><span>{(arabic ? ['لوحة التحكم', 'المرضى', 'طلبات العلاج', 'المواعيد', 'الرعاية السريرية', 'الصيدلية'] : ['Dashboard', 'Patients', 'Treatment requests', 'Appointments', 'Clinical care', 'Pharmacy'])[index]}</span></div>)}</aside>
          <div className="login-dashboard-main"><div className="login-dashboard-topbar"><span>{arabic ? 'البرنامج / لوحة التحكم' : 'Programme / Dashboard'}</span><span><LoginIcon name="shield"/> {arabic ? 'برنامج الرعاية' : 'Care programme'}</span></div><Suspense fallback={<div className="login-dashboard-loading">{arabic ? 'تحميل لوحة التحكم…' : 'Loading dashboard…'}</div>}><DoctorDashboard data={data} arabic={arabic} onNavigate={() => {}} onPatient={() => {}}/></Suspense></div>
        </div>
      </div>
    </div>
    <figcaption><span className="login-live-dot"/>{arabic ? 'من داخل النظام · لوحة تحكم الطبيب' : 'Inside the platform · Doctor dashboard'}</figcaption>
  </figure>
}

function MobilePreview({ data, arabic }: { data: AppData; arabic: boolean }) {
  const patient = data.patients.find(item => item.id === data.activePatientId) ?? data.patients[0]
  const appointment = data.appointments.filter(item => item.patientId === patient?.id && ['Scheduled', 'Confirmed'].includes(item.status)).sort((a, b) => a.date.localeCompare(b.date))[0]
  const tr = (en: string, ar: string) => arabic ? ar : en
  return <figure className="login-mobile-preview" dir={arabic ? 'rtl' : 'ltr'}>
    <div className="login-mobile-device">
      <div className="login-mobile-camera"/>
      <div className="login-mobile-heading"><img src={logo} alt=""/><strong>{tr('My care', 'رعايتي')}</strong><LoginIcon name="shield"/></div>
      <b>{arabic ? patient?.nameAr ?? patient?.name : patient?.name}</b>
      <div className="login-mobile-appointment"><LoginIcon name="calendar"/><span>{tr('Next appointment', 'الموعد القادم')}<strong>{appointment ? new Intl.DateTimeFormat(arabic ? 'ar-AE' : 'en-GB', { day: 'numeric', month: 'short' }).format(new Date(`${appointment.date}T12:00:00`)) : tr('No upcoming visits', 'لا توجد زيارات قادمة')}</strong></span></div>
      <div className="login-mobile-nav"><LoginIcon name="dashboard"/><LoginIcon name="calendar"/><LoginIcon name="bot"/></div>
    </div>
    <figcaption><LoginIcon name="phone"/>{tr('Your care, on mobile', 'رعايتك على الموبايل')}</figcaption>
  </figure>
}

export function LoginGate({ data, arabic, onLanguage, onEnter }: { data: AppData; arabic: boolean; onLanguage: () => void; onEnter: (role: Role) => void }) {
  const [selected, setSelected] = useState<Role>(() => {
    try {
      const saved = window.localStorage.getItem('health-care-login-portal')
      return portals.find(portal => portal.role === saved)?.role ?? 'Pharmacist'
    } catch { return 'Pharmacist' }
  })
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [remember, setRemember] = useState(true)
  const [notice, setNotice] = useState(false)
  const [motionPaused, setMotionPaused] = useState(false)
  const tr = (en: string, ar: string) => arabic ? ar : en
  const current = portals.find(portal => portal.role === selected)!
  const enter = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    try {
      if (remember) window.localStorage.setItem('health-care-login-portal', selected)
      else window.localStorage.removeItem('health-care-login-portal')
    } catch { /* Demo access still works when browser storage is unavailable. */ }
    onEnter(selected)
  }
  return <div className="login-v2" dir={arabic ? 'rtl' : 'ltr'} data-motion={motionPaused ? 'paused' : 'running'}>
    <img className="login-v2-background" src={hospital} alt="" aria-hidden="true"/>
    <div className="login-v2-wash"/>
    <section className="login-v2-story" aria-label={tr('Connected healthcare', 'الرعاية الصحية المتكاملة')}>
      <header className="login-story-header">
        <div className="login-v2-brand"><img src={logo} alt=""/><div><strong>{brandName(arabic)}</strong><small>{tr('Integrated care management system', 'نظام إدارة الرعاية المتكاملة')}</small></div></div>
        <button className="login-motion-toggle" type="button" onClick={() => setMotionPaused(value => !value)} aria-pressed={motionPaused} aria-label={tr(motionPaused ? 'Play animations' : 'Pause animations', motionPaused ? 'تشغيل الحركة' : 'إيقاف الحركة')} title={tr(motionPaused ? 'Play animations' : 'Pause animations', motionPaused ? 'تشغيل الحركة' : 'إيقاف الحركة')}><LoginIcon name={motionPaused ? 'play' : 'pause'}/></button>
      </header>
      <div className="login-story-stage">
        <div className="login-story-copy">
          <div className="login-v2-intro"><h1>{tr('From the first visit to every follow-up…', 'من الاستقبال إلى المتابعة...')}<span>{tr('all care in one place', 'كل الرعاية في نظام واحد')}</span></h1><p>{tr('One connected system helps every care team deliver a clearer, faster experience for patients.', 'نظام ذكي متكامل يدعم فرق الرعاية الصحية، لتجربة أفضل للمرضى وكفاءة أعلى للمنشآت.')}</p></div>
          <DashboardPreview data={data} arabic={arabic}/>
        </div>
        <div className="login-v2-network" aria-hidden="true">
          <svg className="login-network-links" viewBox="0 0 440 580" preserveAspectRatio="none"><path d="M220 280 220 45M220 280 370 145M220 280 370 285M220 280 70 145M220 280 70 440M220 280 370 440M220 280 70 285M220 280 220 490"/></svg>
          <div className="login-network-orbit orbit-one"><span/></div><div className="login-network-orbit orbit-two"><span/></div>
          <div className="login-v2-network-core"><span>AI</span><i/></div>
          <div className="login-v2-network-caption"><strong>{tr('Intelligence at every step', 'ذكاء يدعم كل خطوة')}</strong><small>{tr('Connected insights. Better care.', 'رؤى متصلة لرعاية أفضل.')}</small></div>
          {services.map((service, index) => <div className={`login-v2-service service-${index}`} key={service.en}><span><LoginIcon name={service.icon}/></span><div><strong>{arabic ? service.ar : service.en}</strong><small>{arabic ? service.detailAr : service.detailEn}</small></div></div>)}
          <MobilePreview data={data} arabic={arabic}/>
          <div className="login-network-spark spark-one"/><div className="login-network-spark spark-two"/><div className="login-network-spark spark-three"/>
        </div>
      </div>
      <div className="login-v2-benefits">{benefits.map(item => <div key={item.en}><span><LoginIcon name={item.icon}/></span><div><strong>{arabic ? item.ar : item.en}</strong><small>{arabic ? item.subAr : item.subEn}</small></div></div>)}</div>
    </section>
    <main className="login-v2-panel">
      <div className="login-v2-panel-top"><button className="login-v2-language" type="button" onClick={onLanguage} aria-label={tr('Switch to Arabic', 'Switch to English')}><LoginIcon name="globe"/><span>{arabic ? 'EN' : 'AR'}</span></button></div>
      <div className="login-v2-panel-brand"><img src={logo} alt=""/><strong>{brandName(arabic)}</strong><small>{tr('Integrated care management system', 'نظام إدارة الرعاية المتكاملة')}</small></div>
      <div className="login-v2-welcome"><h2>{tr('Welcome back', 'مرحبًا بك مجددًا')}</h2><p>{tr('Sign in to continue your care journey', 'سجل الدخول إلى حسابك للمتابعة')}</p></div>
      <form onSubmit={enter}>
        <div className="login-v2-portals" role="radiogroup" aria-label={tr('Choose a portal', 'اختر البوابة')}>{portals.map(portal => <button type="button" role="radio" aria-checked={selected === portal.role} className={`login-v2-portal ${selected === portal.role ? 'selected' : ''}`} key={portal.role} onClick={() => setSelected(portal.role)}><LoginIcon name={portal.icon}/><small>{arabic ? portal.ar : portal.en}</small></button>)}</div>
        <div className="login-v2-selected">{tr(`Entering the ${current.en} portal`, `الدخول إلى بوابة ${current.ar}`)}</div>
        <label className="login-v2-field"><span>{tr('Username', 'اسم المستخدم')}</span><div><LoginIcon name="user"/><input autoComplete="username" value={username} onChange={event => setUsername(event.target.value)} placeholder={tr('Enter username', 'أدخل اسم المستخدم')}/></div></label>
        <label className="login-v2-field"><span>{tr('Password', 'كلمة المرور')}</span><div><LoginIcon name="lock"/><input type={showPassword ? 'text' : 'password'} autoComplete="current-password" value={password} onChange={event => setPassword(event.target.value)} placeholder={tr('Enter password', 'أدخل كلمة المرور')}/><button type="button" className="login-v2-eye" onClick={() => setShowPassword(value => !value)} aria-label={tr(showPassword ? 'Hide password' : 'Show password', showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور')}><LoginIcon name={showPassword ? 'eyeOff' : 'eye'}/></button></div></label>
        <div className="login-v2-form-options"><label><input type="checkbox" checked={remember} onChange={event => setRemember(event.target.checked)}/>{tr('Remember my choice', 'تذكر اختياري')}</label><button type="button" onClick={() => setNotice(value => !value)}>{tr('Forgot password?', 'نسيت كلمة المرور؟')}</button></div>
        {notice && <p className="login-v2-notice" role="status">{tr('This interactive demo does not use account passwords. Choose a portal and continue.', 'هذه نسخة تجريبية ولا تستخدم كلمات مرور الحسابات. اختر البوابة وتابع.')}</p>}
        <button className="login-v2-submit" type="submit"><span>{tr('Enter portal', 'دخول')}</span><LoginIcon name="arrow"/></button>
        <p className="login-v2-demo">{tr('Demo access · Username and password are optional', 'دخول تجريبي · اسم المستخدم وكلمة المرور اختياريان')}</p>
      </form>
      <div className="login-v2-assistant"><img src={assistant} alt=""/><div><strong>{tr('Your AI assistant is here', 'مساعدك الذكي دائمًا معك')}</strong><p>{tr('Connected insights and answers across your care workspace.', 'اقتراحات ذكية وإجابات فورية تدعم رحلتك داخل النظام.')}</p><div className="login-assistant-dots" aria-hidden="true"><i/><i/><i/></div></div></div>
    </main>
  </div>
}
