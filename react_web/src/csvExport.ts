export type CsvRow = Record<string, string | number | boolean | undefined>

/** Quoted UTF-8 CSV; text values cannot become executable spreadsheet formulas. */
export function serializeCsv(rows: CsvRow[]) {
  if (!rows.length) return ''
  const keys = [...new Set(rows.flatMap(row => Object.keys(row)))]
  const escape = (value: unknown) => {
    const raw = String(value ?? '')
    const safe = typeof value === 'string' && /^[\s]*[=+@\-\t\r]/.test(raw) ? `'${raw}` : raw
    return `"${safe.replaceAll('"', '""')}"`
  }
  return '\ufeff' + [keys.map(escape).join(','), ...rows.map(row => keys.map(key => escape(row[key])).join(','))].join('\r\n')
}
export function downloadCsv(filename: string, rows: CsvRow[]) {
  const csv = serializeCsv(rows)
  if (!csv) return
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  // WebKit needs the Blob to survive until the download has started.
  window.setTimeout(() => URL.revokeObjectURL(url), 30_000)
}
