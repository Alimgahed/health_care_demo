# UI/UX audit and remediation ledger

Updated 2026-10-01. This ledger records the route inventory, the design decisions made in this pass, and work that still needs review. It is not a claim of clinical or production readiness.

## Design direction

- **Purpose:** Help each role identify the current patient or request, the next safe action, and the latest recorded state.
- **Palette:** forest `#16533A` for actions, navy `#0A2B3E` for operational framing, warm white `#FFFFFF` for reading surfaces, mist `#F4F7F6` for the canvas, restrained gold `#C7A252` for brand accents, and semantic green/amber/red/blue for state.
- **Type:** Inter where available, with the platform Arabic fallback; sentence-case headings and labels, compact page titles, tabular numerals for metrics where used.
- **Composition:** persistent desktop navigation, a content-first center area, compact facts close to actions, and stacked cards or sheets at narrow widths. Patient mobile prioritizes the current treatment and direct tasks.
- **Interaction:** explicit results from `DataProvider`, clear empty and no-result states, confirmation for clinical approval, and 48 px minimum button targets through the theme.

The design avoids identical SaaS cards, decorative dashboard gradients, and unsupported “live” claims. The care journey on the entry screen is the single distinct visual motif. It reflects the actual register → decide → review → dispense flow.

## Route and nested-view inventory

| Area | Screens and nested views | Main UX risks found | Status |
| --- | --- | --- | --- |
| Entry | Splash, role entry, legacy web/mobile login | Large illustration pushed mobile role selection below the fold; disabled entry action hard to see | Role entry rebuilt; legacy login remains to review |
| Admin web | Executive dashboard, geography, patient registry, Patient 360, inventory, alerts, live activity, assistant, misuse, reports, doctor and pharmacy embedded portals, doctor and center management, audit | Mixed density and status treatments; registry table crowded in Arabic; reports header forced horizontal scroll | Registry responsive list, status treatment, reports header and shared theme updated; other admin views remain to review |
| Admin mobile | Dashboard, doctors, centers, regions, inventory, misuse, audit | Dense desktop information translated into mobile cards unevenly | Inventory completed; visual state audit remains |
| Doctor/reviewer web | Registry, patient search, Patient 360, clinical assessments, review queue/detail, care plan builder | Desktop drawer hid primary sections; reviewer showed physician branding; approval lacked confirmation and negative decisions lacked clear reason entry | Desktop navigation, role-specific reviewer identity, approval confirmation, and reason-required reject/information actions updated; the Connected Journey portal section was removed at the user's request; full form audit remains |
| Doctor mobile | Patient discovery/profile, assessment and treatment entry through `DoctorShell` | Table and detail density at tablet widths | Route inventoried; detailed mobile visual pass remains |
| Pharmacy web | Request queue, verification/detail, inventory, dispensing logs, handover | Blank filtered queue; fixed dual pane at small widths; hardcoded stock, batch and coverage; dark-theme contrast failure | Queue states, shared status, provider-backed stock/batch/coverage, and dark surfaces updated. The detail cards and checks now use horizontal desktop rows with a compact no-scroll layout at the inspected desktop viewport; narrower widths show the queue and detail as separate steps. |
| Pharmacy mobile | Dispensing list, patient dispensing detail, handover | Simulated QR scan opened an arbitrary patient; unsupported AI success percentage; hardcoded coverage and narrow-screen overflows | QR simulation removed; canonical queue added; rule-based eligibility and shared coverage displayed; bilingual 320 px widget QA passed |
| Patient web | Home, profile, plan overview, medication, sessions, exercises, notifications, medication order | Desktop drawer concealed navigation; missing patient record was unactionable | Persistent desktop navigation and actionable missing-record state updated; deeper screen pass remains |
| Patient mobile | Home, profile, plan, medication, sessions, exercises, notifications, exercise library and check-in | No primary bottom navigation; home dose action was a local toggle, countdown and watch data were unsupported; fixed profile price | Bottom navigation, shared dose logging, derived schedule, and shared coverage estimate updated; remaining detail screens need visual QA |
| Reports | Program KPIs, filters, journey, clinical/dispensing, regions, providers/finance, export | Header overflow at tablet width; information context hard to scan | Responsive header updated; other report panels need width and data-state review |

## Shared components and states

- `AppSpacing`, `AppRadius`, and `AppLayout` define common geometry and breakpoints.
- `AppTheme` now defines calm surfaces, outlined cards, dialogs, snackbars, and consistent control targets.
- `StatusBadge` provides icon, color, label, and lifecycle mapping. The registry and pharmacy queue use it.
- `PlatformStateView` defines empty, no-results, error, permission, warning, and loading presentations. It is used in the registry, pharmacy queue/detail, patient record fallbacks, notifications, doctor search, and doctor review empty views.
- The registry search, residency filters, pagination, and compact list remain backed by the shared patient collection. Its pagination chevrons now follow text direction.
- The patient mobile dose action writes to and checks `DataProvider.medicationEventsFor`; it reports an error if the operation did not persist. The next date is derived from the treatment plan interval. The patient profile estimate reads `DataProvider.coverageEstimateForPatient`.
- Pharmacy web and mobile now read in-date stock, batches, request status and coverage from `DataProvider`. The mobile entry lists assigned approved requests; search stays within active requests for the selected center. The shared clinical banner presents configured eligibility rules without a fabricated prediction. The prescription card uses an intentional icon in place of a missing image asset.
- `PlatformStateView` has a compact, scrollable layout for short panels so recovery actions remain reachable.

## Open findings

No P0 issue was found in the reviewed core paths. The P1 items below mean this phase does not yet meet the brief's full route-by-route acceptance criteria.

| Priority | Finding | Next step |
| --- | --- | --- |
| P1 | Several older screens still use their own cards, status colors, generic empty/error states, and narrow fixed widths. | Refactor by workflow, starting with treatment builder, legacy mobile admin, and admin management. |
| P1 | The reviewer queue now supports approval, rejection, and information requests for care-plan reviews, with reason-required negative decisions and provider-backed transitions. The connected journey requires reasons for recommendation overrides. Full bilingual visual review and early-dispense exception handling remain open. | Verify each transition and reason field visually in English and Arabic; complete early-dispense reviewer actions. |
| P1 | Some legacy patient and admin views still contain illustrative or static operational content. | Replace with shared records or honest unavailable states. |
| P1 | Browser checks have covered role entry, admin, embedded doctor, registry, and patient mobile home at desktop/tablet/mobile widths; not every nested route has been visually inspected. | Complete route-by-route visual and keyboard QA. |
| P2 | Some Arabic table status labels truncate at desktop width. The complete label is available in semantics, but visual scan quality can improve. | Rebalance columns and add a full-label detail affordance. |
| P2 | The legacy web/mobile login screens still use multiple demonstration credential labels. | Consolidate to one environment note when those routes are used. |
| P2 | Reports beyond the header may still require horizontal scrolling on tablet. | Convert dense breakdowns to stacked detail layouts. |
| P2 | Pharmacy validation reasons and warnings come from domain strings in English even within the Arabic portal. The surrounding headings and decision status are localized. | Add domain error codes and localized message mapping. |
| P2 | The mobile pharmacy currently assumes the first configured center; center selection is available in web only. | Carry the selected center into `MobileCenterShell` and its request list. |
| P3 | Old unused UI helpers and an untracked center-shell backup add maintenance noise. | Remove only after confirming they are outside any intended presentation path. |

## Validation record

- `flutter analyze --no-pub`: clean after the shared theme, navigation, state, reviewer, report, and patient/mobile pharmacy changes.
- `flutter test --no-pub`: 73 tests passed in the preceding remediation pass, including Arabic/English pharmacy layouts at 900, 390, 360 and 320 px, a no-results recovery path, mobile eligibility/coverage, the canonical mobile queue, reviewer rejection reason gating, and a review-queue information request saved to the shared record. The suite has not been rerun after the latest pharmacy layout and doctor navigation edits.
- `flutter build web --no-pub --no-wasm-dry-run`: successful on the final revision.
- Browser walkthrough covered Arabic desktop/tablet role entry, admin, embedded doctor, registry, reviewer empty queue, patient mobile home/medication dose logging, and pharmacy at 900 px. A 390 px mobile pharmacy walkthrough verified the revised clinical banner and handover. Confirming the handover recorded a 2026-10-01 dispense and reduced the live queue from three to two; after a fresh reload, the final revision displayed a clear search field and correctly ordered dose/request labels at phone width. A 900 px review confirmed the selected filter and dark semantic contrast. The reviewer portal displayed role-specific branding; no pending review existed in the browser seed, so the decision detail was verified in widget tests.

## Delivery report

1. **Audit summary:** The route inventory above covers entry, role shells, operational views, nested patient/plan/dispensing views, and reports. The deepest visual review covered the entry, registry, patient dose journey, and pharmacy. The open findings table records screens that still require an individual visual pass.
2. **Design system:** Forest action color, navy operational frame, mist canvas, restrained gold, type hierarchy, 48 px controls, outlined reading surfaces, and `AppSpacing`/`AppRadius`/`AppLayout` tokens now establish the shared visual language. Dark semantic text colors were added for readable status messaging.
3. **Shared components:** `StatusBadge` carries text, icon and color; `PlatformStateView` carries actionable empty, no-results, error, permission, warning and loading states. The latter adapts to short panels without hiding recovery actions.
4. **Admin:** Registry search, filtering and pagination gained compact responsive cards and clear no-results recovery. The report header was made responsive. Admin can preview the connected patient portal alongside existing doctor/pharmacy portal previews. Other management screens retain older composition.
5. **Doctor:** A persistent desktop navigation structure and clearer patient search state improve wayfinding. The Connected Journey portal section was removed from web, mobile, and the embedded admin view at the user's request. Clinical details remain connected to shared patient/plan records; the full treatment builder still needs screen-by-screen polish.
6. **Medical reviewer:** The portal now identifies the medical reviewer rather than the physician. The queue detail offers approval confirmation and reason-required rejection/information requests for care-plan reviews. The connected journey also gates overrides on a reason. Widget tests verify rejection and an information request saved to the shared record. Complete bilingual visual review remains in the P1 audit queue.
7. **Pharmacy:** Web details now place patient, prescription, eligibility checks, previous dispensing, stock, and coverage in horizontal rows at desktop widths. At narrower widths the queue opens into a full detail page with a return action, avoiding a fixed queue panel above the detail. The “Check before handover” heading was removed from web and mobile while its safety warnings remain visible. Stock, in-date batches, coverage, and blocking checks read the shared provider.
8. **Patient web:** Desktop sections are persistently visible; the admin patient preview reuses those views. Missing patient records present an action instead of a blank area. A complete deep-screen web walkthrough remains outstanding.
9. **Patient mobile:** Four primary navigation items replace hidden navigation; secondary destinations live in More. Home dose recording writes to canonical medication history and disables a repeated same-day record. Schedule and coverage displays derive from plan and financial records. A simulated loading delay was removed from the medication order eligibility step.
10. **Reports:** The command-center header responds to narrower widths; filters, export and empty-scope behavior are covered by widget tests. Dense inner report panels remain a P2 width concern.
11. **Responsive:** Desktop role shells use persistent side navigation while tablet/phone shells use drawers or bottom navigation. Pharmacy panels spread horizontally when room permits; narrower widths keep the detail readable as a separate step. Patient medication metrics stack before labels collide. Existing widget tests cover pharmacy Arabic and English at 900, 390, 360 and 320 px; they were not rerun for this latest layout-only request.
12. **Arabic and RTL:** Navigation, pagination and key actions follow text direction; mixed medication dose/request identifiers now render as one left-to-right unit within Arabic cards. Dose labels use the medication name rather than the unrelated “Health Care” text. Domain validation messages still need localized codes and text.
13. **Accessibility:** Status uses icon plus label alongside color; empty/error states expose meaningful text and recovery; buttons gain theme-level minimum targets. A full keyboard and screen-reader pass across every route is still outstanding.
14. **States:** The shared state component is in registry, pharmacy, patient missing-record/notifications, doctor search and review paths. Pharmacy negative reasons and warnings are visible near the handover action. Additional older screens still have inconsistent states.
15. **Interactions:** Patient dose recording verifies persistence; pharmacy handover invokes the canonical dispensing transition; filters and search recover from zero matches; clinical approval requests confirmation. A fresh browser handover changed the queue count from three to two.
16. **Dead controls:** The fake QR scan, disabled print stub and decorative patient toggles were removed or replaced with real provider-backed actions. This is not a claim that every legacy control has been audited.
17. **Golden path:** Existing lifecycle tests cover registration/review/approval/dispensing/patient/report linkage. The browser verified a pharmacy handover with a new dispense record and updated queue; it also verified patient dose logging earlier in this pass.
18. **Negative path:** Tests cover missing labs, rejected requests, reviewer reason gating, shared-record information requests, role denial, duplicate dispensing gates, and pharmacy no-results recovery. Browser visual checks covered empty search and blocked controls in selected workflows; reviewer negative-path visual QA remains open.
19. **Performance:** Shared state is reused rather than copied into display-only records. Search/filter interactions stay local and the web build succeeds. No production profiling or large-data load test was performed.
20. **Tests:** The preceding `flutter test --no-pub` run passed 73 tests. The pharmacy widget test includes bilingual widths, no-results recovery, clinical claim removal and canonical queue display. Reviewer tests confirm reason gating, the saved rejection state, and a queue information request persisted to the canonical record. Tests were not rerun for the latest layout and navigation change.
21. **Build:** Final `flutter analyze --no-pub` reported no issues and `flutter build web --no-pub --no-wasm-dry-run` succeeded.
22. **Screens needing attention:** P1: legacy admin/doctor/reviewer/patient nested views and complete negative-path visual walkthrough. P2: report inner panels, localized pharmacy domain messages, mobile center selection, and a few truncated Arabic table labels. P3: unused legacy helpers and a backup view.
23. **Technical limits:** The app remains a local demo with seeded records and illustrative coverage policy; the estimator is explicitly labeled, and the handover screen does not claim payment collection. The responsive browser walkthrough is not a native iOS/Android device review. No production data, external services or clinical policy approval were involved.
