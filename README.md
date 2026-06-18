# 📒 Ledger — Personal Multi-Project Expense Tracker

A personal expense tracking app with a **Flask web UI**, a **menu-driven CLI**, a **Flutter mobile app**, and **Google Drive sync** to keep your data in sync across multiple devices.

Built for personal use — no cloud service, no subscriptions, no ads. Your data lives as plain JSON files on your own machine and optionally on your own Google Drive.

---

## What it can do

- Track expenses across multiple independent projects (home renovation, college fees, business, travel — anything)
- Each project has its own categories, payment modes, and tags
- Add, edit, delete expenses through a web GUI, the CLI, or the Flutter mobile app
- View analytics — category breakdown, vendor breakdown, payment mode split, tag breakdown, daily timeline
- Export any project to a formatted Excel file with charts
- Auto-sync to Google Drive — web app pulls on startup and pushes after every change, Flutter app fetches on open and pushes after every change
- Use the CLI fully from a terminal, including on Android via Termux
- Manage expenses on Android via a Flutter app that signs in with your own Google account and reads/writes directly to your Drive

---

## Screenshots

![Screenshot_1](/assets/scrsht1.png)

![Screenshot_2](/assets/scrsht2.png)

![Screenshot_3](/assets/scrsht3.png)

---

## Project structure

```
Ledger/
├── app.py                  ← Flask web server (run this)
├── cli.py                  ← Menu-driven terminal CLI
├── requirements.txt        ← Python dependencies
├── DRIVE_SETUP.md          ← Google Drive setup guide
├── credentials.json        ← YOUR OAuth key (not in repo, add manually)
├── token.json              ← Auto-created on first Drive login (not in repo)
├── data/
│   ├── meta.json           ← Global settings + project index
│   ├── projects/
│   │   └── <slug>.json     ← One JSON file per project
│   └── backups/            ← Local timestamped backups
├── exports/                ← Excel exports saved here
├── modules/
│   ├── storage.py          ← JSON read/write, project management
│   ├── expense.py          ← Expense CRUD and analytics
│   ├── exporter.py         ← Excel export logic
│   └── drive_sync.py       ← Google Drive push/pull
├── templates/              ← Jinja2 HTML templates for Flask
└── ledger_viewer/          ← Flutter mobile app
    ├── lib/
    └── pubspec.yaml
```

---

## Part 1 — Python web app and CLI setup

### Prerequisites

- Python 3.10 or higher
- pip

Check your version:
```bash
python --version
```

---

### Windows setup

**Step 1 — Clone the repo**
```bash
git clone https://github.com/Ra-Helios/Ledger.git
cd Ledger
```

**Step 2 — Create a virtual environment (recommended)**
```bash
python -m venv .venv
.venv\Scripts\activate
```

**Step 3 — Install dependencies**
```bash
pip install -r requirements.txt
```

**Step 4 — Run the web app**
```bash
python app.py
```
Open your browser at `http://localhost:5050`

**Step 5 — Or run the CLI**
```bash
python cli.py
```

---

### Linux setup

**Step 1 — Clone the repo**
```bash
git clone https://github.com/Ra-Helios/Ledger.git
cd Ledger
```

**Step 2 — Create a virtual environment**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

**Step 3 — Install dependencies**
```bash
pip install -r requirements.txt
```

**Step 4 — Run the web app**
```bash
python app.py
```
Open your browser at `http://localhost:5050`

**Step 5 — Or run the CLI**
```bash
python cli.py
```

---

### macOS setup

**Step 1 — Clone the repo**
```bash
git clone https://github.com/Ra-Helios/Ledger.git
cd Ledger
```

**Step 2 — Create a virtual environment**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

**Step 3 — Install dependencies**
```bash
pip install -r requirements.txt
```

**Step 4 — Run the web app**
```bash
python app.py
```
Open your browser at `http://localhost:5050`

**Step 5 — Or run the CLI**
```bash
python cli.py
```

> **macOS note:** If you get an SSL error when the Drive login browser opens, make sure you have run `/Applications/Python\ 3.x/Install\ Certificates.command` which ships with the Python macOS installer.

---

### Termux (Android) setup

Termux is an Android terminal app. This lets you run the full CLI on your phone without needing the Flutter app.

**Step 1 — Install Termux**

Download Termux from **F-Droid** (not Play Store — the Play Store version is outdated):
https://f-droid.org/packages/com.termux/

**Step 2 — Update packages and install Python**
```bash
pkg update && pkg upgrade
pkg install python git
```

**Step 3 — Clone the repo**
```bash
git clone https://github.com/Ra-Helios/Ledger.git
cd Ledger
```

**Step 4 — Install Python dependencies**
```bash
pip install flask rich google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
```

> `openpyxl` is only needed for Excel export which the CLI does not support, so you can skip it on Termux. If you want it anyway: `pip install openpyxl`

> If `cryptography` fails to build, try: `pkg install python-cryptography` first, then run the pip install above.

**Step 5 — Copy your security files manually**

These files are not in the repo for security reasons. Copy them to the project folder on your phone:

- `credentials.json` — your Google OAuth client secret (for Drive push/pull)
- `token.json` — generated after first login on another device, copy this across to skip re-login

You can transfer them via:
- USB cable + file manager
- Telegram: send the files to yourself, download in Termux storage
- `adb push` if you have Android tools on your PC

To find your Termux home from a file manager:
```
Internal Storage → Android → data → com.termux → files → home
```

**Step 6 — Run the CLI**
```bash
python cli.py
```

**Step 7 — First time Drive login on Termux**

The OAuth flow needs a browser. On Termux it will print a URL — copy it, open it in your phone browser, log in, and paste the code back. Or just copy `token.json` from a machine where you have already logged in (this skips the browser step entirely).

> For a complete first-time setup detailed walkthrough, see [DRIVE_SETUP.md](DRIVE_SETUP.md).

> **Termux tip:** The CLI is designed for mobile keyboard use — all navigation is single key presses or numbers, nothing requires a mouse.

---

## Part 2 — Google Drive sync setup

This lets you save your project JSONs to your personal Google Drive and keep all devices in sync automatically. Completely optional — the app works fine without it.

> For a detailed step-by-step Drive setup guide, see [DRIVE_SETUP.md](DRIVE_SETUP.md).

### How auto-sync works

**Web app** — on the first page request after `python app.py` starts, all projects are pulled from Drive automatically. After every add, edit, delete, or project settings save, the updated project is pushed to Drive silently in the background.

**Flutter app** — fetches all projects from Drive automatically when the app opens. After every add, edit, delete, or settings change, pushes to Drive automatically. A small spinner in the title bar shows when a push is in progress.

Manual **Save to Drive** and **Fetch from Drive** buttons remain available in Project Settings for on-demand sync (web app). The Flutter app has a manual refresh button and pull-to-refresh on the home screen.

### Conflict detection

When two devices both make changes without syncing in between, the app compares the exact set of entry IDs on each side and detects a diverge — showing you exactly which entries exist on each side and refusing to silently overwrite either copy.

> See [DRIVE_SETUP.md](DRIVE_SETUP.md) for full conflict detection details and how to resolve a diverge manually.

### Security note

Never commit `credentials.json` or `token.json` to a public repo. Both are listed in `.gitignore` already. The Flutter app no longer uses any key file at all — see Part 3 below.

---

## Part 3 — Flutter mobile app

The Flutter app signs in with your own Google account (standard Google Sign-In, the same kind you see in most Android apps) and reads/writes directly to your Drive. It supports full expense management — add, edit, delete, and project settings — and syncs automatically on open and after every change.

No key files, no service accounts, nothing to download and place in the project. Just one Android OAuth client to set up once, then sign in on-device exactly like signing into Gmail or any other Google app.

### Prerequisites

- Flutter 3.x installed: https://docs.flutter.dev/get-started/install
- Android Studio (for the emulator or to build the APK)
- Java 8 or higher

Check your setup:
```bash
flutter doctor
```
All required items (Flutter, Android toolchain, Android Studio) should show ✓.

### Step 1 — Get your debug keystore's SHA-1 fingerprint

Google needs to know which app build is allowed to use sign-in. This is identified by your package name plus a SHA-1 fingerprint derived from the keystore that signs your build.

```bash
keytool -list -v -keystore "C:\Users\<you>\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
(On Linux/macOS the path is `~/.android/debug.keystore`)

Find the line that starts with `SHA1:` and copy the full fingerprint.

### Step 2 — Create an Android OAuth client on Google Cloud

1. Go to https://console.cloud.google.com/ → select your `ledger-backup` project
2. **APIs & Services → Credentials** (or **Google Auth Platform → Clients**)
3. **+ Create Credentials → OAuth 2.0 Client ID**
4. Application type: **Android**
5. Name: anything, e.g. `LedgerAndroid`
6. Package name: `com.adhithya.ledger_viewer` (or your own, must match `applicationId` in `android/app/build.gradle` exactly)
7. SHA-1 certificate fingerprint: paste the value from Step 1
8. Click **Create**
9. No file to download — the client is now registered against your package name + SHA-1, and the app auto-detects it at sign-in time

> **Important:** make sure your Gmail address is added under **OAuth consent screen → Test users**, otherwise sign-in fails with an Access Blocked error. See [DRIVE_SETUP.md](DRIVE_SETUP.md) Step 3.

### Step 3 — Set up the Flutter project

```bash
cd ledger_viewer
flutter pub get
```

Nothing else needed — the Android client ID is auto-detected by `google_sign_in` from your package name and SHA-1, no client ID needs to be entered into the code.

### Step 4 — Run on emulator or device for testing

Start an Android emulator from Android Studio (Device Manager → play button) — make sure it uses a system image **with Google Play Store**, not just "Google APIs", otherwise sign-in will not work. Then:
```bash
flutter run
```

Or connect a real Android phone via USB with USB debugging enabled:
- Settings → About phone → tap Build number 7 times
- Settings → Developer options → USB debugging → ON

Tap **Sign in with Google** on first launch, pick your account, and you're in.

### Step 5 — Build the release APK

```bash
flutter build apk --release
```

APK location:
```
ledger_viewer/build/app/outputs/flutter-apk/app-release.apk
```

**Install on your phone:**
- Send the APK to yourself via WhatsApp or Telegram
- Download on your phone → tap → install
- If blocked: tap **More details → Install anyway**
- If "Unknown sources" warning: Settings → Apps → Special app access → Install unknown apps → allow

### Sharing the APK with friends or family

Since this APK is signed with your debug keystore, anyone who installs it and signs in is still bound to **your** registered SHA-1 + package name — that part is about the app build, not who is using it. Any Google account can sign in, as long as it is on the test users list.

1. Go to Google Cloud Console → **OAuth consent screen** (or **Google Auth Platform → Audience**) → **Test users**
2. Click **+ Add Users** → add each friend's Gmail address
3. Share the same APK file with them (WhatsApp, Drive link, USB — anything)
4. They install it and sign in with their own Google account
5. Each person's data goes to **their own personal Drive** in a `LedgerJsons` folder — completely separate from yours, nobody sees anyone else's expenses

The free tier allows up to 100 test users, more than enough for sharing with friends and family. If you ever want this to be installable by literally anyone without being added as a test user, that requires Google's app verification process — unnecessary for personal/friend use.

### Flutter app features

- **Login screen** — Google Sign-In on first launch, silent auto-login on every launch after that
- **Home screen** — lists all projects from Drive with combined total, auto-fetches on open, pull-to-refresh, sign-out option
- **Dashboard tab** — 4 stat cards (total, average, cash, digital), category doughnut chart, category progress bars, payment mode cards, vendor list, tag breakdown, daily line chart
- **Expenses tab** — full list with search bar and filter sheet (category, mode, tag, sort by date / amount / entry ID), tap to edit, swipe left or long press to delete, ＋ button to add
- **Settings tab** — edit project name, icon, description, currency, add/remove/rename categories, payment modes, and tags
- **Auto-sync** — fetches from Drive on open, pushes to Drive after every change automatically

---

## Part 4 — Web app features

Once running at `http://localhost:5050`:

### All Projects (home screen)
- Shows all your projects as cards with total spend and entry count
- Combined grand total across all projects
- Click any project to open it, or switch via the sidebar

### Dashboard
- Total spend, cash vs digital split, average per entry
- Category breakdown with progress bars
- Payment mode cards
- Tag breakdown
- Top vendors list

### Analytics
- Category doughnut chart
- Category breakdown table with percentages
- Vendor bar chart and table
- Payment mode pie chart
- Tag horizontal bar chart
- Daily expenditure line chart

### Expenses list
- Full table with ID, date, category, vendor, description, tags, mode, amount
- Filter by: category, vendor, mode, tag, date range, amount range, free text search
- Sort by: date, amount, or entry ID (ascending or descending)
- Hover over a row to reveal edit and delete buttons
- Excel export button

### Add / Edit expense
- Date (defaults to today)
- Category (from project's configured list)
- Payment mode (from project's configured list)
- Vendor / payee (free text with autocomplete)
- Description
- Tags (checkbox selection)
- Notes (optional)

### Project settings
- Rename project, change icon, change description
- Add / remove categories, payment modes, tags
- Google Drive sync (push and pull with conflict detection)
- Delete project (cannot be undone)

### New project
- 5 quick templates: Home Renovation, Personal Finance, Business, Travel, Education
- Or fill from scratch
- Per-project currency override

---

## Part 5 — CLI features

Run `python cli.py` from the project folder.

### Project selector
Shows all projects with entry count and total. Enter the number to open a project.

### Inside a project

**1. List expenses**
Displays a table of all expenses sorted by newest date:
`ID | Date | Category | Description | Amount | Mode`
With total at the bottom.

**2. Add expense**
Walks through each field one by one. Required fields loop until valid input is given. Date defaults to today if you press Enter. Tags are selected by number from a list. Shows a review screen before saving.

**3. Edit expense**
Lists all expenses → enter ID → shows full entry detail → shows a field menu. Pick a field number to edit it, then pick another, repeat until done. Press `s` to save all changes, `b` to discard.

**4. Delete expense**
Lists all expenses → enter ID → shows full entry detail verbosely → asks for explicit confirmation. Deletes one entry at a time only.

**5. Project settings**
Lists all configurable fields. Pick one to edit. For categories, modes, and tags you can add new items or delete existing ones. Delete project is intentionally not available in CLI for safety.

**6. Drive sync**
Push local data to Drive or pull from Drive. Shows conflict details if detected and asks what you want to do.

---

## Security notes

- `credentials.json` — your Google OAuth client secret for the web app. Never commit to any repo.
- `token.json` — your saved login session for the web app. Never commit to any repo.
- `data/` — your expense data. Keep off public repos — it is personal financial information.
- Flutter app — no key files at all. The Android OAuth client ID is a public identifier safe to be visible in source code; security comes from the SHA-1 + package name binding registered on Google Cloud Console, not from secrecy of the ID.
- If you ever build a **release-signed** APK (not the default debug build) to distribute more widely, the release keystore file (`.jks` / `.keystore`) and its password (`key.properties`) must never be committed — these are listed in `.gitignore`.
- All sensitive files are listed in `.gitignore` and will not be pushed automatically.

---

## Troubleshooting

**"Access blocked: app has not completed Google verification"**
You need to add your Gmail as a test user. Go to Google Cloud Console → APIs & Services → OAuth consent screen (or Google Auth Platform → Audience) → Test users → Add your email.

**"charmap codec can't decode" error on Drive fetch (Windows)**
Update to the latest `drive_sync.py` — this was a Windows UTF-8 encoding bug that has been fixed.

**"credentials.json not found"**
Place your `credentials.json` file in the root project folder (same folder as `app.py`), not inside any subfolder.

**Flutter: "borderRadius can only be given on borders with uniform colors"**
Update to the latest `widgets.dart` — this rendering bug has been fixed.

**Flutter APK build: Kotlin version warnings**
These are warnings, not errors. The APK will still build and run correctly. They come from Gradle dependencies and do not affect functionality.

**Flutter: PlatformException(sign_in_failed, ApiException: 10)**
This means the SHA-1 fingerprint or package name registered on Google Cloud Console does not match the build that is running. Re-check Step 1 and Step 2 of the Flutter setup above — package name must match `applicationId` exactly, and the SHA-1 must be copied in full without typos.

**Flutter: sign-in works on my device but fails for a friend**
Their Gmail address is not on the test users list. Add it under OAuth consent screen → Test users.

**Termux: Drive login browser does not open**
The OAuth flow will print a URL to the terminal. Copy it manually, open it in your phone browser, complete the login, and paste the resulting code back in the terminal. Alternatively copy `token.json` from a machine that is already logged in.

**Termux: cryptography package fails to install**
Run `pkg install python-cryptography` first, then retry `pip install -r requirements.txt`.

**"next_id not incrementing" (entries getting duplicate IDs)**
Update to the latest `expense.py` — this was a double-save race condition bug that has been fixed.

**Diverge warning appears unexpectedly**
Both devices made changes without syncing in between. See [DRIVE_SETUP.md](DRIVE_SETUP.md) for how to resolve a diverge manually.
