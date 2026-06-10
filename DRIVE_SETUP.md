# Google Drive Sync — First Time Setup Guide

This guide walks a brand new user through connecting Ledger to their personal Google Drive from scratch. No prior Google Cloud experience needed.

---

## What this does

When set up, the **Save to Drive** and **Fetch from Drive** buttons in Project Settings will push and pull your project's JSON file directly to your personal Google Drive under a folder called `LedgerJsons`. This lets you keep data in sync across multiple machines using the same Google account.

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

This tells Google what your app is when users log in.

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

## Step 4 — Create OAuth credentials

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

## Step 5 — First login

1. Start the web app: `python app.py`
2. Open `http://localhost:5050` in your browser
3. Open any project → go to **Project Settings** (⚙ in the sidebar)
4. Scroll to the **Google Drive Sync** section
5. Click **Save to Drive**
6. A browser tab opens automatically showing "Sign in with Google"
7. Choose your Google account
8. Click **Allow** on the permissions screen
9. The browser may show a blank page or say "connection refused" — that is normal, the login was captured
10. Go back to the Ledger app — it should show a success message

A `token.json` file is automatically saved in your project folder. This stores your login session so you never need to log in again on this machine.

---

## Step 6 — Verify it worked

1. Go to https://drive.google.com
2. You should see a folder called `LedgerJsons`
3. Inside it, a file named `<your_project_slug>.json` (e.g. `home_renovation.json`)

That file is your project's full data. It will be replaced each time you Save to Drive.

---

## Step 7 — Setting up on a second machine

On any other machine where you want to use Ledger with the same data:

1. Clone or copy the repo to that machine
2. Copy `credentials.json` to the project root on that machine (same file — you only create it once)
3. Either:
   - Click **Fetch from Drive** in Project Settings → a browser login opens once → done
   - Or copy `token.json` from the first machine to skip the browser login entirely

---

## How conflict detection works

Every expense entry has a unique integer ID that never gets reused. When you sync, the app compares the exact set of entry IDs present on each side to determine what is safe to do.

| Situation | What happens |
|---|---|
| Local has entries Drive has never seen, Drive has nothing new | **Safe to push** — local is a superset |
| Drive has entries local has never seen, local has nothing new | **Blocked** — pull first to get those entries |
| Local has entries Drive has not seen AND Drive has entries local has not seen | **Diverge warning** — both sides have unsynced data, manual merge required |
| Both sides are identical | **Safe to push** — nothing changes |

### The diverge case — what it means and how it happens

A diverge happens when you add entries on one device and forget to push, then add entries on another device and push from there. Now both devices have entries the other has never seen.

Example:
```
Both devices start at IDs [1–14] — in sync.

Laptop A: adds entries 15, 16, 17 — does NOT push.
Laptop B: adds entries 15, 16 (same counter, different data!) — pushes to Drive.

Now:
  Local (Laptop A) has IDs: 1–14, 15, 16, 17
  Drive (Laptop B) has IDs: 1–14, 15, 16

  local_only = [17]       ← Laptop A's entry, Drive never saw it
  drive_only = [15, 16]   ← Laptop B's entries, Laptop A never saw them
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

The diverge case never happens if you follow this habit:

```
Before starting work on any device:
  → Project Settings → Fetch from Drive  (get latest)

After finishing work:
  → Project Settings → Save to Drive  (push your changes)
```

---

## File reference

| File | What it is | In repo? |
|---|---|---|
| `credentials.json` | OAuth client secret from Google Cloud | ❌ Never commit |
| `token.json` | Saved login session, auto-created | ❌ Never commit |
| `data/projects/*.json` | Your actual expense data | ❌ Never commit |

---

## Troubleshooting

**"Access blocked" when logging in**
You have not added your Gmail as a test user. Go to Google Cloud Console → OAuth consent screen (or Google Auth Platform → Audience) → Test users → Add your email.

**"credentials.json not found"**
The file must be in the project root folder (same folder as `app.py`), not in any subfolder.

**"The app has been blocked" or "Error 403: access_denied"**
Same as above — add your email to test users.

**token.json auth error after a long time**
Tokens expire occasionally. Delete `token.json` and click Save/Fetch from Drive to log in again. Takes 30 seconds.

**Drive folder not visible in Google Drive**
It is created automatically on first Save to Drive. If you have not pushed yet, the folder will not exist.

**Diverge warning appears unexpectedly**
This means you added entries on two devices without syncing in between. The app shows you the exact IDs on each side. Do not force push or force pull unless you are okay losing one side's entries. Follow the manual merge steps above to combine both safely.
