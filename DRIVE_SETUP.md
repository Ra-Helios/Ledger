# Google Drive Sync — First Time Setup Guide

This guide walks a brand new user through connecting Ledger to their personal Google Drive from scratch. No prior Google Cloud experience needed.

---

## What this does

The web app and Flutter mobile app both connect to your personal Google Drive to keep your project data in sync across devices.

**Web app behaviour:**
- Automatically pulls all projects from Drive once when the server starts (`python app.py`)
- Automatically pushes to Drive after every add, edit, delete, or project settings change
- Manual **Save to Drive** and **Fetch from Drive** buttons in Project Settings for on-demand sync

**Flutter app behaviour:**
- Automatically fetches all projects from Drive when the app opens
- Automatically pushes to Drive after every add, edit, delete, or settings change
- Manual refresh button and pull-to-refresh for on-demand fetch

All of this uses your own Google Drive account — no external server, no subscriptions.

---

## Step 1 — Create a Google Cloud project

1. Go to https://console.cloud.google.com/
2. Sign in with your personal Google account (the same one whose Drive you want to use)
3. At the very top, click the project dropdown (it may say "Select a project" or show a previous project name)
4. Click **New Project** in the popup
5. Give it any name — e.g. `ledger-backup`
6. Click **Create**
7. Wait a few seconds, then make sure this new project is selected in the top dropdown

---

## Step 2 — Enable the Google Drive API

1. In the left sidebar, click **APIs & Services → Library**
2. In the search box, type `Google Drive API`
3. Click the result named **Google Drive API**
4. Click the blue **Enable** button
5. Wait for it to enable — you will be redirected to the API overview page

---

## Step 3 — Set up the OAuth consent screen

This tells Google what your app is when users log in. This is only needed for the web app — the Flutter app uses a service account instead.

1. In the left sidebar, click **APIs & Services → OAuth consent screen**
   (On newer Google Cloud UI this may appear as **Google Auth Platform**)
2. If asked for user type, select **External** → click **Create**
3. Fill in the required fields:
   - **App name**: `Ledger` (or whatever you like)
   - **User support email**: your Gmail address
   - **Developer contact email**: your Gmail address
4. Leave everything else blank
5. Click **Save and Continue**
6. On the **Scopes** page, click **Save and Continue** without adding anything
7. On the **Test users** page:
   - Click **+ Add Users**
   - Type your Gmail address and press Enter
   - Click **Add**
   - Click **Save and Continue**
8. On the Summary page, click **Back to Dashboard**

> **Why test users?** Google puts new OAuth apps in "Testing" mode. Only Gmail addresses you explicitly add here can log in. You must add your own email or you will get an "Access blocked" error when trying to connect.

---

## Step 4 — Create OAuth credentials (web app)

1. In the left sidebar, click **APIs & Services → Credentials**
   (or **Google Auth Platform → Clients**)
2. At the top, click **+ Create Credentials → OAuth 2.0 Client ID**
3. For **Application type**, choose **Desktop app**
4. Give it any name — e.g. `LedgerDesktop`
5. Click **Create**
6. A popup appears — click **Download JSON**
7. A file downloads with a long name like `client_secret_....json`
8. Rename this file to exactly: `credentials.json`
9. Place `credentials.json` in your Ledger project root folder — the same folder that contains `app.py`

---

## Step 5 — Create a service account (Flutter app)

The Flutter app uses a service account instead of OAuth. A service account is a bot credential — no login screen ever appears on the phone.

1. In the left sidebar, click **IAM & Admin → Service Accounts**
2. Click **+ Create Service Account**
3. Name it anything — e.g. `ledger-mobile-viewer`
4. Click **Create and Continue** → skip the optional role fields → **Done**
5. Click on the created service account in the list
6. Go to the **Keys** tab → **Add Key → Create new key → JSON**
7. A JSON key file downloads — this is your service account key

**Then share your Drive folder with it:**
1. Find the `client_email` field in the downloaded key file — it looks like:
   `ledger-mobile-viewer@ledger-backup.iam.gserviceaccount.com`
2. Go to https://drive.google.com
3. Find the `LedgerJsons` folder (created automatically on first web app sync)
4. Right-click → **Share**
5. Paste the service account email → set permission to **Editor** → **Share**

> **Editor permission is required** — the Flutter app now supports adding, editing, and deleting expenses, so it needs write access.

Place the downloaded key file as `assets/service_account.json` inside the `ledger_viewer` Flutter project folder.

---

## Step 6 — First login (web app)

1. Start the web app: `python app.py`
2. Open `http://localhost:5050` in your browser
3. The app will attempt to pull from Drive automatically on startup
4. If this is your first time, open any project → go to **Project Settings** (⚙ in the sidebar)
5. Scroll to the **Google Drive Sync** section
6. Click **Save to Drive**
7. A browser tab opens automatically showing "Sign in with Google"
8. Choose your Google account
9. Click **Allow** on the permissions screen
10. The browser may show a blank page or say "connection refused" — that is normal, the login was captured
11. Go back to the Ledger app — it should show a success message

A `token.json` file is automatically saved in your project folder. This stores your login session so you never need to log in again on this machine. From this point on, every add/edit/delete automatically pushes to Drive in the background.

---

## Step 7 — Verify it worked

1. Go to https://drive.google.com
2. You should see a folder called `LedgerJsons`
3. Inside it, a file named `<your_project_slug>.json` (e.g. `home_renovation.json`)

That file is your project's full data. It is replaced automatically every time you make a change.

---

## Step 8 — Setting up on a second machine

On any other machine where you want to use Ledger with the same data:

1. Clone or copy the repo to that machine
2. Copy `credentials.json` to the project root on that machine (same file — you only create it once)
3. Start the web app — it will auto-pull from Drive on startup
4. Either:
   - Let it auto-pull on startup (happens automatically)
   - Or click **Fetch from Drive** in Project Settings if you want to force a pull
   - Or copy `token.json` from the first machine to skip the browser login entirely

---

## How auto-sync works

**Web app auto-pull on startup:**
The very first page request after `python app.py` starts triggers a background pull of all projects from Drive. This is silent — no message is shown. If Drive is unavailable or credentials are missing, local data is used normally.

**Web app auto-push after writes:**
Every time you add, edit, or delete an expense, or save project settings, the updated project JSON is automatically pushed to Drive in the background. This happens after the local save, so your data is always safe locally even if the push fails.

**Flutter app auto-fetch on open:**
When the app opens, it immediately fetches all projects from Drive. A loading state is shown while fetching. The last-fetched time is shown in the top bar.

**Flutter app auto-push after writes:**
Every save (add/edit/delete expense, settings change) pushes to Drive automatically. A small spinner appears in the title bar while pushing. Push failures are silent — local state is always up to date.

---

## How conflict detection works

Every expense entry has a unique integer ID that never gets reused. When you manually sync, the app compares the exact set of entry IDs present on each side to determine what is safe to do.

> **Note:** With auto-sync enabled on both web app and Flutter, conflicts are much less likely because both devices push after every change. Conflicts can still occur if you work offline on two devices simultaneously.

| Situation | What happens |
|---|---|
| Local has entries Drive has never seen, Drive has nothing new | **Safe to push** — local is a superset |
| Drive has entries local has never seen, local has nothing new | **Blocked** — pull first to get those entries |
| Local has entries Drive has not seen AND Drive has entries local has not seen | **Diverge warning** — both sides have unsynced data, manual merge required |
| Both sides are identical | **Safe to push** — nothing changes |

### The diverge case — what it means and how it happens

A diverge happens when you work offline on two devices simultaneously without syncing. Both devices add entries independently, and now neither side is a complete copy.

Example:
```
Both devices start at IDs [1–14] — in sync.

Laptop A: goes offline, adds entries 15, 16, 17.
Phone:    also offline, adds entries 15, 16 (same counter, different data!).
Laptop A: comes back online, tries to push.

Now:
  Local (Laptop A) has IDs: 1–14, 15, 16, 17
  Drive (from Phone) has IDs: 1–14, 15, 16

  local_only = [17]       ← Laptop A's entry, Drive never saw it
  drive_only = [15, 16]   ← Phone's entries, Laptop A never saw them
```

Neither side is a complete copy. The app detects this, shows you exactly which IDs are missing on each side, and refuses to silently overwrite either copy.

**How to resolve a diverge:**
1. Open `data/projects/<slug>.json` on the local machine
2. Download `LedgerJsons/<slug>.json` from Google Drive
3. Open both files in a text editor
4. Copy the missing expense entries from each file into one combined file
5. Set `next_id` to the highest ID across both files plus 1
6. Save it locally, then Save to Drive

---

## Normal daily workflow

With auto-sync enabled, the workflow is largely automatic:

```
Web app:
  → Start python app.py  (auto-pulls from Drive on first request)
  → Add/edit/delete expenses  (auto-pushes after each change)
  → Close when done

Flutter app:
  → Open app  (auto-fetches from Drive)
  → Add/edit/delete expenses  (auto-pushes after each change)
  → Close when done
```

If you work on both devices at the same time while offline, use manual sync to resolve any conflicts when back online.

---

## File reference

| File | What it is | In repo? |
|---|---|---|
| `credentials.json` | OAuth client secret for web app Drive sync | ❌ Never commit |
| `token.json` | Saved login session for web app, auto-created | ❌ Never commit |
| `ledger_viewer/assets/service_account.json` | Service account key for Flutter app | ❌ Never commit |
| `data/projects/*.json` | Your actual expense data | ❌ Never commit |

---

## Troubleshooting

**"Access blocked" when logging in (web app)**
You have not added your Gmail as a test user. Go to Google Cloud Console → OAuth consent screen (or Google Auth Platform → Audience) → Test users → Add your email.

**"credentials.json not found"**
The file must be in the project root folder (same folder as `app.py`), not in any subfolder.

**"The app has been blocked" or "Error 403: access_denied"**
Same as above — add your email to test users.

**token.json auth error after a long time**
Tokens expire occasionally. Delete `token.json` and click Save/Fetch from Drive to log in again. Takes 30 seconds.

**Drive folder not visible in Google Drive**
It is created automatically on first push. Start the web app, add any expense, and the folder will appear.

**Flutter app cannot write to Drive**
Make sure the service account has **Editor** permission on the `LedgerJsons` folder, not just Viewer. Right-click the folder in Drive → Share → find the service account email → change to Editor.

**Diverge warning appears**
This means two devices added entries without syncing in between. The app shows the exact IDs on each side. Do not force push or pull unless you are okay losing one side's entries. Follow the manual merge steps above.

**Auto-push spinner keeps showing (Flutter)**
This is normal during a push — it disappears when done. If it stays permanently, check your internet connection and that the service account still has Editor access to the Drive folder.
