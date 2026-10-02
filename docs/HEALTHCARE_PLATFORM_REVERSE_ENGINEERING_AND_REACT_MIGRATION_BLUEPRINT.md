# Healthcare Platform Reverse-Engineering & React Migration Blueprint

**Project:** Mounjaro treatment management / UAE healthcare programme demo  
**Inspection date:** 1 October 2026  
**Source inspected:** `mounjaro_demo/` Flutter application  
**Purpose:** source-grounded product and implementation specification for a future React rebuild. This is documentation only; no Flutter code was changed for this deliverable.

## Evidence and status legend

- **[IMPLEMENTED]** Visible in the active application source. It does not, by itself, mean production-ready.
- **[PARTIAL]** Some screen or local workflow behavior exists, but important scope, validation, persistence, integration, or operational pieces are absent.
- **[MOCK]** Demonstration fixture, deterministic simulation, hard-coded assumption, local-only state, or fake provider/user. Never present this as live Ministry data or an approved policy.
- **[INFERRED]** A conclusion from source wiring or behavior, explicitly not a source-declared product requirement.
- **[RECOMMENDED]** Proposed React target behavior or architecture, not a claim about current behavior.
- **[NOT IMPLEMENTED]** No implementation was found in the inspected active project.
- **[VERIFIED]** A check was actually executed and its result is reported; this is not a certification of production readiness.

Status labels describe the evidence, not a quality certification. Where several apply, more than one label is shown. The active entry path and source were inspected directly; the earlier `HEALTHCARE_SYSTEM_AUDIT.md` was treated as a navigation aid only. Source references below are relative to this document's parent app folder (`mounjaro_demo/`) and include symbol/line anchors for the inspected snapshot; line numbers will move as code changes.

---

## 1. Executive Summary

The current product is a polished **Flutter stakeholder demo** with a Ministry/admin command center, doctor/medical-reviewer workspace, dispensing-centre workspace, and patient web/mobile-responsive experience. It has bilingual Arabic/English presentation, role-scoped UI actions, shared in-process demo data, a deterministic rule-based treatment-request journey, pharmacy stock checks, patient 360, dashboards/reports, and meaningful widget/provider tests. **[IMPLEMENTED][MOCK]**

It is not a connected national health system or a production clinical platform. No server API, identity provider, database, durable file service, external laboratory/claims interface, production notifications, device integration, or auditable deployment boundary was found in the Flutter project. State is held in client memory and resets with a fresh app session. **[NOT IMPLEMENTED]**

The clearest implementation strengths are the breadth of role-specific flows; real cross-screen provider wiring within one app process; structured treatment request states and audit events; deterministic eligibility/dispensing checks; responsive Arabic RTL coverage; and test evidence. The clearest migration risks are the split between legacy and canonical workflows, client-only role checks, duplicate/overlapping state representations, a mixed clock (`DateTime.now` and `DemoClock`), seed data with demo-only dates and assumptions, and a distinction between “AI” presentation and an actual model. **[PARTIAL][MOCK]**

**Migration recommendation:** preserve the visible workflows and domain semantics, but rebuild the client around typed API contracts and server-authoritative workflow/policy decisions. Do not port the Flutter providers as if they were a backend. Before any Ministry-facing production claim, the clinical programme rules, coverage assumptions, identity/authorization, data provenance, retention, hosting, interoperability, audit controls, and operational responsibilities need named owners and formal approval. **[RECOMMENDED]**

### Decision snapshot

| Area | Current evidence | React migration implication |
|---|---|---|
| Portals | Admin, doctor/reviewer, pharmacy, patient web, patient mobile-responsive. **[IMPLEMENTED]** | Keep separate role shells over shared domain modules. **[RECOMMENDED]** |
| Journey | Local deterministic rules and review/dispense workflow; common `DataProvider` is shared across portals in a running app. **[IMPLEMENTED][MOCK]** | Move transition authorization, eligibility, approval, and dispense invariants to API/domain services. **[RECOMMENDED]** |
| Data | Mock fixtures plus mutable in-memory `DataProvider`; no durable store. **[MOCK]** | Define persistence, event IDs, versioning, and audit semantics before UI migration. **[RECOMMENDED]** |
| AI | Rule-based/simulated recommendations; no inference/model service in source. **[MOCK][NOT IMPLEMENTED]** | Label decision support accurately; retain human accountable decision. **[RECOMMENDED]** |
| Localization | Arabic/English and global RTL/LTR directionality; translation dictionaries. **[IMPLEMENTED]** | Preserve, add translation completeness/accessibility and locale-aware dates/numbers. **[RECOMMENDED]** |
| Verification | `flutter test`: 73 tests passed; `flutter analyze`: no issues. | Useful baseline, not an end-to-end integration or regulatory validation. |

## 2. System Overview

**[IMPLEMENTED]** The active Flutter entry is `lib/main.dart`: provider graph → `MaterialApp` → splash → login → role-selected shell. App title is “Health System”; supported locales are `en` and `ar`; Arabic defaults; global `Directionality` changes with locale. There are no named routes/deep links in the active routing setup: navigation is shell-local index state and `Navigator` page pushes.

The central data source in this client is `DataProvider` (`lib/core/constants/mock_data.dart`), initialized from static `MockData` lists and augmented with a special P999 demo beneficiary, lab data, plans, pharmacy requests, treatment requests, activity logs, and facilities. `JourneyProvider` is connected to this provider through `ChangeNotifierProxyProvider`; role-scoped portal previews create a scoped `AccessControlProvider` and journey provider but reuse the same underlying `DataProvider`. This gives useful same-browser demo continuity, not cross-user or cross-device persistence. **[IMPLEMENTED][MOCK]**

### Runtime outline

```text
main.dart
  └─ LocaleProvider / ThemeProvider / AccessControlProvider / DemoSessionProvider
     └─ DataProvider(access + demo session)
        └─ JourneyProvider(DataProvider + AccessControlProvider)
           └─ Splash → role-picker login → Admin | Doctor/Reviewer | Pharmacy | Patient
```

**[PARTIAL]** A `MainShell` and older login implementations also exist, but `MaterialApp.home` does not enter `MainShell`; current role login routes directly to the four portal shells. Treat those parallel files as legacy until a route/call-site audit proves otherwise.

## 3. Product Goals

### Evident demo goals

- **[IMPLEMENTED][MOCK]** Demonstrate national/programme oversight and geographic analytics.
- **[IMPLEMENTED][MOCK]** Demonstrate patient registration, profile/history, treatment plan and request handling.
- **[IMPLEMENTED][MOCK]** Demonstrate medical review and reviewer decision separation from doctor role.
- **[IMPLEMENTED][MOCK]** Demonstrate dispensing checks, stock batches, dispensing records, and patient follow-up.
- **[IMPLEMENTED][MOCK]** Demonstrate patient-facing treatment, medication/adherence, appointments/sessions, exercise and notifications.
- **[IMPLEMENTED]** Demonstrate Arabic and English layouts, RTL/LTR, and responsive breakpoints.

### Not established as production goals in code

- **[NOT IMPLEMENTED]** Approved national Mounjaro clinical policy or regulator-endorsed eligibility rules.
- **[NOT IMPLEMENTED]** Live claims adjudication, insurance payment, Ministry funding, or official subsidy calculation.
- **[NOT IMPLEMENTED]** Interoperability with national ID, EHR, laboratory, e-prescription, pharmacy, or government systems.
- **[NOT IMPLEMENTED]** Production authentication, tenant/organization isolation, legally valid e-signature, or trusted audit.
- **[NOT IMPLEMENTED]** Production clinical AI, wearable ingestion, remote monitoring, or automated intervention.

## 4. Portal Architecture

| Portal / workspace | Current implementation | Notes |
|---|---|---|
| Ministry / System Admin | `WebAdminShell` with 15 indexed destinations: executive dashboard, map analytics, patient registry/360, inventory, Alert OS sections (overview/live feed/assistant), misuse/fraud audit, reports, embedded doctor, embedded pharmacy, embedded patient, doctor management, centre management, system audit. **[IMPLEMENTED]** | Wide-screen shell switches to drawer below 1100 px. Embedded role previews share the local data provider but scope UI permissions. **[IMPLEMENTED][MOCK]** |
| Doctor | `WebDoctorShell`, two top-level tabs: patient registry and assessments; patient selection opens `Patient360View`. **[IMPLEMENTED]** | This is not a separate full multi-tab patient chart at shell level; Patient 360 contains 11 patient tabs. |
| Medical reviewer | Same doctor shell, role-dependent labels and review queue; login opens index 1. **[IMPLEMENTED][PARTIAL]** | Not a separate shell or identity; permission map differentiates reviewer. |
| Dispensing centre / pharmacy | `WebCenterShell`: dispense, inventory, dispensing logs. **[IMPLEMENTED]** | Selects centre from `DemoSessionProvider`, defaults C001. Mobile has dispense/inventory only. |
| Patient web | `WebPatientShell`: home, health profile, plan overview, medication, sessions, exercises; notifications, language/theme/logout and a demo AI assistant entry are present. **[IMPLEMENTED][MOCK]** | Patient ID comes from demo session (P999 default); not authenticated identity. |
| Patient mobile | `MobilePatientShell` provides home, profile, plan overview, medication, sessions, exercise pages plus a “more” sheet for some destinations. **[IMPLEMENTED]** | This is Flutter responsive/mobile UI; source does not establish store-published mobile apps or push-notification infrastructure. **[NOT IMPLEMENTED]** |

## 5. Roles & Permissions

`AppRole`: `systemAdmin`, `doctor`, `medicalReviewer`, `pharmacist`, `careCoordinator`, `patient`. `AppPermission`: view/edit patient; create plan/request; eligibility review; approve/reject/send to pharmacy; dispense/inventory; follow-up; view/edit labs/documents; appointments; audit; adherence; patient activity; request medication. **[IMPLEMENTED]**

| Role | Current permission intent |
|---|---|
| System admin | All `AppPermission` values. **[IMPLEMENTED]** |
| Doctor | View/edit patient, create plan/request, eligibility review, follow-up, view/edit labs/documents, appointments, audit, patient activity. No treatment approve/reject or pharmacy dispense. **[IMPLEMENTED]** |
| Medical reviewer | View patient; review eligibility; approve/reject/send to pharmacy; read labs/documents/audit. **[IMPLEMENTED]** |
| Pharmacist | View patient; dispense, inventory; read labs/documents/audit. **[IMPLEMENTED]** |
| Care coordinator | View patient; follow-up/appointments; read labs/documents/audit; patient activity. **[IMPLEMENTED]** |
| Patient | View own patient/labs/documents; record adherence/activity; request medication. **[IMPLEMENTED]** |

**Security boundary:** `AccessControlProvider` is a client-side UI/service guard, not an identity, authorization server, or security boundary. `_can()` in `DataProvider` returns `true` when no access provider is injected; certain service methods take caller-supplied role/`authorized` values. Production must derive subject and permissions from a verified server session and enforce patient/facility/tenant scope server-side. **[PARTIAL][RECOMMENDED]**

**Role mapping gap:** the login UI exposes admin, doctor, reviewer, center, patient; `careCoordinator` exists only in the permission model, with no dedicated login route/shell. **[PARTIAL]** Login is a demo role picker rather than credential verification. **[MOCK]**

## 6. Navigation Architecture

- **[IMPLEMENTED]** Entry: splash animation → `LoginScreen` → `PremiumLoginScreen` → role-selected shell via `Navigator.pushReplacement`.
- **[IMPLEMENTED]** Admin: 15 integer destinations in `_selectedIndex`; alert subsections map into indexed Alert OS pages.
- **[IMPLEMENTED]** Doctor/reviewer: 2 indexed destinations, patient registry and clinical assessments/review queue; selected patient opens 360 view with initial tab index.
- **[IMPLEMENTED]** Pharmacy: 3 web destinations, 2 mobile destinations.
- **[IMPLEMENTED]** Patient: 6 web/mobile destinations; mobile “more” opens a bottom sheet for sessions, exercises, profile.
- **[PARTIAL]** Patient 360 is a tab view controlled by local `TabController`; deep links, browser back synchronization, reload-safe selected tabs, access-aware URLs, and server-driven route guards are not present.
- **[PARTIAL]** Shell indexes are fragile: integer indices couple menu order, selected index, and switch statements. React should use named route IDs and role-aware route manifests. **[RECOMMENDED]**

## 7. Complete Screen Inventory

### A. Ministry / admin desktop shell

| Destination | Current evidence | Main function |
|---|---|---|
| Executive dashboard | `admin_views/national_command_center.dart`, shell overview | Programme KPIs, activity/operations view. **[IMPLEMENTED][MOCK]** |
| Geographic analytics | `web_map_analytics_screen.dart` / regional analytics | Emirate/facility/patient map and summaries. **[IMPLEMENTED][MOCK]** |
| Patient registry | `patients/patient_registry_view.dart` | Search/filter/paginate patients and open 360. **[IMPLEMENTED][MOCK]** |
| Patient 360 | `treatment_plan/web/patient_360_view.dart` | Overview, medical history, plan, journey, medication, labs, eligibility, requests, documents, appointments, audit. **[IMPLEMENTED][MOCK]** |
| Inventory | `web_admin_shell.dart` `InventoryView` | Facility stock and replenishment UI. **[IMPLEMENTED][MOCK]** |
| Alert OS | `alert_os_dashboard.dart` | Overview, live feed, AI assistant. **[IMPLEMENTED][MOCK]** |
| Misuse/fraud audit | `_FraudAuditView` | Flagged/overridden sample events. **[IMPLEMENTED][MOCK]** |
| Reports | `reports_command_center.dart` + `report_analytics_data.dart` | Filtered derived KPIs, operations, trends, and CSV/JSON export. **[IMPLEMENTED][MOCK]** |
| Embedded doctor | `OperationalPortalPreview` + `WebDoctorShell` | Shared data, doctor-scoped UI. **[IMPLEMENTED][MOCK]** |
| Embedded pharmacy | `OperationalPortalPreview` + `WebCenterShell` | Shared data, pharmacist-scoped UI. **[IMPLEMENTED][MOCK]** |
| Embedded patient | `OperationalPortalPreview` + `WebPatientShell` | Shared data, patient-scoped UI. **[IMPLEMENTED][MOCK]** |
| Manage doctors | `_ManageDoctorsView` | Local doctor directory changes. **[IMPLEMENTED][MOCK]** |
| Manage centres | `_ManageCentersView` | Local dispensing/therapy centre management. **[IMPLEMENTED][MOCK]** |
| System audit | `system_audit_log_view.dart` | Activity log display and unread badge. **[IMPLEMENTED][MOCK]** |

### B. Doctor and reviewer

- **[IMPLEMENTED][MOCK]** Patient list, search/filter, patient selection, clinical assessment/review queue, eligibility and lab context, approve/reject/request-information actions (role-dependent), patient registration dialog, plan creation, Patient 360.
- **[PARTIAL]** Reviewer is a doctor-shell variant with a review label and queue; not a distinct application or separate identity lifecycle.
- **[PARTIAL]** Registration supports PDF/images through `file_picker`; there is no verified secure upload service in this project.

### C. Pharmacy

- **[IMPLEMENTED][MOCK]** Dispensing queue/detail, patient/plan/eligibility/lab/prescription/cooldown/stock validation, confirmation screen, in-memory dispense, stock batch consumption, inventory and logs.
- **[PARTIAL]** Coverage review UI calculates a local estimate; `PaymentScreen` source explicitly says it records no payment collection. Do not label estimated coverage as a paid claim.
- **[PARTIAL]** Mobile pharmacy omits dispensing logs and has a mobile inventory placeholder/simplification compared with desktop.

### D. Patient web/mobile

- **[IMPLEMENTED][MOCK]** Dashboard and profile; plan overview/medication/sessions/exercises; medication order wizard (eligibility/centre/payment-style review/success); notifications; adherence recording; weight check-in; appointment/session data.
- **[PARTIAL]** “AI Health Assistant” is a demo UI. No live assistant/model call was found.
- **[NOT IMPLEMENTED]** Wearable device ingestion, real reminders/push, telehealth, external support channel, or identity-backed patient self-service.

### E. Patient 360 tabs

Current source order: **Overview; Medical History; Treatment Plan; Treatment Journey; Medications; Laboratory Results; Eligibility; Treatment Requests; Documents; Appointments; Audit Trail. [IMPLEMENTED]**

## 8. Data Model

The authoritative source today is a set of Dart classes in `core/constants/mock_data.dart`, `features/treatment_plan/models/treatment_plan.dart`, `features/journey/journey_models.dart`, and clinical attachment models. Objects are mutable/in-memory; they are not database entities or API DTOs. **[MOCK]**

| Entity | Key fields / current semantics | Status |
|---|---|---|
| Patient | Local ID/MRN, Emirates ID string, bilingual names/nationality/gender/emirate, residency, age, height/weight/BMI, conditions/chronic flag, labs, current dose/dose history, dispense history, next eligible string, facility, location, compliance, attachments, allergies/current medicines. | **[MOCK]** |
| TreatmentPlan | Patient/doctor, creation/update, medication dose/interval/quantity/prescription/validity/reminders, assigned therapy centre, sessions, home exercises, target weight, Active/Completed/Paused status, approval status. | **[MOCK]** |
| DemoTreatmentRequest | Patient and plan references plus demographic snapshots, diagnosis, medication/indication, prior/current treatment, CRP/ESR, physician-report flag, duplicate/urgent flags, status, deterministic criteria/recommendation, human decision/reviewer note/override, validity, monitoring, audit events. | **[MOCK]** |
| PharmacyDispensingRequest | Patient/plan/treatment request, medicine/dose/quantity, requested time, assigned centre, priority, queue status. | **[MOCK]** |
| DispensingCenter | Bilingual centre name/region, dose counters, batch list, geo, phone. `totalAvailable` and allocated totals are derived. | **[MOCK]** |
| MedicationBatch | ID, dose, expiry, remaining quantity. Consumption sorts expiry ascending and uses in-date batches first (FEFO-like). | **[IMPLEMENTED][MOCK]** |
| PatientDispenseRecord | Date string, dose, centre ID. Source reconciles initial records from dose history and last dispense. | **[MOCK]** |
| PatientLabResult | Code/name/value/unit/reference/date/source/notes/category/trend list. The seeded one-point trends do not establish a true longitudinal series. | **[MOCK]** |
| PatientAppointment | ID/patient/date/time/doctor/purpose/status (scheduled/completed/cancelled/missed). Initially materialized from care-plan sessions. | **[MOCK]** |
| TherapySession / HomeExercise | Session number/date/attendance/weight/notes; exercise name, bilingual instructions, category/duration/sets/reps/completed dates. | **[MOCK]** |
| MedicationDoseEvent | Patient/plan/scheduled and recorded timestamps/status taken/skipped/missed. | **[PARTIAL][MOCK]** |
| FinancialSupportRecord | Request/plan/patient references, total/covered/copay AED, estimated/settled/cancelled, assessed timestamp. | **[MOCK]** |
| PatientNotification | Patient ID, title/detail, created time/read flag. | **[MOCK]** |
| ActivityLog / JourneyAuditEvent | Actor/role/action/status/time, optionally previous/new request state/reason/recommendation/decision. | **[PARTIAL][MOCK]** |
| Doctor / PhysicalTherapyCenter | Directory/provider/facility metadata and service/location data. | **[MOCK]** |

## 9. Entity Relationships

```text
Patient 1 ── * TreatmentPlan (application effectively assumes one active plan)
Patient 1 ── * DemoTreatmentRequest ── 1 TreatmentPlan
DemoTreatmentRequest 1 ── 0..* PharmacyDispensingRequest (current sync expects linked queue)
PharmacyDispensingRequest * ── 1 DispensingCenter
DispensingCenter 1 ── * MedicationBatch
Patient 1 ── * PatientLabResult / Appointment / Notification / DispenseRecord / DoseEvent
TreatmentPlan 1 ── * TherapySession / HomeExercise
TreatmentRequest 1 ── 0..1 FinancialSupportRecord (usually one local estimate, then settlement)
TreatmentRequest 1 ── * JourneyAuditEvent
```

**[INFERRED]** The model allows history, but several selectors use “last request” or the first active plan and the service often assumes one active request/plan and one current queue item per patient. The React domain must define versioning and uniqueness explicitly rather than copy these assumptions accidentally. `assignedCenterId` on treatment plan can refer to `T001` (therapy center), while pharmacy queue has a separate dispensing-centre identifier; the relationship must stay distinct.

## 10. Mock Data Architecture

- **[MOCK]** Static lists are generated under `MockData` for doctors, patients, dispensing centres, therapy centres, treatment plans, and laboratory fixtures.
- **[MOCK]** `DataProvider` copies some lists, inserts P999 (Ahmed Al Mansoori), assigns patient-specific lab values, ensures P999 has a plan, reconstructs dispensing history/facility data, and seeds activity, queue and request records.
- **[IMPLEMENTED][MOCK]** Most portals read and mutate one shared `DataProvider` in the same running app; `JourneyProvider` mirrors request history into it when attached.
- **[MOCK]** There is no database, API, service-worker cache, local database, local storage, or cross-browser synchronization in the inspected dependency/config/source.
- **[MOCK]** `DemoSessionProvider` starts at patient P999 and centre C001; it holds only local selection context.
- **[PARTIAL]** `DemoClock` is used by the journey module, but many data/business methods and fixture generators call `DateTime.now()` directly. See §39.
- **[MOCK]** Some log examples are seeded narratives (“misuse prevented”, overrides, IDs). They are illustrative examples, not evidence those incidents occurred in production.

## 11. UAE Context

- **[IMPLEMENTED][MOCK]** Emirates ID-shaped identifiers, Emirates/emirate labels, AED formatting, bilingual English/Arabic names and facilities, UAE-themed portals and location points appear in the fixtures/UI.
- **[MOCK]** `DemoFinancialSupportPolicy` declares AED 1,000 per medication unit and sample coverage ratios of citizen 100%, resident 50%, visitor 0%, explicitly labeled local demo assumptions. These values are **not** an official payer or Ministry policy.
- **[MOCK]** `ClinicalEligibilityConfig` sets local demo BMI/HbA1c/glucose thresholds and English-language contraindication strings. These values must not be represented as approved UAE clinical guidance.
- **[NOT IMPLEMENTED]** No official national identity verification, UAE Pass, national terminology, FHIR/HL7 endpoint, claims API, insurer integration, licensed e-prescribing, Ministry master data, data-residency control, retention schedule, or demonstrated regulatory sign-off was found.
- **[RECOMMENDED]** Have UAE clinical, programme, pharmacy, finance, privacy, cybersecurity, and interoperability owners sign off policy and data contracts before production design is frozen. No current regulation is asserted in this reverse-engineering document.

## 12. Treatment Lifecycle

### Current request states

`draft → submitted → assessing → needsInformation | underReview → approved | rejected | needsInformation → readyToDispense → dispensed → monitoring → renewalDue | completed`; `needsInformation → submitted`; `renewalDue → monitoring | completed`. `rejected`, `completed`, `expired`, `cancelled` have no outbound transitions in the declared graph. **[IMPLEMENTED]**

### Current process and hand-offs

1. **Patient selection / context.** Doctor or admin opens a patient; `JourneyProvider.bindExistingPatient()` constructs a request snapshot/criteria from the current record if no history exists. **[IMPLEMENTED][MOCK]**
2. **Plan creation.** Doctor creates a `TreatmentPlan`; `DataProvider.createTreatmentPlan()` validates a subset of plan fields, sets `pending_review`, creates a draft treatment request and pending pharmacy queue item, and cancels a superseded unfinished request/queue. **[IMPLEMENTED][MOCK]**
3. **Submission.** Doctor submits only a draft or information-requested request, and an attached provider requires a matching active plan. **[IMPLEMENTED]**
4. **Automated assessment.** A deterministic local rule evaluator writes criterion results/recommendation. Missing mandatory criteria routes to `needsInformation`; otherwise the request goes to `underReview`. This is not AI inference. **[IMPLEMENTED][MOCK]**
5. **Human review.** Medical reviewer can approve/reject/request information; reason is required for non-approval, and a disagreement with the rule recommendation requires a reason. Successful approval updates request and plan approval. **[IMPLEMENTED]**
6. **Release to pharmacy.** Reviewer sends approved request to pharmacy after approval-validity and `pharmacyReleaseIssues` checks; queue synchronization links the request. **[IMPLEMENTED]**
7. **Dispense.** Pharmacist confirmation checks plan, approval, recent required labs, eligibility, prescription, dose/quantity/frequency, medication allergy, refill interval, assigned centre stock and ready linked request; batch quantities are consumed, dispense records/financial status/activity/notification updated. **[IMPLEMENTED][MOCK]**
8. **Monitoring / renewal.** `startMonitoring`, `markRenewalDue`, and `completeTreatment` exist in JourneyProvider. Patient adherence/weight/session events are recorded through separate DataProvider paths. **[PARTIAL]**

### Important path split

**[PARTIAL]** There are both a canonical JourneyProvider request lifecycle and legacy DataProvider paths. Patient 360 plan creation submits and evaluates automatically; the refill wizard can create a `readyToDispense` request directly under a previously approved plan. The pharmacy screen may therefore see seeded or legacy queue states that did not pass through every visible journey stage. Keep the business invariant in one server workflow in React; do not merely port all routes as equally authoritative.

## 13. Golden Patient Journey

Recommended demo narrative, source-backed where indicated:

| Step | Persona | Data/action | Observable result |
|---|---|---|---|
| 1. Register/select | Doctor | Select existing beneficiary or register demographics/clinical details/attachments. **[IMPLEMENTED][MOCK]** | One patient ID reused in list and 360. |
| 2. Review record | Doctor | Inspect diagnosis, vitals/BMI, labs, medications, documents, prior dispensing. **[IMPLEMENTED][MOCK]** | Missing or abnormal evidence clearly marked; no fabricated “AI certainty”. |
| 3. Create plan/request | Doctor | Select valid medicine/dose/quantity/interval, assigned facility; submit to review. **[IMPLEMENTED][MOCK]** | Plan and request IDs linked. |
| 4. Assess | Rule engine | Calculate local criteria and attach rule/version/evidence. Current: local deterministic evaluation. **[MOCK]** | `needsInformation` or `underReview`; every criterion visible. |
| 5. Human decision | Reviewer | Approve/reject/request information with reason/override reason. **[IMPLEMENTED]** | Actor, timestamp, prior/new state and evidence captured locally. |
| 6. Prepare dispensing | Reviewer/pharmacy | Release approved, valid request to an assigned centre; show queue/stock. **[IMPLEMENTED][MOCK]** | Ready/blocking reasons visible, not just a disabled action. |
| 7. Dispense | Pharmacist | Confirm identity, prescription, dose, stock/batch/expiry and dispense. **[IMPLEMENTED][MOCK]** | Inventory decreases; dispense and local notification appear. |
| 8. Continue care | Patient/doctor/coordinator | Take/skip/miss dose, record weight, attend session, labs/follow-up and renewal. **[PARTIAL][MOCK]** | Adherence, plan and longitudinal outcomes agree across portals. |

**React acceptance gate [RECOMMENDED]:** each step must preserve one immutable patient/request/plan/dispense identity across role sessions and reload; status transitions must be API-enforced and auditable; all failed actions must return actionable reasons; no next state may be inferred only from an optimistic UI mutation.

## 14. Negative Flows

| Condition | Current behavior found | Migration behavior required |
|---|---|---|
| Missing lab/docs | Journey may classify missing information; dispensing requires recent HbA1c + fasting glucose; report/reference attachment checks are partial. **[IMPLEMENTED][PARTIAL]** | Block with exact missing evidence, owner and “what to do next”; validate collection date/source on server. **[RECOMMENDED]** |
| Ineligible patient | Rule engine adds violation; create plan/dispense guards block. **[IMPLEMENTED][MOCK]** | Versioned clinical policy, clinician override policy, transparent explanation, server audit. |
| Recent duplicate/early refill | Cooldown blocks; separate reviewer authorization/override structures exist. **[IMPLEMENTED][MOCK]** | Separate routine clinical authorization from exception override; require reason, evidence, named approver, expiry and second-person policy if approved. |
| Expired prescription/approval | Some dispense/release validations reject expiry. **[IMPLEMENTED]** | Use consistent server UTC timestamps and expiry semantics; handle race condition at final commit. |
| Out-of-stock/expired stock | Pharmacy queue derives pending/out-of-stock; dispensing consumes in-date batches. **[IMPLEMENTED][MOCK]** | Reserve stock transactionally, prevent double allocation, display alternative centre/transfer flow. |
| Duplicate active request | Refill submission blocks an existing active queue; plan creation supersedes some open request. **[IMPLEMENTED][PARTIAL]** | Define idempotency, active request uniqueness, amendment/resubmission semantics centrally. |
| Bad/unknown patient/centre/plan | Service returns failure/empty state in some flows. **[PARTIAL]** | 404/validation/error states with recovery action; never silently fall back to arbitrary first record/centre. |
| Invalid dose/quantity/frequency | Dose utility and plan validation block unsupported dose/nonpositive quantities/intervals. **[IMPLEMENTED]** | API schema validation and program catalog version. |
| Permission denied | Some provider methods return false/no-op and JourneyProvider adds access-denied audit. **[PARTIAL]** | HTTP 403 with localized explanation, server audit, hidden/disabled UI only as convenience. |
| Network/service failure | Not meaningful in current local-only app. **[NOT IMPLEMENTED]** | Loading, retry, stale-data, idempotent submit and offline policy. |
| Concurrent approval/dispense | No server concurrency/locking. **[NOT IMPLEMENTED]** | Optimistic concurrency/version + transactional writes; conflict UI. |

## 15. Business Rules

### Source-defined local demo rules

- **[MOCK]** BMI minimum: 30 without chronic disease, 27 with chronic disease.
- **[MOCK]** HbA1c blocks only when `> 8.5%`; fasting glucose blocks only when `> 180 mg/dL`; equality passes.
- **[MOCK]** Missing HbA1c/glucose does not fail `ClinicalEligibilityRules` by default (`requireLabValuesOnFile = false`), but pharmacy dispensing independently requires both results in the prior 180 days.
- **[MOCK]** Contraindications match an English condition label exactly (case-insensitive): Active pancreatitis, Medullary thyroid carcinoma, Pregnancy. Arabic or synonymous terms are not normalized by this list comparison.
- **[MOCK]** Dispense requires active plan, approved status, valid prescription, supported dose, quantity ≥ 1, interval ≥ 1, eligible patient, required recent labs, no unresolved medication allergy, permission, center, available in-date stock, and a linked ready queue/request. Current medication-list presence yields a warning to review rather than a drug-interaction computation.
- **[MOCK]** Refill cooldown derives from last dispense and current plan interval; default `Patient.isWithinDispensingCooldown` is 28 days when no interval is supplied.
- **[MOCK]** A treatment review approval can be valid for 30 days in JourneyProvider/legacy approval paths.
- **[MOCK]** Active plan is found by first patient-matched plan whose string status equals `Active`; multiple active plans are not disambiguated.
- **[MOCK]** `_consumeBatches` sorts expiry ascending and consumes eligible stock from earliest-expiring batches.
- **[MOCK]** Coverage: AED 1,000 × plan medication quantity; residency-based demo ratios (citizen/resident/visitor 100/50/0%). This is a local financial illustration, not an official benefit determination.

### Rules not present / require decision

- **[NOT IMPLEMENTED]** Approved clinical treatment guideline with disease-indication combinations, full contraindications, titration, monitoring/follow-up intervals, age/pregnancy/lactation nuance, renal/hepatic concerns, medication interactions, and specialist sign-off.
- **[NOT IMPLEMENTED]** Formal residency/insurance/benefit evidence, annual caps, co-pay exceptions, claim status lifecycle, payer rules or adjudication.
- **[NOT IMPLEMENTED]** Versioned policy effective dates, retrospective recalculation policy, appeals, independent override controls, or clinical governance.
- **[RECOMMENDED]** Treat all hard-coded thresholds as demo rules until policy owners approve a machine-readable ruleset and release process.

## 16. Calculations

| Metric | Current calculation | Caveat |
|---|---|---|
| BMI | `weight / (heightM × heightM)` on `Patient`. **[IMPLEMENTED]** | Height/weight are fixture/user-entered and have no unit/source/time provenance. |
| Eligibility | Rule evaluation described in §15. **[IMPLEMENTED][MOCK]** | Demo program criteria; not official clinical guidance. |
| Dispensing cooldown | Difference between local calendar dates since last dispense vs plan interval. **[IMPLEMENTED][MOCK]** | Code uses system `DateTime.now`; separate `nextEligibleDate` text can be stale. |
| Recent labs | Exact codes HbA1c and Fasting glucose, parseable date within 180 days and not future. **[IMPLEMENTED][MOCK]** | No server timezone/date standard; source/authenticity/units are not validated in this check. |
| Dose adherence | Current event log calculates taken / event count in report; other patient-facing/demo compliance fields use pre-seeded `complianceRate`. **[PARTIAL][MOCK]** | Different UI and report paths can show different underlying measures. |
| Reports: BMI/weight trends | Monthly values from plan session weight observations; patient weight-history lists are not dated observations. **[PARTIAL][MOCK]** | Trend completeness depends on attended sessions with weight. |
| Report abnormal lab | Parses simple `<`, `>`, or numeric range reference string. **[IMPLEMENTED][MOCK]** | Unparseable reference is treated as within range; units and test-specific clinical interpretation are not normalized. |
| Financial estimate | Unit price × quantity and sample ratio; settlements counted from locally updated financial records. **[MOCK]** | Not a claim, payment or official subsidy. |
| Dashboard active totals | Mostly provider-derived counts; one legacy getter `totalActivePatients` simply returns all patient count. **[PARTIAL]** | KPI names must be reconciled to written metric definitions. |

## 17. State Management

- **[IMPLEMENTED]** Flutter `provider`/`ChangeNotifier` for locale, theme, role, session, central data and journey state.
- **[IMPLEMENTED]** `DataProvider` is shared by widgets through root-level providers; changes trigger rebuilds across portal previews.
- **[IMPLEMENTED]** `JourneyProvider` can use a local per-patient fallback when instantiated without a `DataProvider`, but active app wiring connects it to the shared central store.
- **[PARTIAL]** Several screens maintain independent selection/search/filter state; some mutable entities/lists are directly mutated and then notify listeners.
- **[NOT IMPLEMENTED]** Durable state, multi-user concurrency, synchronization/conflict resolution, API cache invalidation, persistence migrations, offline write queue, or explicit event replay.
- **[RECOMMENDED]** React: server state via typed query/cache layer; local UI state separately; workflow commands as API mutations returning canonical resources; no duplicated write-model state in page components.

## 18. User Actions

### Actions verified in source

- Admin: navigate portal sections; toggle Arabic/English and theme; open patient 360; manage local doctor/centre records; replenish stock; view reports/alerts/audit. **[IMPLEMENTED][MOCK]**
- Doctor: search/filter and select patient; open 360 tabs; register patient; create plan/request; add documents/labs; schedule/reschedule/cancel appointment; record clinical activity/weight. **[IMPLEMENTED][MOCK]**
- Reviewer: assess queue; approve/reject/request information; reason/override reason flows. **[IMPLEMENTED][MOCK]**
- Pharmacist: select patient/request; see dispense blockers/warnings; review cost estimate; confirm handover; replenish inventory; inspect dispense logs. **[IMPLEMENTED][MOCK]**
- Patient: view dashboard/health/plan; choose centre and proceed through order wizard; record medication status/weight/session; view notifications; inspect exercises. **[IMPLEMENTED][MOCK]**

### Action semantics to preserve/improve

- **[PARTIAL]** Several methods fail via Boolean/void/no-op, so a UI action may give little detail; React endpoints should return typed validation errors.
- **[PARTIAL]** Some actions have separate code paths (legacy direct approval/refill vs JourneyProvider) with different audit richness and transitions.
- **[RECOMMENDED]** Every state-changing action should show actor, target, consequence, evidence, pending/success/failure, be idempotent where retried, and append one server event.

## 19. Admin Portal

**[IMPLEMENTED][MOCK]** National command center, regional/map view, patient registry, central stock, Alert OS overview/feed/assistant, misuse log, program reports, embedded operational portal demos, provider/facility management, system activity log. UI has unread/pending/ready badges and language/theme/logout controls.

**[PARTIAL]** Menu is code-indexed and not route-addressable. The topbar notification icon points users back to the Alerts Center rather than an independent notification inbox. Admin CRUD changes only in-memory lists. Alert/fraud numbers depend on mock activity records, including synthetic examples. No admin audit actor identity is authenticated.

**React target [RECOMMENDED]:** URL-addressable modules; explicit data freshness/provenance; permission-aware navigation; filter state reflected in URLs; separate operational vs analytic data; admin changes with confirmation, validation, server audit and rollback/version history.

## 20. Doctor Portal

**[IMPLEMENTED][MOCK]** Patient registry, search and filters; selected patient Patient 360; registration dialog; clinical review context; treatment plan builder; local assessment and request workflow. Patient 360 offers 11 tabs (listed in §7).

**[PARTIAL]** Plan creation writes a local plan and associated request/queue. Patient 360 then binds the patient, submits and immediately evaluates. Some review calls return actions that are local or data-provider-specific. Chart/document upload is not backed by a persistent repository. Many patient data fields do not track who recorded them, effective date, or source.

**React target [RECOMMENDED]:** patient-level access rules; chart sections from server resources; distinct create/update/submit commands; autosave vs explicit submit semantics; immutable plan versions; clinical evidence provenance; accessibility and readable empty/abnormal states.

## 21. Reviewer Portal

**[IMPLEMENTED][MOCK]** The reviewer role maps to `medicalReviewer`, uses doctor shell but opens the assessment/review queue; queue displays pending count and decision detail panel. Approval/rejection/more-information permissions differ from doctor.

**[PARTIAL]** Request-information calls are checked against `approveTreatment` in one detail-panel callback; the same role has it, so it works today but the permission is semantically imprecise. Reviewer identity/credentials are hard-coded demo actor names in several journey methods. One direct approval path exists in DataProvider; one decision path in JourneyProvider.

**React target [RECOMMENDED]:** dedicated queue, assignment/claim/aging/SLA, structured checklist, independent decision object, separation-of-duties rules, mandatory evidence/reasons, immutable override record, conflict prevention and full decision history.

## 22. Pharmacy Portal

**[IMPLEMENTED][MOCK]** Queue/detail, eligibility/safety checks, prescription and interval validation, stock by dose and expiry-aware batches, dispense confirmation, notifications, activity and inventory logs. `PaymentScreen` explicitly documents “No payment collection is recorded.”

**[PARTIAL]** Pharmacy center defaults to C001 unless locally selected; request/center assignment and summary heuristics have first-center fallbacks in some code. JourneyProvider dispense selects `data.centers.first`. Additionally, `validateDispensing()` validates stock against the supplied centre but does not compare that centre with the selected queue item's `assignedCenterId`; the final request checks also do not enforce that equality. This creates a plausible wrong-centre stock decrement path if the workflow is invoked with a mismatched centre. Queue is in memory; no actual barcode/NFC scan, ID check service, dispensing device, transactional stock reservation, drug catalog, serialized pack, or claim is integrated.

**React target [RECOMMENDED]:** center-scoped account; transactionally reserve/consume lot; verify Rx and patient identity; hard-stop/override policy; capture pack/lot/expiry/quantity/pharmacist/time; prevent duplicate handover; reconcile actual stock; separate claim estimate from adjudication/payment.

## 23. Patient Web

**[IMPLEMENTED][MOCK]** Dashboard, personal health profile, plan, medication, visits/sessions, exercises; notification sheet; language toggle, logout, and demo assistant. `DemoSessionProvider` supplies the patient ID; default and login selection use P999.

**[PARTIAL]** Patient role can update local adherence/activity but there is no verified self-authentication, account recovery, consent, secure messaging, push delivery, real device data, or account-level session lifecycle. `DemoSessionProvider` itself describes its identity/context as intentionally not an authentication service.

## 24. Patient Mobile

**[IMPLEMENTED]** Flutter responsive patient mobile shell includes home, profile, plan overview, medication, sessions and exercise pages; “more” sheet gives access to selected destinations; medication-order wizard uses a four-step page flow.

**[PARTIAL]** Some routes appear only in “More” on mobile; mobile is not feature-parity with web/admin. The project dependencies/assets do not evidence App Store/Play Store signing, push setup, secure device storage, deep links, offline support, or production mobile release pipeline. Do not describe as deployed native app. **[NOT IMPLEMENTED]**

## 25. Dashboard Specifications

### Current dashboard/report surfaces

- **[IMPLEMENTED][MOCK]** Admin national dashboard and regional analytics derive from `DataProvider` and `demo_metrics.dart`/provider values.
- **[IMPLEMENTED][MOCK]** Reports command center has period, emirate, centre, residency, care status, pharmacy queue status, treatment request status, doctor filters; KPI, journey, clinical, dispensing, regional/facility, provider/financial and data-boundary/insight sections; CSV/JSON web export.
- **[IMPLEMENTED][MOCK]** Report values are a calculated view over patients, plans, requests, dispense history, appointments, labs, inventory and medication events.

### Metric definition issues

- **[PARTIAL]** “Active plan” is based on an active-plan lookup; older `totalActivePatients` alias is actually all patients. Do not assume labels are interchangeable.
- **[PARTIAL]** Adherence can come from fixture `complianceRate` or dose events; missing dose events yield null in analytics rather than a representative rate.
- **[PARTIAL]** BMI/weight historical charts use therapy-session weight observations, while other views may show undated `weightHistory` arrays.
- **[PARTIAL]** Financial report contains both estimated residency summaries and period-bounded local assessed/settled rows; these represent different populations/semantics and need clear labels.
- **[MOCK]** A report “refreshed” label is local time/state, not server synchronization evidence.

### React dashboard contract

**[RECOMMENDED]** Every metric must specify: numerator/denominator, population, period, inclusion/exclusion, source timestamp, refresh timestamp, policy version, privacy aggregation threshold, missing-data behavior, and whether it is estimated or settled. Add a source drill-through and “demo data” badge until connected to governed sources.

## 26. Reports & Analytics

**[IMPLEMENTED][MOCK]** `ReportAnalyticsData.derive()` scopes data in memory. It derives patient, plan, pharmacy request, treatment request, finance, dispense, weight observation, appointment, laboratory and dose-event aggregates. Reference-range parsing handles simple `>`, `<`, or numeric intervals; an unparseable range is not silently classed abnormal by the helper (it returns true). CSV/JSON file downloads are implemented for web using conditional platform exports.

**[PARTIAL]** Center filter scopes patients by recorded/plan/request relation; the center filter and visible facilities may not imply a true operational tenant boundary. Doctor matching uses normalized name-prefix matching against plan doctor text rather than stable doctor ID. Report source/metric definitions do not form a versioned semantic layer. CSV/JSON is a local export of demo data, not an official signed Ministry report.

## 27. Notifications

**[IMPLEMENTED][MOCK]** In-memory patient notification list; status updates include approval, information needed, rejection, pharmacy readiness, dispense, appointment create/reschedule and session check-in; patient can mark notification read under a permission check.

**[PARTIAL]** Notification titles/details are primarily English and are not uniformly modeled as localized keys. There is no outbound SMS, email, push service, delivery receipt, retry, preferences, template/version control, escalation, or delivery audit. Admin notification control is navigation/snackbar rather than a full inbox.

## 28. Audit & Activity

**[IMPLEMENTED][MOCK]** Journey event has action, actor string, role string, old/new state, timestamp, reason, AI recommendation and human decision. Local activity log includes registration, care plan, dispense, inventory, appointment, patient events and seeded misuse examples. Journey events are mirrored into local `DataProvider` logs.

**[PARTIAL]** Logs are mutable client memory and are not tamper-resistant; actor names/roles can be code constants; some paths have less detail or duplicate logging; not all data edits have before/after field diffs; no append-only server store, export integrity, retention or monitoring is present.

**React target [RECOMMENDED]:** server-generated event IDs and UTC time; authenticated subject, effective role, facility/tenant; resource and correlation/idempotency IDs; action/result/reason; old/new values with sensitive-data minimization; immutable append-only storage and export/audit controls.

## 29. Search / Filters / Tables

- **[IMPLEMENTED][MOCK]** Patient registry searches/filtering/pagination; pharmacy has patient/request selection; reports have shared filters; logs/tables have local sort/display patterns.
- **[PARTIAL]** Search semantics are page-local; no central search API, stable sort/cursor paging, server-side filtering, saved views, advanced query, or cross-portal consistency.
- **[PARTIAL]** Some tables are responsive, others rely on desktop sizing or local pagination. Empty/error/loading states are uneven but shared `PlatformStateView` and skeleton widgets exist.
- **[RECOMMENDED]** Use explicit query contracts: `q`, filters, sort key/direction, page cursor/size; preserve URL state; show result count and clear/reset; accessibility keyboard navigation; never expose broader patient search than authorized scope.

## 30. Forms & Validation

**[IMPLEMENTED][MOCK]** Patient registration has a multi-step dialog, field validation, attachment picker and required data checks. Treatment plan builder checks dose/quantity/frequency/validity and eligibility. Reviewer non-approval and override require reason. Medication order wizard screens eligibility and centre selection. Dispense validates safety and stock.

**[PARTIAL]** Validation is split between widgets, journey provider and data provider. Not all invalid numeric edge cases/source/date semantics are checked centrally; error types are mostly strings; upload has no secure storage/virus scan; authorization can be bypassed if a provider is instantiated without access. Some actions silently no-op.

**React target [RECOMMENDED]:** shared schemas for browser and server, field-level error mapping, accessible focus/summary, unit-aware lab validation, duplicate/idempotency handling, unsaved-change protection, retry-safe commands, attachment lifecycle and explicit clinical attestation.

## 31. UI Component System

**[IMPLEMENTED]** Shared app colors/theme, design tokens, KPI cards, status badges, empty/skeleton/platform-state components, dialogs/toasts and Lucide icons. Main design system appears in `core/theme/` and `core/widgets/`.

**[PARTIAL]** Some pages use page-specific cards/spacing/labels and legacy widgets; app-wide tokens do not yet guarantee standardized screen density, tables, patient identity banner, form validation, responsive rules, or clinical severity semantics.

**[RECOMMENDED]** Build React foundations first: typography and spacing tokens, clinical semantic colors with non-color cues, focus states, RTL-safe logical properties, app shell, page header, patient identity banner, cards, data table, status, inline validation, confirmation, toast, empty/loading/error, and accessible chart wrappers.

## 32. Design System

**[IMPLEMENTED]** Brand colors include navy, green, gold and light/dark surfaces; `ThemeProvider` follows system brightness and supports toggle. App theme and design tokens define base components. Arabic starts as default locale.

**[PARTIAL]** Theme preference is in-memory, not persisted. Some primary/badge colors are global mutable static state. Do not treat current visual styling or government-like branding as formal Ministry design approval.

**[RECOMMENDED]** Tokenize brand and semantic colors; use status labels/icons as well as color; standardize typography for Arabic/English and numeric IDs; define touch targets and motion-reduction; verify contrast and keyboard/screen-reader behavior; design responsive breakpoints from content, not copied Flutter layout widths.

## 33. Localization / Arabic / RTL

**[IMPLEMENTED]** Custom `AppLocalizations` with English/Arabic translation maps; locale provider toggles en/ar; app wraps content with RTL for Arabic and LTR for English; several user-facing screens use bilingual model fields and localized format helpers.

**[PARTIAL]** Business/domain status strings and notifications are sometimes English constants; exact bilingual coverage is not guaranteed. Dates and numeric formatting are not consistently locale-aware; some date strings use ISO text; the system timezone/Arabic calendar convention is not modeled explicitly. A terminology helper exists but not every view necessarily uses it.

**React target [RECOMMENDED]** Use `i18next` or equivalent namespaces and typed translation keys; logical CSS properties; locale-aware `Intl` numbers/currency/date; preserve LTR presentation of identifiers and values inside RTL; test every route at Arabic/mobile/tablet/desktop and confirm no truncation/overflow.

## 34. Responsive / Mobile Behavior

**[IMPLEMENTED]** Admin drawer below 1100 px; shared `ResponsiveLayout` determines doctor/center/patient layouts; mobile-specific patient, doctor and center shells exist; pharmacy detail and patient 360 mobile/RTL behavior have tests.

**[PARTIAL]** Admin mobile menu is a reduced subset; center mobile lacks web logs; physician mobile has only patients/assessments; patient mobile turns some items into “More”. This is not identical portal parity. A hidden desktop route or menu must not be mistaken for implemented mobile capability.

**React target [RECOMMENDED]** Explicit parity matrix; preserve role + current task on resize; responsive charts/table detail strategy; drawer focus/escape behavior; minimum-width and keyboard tests; mobile top/bottom navigation with visible critical actions.

## 35. Current Implementation

### Framework and package evidence

- **[IMPLEMENTED]** Flutter/Dart (SDK constraint in `pubspec.yaml`); `provider`; `fl_chart`; `flutter_map`/`latlong2`; `file_picker`; Lucide icons; Google Fonts; web package for browser download.
- **[NOT IMPLEMENTED]** No HTTP client, backend SDK, persistence package, auth SDK, or database dependency was found in `pubspec.yaml`.
- **[IMPLEMENTED]** README run path is `flutter run -d chrome`; README calls this a Flutter web/mobile demo for UAE Ministry stakeholder presentations.

### Verified test/build checks

- **[VERIFIED]** `flutter test` in `mounjaro_demo/`: all 73 tests passed on 1 Oct 2026.
- **[VERIFIED]** `flutter analyze` in `mounjaro_demo/`: “No issues found”.
- These checks establish current static-analysis and automated test pass only. They do not prove live integration, clinical safety, device compatibility, production security, performance at Ministry scale, browser/device matrix, or regulatory acceptance.

### Test suite coverage observed

Canonical lifecycle transitions, missing lab, rejection, human override reasons, duplicate refill, old dispensing guard, patient-specific history/labs, patient medication view, patient home dose, review dialog reasons, 360 rendering/Arabic RTL/mobile, pharmacy responsive/detail/queue, role-scoped admin portal preview, reports rendering/filter/export controls and empty scope. **[IMPLEMENTED]**

## 36. Recommended React Experience

### User-facing principles

1. Keep one patient identity banner and explicit active plan/request status across portals. **[RECOMMENDED]**
2. Surface workflow state and actionable next step, not just a set of disconnected modules. **[RECOMMENDED]**
3. Make AI/rules/evidence source and policy version visible; make human decision and accountability unmistakable. **[RECOMMENDED]**
4. Show freshness, provenance, demo/live environment and estimated/settled finance status. **[RECOMMENDED]**
5. Keep admin operational monitoring distinct from clinical charting and payer operations. **[RECOMMENDED]**
6. Build true empty/loading/error/denied/stale/conflict states for each high-risk screen. **[RECOMMENDED]**

### Screen map proposal

| Route family | Key screen |
|---|---|
| `/login` | Role/provider-aware authentication; no client role picker outside demo mode. |
| `/admin/overview`, `/admin/regions`, `/admin/reports` | Governed operational and analytic dashboards. |
| `/admin/patients`, `/admin/patients/:patientId/*` | Patient registry and 360 with access-aware sections. |
| `/doctor/patients`, `/doctor/patients/:patientId/*` | Clinical registry and chart. |
| `/review/queue`, `/review/requests/:requestId` | Independent review queue and decision workspace. |
| `/pharmacy/queue`, `/pharmacy/requests/:requestId`, `/pharmacy/inventory`, `/pharmacy/dispenses` | Centre-scoped dispense and inventory. |
| `/patient/home`, `/patient/plan/*`, `/patient/appointments`, `/patient/medications` | Patient self-service. |

Use named, permission-checked routes and a role-aware nav manifest; deep links must re-check authorization server-side. **[RECOMMENDED]**

## 37. Known Limitations

1. **[NOT IMPLEMENTED]** Server/backend, durable database and cross-session persistence.
2. **[MOCK]** Role-picker login and fixed/default P999/C001 context; no real authentication.
3. **[PARTIAL]** Client-side permissions and optional access dependencies; not a production security boundary.
4. **[MOCK]** Hard-coded patient/provider/facility/lab/inventory/request/activity fixtures.
5. **[MOCK]** Eligibility and support amounts are local demo assumptions with no official endorsement in source.
6. **[NOT IMPLEMENTED]** Live AI/ML, national identity, EHR/LIS, e-prescribing, claims, pharmacy hardware or wearables.
7. **[PARTIAL]** Two overlapping request/refill approval routes and more than one audit path.
8. **[PARTIAL]** Split date/time source and mixed string/typed statuses/date representation.
9. **[PARTIAL]** Financial UI estimates/settlement are simulated; no money is collected.
10. **[PARTIAL]** Mobile portal capability differs from desktop.
11. **[PARTIAL]** No production monitoring, backup, incident response, retention, consent, data minimization or export governance.
12. **[PARTIAL]** Visual and functional tests exist, but no broad browser e2e, API contract, load, threat, accessibility, security or interoperability suite was found.

## 38. Technical Debt / Duplications

- **[PARTIAL]** `MainShell`, responsive role shells, legacy `DispensingScreen`, current `WebPharmacyDispensingView`, `web_center_shell_backup.dart`, web/mobile login files, and premium role login coexist. Confirm active vs retired ownership before porting.
- **[PARTIAL]** Treatment approval appears in both `JourneyProvider.review()` and `DataProvider.approveClinicalReview()`; refill can use `submitRefillRequest()` directly under an approved plan; plan creation and journey submission/evaluation are separate methods.
- **[PARTIAL]** Appointment/session entities overlap: initial appointments are synthesized from therapy sessions, then appointment edits live in a separate map; attendance updates session, not necessarily corresponding appointment status.
- **[PARTIAL]** Adherence appears as `Patient.complianceRate`, `MedicationDoseEvent` history, and `DemoTreatmentRequest.adherencePercent`; these are not one canonical calculation.
- **[PARTIAL]** Duplicated status fields: plan string `clinicalApprovalStatus`, pharmacy queue enum, treatment request enum, patient-level dispense/cooldown and request human decision.
- **[PARTIAL]** `createTreatmentPlan()` removes every prior plan for that patient before adding the new one, including completed/paused plans. Historical requests can then retain a `treatmentPlanId` whose plan record no longer exists.
- **[PARTIAL]** Request model snapshots demographics but joins to mutable Patient; some copied attributes can become stale.
- **[PARTIAL]** Web admin navigation, responsive shell choice and mobile subset are coded separately, inviting parity drift.
- **[PARTIAL]** Many operations return bool/void/string messages rather than typed domain failures; `copyWith` nullable fields cannot always explicitly clear existing values.
- **[PARTIAL]** DemoClock is not the sole clock. Mutable global theme color state is another concern for isolation/testing.

## 39. Data Consistency Findings

| Finding | Evidence and effect | Priority for migration |
|---|---|---|
| Mixed time source | Journey uses `DemoClock`; dozens of `DataProvider`, model, fixture and screen paths use `DateTime.now()`. A time-travel/test/demo date may disagree across eligibility, queue, expiry, notification and audit. **[PARTIAL]** | P0: inject one UTC clock into domain/API tests. |
| Multiple adherence sources | Preseeded patient percentage; logged dose event history; request-level percentage. Journey adherence method copies existing patient compliance and logs a status event, but the shared medication-dose event path is `DataProvider.logMedication()`. **[PARTIAL]** | P0: define canonical dose schedule/event and derive percentages from it. |
| Patient request and queue linkage | Journey queue synchronization finds/creates queue based on patient/plan and reuses current undispensed item; dispense code receives request ID from patient queue helper. **[PARTIAL]** | P0: use unique IDs/FKs and transactional transition; avoid “latest by patient” at dispense. |
| First-centre fallback | Several seed/queue/dispense pathways choose first centre if assignment invalid; JourneyProvider dispense selects `data.centers.first`. **[PARTIAL]** | P0: fail closed and use explicitly assigned, authorized centre. |
| Supplied vs assigned centre | Dispensing validates dose stock for the supplied centre, but request validation does not assert that supplied centre equals the queue item's `assignedCenterId`. **[PARTIAL]** | P0: enforce centre equality server-side and reserve/decrement the request's assigned centre transactionally. |
| Rule/evidence mismatch | Eligibility rule missing-lab setting is false, but dispense requires recent exact-code labs. Eligibility can display eligible while dispense blocks. **[IMPLEMENTED][MOCK]** | P0: distinguish “programme eligible” from “dispense ready”; expose both criteria sets and versions. |
| Demographics/diagnosis copies | Request stores names, age, gender, MRN and diagnosis snapshots; changes to Patient do not automatically refresh an existing request. **[IMPLEMENTED]** | P1: choose immutable submitted snapshot or versioned references with clear amendment workflow. |
| Lab series | Personalized mock labs can have single-item `trend` arrays; reporting trends and result rows depend on different data. **[MOCK]** | P1: persist each observation with collection/effective time, units, source and reference range. |
| Lab code/date matching | Dispense requires exact `HbA1c` and `Fasting glucose` test codes and parseable dates; display names/localized labels are separate. **[PARTIAL]** | P0: standard test catalog/canonical codes/units and server validation. |
| Eligibility label matching | Absolute blocks compare English strings exactly ignoring case; Arabic/local synonyms can miss. `hasChronicDisease` can drift from condition list. **[PARTIAL]** | P0: coded diagnoses, normalized terminologies, validated derived flags. |
| Appointments vs sessions | `appointmentsFor` lazily maps sessions to appointments, but subsequent create/reschedule/cancel mutates a separate appointment list. **[PARTIAL]** | P1: decide if appointments schedule sessions or are separate entities; synchronize explicitly. |
| Active-plan assumptions | `getPlanForPatient` returns first status `Active`; no uniqueness constraint or ordering/version. **[PARTIAL]** | P0: enforce exactly one active plan per episode or document multiple-plan rules. |
| Plan history deletion | `createTreatmentPlan()` removes all plans for the patient before inserting the new plan; historical requests are not deleted with them and may point to removed plan IDs. **[PARTIAL]** | P0: preserve immutable plan versions/history; supersede/close old plans without deleting clinical records. |
| Finance meaning | Demo estimate is created and later marked settled at local dispense. “Settled” can be read as payment/claim completion, but no collection/claims backend exists. **[MOCK]** | P0: rename current state to demo-simulated and define claim/payment lifecycle. |
| KPIs / synthetic flags | `fraudIncidentsPrevented` counts seeded logs with Flagged/Overridden; `totalActivePatients` equals all patients. **[MOCK][PARTIAL]** | P1: metric glossary and test fixtures per KPI. |
| Locale/date | Date strings are often ISO and date calculations use system local date; no explicit UAE timezone storage contract. **[PARTIAL]** | P1: server UTC instants + local date/time zone policies. |

## 40. React Architecture Recommendations

### Frontend

- **[RECOMMENDED]** React + TypeScript, feature/domain modules, Vite or organization-standard build, design-system package.
- **[RECOMMENDED]** Router with named routes, role/permission-aware route metadata and deep-link handling.
- **[RECOMMENDED]** TanStack Query (or equivalent) for API/server state; lightweight local state for UI; avoid recreating the central mutable monolith.
- **[RECOMMENDED]** React Hook Form + Zod (or equivalent) for schemas; share domain validation only where server contract is authoritative.
- **[RECOMMENDED]** i18next and logical CSS; Arabic RTL and locale-native date/currency/numeric formatting.
- **[RECOMMENDED]** Chart library and map adapter chosen behind typed components; label sample/estimated data and expose text/table alternatives.
- **[RECOMMENDED]** Component testing, Playwright e2e, accessibility checks, and visual snapshots for bilingual role/responsive combinations.

### Backend/domain boundary (required before production)

- **[RECOMMENDED]** AuthN/session/identity, server RBAC+ABAC and organization/facility scope.
- **[RECOMMENDED]** API/domain service for patient registry, plans, requests, eligibility assessments, reviewer decisions, queue release, inventory lot reservation, dispense transaction, appointments, adherence, documents, notifications, audit and analytics.
- **[RECOMMENDED]** Database with normalized patient/encounter/request/plan/dispense/lab/document relationships; UTC event times, optimistic concurrency, transaction boundaries and migrations.
- **[RECOMMENDED]** Object storage plus malware/content checks and access/audit controls for documents.
- **[RECOMMENDED]** Outbox/eventing for notifications/analytics; idempotency for dispense/submit; durable retry and delivery status.
- **[RECOMMENDED]** Versioned policies with accountable clinical/finance owners; store policy version and input evidence for every eligibility/coverage result.
- **[RECOMMENDED]** Integration adapters behind interfaces for EHR/LIS, identity, e-prescribing, payer and pharmacy systems; do not hard-wire vendor assumptions into React.

### Suggested bounded contexts

1. Identity/access; 2. Beneficiary registry; 3. Clinical chart/labs/documents; 4. Treatment plan/request; 5. Eligibility and policy; 6. Review; 7. Pharmacy/dispensing/inventory; 8. Patient engagement/adherence/appointments; 9. Coverage/claims; 10. Notifications; 11. Audit/analytics.

## 41. React Implementation Checklist

### Phase 0 — governance and contracts

- [ ] Confirm clinical policy owner and approved rules / contraindication terminology.
- [ ] Confirm benefit, payer, residency evidence, price and funding logic; remove demo assumptions from any public/official claim.
- [ ] Confirm patient identifiers, identity provider, role provisioning, facility scopes and privileged-access model.
- [ ] Decide official data sources, source-of-truth per field, retention/access/export rules and integrations.
- [ ] Define terminology, lab catalogs/units, date/time/time-zone and measurement provenance.
- [ ] Define what is in/out of migration, what stays in Flutter, and whether native mobile is in scope.

### Phase 1 — domain model and API

- [ ] Publish canonical schemas for patient, clinical episode, plan/version, request, eligibility assessment, reviewer decision, prescription, pharmacy queue, inventory lot, dispense transaction, lab, attachment, appointment, adherence, notification, financial claim/estimate and audit event.
- [ ] Publish state machine with allowed transitions, roles, preconditions, idempotency and terminal-state/reopen policy.
- [ ] Define typed reason codes for blocked actions and stable error envelope.
- [ ] Add policy version, evidence references, effective time and decision provenance.
- [ ] Add server-side authorization and transactional idempotent operations.
- [ ] Add persistence, migrations, backup/recovery, observability and contract tests.

### Phase 2 — React foundations and role shells

- [ ] Build responsive admin/doctor/reviewer/pharmacy/patient shell and route guards.
- [ ] Build shared bilingual design system, RTL/LTR and patient identity header.
- [ ] Implement loading/empty/error/denied/stale/offline/conflict states.
- [ ] Add accessibility, keyboard navigation, focus management and screen reader labels.
- [ ] Add auth/session expiry, logout, secure token handling and no role-picker in production mode.

### Phase 3 — end-to-end clinical/dispensing vertical slice

- [ ] Registry → patient 360 → chart/labs/documents.
- [ ] Create/version plan → submit request → evaluate/versioned eligibility.
- [ ] Reviewer queue → reasoned approve/reject/information request → audit readback.
- [ ] Release → pharmacy queue → reserve in-date inventory lot → confirm dispense transaction.
- [ ] Patient notification and shared chart/dispense history readback across independently authenticated users.
- [ ] Negative tests: missing/stale/future labs, ineligible, duplicate, expired approval/Rx, wrong centre, out-of-stock, insufficient stock, repeated click, race condition, access denial, network retry.

### Phase 4 — patient engagement and reporting

- [ ] Patient web/mobile-responsive flows, medication events, weight, sessions, exercises, appointments and notification delivery.
- [ ] Establish a single canonical adherence computation and measured observation history.
- [ ] Govern KPI definitions, aggregation/privacy, filter semantics and report freshness.
- [ ] Implement exports with role/field restrictions, provenance, test fixtures and official-vs-demo labels.

### Phase 5 — migration and go-live readiness

- [ ] Map/migrate seed/demo fixtures separately from any real records; validate counts and referential integrity.
- [ ] Verify Arabic/English across every route and viewport; run visual and accessibility review.
- [ ] Conduct security, privacy, threat, penetration, load, backup/restore and integration testing.
- [ ] Obtain clinical, pharmacy, finance, operations, privacy/security and Ministry acceptance.
- [ ] Train users; prepare support, incident response, downtime procedures, monitoring, release rollback and data reconciliation.

## 42. Final Migration Notes

1. **Rebuild from the domain contract, not widget structure.** Flutter classes are useful discovery artifacts but mix display, business logic, fixtures and state. **[RECOMMENDED]**
2. **Keep demo mode as a separate environment.** Make every fixture, rule, AI label, coverage estimate, seeded audit narrative and report visibly “Demo”; never silently blend demo and live data. **[RECOMMENDED]**
3. **One canonical lifecycle.** Remove direct bypasses after introducing the versioned API state machine; distinguish plan state, review state, pharmacy queue state and dispense transaction state. **[RECOMMENDED]**
4. **Server owns trust.** The React client may guide and explain but must not grant roles, approve treatment, authorize early dispense, settle money or assert official compliance. **[RECOMMENDED]**
5. **Preserve what is already strong.** Role-specific workflows, patient 360 information architecture, Arabic RTL, local explainability, visible human review and stock/expiry checks are valuable demo/product behaviors to retain behind verified services. **[RECOMMENDED]**
6. **Release gate.** A React port that only reproduces the current screens is a UI migration, not a production healthcare-system migration. Production readiness depends on approved policy, verified integrations, persistent and secured services, clinical safety validation, operational ownership and formal acceptance. **[RECOMMENDED]**

---

## Appendix A. Source Traceability Index

Paths are relative to `mounjaro_demo/`.

| Topic | Primary source |
|---|---|
| App boot/provider graph/locales | `lib/main.dart:L15-L79` (`main`, `MounjaroApp`) |
| Splash/login/role routing | `lib/features/dashboard/splash_screen.dart:L6`; `lib/features/auth/login_screen.dart:L4`; `lib/features/auth/premium_login_screen.dart:L17-L60` (`LoginRole`, `_login`) |
| Roles/permissions | `lib/core/auth/access_control.dart:L3-L103` (`AppRole`, permission map) |
| Demo identity/context/time | `lib/core/demo/demo_session_provider.dart:L7`; `lib/core/demo/demo_clock.dart:L2` |
| Main mock domain and data operations | `lib/core/constants/mock_data.dart:L15-L222` (records/policy), `L340` (Patient), `L815` (MockData), `L2130` (DataProvider), `L3298` (dispense validation), `L3666` (dispense), `L4380` (plan create), `L4651` (dose log) |
| Local eligibility policy | `lib/core/clinical/clinical_eligibility_config.dart:L2-L24`; `lib/core/clinical/clinical_eligibility_rules.dart:L29-L97` |
| Treatment plan/session/exercise model | `lib/features/treatment_plan/models/treatment_plan.dart:L1-L150` |
| Request states, criteria and audit model | `lib/features/journey/journey_models.dart:L1-L115` |
| Connected local journey workflow | `lib/features/journey/journey_provider.dart:L8-L73` (provider binding), `L87` (bind), `L369-L390` (allowed states), `L407` onward (commands); `lib/features/journey/journey_screen.dart:L9-L70` |
| Admin nav and role previews | `lib/features/dashboard/web/web_admin_shell.dart:L33-L43` (shell), `L146-L207` (screen switch), `L235` onward (sidebar); `lib/features/dashboard/mobile/mobile_admin_shell.dart:L14-L90` |
| Doctor and reviewer portal | `lib/features/dashboard/web/web_doctor_shell.dart:L22`; `lib/features/dashboard/doctor_shell.dart:L15-L119`; `lib/features/clinical/clinical_review_detail_panel.dart:L292-L367` (decision actions) |
| Pharmacy portal and dispense workflow | `lib/features/dashboard/web/web_center_shell.dart:L17-L100`; `lib/features/dispensing/web_pharmacy_dispensing_view.dart:L16`; `lib/features/dispensing/payment_screen.dart:L10-L28` (explicit no-payment note) |
| Patient portal and order wizard | `lib/features/dashboard/web/web_patient_shell.dart:L23`; `lib/features/dashboard/patient_shell.dart:L21-L120`; `lib/features/patient_app/medication_order/medication_order_wizard.dart:L10-L120` |
| Patient registry / 360 | `lib/features/patients/patient_registry_view.dart:L15`; `lib/features/treatment_plan/web/patient_360_view.dart:L21-L365` (shell/tabs) |
| Reports/analytics/exports | `lib/features/dashboard/admin_views/report_analytics_data.dart:L174` onward; `lib/features/dashboard/admin_views/reports_command_center.dart:L16-L39`, `L2711` (export); `lib/features/dashboard/admin_views/report_export_web.dart` |
| Translation/theme/responsive | `lib/core/localization/locale_provider.dart:L3`; `lib/core/theme/theme_provider.dart:L5`; `lib/core/utils/responsive_layout.dart:L3`; translation dictionaries under `lib/core/localization/` |
| Test evidence | `test/` (10 Dart test files at inspection time; executed with `flutter test`) |

## Appendix B. Migration Traceability Matrix

| Current Flutter capability | React domain/route target | Required authoritative service |
|---|---|---|
| `PatientRegistryView` | Beneficiary search/list | Patient registry API + scoped search |
| `Patient360View` 11 tabs | Patient chart routes/tabs | Chart, labs, documents, plan, request, appointment, audit APIs |
| `TreatmentPlanBuilder` | Plan version form | Plan service + clinical catalog |
| `JourneyProvider` state machine | Request workflow workspace | Workflow/eligibility/review API |
| `ClinicalEligibilityRules` | Criteria/explanation panel | Versioned policy engine service |
| `ClinicalReviewDetailPanel` | Reviewer queue and decision form | Review decision API + server audit |
| `WebPharmacyDispensingView` | Pharmacy queue/detail | Queue + inventory reservation + dispense transaction APIs |
| `PaymentScreen` local estimate | Coverage/claim review | Benefit/claims API; not a payment endpoint unless explicitly integrated |
| `logMedication` / `recordWeight` | Patient adherence/measurements | Patient engagement event API |
| `ReportAnalyticsData` | Report screens and filters | Governed analytics/semantic layer; source-freshness API |
| `ActivityLog` / audit models | Activity/audit views | Append-only audit/event service |
