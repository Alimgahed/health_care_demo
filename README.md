# MoH Mounjaro Management Platform (Demo)

Flutter web/mobile demo for UAE Ministry of Health stakeholder presentations.

## Run

```bash
cd mounjaro_demo
flutter pub get
flutter run -d chrome
```

Recommended demo path: **Ministry Executive** role on web (≥1100px width) for the National Command Center.

## Demo credentials (role picker)

- Ministry Executive — `admin@moh.gov.ae`
- Clinician — `clinical@moh.gov.ae`
- Dispensing Center — `pharmacy@moh.gov.ae`
- Patient — `patient@mounjaro.ae` (Ahmed Al Mansoori, P001)

## Performance notes

- Patient registry uses pagination (25 per page).
- Map caps patient markers at ~35 for smooth rendering.
- Chart animations disabled for snappier dashboard updates.
