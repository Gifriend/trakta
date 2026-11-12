# Firebase and Firestore setup

This app's project is **`presensi-e558f`**, matching `VITE_FIREBASE_PROJECT_ID` in `.env`. The Firebase CLI uses the same target through `.firebaserc`.

Firebase handles Authentication and Firestore. The website is deployed separately to Vercel; see the [Vercel guide](VERCEL.md). `firebase.json` only configures the database, rules, indexes, and emulators.

## 1. Install dependencies with Bun

```powershell
bun install --frozen-lockfile
```

Use `bun.lock` as the lockfile. The app commands are `bun run dev`, `bun run check`, and `bun run build`. The Firebase CLI still uses the installed Node runtime; you don't need to install it globally.

## 2. Sign in with the project owner's account

```powershell
bun run firebase:login --reauth
bun run firebase:databases
```

Sign in with a Google account that has access to `presensi-e558f`. To switch accounts:

```powershell
bunx --no-install firebase login:add
bunx --no-install firebase login:use OWNER_ACCOUNT_EMAIL
```

If you see `403 The caller does not have permission`, the CLI account doesn't have the required permissions. Use the project owner's account, or ask the owner to grant access to manage the database, rules, and indexes. The web configuration in `.env` doesn't grant administrative deployment permissions.

## 3. Create or check the database

Open [Firestore for presensi-e558f](https://console.firebase.google.com/project/presensi-e558f/firestore).

If there isn't a database yet, choose **Create database** with these settings:

| Setting                     | Value                       |
| --------------------------- | --------------------------- |
| Edition                     | Standard                    |
| Database ID                 | `(default)`                 |
| Mode                        | Native / Firestore          |
| Location for a new database | `asia-southeast2` — Jakarta |
| Initial security rules      | Production mode             |

`firebase.json` includes these database, edition, location, rules, and index settings. The Firebase CLI can create the default database on the first deployment if it doesn't exist and the account has permission. An existing database keeps its current location; this configuration doesn't move data. Choose the location before creating a new database, since it can't be changed afterward.

## 4. Deploy rules and indexes

The following default rule blocks all reads and writes, including requests from signed-in users:

```text
allow read, write: if false;
```

If the app shows **Akses presensi belum diizinkan** (Attendance access isn't allowed yet), or an older version shows **Data belum dapat dimuat** (Data couldn't be loaded), open [Firestore → Rules](https://console.firebase.google.com/project/presensi-e558f/firestore/rules), **replace the entire editor contents with the full contents of [firestore.rules](../firestore.rules)**, then select **Publish**. Use the `(default)` database in `presensi-e558f`. Once the rules are published, click **Muat ulang data** (Reload data) in the app. If the listener still uses the old rules, wait for the rules to propagate and try again.

Local files don't automatically update the rules running in Firebase. Deploying the website to Vercel doesn't publish rules either. The last checked CLI account lacked project management permissions (HTTP 403); use the Firebase Console with the owner's account, or sign in to the CLI with an authorized account. You don't need to make the rules public.

To deploy the same rules and indexes through the CLI:

```powershell
bun run firestore:deploy
```

This script only targets Firestore. Run it separately whenever rules or indexes change; the Vercel build doesn't run it automatically. It deploys:

- `firestore.rules`: authenticated users can only access their own data. Timestamps must come from the server, clock-in and clock-out are limited to once each per WIB day, photos are required in the same transaction, and notes are limited to 300 characters.
- `firestore.indexes.json`: the photo `base64` field isn't indexed. History queries use the single-field `dateKey` index, so they don't need a composite index.

Attendance entries and photos can't be edited or deleted through the app. These app-specific rules don't grant access to other collections. If other apps share the Firebase project, merge their rules before deploying.

Alternatively, open the Console's **Rules** tab, paste the full contents of `firestore.rules`, and select **Publish**. The photo index exemption still needs to be applied through the CLI or the Console's single-field index configuration for the `photos` collection group and `base64` field.

## 5. Enable Authentication

Open [Authentication](https://console.firebase.google.com/project/presensi-e558f/authentication), enable the **Email/Password** provider, and check Authorized domains. Add the production Vercel hostname (for example, `your-project.vercel.app`), any custom domain you use, and `localhost` for development. Enter domains without a protocol or path.

This project's local setup already has an `.env` file, so don't overwrite it. On another computer, copy `.env.example` to `.env` and fill in the Web app configuration from Firebase Project settings. Make sure `VITE_FIREBASE_USE_EMULATORS=false` when using production Firebase.

## 6. Run and verify

```powershell
bun run dev
```

Sign up or sign in, submit a photo to clock in, then submit a photo to clock out. App transactions create documents automatically; you don't need to create collections or sample data by hand:

```text
users/{firebaseAuthUid}/attendance/{YYYYMMDD}
  dateKey: string
  checkIn: { timestamp: Timestamp, mode: string, note: string }
  checkOut: { timestamp: Timestamp, mode: string, note: string }

users/{firebaseAuthUid}/attendance/{YYYYMMDD}/photos/checkIn
users/{firebaseAuthUid}/attendance/{YYYYMMDD}/photos/checkOut
  base64: string
  bytes: integer <= 100000
  mimeType: "image/jpeg"
  createdAt: Timestamp
```

You don't need to create the `users/{uid}` document itself; Firestore allows subcollections without a parent document. Original photos are compressed to JPEG at no more than 100 KB, then stored as base64 text in photo documents. Attendance times use `serverTimestamp()` and are checked by the rules.

To test locally without touching the production project:

```powershell
bun run test:rules
```

This command uses the `demo-presensi` emulator project, separate from the production target. Java 21 is required.

Official references: [Firebase CLI](https://firebase.google.com/docs/cli), [database management](https://firebase.google.com/docs/firestore/manage-databases), [Firestore locations](https://firebase.google.com/docs/firestore/locations).
