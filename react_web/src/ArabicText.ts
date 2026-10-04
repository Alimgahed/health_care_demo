export function localizeArabic(text: string, catalogue: typeof import('./ArabicCatalogue')) {
  const { phrases, words, orderedPhrases } = catalogue
  text = catalogue.localizeAdminTemplate(text) ?? text
  const doseNotice = text.match(/^Your (.+) dose was added to your adherence history\.$/)
  if (doseNotice) return `تمت إضافة جرعة ${doseNotice[1]} إلى سجل الالتزام الخاص بك.`
  const exact = phrases.get(text.trim())
  if (exact) return text.replace(text.trim(), exact)
  const identifiers: string[] = []
  let localized = text.replace(/https?:\/\/[^\s]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\b(?:[A-Z]{2,}(?:-[A-Za-z0-9.]+)+|P[0-9]{3,})\b/g, value => { const index=identifiers.push(value)-1; return `⟦${index}⟧` })
  for (const [english, arabic] of orderedPhrases) {
    const escaped = english.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    localized = localized.replace(new RegExp(`\\b${escaped}(?=$|[^A-Za-z])`, 'gi'), arabic)
  }
  return localized.replace(/[A-Za-z]+(?:[-'][A-Za-z]+)*/g, word => words.get(word.toLowerCase()) ?? word).replace(/⟦(\d+)⟧/g, (_,index) => identifiers[Number(index)])
}
