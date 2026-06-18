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
- Signs in with your own Google account once, then silently stays signed in
- Automatically fetches all projects from Drive when the app opens
- Automatically pushes to Drive after every add, edit, delete, or settings change
- Manual refresh button and pull-to-refresh for on-demand fetch

All of this uses your own Google Drive account — no external server, no subscriptions, no key files to manage on the Flutter side.

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

This tells Google what your app is when users log in. This is needed for **both** the web app and the Flutter app.

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

> **Why test users?** Google puts new OAuth apps in "Testing" mode. Only Gmail addresses you explicitly add here can log in, on either the web app or the Flutter app. You must add your own email or you will get an "Access blocked" error when trying to connect. If you later share the Flutter APK with friends, add their Gmail addresses here too — see the bottom of this guide.

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

## Step 5 — Create OAuth credentials (Flutter app)

The Flutter app uses **Google Sign-In** — the same kind of "Sign in with Google" button you see in most Android apps. No file is downloaded or placed anywhere; the app is registered against your package name and signing certificate instead.

**Get your debug keystore's SHA-1 fingerprint:**

Windows:
```bash
keytool -list -v -keystore "C:\Users\<you>\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Linux / macOS:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line starting with `SHA1:` and copy the full value, including all the colons.

**Create the Android OAuth client:**

1. Still in **APIs & Services → Credentials** (or **Google Auth Platform → Clients**)
2. **+ Create Credentials → OAuth 2.0 Client ID**
3. Application type: **Android**
4. Name: anything, e.g. `LedgerAndroid`
5. Package name: `com.adhithya.ledger_viewer` (must exactly match `applicationId` in `ledger_viewer/android/app/build.gradle`)
6. SHA-1 certificate fingerprint: paste what you copied above
7. Click **Create**
8. There's a **Download JSON** button on the confirmation popup — you can ignore it, nothing needs to be downloaded for Android sign-in to work. Just click **OK**

That's it. The Flutter app automatically detects this client at sign-in time using your app's package name and signing certificate — there is no client ID or key file to copy anywhere in the project.

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

## Step 7 — First login (Flutter app)

1. Build and install the app on your phone (see README.md Part 3 for build steps)
2. Open the app — a **Sign in with Google** screen appears
3. Tap it, choose your Google account from the native picker, allow access
4. You're redirected straight to the home screen, and your projects load automatically

Every time you reopen the app after this, it signs in silently in the background — no popup, no friction.

> **If sign-in fails with "ApiException: 10"** — this means the SHA-1 or package name doesn't match what's registered on Cloud Console. Re-check Step 5 above carefully; this is almost always a copy-paste mismatch.

> **If sign-in fails with "Access blocked"** — your Gmail isn't on the test users list from Step 3. Add it there.

---

## Step 8 — Verify it worked

1. Go to https://drive.google.com
2. You should see a folder called `LedgerJsons`
3. Inside it, a file named `<your_project_slug>.json` (e.g. `home_renovation.json`)

That file is your project's full data. It is replaced automatically every time you make a change, from either the web app or the Flutter app.

---

## Step 9 — Setting up on a second machine

On any other machine where you want to use Ledger with the same data:

**Web app:**
1. Clone or copy the repo to that machine
2. Copy `credentials.json` to the project root on that machine (same file — you only create it once)
3. Start the web app — it will auto-pull from Drive on startup
4. Either let it auto-pull, click **Fetch from Drive** to force it, or copy `token.json` from the first machine to skip the browser login

**Flutter app (a different phone, still you):**
1. Build the APK the same way and install it
2. Sign in with the same Google account
3. Your projects appear automatically

---

## Sharing the Flutter app with friends or family

The Android OAuth client you created in Step 5 is bound to your app's package name and signing certificate — not to a specific Google account. This means:

1. Add each friend's Gmail address under **OAuth consent screen → Test users** (Step 3 above)
2. Share the same APK file with them
3. They install it and sign in with their **own** Google account
4. Their data goes into a `LedgerJsons` folder on **their own** Drive — fully separate from yours

The free testing tier supports up to 100 test users, which is plenty for sharing with friends and family. If you ever want anyone to be able to install and sign in without being explicitly added, that requires Google's app verification process, which is unnecessary overhead for personal or friend-group use.

---

## How auto-sync works

**Web app auto-pull on startup:**
The very first page request after `python app.py` starts triggers a background pull of all projects from Drive. This is silent — no message is shown. If Drive is unavailable or credentials are missing, local data is used normally.

**Web app auto-push after writes:**
Every time you add, edit, or delete an expense, or save project settings, the updated project JSON is automatically pushed to Drive in the background. This happens after the local save, so your data is always safe locally even if the push fails.

**Flutter app auto-fetch on open:**
When the app opens, it signs in silently (if previously signed in) and immediately fetches all projects from Drive. A loading state is shown while fetching. The last-fetched time is shown in the top bar.

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
  → Open app  (silent sign-in, auto-fetches from Drive)
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
| `data/projects/*.json` | Your actual expense data | ❌ Never commit |

The Flutter app uses no key files at all — its Android OAuth client ID is a public identifier safe to leave visible in source code, since security comes from the SHA-1 + package name binding on Google Cloud Console rather than secrecy of the ID itself.

---

## Troubleshooting

**"Access blocked" when logging in (web app or Flutter app)**
You have not added your Gmail as a test user. Go to Google Cloud Console → OAuth consent screen (or Google Auth Platform → Audience) → Test users → Add your email.

**"credentials.json not found"**
The file must be in the project root folder (same folder as `app.py`), not in any subfolder.

**"The app has been blocked" or "Error 403: access_denied"**
Same as above — add your email to test users.

**token.json auth error after a long time**
Tokens expire occasionally. Delete `token.json` and click Save/Fetch from Drive to log in again. Takes 30 seconds.

**Drive folder not visible in Google Drive**
It is created automatically on first push. Start the web app, add any expense, and the folder will appear.

**Flutter: PlatformException(sign_in_failed, ApiException: 10)**
The SHA-1 fingerprint or package name registered on Google Cloud Console doesn't match this build. Re-verify Step 5 above — package name must match `applicationId` in `build.gradle` exactly, and the SHA-1 must be copied without typos or missing characters.

**Flutter: sign-in works for me but not for a friend I shared the APK with**
Their Gmail address needs to be added to the test users list (Step 3), not just yours.

**Flutter: emulator sign-in fails but real device works**
Some Android emulator images don't include Google Play Store, only "Google APIs". Create a new emulator using a system image that explicitly includes Play Store, visible as a Play Store icon next to the device name in Android Studio's Device Manager.

**Diverge warning appears**
This means two devices added entries without syncing in between. The app shows the exact IDs on each side. Do not force push or pull unless you are okay losing one side's entries. Follow the manual merge steps above.

**Auto-push spinner keeps showing (Flutter)**
This is normal during a push — it disappears when done. If it stays permanently, check your internet connection and that you are still signed in (try the sign-out and sign-in again from the home screen menu).
