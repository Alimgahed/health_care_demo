import type { CSSProperties } from 'react'

const paths = {
  phone: 'M7 2h10a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2M10 5h4M11 19h2',
  clinic: 'M4 21V7h16v14M8 7V3h8v4M10 21v-5h4v5M10 10h4M12 8v4M7 14h1M16 14h1',
  patient: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M18 8h4M20 6v4',
  doctor: 'M6 3v2M12 3v2M4 4v5a5 5 0 0 0 10 0V4M9 14v2a5 5 0 0 0 10 0v-2M21 11a2 2 0 1 0-4 0 2 2 0 0 0 4 0',
  pharmacy: 'M8.5 19.5a5 5 0 0 1-7-7l11-11a5 5 0 0 1 7 7zM7 7l7 7',
  reviewer: 'M9 4H5v17h14V4h-4M9 2h6v4H9zM8 13l3 3 5-6',
  admin: 'M12 2 3 6v6c0 5 9 10 9 10s9-5 9-10V6zM15 10a3 3 0 1 0-6 0 3 3 0 0 0 6 0M7 17a5 5 0 0 1 10 0',
  lab: 'M9 3h6M10 3v6l-6 10a1.3 1.3 0 0 0 1 2h14a1.3 1.3 0 0 0 1-2L14 9V3M7 15h10M9 18h.01M13 12h.01',
  request: 'M14 2H5v20h14V7zM14 2v6h5M8 12h8M8 16h5M8 19h3',
  calendar: 'M8 2v4M16 2v4M3 10h18M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2M7 14h2M13 14h2M7 18h2',
  activity: 'M2 12h5l3-8 4 16 3-8h5',
  chart: 'M3 3v18h18M7 16v-5M12 16V7M17 16V4',
  team: 'M9 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6M3 21v-3a5 5 0 0 1 10 0v3M16 5a3 3 0 0 1 0 6M21 21v-3a5 5 0 0 0-4-4',
  clock: 'M22 12a10 10 0 1 0-20 0 10 10 0 0 0 20 0M12 6v6l4 2',
  shield: 'M12 2 3 6v6c0 5 9 10 9 10s9-5 9-10V6zM8 12l3 3 5-6',
  network: 'M14 5a2 2 0 1 0-4 0 2 2 0 0 0 4 0M6 19a2 2 0 1 0-4 0 2 2 0 0 0 4 0M22 19a2 2 0 1 0-4 0 2 2 0 0 0 4 0M12 7v5M4 17v-5h16v5',
  bot: 'M12 3v3M10 2h4M5 6h14a2 2 0 0 1 2 2v11H3V8a2 2 0 0 1 2-2M1 10v5M23 10v5M7 11h.01M17 11h.01M8 15c2 2 6 2 8 0M7 19v3M17 19v3',
  globe: 'M22 12a10 10 0 1 0-20 0 10 10 0 0 0 20 0M2 12h20M12 2c5 5 5 15 0 20-5-5-5-15 0-20',
  user: 'M16 7a4 4 0 1 0-8 0 4 4 0 0 0 8 0M4 21v-3a8 6 0 0 1 16 0v3z',
  lock: 'M6 10h12a2 2 0 0 1 2 2v9H4v-9a2 2 0 0 1 2-2M8 10V6a4 4 0 0 1 8 0v4M12 14v3',
  eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12M15 12a3 3 0 1 0-6 0 3 3 0 0 0 6 0',
  eyeOff: 'M3 3l18 18M10 5a12 12 0 0 1 12 7 18 18 0 0 1-3 4M6 6a18 18 0 0 0-4 6s4 7 10 7a11 11 0 0 0 4-1M9 9a4 4 0 0 0 6 6',
  arrow: 'M4 12h16M14 6l6 6-6 6',
  pause: 'M7 4h3v16H7zM14 4h3v16h-3z',
  play: 'M7 3v18l14-9z',
  dashboard: 'M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z',
} as const

export type LoginIconName = keyof typeof paths
export function LoginIcon({ name, style }: { name: LoginIconName; style?: CSSProperties }) {
  return <svg className="login-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={style}><path d={paths[name]}/></svg>
}
