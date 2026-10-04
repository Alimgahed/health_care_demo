import { useEffect, useRef } from 'react'

import { localizeArabic as localize } from './ArabicText'

export function useArabicDom(enabled: boolean, patients: readonly { name: string; nameAr?: string }[]) {
  const rootRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const root = rootRef.current
    if (!enabled || !root) return
    let cleanup: (()=>void) | undefined
    let active = true
    void import('./ArabicCatalogue').then(baseCatalogue => {
    if (!active) return
    // Localize names from the shared records instead of maintaining a second patient list.
    const phrases = new Map(baseCatalogue.phrases)
    for (const patient of patients) if (patient.nameAr) phrases.set(patient.name, patient.nameAr)
    const catalogue = { ...baseCatalogue, phrases, orderedPhrases: [...phrases].sort(([a], [b]) => b.length - a.length) }
    const textNodes = new Map<Text, { original: string; localized: string }>()
    const attributes = new Map<Element, Map<string, { original: string; localized: string }>>()
    const localizeTextNode = (node: Text) => {
      if (node.parentElement?.closest('[data-no-localize]')) return
      const previous = textNodes.get(node)
      const original = previous && node.data === previous.localized ? previous.original : node.data
      const localized = localize(original, catalogue)
      textNodes.set(node, { original, localized })
      if (node.data !== localized) node.data = localized
    }
    const localizeAttributes = (element: Element) => {
      const known = attributes.get(element) ?? new Map<string, { original: string; localized: string }>()
      for (const name of ['placeholder','aria-label','title','alt','label']) {
        const current = element.getAttribute(name)
        if (current === null) continue
        const previous = known.get(name)
        const original = previous && current === previous.localized ? previous.original : current
        const localized = localize(original, catalogue)
        known.set(name, { original, localized })
        if (current !== localized) element.setAttribute(name, localized)
      }
      attributes.set(element, known)
    }
    const visit = (node: Node) => {
      if (node.nodeType === Node.TEXT_NODE) { localizeTextNode(node as Text); return }
      if (node.nodeType !== Node.ELEMENT_NODE && node.nodeType !== Node.DOCUMENT_FRAGMENT_NODE) return
      if (node instanceof Element) {
        if (node.tagName === 'OPTION' && !node.hasAttribute('value')) node.setAttribute('value', (node as HTMLOptionElement).value)
        localizeAttributes(node)
      }
      for (const child of Array.from(node.childNodes)) visit(child)
    }
    visit(root)
    const observer = new MutationObserver(records => {
      for (const record of records) {
        if (record.type === 'characterData' && record.target instanceof Text) localizeTextNode(record.target)
        for (const added of Array.from(record.addedNodes)) visit(added)
        if (record.type === 'attributes' && record.target instanceof Element) localizeAttributes(record.target)
      }
    })
    observer.observe(root, { subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ['placeholder','aria-label','title','alt','label'] })
    cleanup = () => {
      observer.disconnect()
      for (const [node, value] of textNodes) if (node.data === value.localized) node.data = value.original
      for (const [element, entries] of attributes) for (const [name, value] of entries) if (element.getAttribute(name) === value.localized) element.setAttribute(name, value.original)
    }
    })
    return () => { active=false; cleanup?.() }
  }, [enabled, patients])
  return rootRef
}
