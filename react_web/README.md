# Health Care

Unified healthcare operations and continuous patient care, built with React and TypeScript. Five workspaces—Admin, Doctor, Medical Reviewer, Pharmacist and Patient—share the same records and deterministic business operations.

## Run

```sh
npm install
npm run dev
```

The active development preview for this implementation is `http://127.0.0.1:5175/`. Vite's port can differ when other development servers are running. Use the sidebar role selector to move between workspaces. The Patient workspace has a clearly labelled **Demo patient profile** selector; choose `P001` for the Resident care-plan scenario or another profile to inspect its own shared records.

## Product areas

- Administrative command board, executive summary, an interactive geographic care map, patient registry, doctor and centre management, safety/misuse reviews, reports and audit.
- Doctor Patient 360 as a compact Arabic-first clinical workspace with ten connected sections: overview, clinical history, analysis, treatment, care plan, appointments, continuous care, documents, notifications and activity. Its appointment, clinical-note, treatment-request and care-plan actions use the shared business operations.
- Doctor assessment drafts, vitals, laboratory results, transparent eligibility checks, treatment drafts/submission, follow-up appointments and guided integrated care planning.
- Reviewer evidence, approval, rejection and information requests with recorded rationale; clinician resubmission and explicit pharmacy release.
- Pharmacist queue with identity attestation and a shared verification matrix, earliest-expiry usable stock selection, batch receipts, movement reconciliation and dispensing history.
- Patient web home, medication/dose history, progress, appointments, activity logging, rehabilitation, notifications and profile.

## Canonical data and operations

`src/domain.ts` owns typed records, the deterministic seed, access checks, selectors and state-changing operations. `canonicalize()` derives patient status, eligibility, adherence and organization identifiers. `domainGraph()` exposes related histories, prescriptions, reviews, decision-support results, verification records, coverage estimates and activity as a normalized read model; these are derived from the source records rather than separate portal mocks.

`src/mockRepository.ts` is the persistence boundary. It uses `healthcare-state-v7` in localStorage, migrates earlier v3–v6 data and preserves current edits. Save failures are surfaced without updating the displayed state. Role switching preserves the shared dataset.

Request/plan IDs survive draft editing and submission. Submission checks current clinical evidence and the one-calendar-month interval since the last dispensing. Eligible requests receive a prescription and go directly to the pharmacy queue. When the system flags a clinical criterion or early refill, the doctor must write an exception rationale; an independent reviewer must record a separate approval reason before pharmacy release. Review and dispensing validate evidence, plan dates and state transitions. Dispensing updates the request, plan, batch, inventory movement, patient medication, estimate, notification and audit in one operation. Invalid actions leave the prior state unchanged. Completed plans remain visible in history.

All stock comes from batches and movements. Expired batches are excluded from usable inventory; pharmacy-ready requests reserve units. Adherence counts distinct recorded dose days within 28 days against the dispensed plan's schedule. `calculateCoverage(patientType, treatmentCost)` applies the specified mock rules everywhere: Citizen 100%, Resident 50%, Visitor 0%. A Resident plan with one medication dispensing unit (AED 1,200) and six physiotherapy sessions (AED 900) totals AED 2,100: programme coverage AED 1,050 and patient amount AED 1,050. Dispensing updates the existing estimate; it does not charge for the care plan twice. These estimates do not process payments.

## Integrated care workflow

A medication Treatment Request and its prescription plan remain separate from the broader Integrated Care Plan. The latter is one canonical umbrella record in `AppData.integratedCarePlans`.

1. Choose **Doctor → Patients → P001**. P001 is a **Resident** assigned to Dr. Laila Hassan. The Doctor opens a dedicated full-page Patient 360 record. It includes the context bar, clinical history, current and previous medication, laboratory evidence, dispensing, adherence and actions.
2. Choose **Create Care Plan**. The nine focused steps cover patient context, optional medication, eligibility, rehabilitation, nearby centre selection, home exercises, follow-up, clinical review and confirmation.
3. Choose Mounjaro **5 mg**, frequency, duration and instructions. The existing evidence rules explain eligibility. An existing unlinked medication request can also be included without creating a second prescription or resetting its review status.
4. Add **Physiotherapy**, six sessions, and select **Abu Dhabi Rehabilitation Centre** from the map or distance-sorted directory. Select **Strength training**, **Walking** and **Flexibility** from the central exercise catalogue.
5. Set the follow-up date/time and monitoring plan. The final review shows all components, clinical evidence, eight completeness checks and the required doctor rationale. Financial coverage appears in the Pharmacist workspace after the request reaches pharmacy.
6. Confirm. One operation saves the care plan, linked medication request when needed, appointment, estimate, notifications and audit. Eligible new medication requests go directly to **Pharmacist**; flagged cases go to **Reviewer** for exception approval first. Rehabilitation/home care appear immediately.
7. In **Integrated care plans**, record a completed rehabilitation session. The same record supplies Patient 360, Patient Portal, Admin and the rehabilitation report. Patient activity can reference a prescribed exercise and its integrated plan. Appointment rescheduling updates the linked care-plan follow-up date; completed attendance updates the patient's latest follow-up.

Medication is optional; rehabilitation-only or exercise/follow-up plans do not create phantom medication requests. Only configured catalogue medication participates in the existing pharmacy rules. A care-plan confirmation follows the same automatic-or-exception routing. Pharmacy still checks prescription, identity, monthly timing (or approved exception), batch and stock.

`Patient360.tsx` renders the Doctor record from canonical patient, clinical, treatment, dispensing, rehabilitation, notification and audit records. `CarePlanViews.tsx` renders the nine-step creation workflow. `CareMap.tsx` reads the same rehabilitation centre/programme, treatment centre, pharmacy and patient records. The map supports layers, marker selection, keyboard selection, zoom, pan and emirate filtering; distance uses the Haversine calculation from the patient's approximate registered-area centroid. Pharmacy outlets are derived from the same central centre/pharmacy relationships used by dispensing. Locations and capacities are demonstration data, not street directions or live availability. No external map service or precise patient address is used.

Saved v7 data is enriched through `initializeCareEcosystem()`, including the P001 Resident/doctor correction for pre-workflow data. Earlier rehabilitation programmes are migrated once into linked integrated plans and financial estimates without repeating dispensing or stock movements. Existing user-entered records are retained.

## Demonstration scenarios

| Scenario | Record |
| --- | --- |
| Active treatment, prior completed course, follow-up, dose history, rehabilitation and care summary | P999 |
| Resident integrated care-plan demonstration; prior medication and physiotherapy | P001 |
| Dispensed treatment and adherence history | P002 |
| High BMI review signal, pending medical review | P004 |
| Eligibility failure and rejected request | P005 |
| Missing HbA1c result and information request | P006 |
| Pharmacy-ready request using low/expiring 10 mg stock | P007 |
| Pending review | P008 |
| Poor adherence and early refill block | P009 / TR-P009-REFILL |
| Initial medical review | P010 / TR-24018 |
| Approved request awaiting explicit release | P011 / TR-24017 |
| Ready for pharmacy verification | P012 / TR-24015 |
| Information requested | P013 / TR-24011 |
| Expired inventory excluded from dispensing | UAE-75-2026-OLD |

The seed is a September/October 2026 presentation snapshot. Date-sensitive checks use the current clock, so due dates, expiry warnings and adherence naturally change over time. Browser QA actions are retained in the running preview; they can change the initial queue counts shown above.

## Interface

Shared navy, green and white styling, compact operational tables, evidence-led request details and a coherent navigation icon family apply across workspaces. The layout adapts to desktop, tablet and narrow web widths. The patient workspace has its own accessible web navigation.

English and Arabic interface catalogues are centralized in `ArabicCatalogue.ts`, `CareTranslations.ts` and `CareWorkflowTranslations.ts`; Arabic loads on demand and applies RTL. The existing DOM translation adapter is retained for compatibility. Record identifiers, email addresses and form values are preserved. Authored care-plan titles and decision notes remain in their entered language. Free-text clinical notes are not a clinically validated translation service.

Dialogs support Escape, focus containment and focus restoration. Patient 360 tabs support arrows, Home and End. Focus styles, semantic labels, text status indicators, lazy-loading feedback, empty results and an error boundary are included. This is not a formal accessibility certification.

## Reports and export

Seventeen report types derive from the same records: integrated care plans, rehabilitation progress, patients, treatment requests, review performance, approvals, rejections, missing information, dispensing, inventory, low stock, expiring medication, adherence, appointments, financial/coverage, audit and operational activity. Reports include source context, filters, summary bars and bounded tables. The programme KPI strip is aggregate context; report filters apply to the report rows, chart and export.

CSV serialization preserves Arabic, quotes and line breaks and protects text cells from spreadsheet formula interpretation. `Preview CSV` exposes exactly the filtered export and provides a copyable fallback when an embedded browser does not support downloading Blob files.

## Validation

```sh
npm run lint
npm test
npm run build
```

The test suite covers domain transitions, access boundaries, evidence validation, draft identity preservation, atomic dispensing, stock/movement reconciliation, repository migrations, rehabilitation, schedule-aware adherence, full care-journey linkage and CSV serialization. Browser verification and limitations are recorded in [QA.md](QA.md).

## POC boundaries

There is no backend, real authentication, external AI, payment gateway, government integration or wearable connection. The role selector simulates authorization; browser storage is not a production security boundary. Decision support uses visible demonstration rules. For this mock workflow, requests meeting configured criteria are routed automatically to the pharmacy queue; clinicians remain responsible for treatment decisions, and pharmacy safety verification still applies. Costs, coverage and risk categories are illustrative. This app is a presentation POC, not a clinical decision or validated prediction service.

## Doctor icons, patient portraits and demonstration reports

The seed now contains **150 patients**. The additional 99 records have bilingual names, demographics, an assigned clinician/centre, vitals, an assessment, three laboratory results and a follow-up appointment. Existing v7 browser data is merged by stable IDs; edited records and uploaded files survive reloads. Doctors still see their assigned patients, while Admin sees the full programme.

`CareIcon.tsx` provides an explicit semantic SVG family across navigation and clinical actions: stethoscope for assessment, specimen flask for labs, prescription clipboard for requests, checklist for integrated care plans and a checked shield for decision support. Clinical care records the assessment and evidence; Decision support checks those saved records using the existing transparent demonstration rules.

`PatientAvatar.tsx` uses both locally stored fictional portrait atlases, with stable portrait metadata on demo records. The 32 illustrative portraits are reused across the demonstration population; they are not identity photographs. New user-created records retain initials until a real portrait feature is introduced. Both atlases were generated with the built-in image generation tool:

- `public/images/demo-patient-portraits.png`: “A square 4 by 4 atlas of 16 distinct fictional Middle Eastern adults; top two rows men, bottom two rows women; ages 30–65; everyday clothing, a mix of hijab and uncovered hair; neutral pale-grey background, natural lighting, centered head-and-shoulders portraits, no text or borders.”
- `public/images/demo-emirati-portraits.png`: “A square 4 by 4 atlas of 16 distinct fictional Emirati Arab adults; top two rows men in white kandura and ghutra with black agal, bottom two rows women in black abaya and shayla; varied adult ages; neutral pale-grey background, natural lighting, centered head-and-shoulders portraits, no text or borders.”

Every saved laboratory result appears in Patient 360 → Documents, with preview and PDF download generated from the current saved values. Existing source uploads stay separately downloadable. Pending results display no numeric result. Reports are clearly labelled demonstration data; PDF binaries are generated on demand rather than filling localStorage with duplicate copies.
