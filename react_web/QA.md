# Implementation and QA handoff — 1 October 2026

## Screen coverage

| Workspace | Reviewed and updated areas |
| --- | --- |
| Admin | Command board, executive summary, geography, registry and filters, Patient 360, requests, appointments, continuous care, inventory and receipts, alerts, activity, decision support, misuse, reports, doctor management, centre management, audit |
| Doctor | Command board, scoped patients, Patient 360, assessment, vitals/labs, treatment drafting/submission, decision support, appointments, rehabilitation |
| Reviewer | Command board, queue, clinical evidence, eligibility, review rationale, approval/rejection/information requests and history |
| Pharmacy | Command board, collection queue, verification matrix, identity attestation, invalid refill, dispensing, stock/batches/receipts/movements, alerts and history |
| Patient | Home, treatment, medication, progress, appointments, activity/rehabilitation, notifications and profile |

New/expanded surfaces include the care command boards, connected journey, guided integrated care planning, geographic care map, central rehabilitation/exercise catalogues, rehabilitation progress, registration, editable treatment drafts, preventive-care signals, historical documents and expanded Patient 360 tabs. Existing functional modules were retained and restyled rather than replaced with static demonstrations.

## Browser verification performed

- Navigated the five role workspaces and the major administrative routes.
- Exercised reviewer rejection without a reason: validation blocked the action. Approved TR-24018 with a rationale, switched to pharmacy, confirmed identity and dispensed; the patient, inventory, movement/history and report records reflected the same action.
- Attempted the P009 early refill; dispensing remained blocked even after identity attestation.
- Switched pharmacy requests and confirmed identity attestation resets for the selected request.
- Recorded P999's dose and a 15-minute home exercise. Adherence and notifications updated; the final dose action is disabled after today's dose.
- Inspected all nine Patient 360 tabs, including treatment history and care documents. Arrow-key tab navigation worked; Escape closed the dialog and restored focus to the triggering patient control.
- Tested patient search and no-results feedback. Verified report status filtering produces only the two under-review requests and inspected the matching CSV preview.
- Inspected loaded clinical decision support. Doctor workspace has scoped evidence and no unauthorized inventory action.
- Checked Arabic navigation, labels, generated dose notification, RTL direction, preserved IDs, language restoration and patient activity forms. Corrected a legacy double-reversal that kept the Arabic sidebar on the left.
- Checked widths of 1440, 900 and 390 pixels on representative operational/patient views. Fixed tablet registry filter overflow. Registry, inventory, reports, appointments, continuous care and patient views were checked at narrow widths; the final mobile Arabic patient view had no document-level horizontal overflow. Wide tables retain their own scrolling areas.
- Reviewed console output after the final interaction pass. Existing early-development HMR messages remained in the log; no new runtime errors were observed during the final pass.

Browser testing used the Codex embedded WebKit browser. Full-page screenshot stitching was unreliable under an overridden viewport, so screenshot output is not offered as a pixel-accurate visual regression baseline. Screenshots and DOM geometry were used together for inspection. Temporary viewport overrides are reset at handoff.

## Integrated care scenario verified in the browser

- Doctor opened **P001 (Resident)** through Patient 360 and created **Metabolic health and functional recovery**. Selected Mounjaro 5 mg weekly, six physiotherapy sessions at Abu Dhabi Rehabilitation Centre, Walking, Strength training, Flexibility and a follow-up on 15 October 2026.
- Review showed eight completeness checks after rationale entry and the exact estimate: AED 2,100 total, 50% discount, AED 1,050 support, AED 1,050 patient amount.
- Saved `ICP-1790851377461-1`, linked to `TR-1790851377461-2`. Reviewer approved with a reason. Pharmacist verified identity, prescription, human approval, dose, duplicate/refill timing, evidence, reservation and a valid batch before successful dispensing.
- Patient Portal profile **P001** showed that same request as Dispensed, the same physiotherapy centre, all three exercises and the scheduled follow-up. A 20-minute Walking entry retained the integrated plan ID.
- Doctor recorded the first physiotherapy session. The plan and rehabilitation report showed **1 / 6 sessions, In progress**. Admin's care-plan report contained the exact patient, request, centre, programme, exercise count, follow-up and coverage values.
- Financial report and CSV preview showed the same care-plan/request and 50% calculation. A duplicate React row key discovered while switching reports was fixed; switching between care-plan and financial reports no longer leaves stale rows.
- Reload preserved the plan, dispensing status and rehabilitation session. Historical rehabilitation estimates now reconcile with their linked financial record through an idempotent migration.
- Geographic map uses the shared catalogue. Selected Abu Dhabi Rehabilitation Centre with the keyboard; zoom changed the viewBox; the Abu Dhabi filter showed exactly two rehabilitation markers and matching directory entries. P001's nearest centre was 1.6 km from the approximate area centroid.
- Checked Arabic map labels, centre selection, home-exercise instructions, coverage, intact IDs/email addresses and care-plan cancel confirmation. Free-text plan titles/rationale stay in their entered language. Arabic mobile map and wizard at 390 px and care-plan cards at 900 px had no document-level horizontal overflow.
- Final diagnostics contained only the earlier duplicate-key warning from before the fix; no new errors appeared in the subsequent flow.

The demonstrated creation/dispensing action is already saved in the embedded browser. Repeating medication dispensing for P001 on the same day correctly triggers duplicate/refill protections. Use the retained plan to review the completed demonstration; automated tests run against independent fresh seed copies.

## Automated coverage

The 45 tests cover:

- seed references and plan date/dose consistency;
- clinical evidence, newest-lab selection and missing vitals;
- authorized role/patient access and invalid clinical values;
- submission, review, return-for-information/resubmission, pharmacy release and course completion;
- required prescription/approval, identity, dose, refill, expiry, reservation and batch checks;
- failed-operation immutability, successful dispensing and inventory reconciliation;
- appointments, duplicate doses, schedule-aware adherence and future-dose exclusion;
- rehabilitation assignment and linked notifications;
- full clinical-to-dispensing-to-continuous-care linkage;
- organization changes, safety review/audit and local persistence migrations;
- Arabic-safe CSV quoting, line breaks and formula protection;
- Citizen 100%, Resident 50%, Visitor 0%, including the full medication approval/dispensing cycle for each type;
- canonical P001 integrated plan, clinical review, stock reduction, one financial estimate, rehabilitation session, exercise linkage, notifications and audit;
- atomic failures for inactive/full centres, unsupported exercises, invalid sessions and missing rationale;
- rehabilitation-only plans and linking an existing medication request without duplicate prescriptions;
- care-plan/catalogue/profile persistence and idempotent legacy estimate reconciliation;
- follow-up rescheduling and completed attendance updating the patient context.

## Verification boundaries

- The embedded browser did not expose a successful Blob-download event or a saved CSV file. The export implementation uses a retained Blob and attached download anchor; serialization is tested, and the exact filtered CSV is available in the verified on-screen preview. Native download behavior still needs confirmation in a regular browser.
- Responsive and Arabic checks are representative browser checks, not an exhaustive automated visual/accessibility matrix for every state of every form. Free-text clinical content is not professionally translated.
- The geographic experience is a self-contained interactive SVG map using approximate demo coordinates, central facility relationships and straight-line distances. It has no street navigation, live capacity feed or external map tiles.
- This remains the requested frontend POC. Production authentication, server authorization, clinical validation, live integrations and real payments are outside its implemented scope.

## Doctor flow update (1 October 2026)

- Doctor registry exposes **Open record**. P001 opens as a full page with Patient 360 tabs, clinical evidence and the next regular dispensing date; the record is no longer a small modal.
- **Create treatment request** opens a full-screen workspace with prescription fields, evidence, monthly refill timing and a clear automatic/exception route. The Doctor screen contains no coverage or patient payment estimate.
- A clinically eligible patient past the calendar-month interval goes directly to **Ready to dispense**. A clinical-rule or early-refill exception requires a doctor rationale, then a separate Reviewer approval reason before Pharmacy. Pharmacy sees coverage and still verifies identity, prescription, stock and safety.
- Automated checks: 48 passed; build and lint passed. Browser inspection confirmed the Doctor registry, dedicated P001 record and full-screen exception request, with P001 next regular dispensing date shown from stored demo data.

## Patient 360 enterprise redesign (1 October 2026)

- Replaced the Doctor patient record with one compact, Arabic-first workspace. The header and brief show identity, care stage, treatment, adherence, dispensing, appointment and system eligibility from canonical records. Actions open the existing treatment and care-plan flows or working appointment/clinical-note forms.
- Walked all ten Patient 360 tabs in English and Arabic. Clinical history uses a dated timeline; Analysis shows real previous results and a clear insufficient-trend state; Treatment links requests and dispensing; Care Plan displays the integrated components; Continuous Care derives progress and adherence; Documents, Notifications and Activity read the shared record.
- Checked RTL desktop widths 1024, 1280 and 1440 px: no document-level horizontal overflow. Abnormal lab results use the warning colour. Free-text clinical notes are preserved as entered rather than partially translated.
- Walked the nine-step care-plan wizard in Arabic through final review without saving a QA-only plan. Centre selection still uses the shared map/distance data and all final checks run through `integratedCareChecks`. The Doctor's care-plan flow shows no financial amount.
- `npm run build`, `npm run lint` and 48 automated tests pass.

### Doctor icon and 150-patient presentation update — 2 October 2026

- Expanded the canonical seed to 150 patients; 99 new patients each include vitals, a submitted assessment, three lab results and a follow-up. The 32 fictional portraits mix everyday clothing with Emirati clothing, with stable assignment across screens.
- Verified the existing v7 merge preserves patient edits, edited results and uploaded files, and that repeated loading adds no duplicates. Doctor assignment restrictions remain in effect.
- Replaced unrelated glyphs with shared SVG icons across doctor navigation, dashboard, request statistics, appointment actions, care plans, patient tabs, documents and map markers; shared components cover other workspaces as well.
- Browser checked mixed portraits in the patient registry and request list, P051's three generated documents, inline report preview, Clinical Care and Decision Support explanatory text, and English/Arabic switching.
- Tested the document view at 390 px: page width remained 390 px and preview/download controls stayed within the screen. Reset the viewport after testing.
- The PDF button downloaded `P051-Fasting-glucose-2026-09-01.pdf` to Downloads. The embedded browser's download-event observer timed out, but filesystem verification and `pdfinfo` confirmed the actual downloaded file: valid one-page A4 PDF, 103,104 bytes.
- Rendered representative English result and Arabic pending-result PDFs with Poppler and visually inspected both. Pending status contains no fabricated numeric result. Test files remain in the temporary QA directory.
- All 74 tests passed; production build and lint passed after the concurrent reports changes were integrated.

### Reviewer overview — reference redesign (2026-10-03)
- Dedicated ReviewerDashboard with medical banner, four KPIs, connected journey, 30-day request trend, latest reviews, appointments and scoped safety alerts.
- All values and linked record lists derive from AppData through reviewerDashboardData; no screenshot totals are baked into the view.
- Chart status filtering, keyboard-accessible point values and table alternative. KPI/journey dialogs preserve patient/request context. Appointment links open the selected scoped appointment in read-only view.
- Verified Arabic/English overview and appointment details; 375px layout has no horizontal overflow. Existing workspace shimmer and reduced-motion support retained.
- Build and focused lint passed; full suite 105 tests passed, including scope, repository changes, date boundaries, chart filtering and upcoming-appointment exclusion checks.

## 2026-10-04 — Connected care assistant
- Rebuilt the bilingual assistant around the supplied reference: mint orbital hero, linked-record sidebar, live derived insights, topic shortcuts, structured replies and request journey.
- Responses read the canonical role-scoped AppData. Added patient/request context, duplicate-name clarification, Arabic numeral IDs, status/date filters, chronological upcoming appointments, abnormal results, shared eligibility rules and assigned doctor lookup.
- Added response sources, follow-up questions, copy/download, conversation reset, compact response options, text-question import, cancellable loading and reduced-motion styles.
- Verified Arabic patient follow-up followed by English all-request filtering in the local browser; P999 lab evidence and three review requests matched stored records. Desktop visual check at 1440×1000. Source links retain canonical IDs; care plan links initialize the patient/plan context.
- Production build passed. Full suite passed at 113 tests before the final focused additions; 19 assistant regression tests pass afterward. Existing bundle-size and Arabic catalogue import warnings remain.
- Local retrieval demo: no external LLM or server database; no clinical decision is executed by the assistant. Phone layout uses responsive styles; a dedicated final mobile browser pass was not completed.
