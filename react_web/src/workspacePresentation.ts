export type SkeletonKind = 'dashboard' | 'table' | 'patient' | 'timeline' | 'map' | 'assistant'
export function skeletonFor(page: string): SkeletonKind {
 if (page.includes('Overview') || page==='Reports') return 'dashboard'
 if (page.includes('Geographic')) return 'map'
 if (page.includes('assistant')) return 'assistant'
 if (page.includes('care') || page==='My care') return 'patient'
 if (page.includes('Activity') || page.includes('audit')) return 'timeline'
 return 'table'
}
