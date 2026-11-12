# Contributing to Trakta

## Run the project

```powershell
bun install --frozen-lockfile
bun run dev
```

Copy `.env.example` to `.env` only for a fresh setup, then fill in your local configuration. `bun.lock` is committed to keep dependency versions consistent.

## Conventional Commits

Use `type(scope): summary`, with one main purpose per commit:

| Type       | Example use                                 |
| ---------- | ------------------------------------------- |
| `feat`     | Camera, gallery, or attendance features     |
| `fix`      | Bug fixes or error handling                 |
| `build`    | Bun, build, or Vercel configuration         |
| `chore`    | Repository configuration and tooling        |
| `test`     | Tests without feature changes               |
| `docs`     | Setup, usage, or deployment guides          |
| `refactor` | Code restructuring without behavior changes |

Examples:

```text
feat(camera): add automatic capture and gallery selection
fix(attendance): explain denied Firestore access
build(vercel): separate static hosting from Firebase
docs: explain Firebase rules deployment
```

Add a commit body when you need to explain the reason for a change or its limitations. For breaking changes, add `!` after the type/scope and explain `BREAKING CHANGE:` in the body.

## Files for GitHub

| Committed                                                 | Ignored by `.gitignore`                                  |
| --------------------------------------------------------- | -------------------------------------------------------- |
| `src/`, `static/`, PWA icons                              | `node_modules/`, `.svelte-kit/`, `build/`                |
| `package.json`, `bun.lock`, build/lint configuration      | Other package managers' lockfiles                        |
| `.env.example` with placeholders                          | `.env` and all `.env.*` files with local values          |
| `firebase.json`, `.firebaserc`, rules, and indexes        | Service accounts, private keys, cloud credentials        |
| `vercel.json`                                             | `.vercel/`, hosting and emulator state                   |
| `tests/`, `scripts/`, documentation                       | Logs, test screenshots, browser profiles, coverage       |
| Recommended `.vscode/settings.json` and `extensions.json` | Other editor state and OS files                          |
| Application source                                        | Local skills/agents in `.agents/`, `.claude/`, `.codex/` |

`.firebaserc` contains the project ID used by the CLI; a project ID isn't a credential. Firebase web configuration uses `VITE_*` variables and is available in the browser build. Private keys and service accounts must never be added to source files or `VITE_*` variables.

Keep `static/` committed because it contains the manifest and app icons. Don't store real attendance photos in source folders; the app stores them in Firestore. `test-results/` and `uploads/` are ignored for local output. `.prettierignore` only controls formatting, not which files are sent to GitHub.

If a secret was already committed, adding it to `.gitignore` won't remove it from history. Rotate the exposed credentials and handle the Git history separately before publishing.

## Checks before committing

```powershell
bun run check
bun run test:unit --run --project server
bun run build
git diff --cached --check
git diff --cached --stat
```

For camera changes, run `bun run test:browser` with the Firebase Emulator and a local server in emulator mode. The script uses Chrome's virtual camera, so it doesn't capture images from your personal webcam.

Review staged files before committing. A local commit doesn't automatically push code to GitHub. See [docs/VERCEL.md](docs/VERCEL.md) for website deployment; Firestore rules are deployed separately as described in [docs/FIREBASE.md](docs/FIREBASE.md).
