# Deploy the website to Vercel

Trakta uses SvelteKit with a static adapter. Vercel serves the build output, while Firebase handles sign-in and attendance/photo storage.

| Part                     | Service                 | Configuration                                                |
| ------------------------ | ----------------------- | ------------------------------------------------------------ |
| Website, assets, and PWA | Vercel                  | `vercel.json`                                                |
| User sign-in             | Firebase Authentication | Firebase Console                                             |
| Attendance and photos    | Cloud Firestore         | `firebase.json`, `firestore.rules`, `firestore.indexes.json` |
| Firebase project target  | Firebase CLI            | `.firebaserc`                                                |

## 1. Import the repository

Push the project to your Git repository, then choose **Add New → Project** in Vercel and import it. Use the root directory containing `package.json` and `vercel.json`.

The build settings are already in `vercel.json`:

| Setting          | Value                           |
| ---------------- | ------------------------------- |
| Framework Preset | Other (`framework: null`)       |
| Install Command  | `bun install --frozen-lockfile` |
| Build Command    | `bun run build`                 |
| Output Directory | `build`                         |

The Other preset is used because the project generates a static website through its configured SvelteKit adapter. The build still runs SvelteKit. This setup doesn't need a Vercel adapter or Vercel Functions.

Use a Node build version compatible with the dependencies (development uses Node 24). Commit `bun.lock` so Vercel installs the same dependency versions.

## 2. Add environment variables

In **Project → Settings → Environment Variables**, copy the same Firebase Web app configuration values you use in your local `.env`:

```dotenv
VITE_FIREBASE_API_KEY=value_from_firebase
VITE_FIREBASE_AUTH_DOMAIN=presensi-e558f.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=presensi-e558f
VITE_FIREBASE_APP_ID=value_from_firebase
VITE_FIREBASE_USE_EMULATORS=false
```

Apply them to **Production**, and to **Preview** if preview deployments need Firebase access. `VITE_*` values are embedded at build time, so changing them requires a new deployment. Your local `.env` isn't uploaded to Git. Vercel doesn't need a Firebase admin account, service account, or Firebase CLI token to build this website.

If Preview uses the same production Firebase project, attendance submitted from Preview also goes into the production database. Use a separate Firebase project for testing if needed.

## 3. Set up Firebase Authentication domains

Once you have the production URL, open [Firebase Authentication](https://console.firebase.google.com/project/presensi-e558f/authentication) → **Settings → Authorized domains**. Add the production Vercel hostname and any custom domain you use, without `https://` or a path.

Keep `VITE_FIREBASE_AUTH_DOMAIN` set to the Firebase Web app domain. Register the Vercel website domain under Authorized domains. The app uses the Email/Password provider.

## 4. Deploy Firestore separately

Run these commands on a computer signed in to Firebase with an authorized account:

```powershell
bun run firebase:login
bun run firestore:deploy
```

These commands deploy rules and indexes to `presensi-e558f`. Vercel deployments don't run the Firebase CLI. UI changes only need a Vercel deployment; rule and index changes need the Firestore command above. See [FIREBASE.md](FIREBASE.md) for details.

## 5. Verify the deployment

1. Open the production HTTPS URL and sign in.
2. Clock in and out with photos, then check the history.
3. Try installing the PWA from a supported browser.
4. After your first online visit, reopen the app offline to check the PWA shell. Submitting attendance still requires internet access.

Security headers and `Cache-Control: no-cache` for `service-worker.js` are configured in `vercel.json`. Assets, the manifest, and the service worker are served from the same Vercel domain. This configuration doesn't rewrite every request to HTML, so missing PWA files still return a 404.

References: [vercel.json configuration](https://vercel.com/docs/project-configuration/vercel-json), [build configuration](https://vercel.com/docs/builds/configure-a-build).
