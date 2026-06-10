# 📒 Ledger — Personal Multi-Project Expense Tracker

A personal expense tracking app with a **Flask web UI**, a **menu-driven CLI**, a **read-only Flutter mobile app**, and **Google Drive sync** to keep your data in sync across multiple devices.

Built for personal use — no cloud service, no subscriptions, no ads. Your data lives as plain JSON files on your own machine and optionally on your own Google Drive.

---

## What it can do

- Track expenses across multiple independent projects (home renovation, college fees, business, travel — anything)
- Each project has its own categories, payment modes, and tags
- Add, edit, delete expenses through a web GUI or the CLI
- View analytics — category breakdown, vendor breakdown, payment mode split, tag breakdown, daily timeline
- Export any project to a formatted Excel file with charts
- Sync your JSON data to Google Drive and fetch it on another machine
- Use the CLI fully from a terminal, including on Android via Termux
- View all data read-only on Android via a Flutter app that reads directly from Drive

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
└── ledger_viewer/          ← Flutter mobile app (read-only viewer)
    ├── lib/
    ├── assets/
    │   └── service_account.json  ← YOUR Drive service account key (add manually)
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
git clone https://github.com/Ra-Helios/Leadger.git
cd Leadger
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
git clone https://github.com/Ra-Helios/Leadger.git
cd Leadger
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
git clone https://github.com/Ra-Helios/Leadger.git
cd Leadger
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
git clone https://github.com/Ra-Helios/Leadger.git
cd Leadger
```

**Step 4 — Install Python dependencies**
```bash
pip install flask rich google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
```

> `openpyxl` is only needed for Excel export which the CLI does not support, so you can skip it on Termux. If you want it anyway: `pip install openpyxl`

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

This lets you save your project JSONs to your personal Google Drive and fetch them on any other machine. Completely optional — the app works fine without it.

### Step 1 — Create a Google Cloud project

1. Go to https://console.cloud.google.com/
2. Click the project dropdown at the top → **New Project**
3. Name it anything, e.g. `ledger-backup` → **Create**
4. Make sure this new project is selected in the dropdown

### Step 2 — Enable the Google Drive API

1. In the left sidebar → **APIs & Services → Library**
2. Search for `Google Drive API`
3. Click it → **Enable**

### Step 3 — Configure the OAuth consent screen

1. Left sidebar → **APIs & Services → OAuth consent screen**
   (This may now appear under **Google Auth Platform**)
2. User type: **External** → **Create**
3. Fill in:
   - App name: `Ledger` (or anything)
   - User support email: your Gmail
   - Developer contact email: your Gmail
4. Click **Save and Continue** through all steps (scopes and test users can be done after)
5. Back on the OAuth consent screen, scroll to **Test users**
6. Click **+ Add Users** → add your Gmail address → **Save**

> This step is required. Without adding yourself as a test user, Google will block the login with "Access blocked" error.

### Step 4 — Create OAuth credentials

1. Left sidebar → **APIs & Services → Credentials**
   (or **Google Auth Platform → Clients**)
2. **+ Create Credentials → OAuth 2.0 Client ID**
3. Application type: **Desktop app**
4. Name: anything, e.g. `LedgerDesktop`
5. **Create**
6. Click **Download JSON** on the popup (or download icon next to the client)
7. Rename the downloaded file to exactly `credentials.json`
8. Place it in your project root folder (same folder as `app.py`)

### Step 5 — First login

Start the web app (`python app.py`) and go to **Project Settings** for any project. You will see the Google Drive Sync section. Click **Save to Drive**.

A browser tab opens → log in with the Google account you added as a test user → allow access → done.

A `token.json` file is automatically saved. All future syncs are silent — no login needed again on this machine.

### Step 6 — Second machine setup

On the second machine:
1. Pull the repo
2. Place `credentials.json` in the project root (same file, copy it across)
3. Either click Save/Fetch from Drive to do the browser login once, or copy `token.json` from the first machine to skip it entirely

### How sync works

- **Save to Drive** — pushes your local project JSON to `My Drive → LedgerJsons → <project>.json`
- **Fetch from Drive** — pulls the Drive JSON down to local
- **Conflict detection** — uses `next_id` (a counter that only ever increases) to detect which copy is newer:
  - Local newer → safe to push
  - Drive newer → safe to pull
  - Conflict → shows both sides, you decide

> **Security note:** Never commit `credentials.json` or `token.json` to a public repo. They are listed in `.gitignore` already.

---

## Part 3 — Flutter mobile app (read-only viewer)

The Flutter app connects directly to your Google Drive using a service account and shows all your projects and expenses. It is strictly read-only — no add, edit, or delete.

### Prerequisites

- Flutter 3.x installed: https://docs.flutter.dev/get-started/install
- Android Studio (for the emulator or to build the APK)
- Java 8 or higher

Check your setup:
```bash
flutter doctor
```
All required items (Flutter, Android toolchain, Android Studio) should show ✓.

### Step 1 — Create a service account on Google Cloud

A service account is a bot credential that lets the Flutter app read your Drive silently — no login screen ever appears on the phone.

1. Go to https://console.cloud.google.com/ → select your `ledger-backup` project
2. Left sidebar → **IAM & Admin → Service Accounts**
3. **+ Create Service Account**
4. Name: `ledger-mobile-viewer` (or anything)
5. Click **Create and Continue** → skip the optional role fields → **Done**
6. Click on the created service account in the list
7. Go to the **Keys** tab → **Add Key → Create new key → JSON**
8. A JSON file downloads — this is your service account key

### Step 2 — Share your Drive folder with the service account

1. Open the downloaded service account JSON file
2. Find the `client_email` field — it looks like:
   `ledger-mobile-viewer@ledger-backup.iam.gserviceaccount.com`
3. Go to **Google Drive** in your browser
4. Find the `LedgerJsons` folder (created automatically when you first used Save to Drive)
5. Right-click → **Share**
6. Paste the service account email → set permission to **Viewer** → **Share**

> If `LedgerJsons` doesn't exist yet, run Save to Drive from the web app first to create it.

### Step 3 — Set up the Flutter project

**Navigate into the Flutter app folder:**
```bash
cd ledger_viewer
```

**Replace the placeholder service account file:**

Open `assets/service_account.json` and replace its entire contents with your real service account key JSON that you downloaded in Step 1.

**Install Flutter dependencies:**
```bash
flutter pub get
```

### Step 4 — Run on emulator or device for testing

Start an Android emulator from Android Studio (Device Manager → play button), then:
```bash
flutter run
```

Or connect a real Android phone via USB with USB debugging enabled:
- Settings → About phone → tap Build number 7 times
- Settings → Developer options → USB debugging → ON

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

### Flutter app features

- **Home screen** — lists all projects from Drive with combined total, auto-fetches on open
- **Pull to refresh** — swipe down anywhere to re-fetch from Drive
- **Analytics tab** — 4 stat cards (total, average, cash, digital), category doughnut chart, category progress bars, payment mode cards, vendor list, tag breakdown, daily line chart
- **Expenses tab** — full list with search bar and filter sheet (category, mode, tag, sort by date / amount / entry ID)
- **View only** — no add, edit, or delete anywhere in the app

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

- `credentials.json` — your Google OAuth client secret. Never commit to any repo.
- `token.json` — your saved login session. Never commit to any repo.
- `assets/service_account.json` (Flutter) — your Drive service account key. Never commit the real version.
- `data/` — your expense data. Keep off public repos — it is personal financial information.
- All three are listed in `.gitignore` and will not be pushed automatically.

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

**Termux: Drive login browser does not open**
The OAuth flow will print a URL to the terminal. Copy it manually, open it in your phone browser, complete the login, and paste the resulting code back in the terminal. Alternatively copy `token.json` from a machine that is already logged in.

**"next_id not incrementing" (entries getting duplicate IDs)**
Update to the latest `expense.py` — this was a double-save race condition bug that has been fixed.
