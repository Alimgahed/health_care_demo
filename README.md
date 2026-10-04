# MoH Mounjaro Management Platform (Demo)

Flutter mobile demo for UAE Ministry of Health stakeholder presentations.

## Run

```bash
flutter pub get
flutter run
```

The app is designed for Android and iOS phones. Choose a portal from the role picker.

## Demo credentials (role picker)

- Ministry Executive — `admin@moh.gov.ae`
- Clinician — `clinical@moh.gov.ae`
- Dispensing Center — `pharmacy@moh.gov.ae`
- Patient — select Patient in the access screen (Ahmed Al Mansoori, P999)

## Performance notes

- Patient registry uses pagination (25 per page).
- Map caps patient markers at ~35 for smooth rendering.
- Chart animations disabled for snappier dashboard updates.

## React web application

The standalone React and TypeScript web demo lives in [`react_web/`](react_web/README.md).
Run it independently from the Flutter app:

```bash
cd react_web
npm ci
npm run dev
```

The React demo uses browser-local demonstration data; it does not share live records or a backend with the Flutter app.
