# healthcare mobile app: parity review and delivery plan

Reviewed 2026-10-04. Scope is the Flutter mobile experience in `mounjaro_demo`; the separate React portal at `/Users/alimegahed/health_care` was read only. This review describes the current demo, not a claim of production readiness or clinical validation.

## What changed in this pass

- Reused the official `healthcare` logo already present in Flutter. Its SHA-256 matches the portal's `healthcare-logo.png`; the image itself was not redrawn or recolored.
- Replaced the default Flutter launcher mark with that original brand image in the Android and iOS icon sizes. Updated the native app display name and Flutter title to the exact wordmark `healthcare`.
- Added the original portal robot illustration to the compact mobile entry screen. It is labelled as a demo illustration and does not imply a connected AI service.
- Kept four selectable mobile entry portals (System/Admin, Doctor, Pharmacy, Patient). Reviewer remains a separate approval role in the existing access model and wider portal experience; it was not reassigned to a doctor or admin.
- Aligned shared Flutter palette/type/navigation tokens to the portal's petrol teal and mint language, using a darker action green where needed for white-text contrast.
- Kept patient destinations in bottom navigation plus “More”; the patient drawer now holds language/logout settings rather than duplicating the same page links.
- Made the mobile entry safe-area aware, increased role-card touch area/text, exposed selected-role semantics, followed RTL for the primary action arrow, and shortened splash motion with reduced-motion handling.

## Mobile-to-portal feature matrix

| Function | Portal reference | Flutter mobile today | Gap / action |
|---|---|---|---|
| Brand and language | Shared `healthcare` logo, petrol teal/mint, English and Arabic | Same logo was already in Flutter; app icon was still Flutter-branded. Arabic/English localization and RTL exist, but typography and themes varied by screen. | Launcher icons/name and shared tokens are now aligned. Finish route-by-route Arabic/large-text QA and provide a reviewed Arabic font asset if native fallbacks differ on target devices. |
| Admin | Dashboard, patients/Patient 360, requests, plans, appointments, inventory/safety, audit, reports and geography | `MobileAdminShell`: dashboard, doctor/centre management, regional analytics, inventory, misuse/safety and audit via a drawer. | Patient registry/360, requests, care plans, reports/export and content management are not surfaced as complete mobile destinations. Add permission-aware card/detail routes before adding more top-level links. |
| Doctor | Assigned patients, Patient 360, requests/drafts, care plans, labs, appointments, rehab and follow-up | `MobileDoctorShell`: patient registry and a second activity/review-oriented tab; patient/plan flows are reachable from the registry. | Appointments, draft recovery, full clinical context and rehab follow-up need a focused mobile route audit. The phone entry no longer offers a separate reviewer portal; reviewer approvals must remain in the existing reviewer workflow/service. |
| Pharmacy | Authorized requests, verification, dispensing, stock/batches, expiry, coverage and audit | `MobileCenterShell`: canonical dispensing queue and inventory tabs; the queue/handover operates on the shared in-app `DataProvider`. | Mobile centre selection is not complete; batch/expiry/coverage evidence and receipt/audit behavior need end-to-end parity QA. No server authorization is present. |
| Patient | Daily next action, medication/dose history, nutrition, activity, rehab, progress, labs/documents, appointments, notices and optional device data | Home, profile, plan, medication, sessions, exercises, notifications and medication-request flow. Four bottom destinations with secondary pages in More. | No nutrition-plan/log module or device/consent connection model is present. Labs/documents are not first-class patient mobile destinations. Add these only with a shared portal/API contract; use truthful empty states until then. |
| Medical review | Reviewer verifies evidence and decides; request/plan lifecycle retains an explicit review stage | `AppRole.medicalReviewer` and provider review transitions remain in Flutter business logic and tests; current standalone portal is separate. | The new compact phone selector intentionally exposes only four portals. Do not change reviewer permissions or lifecycle to compensate; agree a secure existing reviewer service/portal handoff before claiming end-to-end mobile approval. |
| Smart assistant | Role-scoped answers grounded in existing records; no fabricated clinical decisions | A robot asset is now shown on mobile entry as a visual; no patient-facing connected assistant API is configured in this Flutter app. | Treat the robot as brand illustration only. Any assistant implementation needs a real scoped service, provenance/record links, safety limits and visible unavailable/error states. |
| Wearables | Consent-based source, timestamps, quality, deduplication, disconnect and sync state | No HealthKit/Health Connect/companion integration or device observation model/dependency is present. | No readings are imported from a watch today. Choose the supported phone health source/device scope, define consent and shared API contracts, then implement platform-specific permission and sync handling. |
| Notifications/offline | Push or scheduled reminders, retry, secure offline cache, revocation, delivery status | Notification/history sheets use in-memory demo records; no push/local-notification, secure persistent store, or API client dependency is configured. | Implement server-backed notification preferences/delivery and an encrypted offline/outbox strategy with idempotent retry. Until then, do not call demo records live reminders or cross-device sync. |
| Authentication and data | Server identity, role/tenant scope, patient/doctor/centre authorization and audit | The entry screen selects a seeded role; no credentials are checked. `DemoSessionProvider` and `DataProvider` are in-memory; the test patient defaults to P999. Client-side permission checks are useful for demo behavior but are not a security boundary. | Production readiness requires identity-provider integration, server-enforced RBAC, tenant/patient scope, API contracts/versioning, audit, durable storage, secrets handling and recovery flows. |

## Functional boundary and important data risks

- This is a local demo. A change made in Flutter does not synchronize to the separate React portal or a backend. The portal's mock repository and browser state are not a cross-app source of truth.
- `DataProvider` seeds and mutates process memory. Reopening/restarting the app is not durable persistence. Login is a role switch, not authentication.
- Seeded eligibility, coverage, adherence, dates and measurements are demo values. Coverage percentages are not verified UAE policy. The app must label seeded information as demo or derive it from auditable records before showing it as a real patient fact.
- The existing “record dose” action has a shared in-session record and duplicate same-day guard, but a day-level check is not a prescription-linked weekly occurrence schedule. Add `DoseSchedule`/`DoseOccurrence` in the shared model/API and drive reminders and taken/missed state from that occurrence. Opening or snoozing a notification must never mark a dose taken.
- Exercise assignment, manually reported exercise, wearable activity and supervised physiotherapy attendance must remain different records. Steps must not complete a therapy session.
- Nutrition and wearable features are not implemented or synchronized. Do not seed a separate mobile-only subsystem or display generated dietary/medical advice as clinician-approved.
- No external API client, persistence library, notification plugin, HealthKit/Health Connect package, or cloud auth SDK is declared in the Flutter package.

## Recommended mobile feature set

1. **System/Admin:** compact operational overview; searchable/filterable patient cards and Patient 360; request/plan status visibility; clinician/centre administration; inventory batches and expiry; safety alerts; audit; exportable reports; accessible geography summary. Keep actions permission-gated and preserve the reviewer decision boundary.
2. **Doctor:** assigned-patient inbox; patient 360 with allergies/history/vitals/labs/documents; draftable treatment requests with inline missing-information feedback; integrated plan; appointment management; review of patient-reported activity and sessions; permission-scoped assistant only after service integration.
3. **Pharmacy:** assigned-centre queue; prescription and request lifecycle; identity/approval/early-refill checks; available lot, expiry and quantity; a single idempotent dispense action; coverage/cost receipt; inventory movement and audit receipt. Restrict clinical information to what dispensing requires.
4. **Patient:** “Today / next step”; prescription card and occurrence-based dose schedule; medication history; assigned nutrition plan and meal/water logs only when clinician-authored data exists; assigned exercise and separately scheduled therapy sessions; labs/documents; appointments; reminders; accessible progress; device connection, consent and data source/timestamp when a real health integration exists.
5. **Shared platform:** production auth and server-side authorization; canonical API/repository; durable encrypted local cache and offline state; event provenance/timezone/idempotency; push/reminder delivery; audit; localization; accessibility and native-device release QA.

Nutrition additions should be shared `NutritionPlan`, `MealPlanEntry`, `MealLog`, and `HydrationLog` records. Device additions should be shared `DeviceConnection`, `Consent`, and `HealthObservation` records including metric, value/unit, recorded/received time, timezone, source/device, external record ID and quality. These contracts need matching portal/backend work before mobile can claim synchronization.

## Design tokens and assets

- Action green: `#007C6E` for readable white labels; brighter portal teal accent: `#008D78`; deep teal: `#075951`; petrol navigation: `#032E3A`.
- Text: `#123D3F`; secondary text: `#526B67`; canvas: `#F5FAF7`; pale mint: `#E9F7EF`; border: `#DEEBE5`; restrained gold: `#C7A252`.
- English text styles: DM Sans body and Manrope headings through the existing `google_fonts` package, with platform Arabic fallbacks. No extra UI framework/dependency was added.
- Existing official logo: `mounjaro_demo/assets/logo.png`; original robot: `mounjaro_demo/assets/illustrations/healthcare_assistant.png`.

## Verification

- Before edits: `flutter test --no-pub` passed all 73 existing tests.
- This pass adds phone-width English/Arabic entry tests for the four-portals limit and overflow. `flutter analyze --no-pub` reports no issues and `flutter test --no-pub` passes all 75 tests.
- `flutter build apk --debug --no-pub` and `flutter build ios --no-codesign --no-pub` both completed successfully. Android reports a future-migration warning for the Kotlin Gradle Plugin; it does not fail this build.
- Native-device screenshots, VoiceOver/TalkBack, dynamic text scaling and reduced-motion checks still need actual simulator/device QA.
- No native API, backend, real login, push-notification or smartwatch connection is claimed by this pass.
