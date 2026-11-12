# Trakta

Trakta is a simple attendance app for clocking in and out, with photos, work location options, and attendance history. Built with Svelte 5, SvelteKit, TypeScript, Firebase Authentication, and Cloud Firestore, it's installable as a PWA. The app has an Indonesian interface that works on desktop and mobile.

## Features

- Sign up, sign in, sign out, and reset your password through Firebase email authentication.
- Clock in and out once each per day in **Asia/Jakarta (WIB)**.
- Choose office, work from home, or off-site duty, with an optional note of up to 300 characters.
- The front camera opens automatically when the attendance form is ready. For remote or off-site attendance, **Pilih galeri/file** (Choose gallery/file) also accepts JPG, PNG, or WebP up to 20 MB. Images are compressed on your device to JPEG at **no more than 100,000 bytes (100 KB)** before upload.
- Firestore server timestamps for both entries. Security rules reject client-generated timestamps, incorrect dates, duplicate entries, and clocking out before clocking in.
- View the last 31 attendance days, the current month's summary, work duration, notes, and photos on demand.
- PWA support: the app shell opens offline after an online visit. Submitting attendance requires a connection and server confirmation.

## Firebase setup

The Firebase CLI target is set to `presensi-e558f` in `.firebaserc`. For database setup, rules, indexes, and permission troubleshooting, see [Firebase and Firestore setup](docs/FIREBASE.md).

Use **Bun 1.4.2 or newer** to manage dependencies and run scripts. `bun.lock` is the project's lockfile. Some development CLIs still need a compatible Node installation (development uses Node 24), and the Firebase Emulator needs Java 21.

```powershell
bun install --frozen-lockfile
# For a fresh setup only, if .env doesn't exist yet:
Copy-Item .env.example .env
```

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Add a **Web app** in Project settings. Copy `apiKey`, `authDomain`, `projectId`, and `appId` into the `VITE_FIREBASE_*` variables in `.env`.
3. Enable **Authentication → Sign-in method → Email/Password**. Add your app's domain to Authorized domains, including `localhost` for development if it's missing.
4. Create a **Cloud Firestore database (Standard edition)** in production mode, then deploy the project's rules with the commands below. Don't use public-access rules.

```powershell
bun run firebase:login
bun run firestore:deploy
bun run dev --host 127.0.0.1
```

Open the local Vite URL. Create an account, sign in, choose a work location, add a photo and optional note, then clock in. The form switches to clock-out mode once the server accepts your clock-in entry.

Firebase web configuration is public and included in the browser build. Don't put private keys or service accounts in `VITE_*` variables. Data access is controlled by `firestore.rules`.

## Run locally without a Firebase account

The emulator needs Java 21. In `.env`, leave the four configuration values empty and set `VITE_FIREBASE_USE_EMULATORS=true`. Run these in two terminals:

```powershell
bun run emulators
```

```powershell
bun run dev --host 127.0.0.1
```

Auth: `127.0.0.1:9099`; Firestore: `127.0.0.1:8085`; Emulator UI: `127.0.0.1:4000`. Emulator data is temporary. Don't enable emulator mode in production or when testing from another phone, since loopback addresses point to that device itself.

## Folder structure

```text
src/
  lib/
    components/       # AuthPanel, Dashboard, AttendanceForm, History, PwaInstall
    firebase/         # SDK, auth, attendance transactions and queries
    types/            # Attendance domain types
    utils/            # Photo compression and WIB dates
  routes/             # Pages, layouts, tokens, and global styles
  service-worker/     # Public app shell cache
static/
  icons/              # Regular and maskable PNG icons
  manifest.webmanifest
tests/
  firestore.rules.test.mjs
firestore.rules
firestore.indexes.json
firebase.json         # Firestore and emulators
vercel.json           # Static website deployment to Vercel
```

Components use Svelte 5 runes, modern event handlers, derived state, listener cleanup, and separate services. Authentication state belongs to the page and isn't shared across SSR requests.

## Firestore data

```text
users/{uid}/attendance/{YYYYMMDD}
  dateKey: "20261110"
  checkIn:  { timestamp: Timestamp, mode: "office", note: "..." }
  checkOut: { timestamp: Timestamp, mode: "office", note: "..." }  # after clock-out

users/{uid}/attendance/{YYYYMMDD}/photos/{checkIn|checkOut}
  base64: "..."
  bytes: 98432
  mimeType: "image/jpeg"
  createdAt: Timestamp
```

Attendance summaries and photos are written in **one atomic transaction**; a valid attendance entry always includes a photo. Photos are stored separately so loading history doesn't download images. Base64 adds about 33% overhead: a 100 KB image becomes roughly 133 KB of text. Indexing is disabled for the `base64` field.

Rules check the decoded size using the base64 length and padding, and reject falsified sizes. They don't verify photo content or facial identity. Users can read their own data but can't edit or delete attendance entries or photos. Firebase project administrators still have administrative access.

The date is checked against server time plus 7 hours. The device clock is only used for display and choosing the requested document; an incorrect clock can cause a request to be rejected. Clock-out must happen on the same WIB day, so overnight shifts aren't supported yet. Duration is the time between clock-in and clock-out, without subtracting breaks. GPS validation, work schedules, and lateness tracking aren't available yet.

## Validation

```powershell
bun run check
bun run test:unit --run --project server
bun run test:rules
bun run build
```

`test:rules` runs the emulator to check cross-account access, timestamps, WIB dates, atomic photo writes, duplicates, data changes, photo sizes, and field validation. Image compression and UI flows are verified in a real browser.

`bun run test:browser` tests the full flow using an installed Chrome browser, a development server on port 5173 in emulator mode, and running Auth/Firestore Emulators. The script creates test accounts and attendance entries in the emulator. `bun run test:pwa` checks the manifest, installability, shell cache, and offline reload on the production preview at port 4173. Screenshots are saved in `test-results/` (ignored by Git). Don't run a build while preview is running; restart preview after a new build.

`bun run validate:svelte` runs the official autofixer from the Svelte skill. `bind:this` element references open the native file picker and control the photo dialog; the app doesn't use manual DOM manipulation for rendering.

## Build and PWA

```powershell
# Fill in production .env values, set VITE_FIREBASE_USE_EMULATORS=false, then build.
bun run build
bun run preview --host 127.0.0.1

# Separately deploy Firestore rules and indexes:
bun run firestore:deploy
```

The website is deployed to **Vercel** using `vercel.json`. The static adapter generates the `build/` folder without a Node server at runtime. Vercel runs `bun install --frozen-lockfile` and `bun run build`. For project import, environment variables, and domains, see [Vercel deployment](docs/VERCEL.md).

Firebase handles Authentication and Firestore. Deploy rules and indexes with `bun run firestore:deploy`, separately from the website. The `firebase:deploy` script remains available as an alias for that Firestore command.

Set the `VITE_FIREBASE_*` variables in Vercel's Environment Variables settings, with `VITE_FIREBASE_USE_EMULATORS=false`. Rebuild or redeploy after changing configuration values.

PWA support is enabled in production builds over HTTPS or localhost. On Android and desktop, use **Pasang aplikasi** (Install app) or the browser menu. On iPhone, use Safari → Share → Add to Home Screen. The service worker only caches the build, icons, and public app shell; it doesn't cache Auth responses, Firestore documents, or photos. Firestore uses the SDK's in-memory cache, not persistent offline caching. Firebase Auth still manages login sessions in the browser; use **Keluar** (Sign out) on shared devices.

Regenerate icons from `static/icon.svg` with `bun scripts/generate-icons.mjs` (requires Google Chrome, like the browser tests).

Live camera capture requires HTTPS or localhost, browser support, and camera permission. Gallery selection is available for remote attendance, field attendance, and photo booth sessions. The camera stops after a photo is taken, when switching to the gallery, when the tab is hidden, or when the form is closed. Photos are only sent when attendance is submitted.

Attendance photos require location permission. For **Di kantor**, use the live camera within 150 m of the Graha Sucofindo pin in Pancoran, with a location accuracy estimate of 100 m or better. For **Dari rumah** and **Dinas luar**, gallery uploads record the device location when the file is selected. Check-in and check-out each store their own `photoLocation` in Firestore. Deploy the updated rules and the corresponding website release together.

References: [Firebase auth](https://firebase.google.com/docs/auth/web/password-auth), [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions), [security rules](https://firebase.google.com/docs/firestore/security/rules-fields), [SvelteKit service workers](https://svelte.dev/docs/kit/service-workers).
