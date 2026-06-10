"""
drive_sync.py — Google Drive sync for Ledger project JSONs.

Flow:
  - credentials.json  → your OAuth client secret (one-time setup)
  - token.json        → auto-saved after first login (never share this)

Folder on Drive: "LedgerJsons"  (created automatically if missing)
File on Drive:   "<slug>.json"  (one file per project, always replaced)

Conflict logic (based on next_id, which only ever increases):
  local next_id > drive next_id  → local is ahead  → safe to push
  drive next_id > local next_id  → drive is ahead  → pull first
  equal                          → local wins      → push (working machine)
  both diverged (neither is subset) → show conflict info, user decides
"""

import os
import json
import io
from datetime import datetime

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload, MediaIoBaseDownload
from googleapiclient.errors import HttpError

SCOPES = ['https://www.googleapis.com/auth/drive.file']

BASE         = os.path.dirname(__file__)
CREDS_FILE   = os.path.join(BASE, '..', 'credentials.json')
TOKEN_FILE   = os.path.join(BASE, '..', 'token.json')
DRIVE_FOLDER = 'LedgerJsons'


# ── Auth ──────────────────────────────────────────────────────

def _get_service():
    """Authenticate and return a Drive service object."""
    creds = None

    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except Exception:
                # Token expired/revoked — redo the flow
                creds = None

        if not creds:
            if not os.path.exists(CREDS_FILE):
                raise FileNotFoundError(
                    "credentials.json not found. "
                    "Place your Google OAuth client secret file at: " + CREDS_FILE
                )
            flow = InstalledAppFlow.from_client_secrets_file(CREDS_FILE, SCOPES)
            # Opens browser on first run; localhost redirect catches the token
            creds = flow.run_local_server(port=0, open_browser=True)

        with open(TOKEN_FILE, 'w') as f:
            f.write(creds.to_json())

    return build('drive', 'v3', credentials=creds)


# ── Drive folder helpers ──────────────────────────────────────

def _get_or_create_folder(service):
    """Return the folder ID of LedgerJsons, creating it if needed."""
    q = (f"name='{DRIVE_FOLDER}' "
         f"and mimeType='application/vnd.google-apps.folder' "
         f"and trashed=false")
    results = service.files().list(q=q, fields='files(id, name)').execute()
    files = results.get('files', [])

    if files:
        return files[0]['id']

    # Create it
    meta = {
        'name': DRIVE_FOLDER,
        'mimeType': 'application/vnd.google-apps.folder'
    }
    folder = service.files().create(body=meta, fields='id').execute()
    return folder['id']


def _find_file(service, folder_id, filename):
    """Return file ID if filename exists in folder, else None."""
    q = (f"name='{filename}' "
         f"and '{folder_id}' in parents "
         f"and trashed=false")
    results = service.files().list(q=q, fields='files(id, name)').execute()
    files = results.get('files', [])
    return files[0]['id'] if files else None


# ── Core operations ───────────────────────────────────────────

def _upload(service, folder_id, filename, data_bytes, existing_file_id=None):
    """Upload or update a file on Drive. Returns file ID."""
    media = MediaIoBaseUpload(
        io.BytesIO(data_bytes),
        mimetype='application/json',
        resumable=False
    )
    if existing_file_id:
        # Update existing file in place (no new file created)
        file = service.files().update(
            fileId=existing_file_id,
            media_body=media,
            fields='id'
        ).execute()
        return file['id']
    else:
        meta = {'name': filename, 'parents': [folder_id]}
        file = service.files().create(
            body=meta,
            media_body=media,
            fields='id'
        ).execute()
        return file['id']


def _download_json(service, file_id):
    """Download a Drive file and return parsed JSON dict."""
    request = service.files().get_media(fileId=file_id)
    buf = io.BytesIO()
    downloader = MediaIoBaseDownload(buf, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    buf.seek(0)
    raw = buf.read()
    # Force utf-8 — emoji characters in project names/icons cause charmap
    # errors on Windows if we let Python pick the default system encoding
    return json.loads(raw.decode('utf-8'))


# ── Public API ────────────────────────────────────────────────

def check_credentials_exist():
    return os.path.exists(CREDS_FILE)


def is_authenticated():
    """Quick check — is there a valid token already?"""
    if not os.path.exists(TOKEN_FILE):
        return False
    try:
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
        if creds.valid:
            return True
        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            return creds.valid
    except Exception:
        pass
    return False


def _detect_diverge(local_data, drive_data):
    """
    Detect if both sides have entries the other does not — a true diverge.
    Returns a dict with full details for the conflict UI.
    """
    local_ids  = {e['id'] for e in local_data.get('expenses', [])}
    drive_ids  = {e['id'] for e in drive_data.get('expenses', [])}
    local_only = sorted(local_ids - drive_ids)
    drive_only = sorted(drive_ids - local_ids)
    return {
        'diverged':       bool(local_only) and bool(drive_only),
        'local_only_ids': local_only,
        'drive_only_ids': drive_only,
        'local_next_id':  local_data.get('next_id', 1),
        'drive_next_id':  drive_data.get('next_id', 1),
        'local_count':    len(local_data.get('expenses', [])),
        'drive_count':    len(drive_data.get('expenses', [])),
    }


def push_to_drive(slug, local_proj_data):
    """
    Push local project JSON to Drive.
    Now detects true diverge (both sides have unsynced entries) and refuses
    to silently overwrite — the old next_id-only check missed this case.

    Returns dict:
      status: 'pushed' | 'conflict' | 'diverged' | 'error'
    """
    try:
        service     = _get_service()
        folder_id   = _get_or_create_folder(service)
        filename    = f'{slug}.json'
        existing_id = _find_file(service, folder_id, filename)

        local_nid = local_proj_data.get('next_id', 1)

        if existing_id:
            drive_data = _download_json(service, existing_id)
            diff = _detect_diverge(local_proj_data, drive_data)

            if diff['diverged']:
                # Both sides have entries the other never saw — cannot safely push
                return {
                    'status': 'diverged',
                    'message': (
                        f'Both devices have unsynced entries. '
                        f'Local has {len(diff["local_only_ids"])} entries Drive never saw '
                        f'(IDs: {diff["local_only_ids"]}). '
                        f'Drive has {len(diff["drive_only_ids"])} entries local never saw '
                        f'(IDs: {diff["drive_only_ids"]}). '
                        f'Pushing now will permanently lose the Drive-only entries.'
                    ),
                    **diff,
                }

            if diff['drive_only_ids'] and not diff['local_only_ids']:
                # Drive has entries local has never seen — this machine just needs to pull first
                return {
                    'status': 'conflict',
                    'message': (
                        f'Drive has {len(diff["drive_only_ids"])} entries this device has never seen '
                        f'(IDs: {diff["drive_only_ids"]}). Fetch from Drive first.'
                    ),
                    **diff,
                }

            # local is superset or equal — safe to push

        data_bytes = json.dumps(local_proj_data, indent=2, ensure_ascii=False).encode('utf-8')
        _upload(service, folder_id, filename, data_bytes, existing_id)

        return {
            'status': 'pushed',
            'message': f'Pushed to Drive → LedgerJsons/{filename} (next_id={local_nid})',
        }

    except FileNotFoundError as e:
        return {'status': 'error', 'message': str(e)}
    except HttpError as e:
        return {'status': 'error', 'message': f'Drive API error: {e}'}
    except Exception as e:
        return {'status': 'error', 'message': f'Unexpected error: {e}'}

def pull_from_drive(slug):
    """
    Pull project JSON from Drive.
    Now uses ID-set comparison instead of next_id-only to detect diverge.

    Returns dict:
      status: 'pulled' | 'conflict' | 'diverged' | 'not_found' | 'error'
    """
    from .storage import load_project, project_path, save_project
    import os as _os

    try:
        service     = _get_service()
        folder_id   = _get_or_create_folder(service)
        filename    = f'{slug}.json'
        existing_id = _find_file(service, folder_id, filename)

        if not existing_id:
            return {
                'status': 'not_found',
                'message': f'No backup found on Drive for project "{slug}".',
            }

        drive_data = _download_json(service, existing_id)
        drive_count = len(drive_data.get('expenses', []))

        proj_file = project_path(slug)
        if not _os.path.exists(proj_file):
            # No local file at all — safe to pull straight away
            save_project(slug, drive_data)
            return {
                'status': 'pulled',
                'message': f'Pulled from Drive → {drive_count} entries (new local project)',
                'data': drive_data,
            }

        with open(proj_file, encoding='utf-8') as f:
            local_data = json.load(f)

        diff = _detect_diverge(local_data, drive_data)

        if diff['diverged']:
            # Both sides have entries the other never saw
            return {
                'status': 'diverged',
                'message': (
                    f'Both devices have unsynced entries. '
                    f'Local has {len(diff["local_only_ids"])} entries Drive never saw '
                    f'(IDs: {diff["local_only_ids"]}). '
                    f'Drive has {len(diff["drive_only_ids"])} entries local never saw '
                    f'(IDs: {diff["drive_only_ids"]}). '
                    f'Pulling now will permanently lose the local-only entries.'
                ),
                'data': drive_data,
                **diff,
            }

        if diff['local_only_ids'] and not diff['drive_only_ids']:
            # Local has entries Drive has never seen — pulling would lose them
            return {
                'status': 'conflict',
                'message': (
                    f'Local has {len(diff["local_only_ids"])} entries Drive has never seen '
                    f'(IDs: {diff["local_only_ids"]}). '
                    f'Pulling will overwrite and lose these entries.'
                ),
                'data': drive_data,
                **diff,
            }

        # Drive is superset or equal — safe to pull
        save_project(slug, drive_data)
        return {
            'status': 'pulled',
            'message': f'Pulled from Drive → {drive_count} entries, next_id={diff["drive_next_id"]}',
            'data': drive_data,
        }

    except FileNotFoundError as e:
        return {'status': 'error', 'message': str(e)}
    except HttpError as e:
        return {'status': 'error', 'message': f'Drive API error: {e}'}
    except Exception as e:
        return {'status': 'error', 'message': f'Unexpected error: {e}'}


def force_pull_from_drive(slug):
    """Pull from Drive unconditionally — used after user confirms conflict override."""
    from .storage import save_project
    try:
        service     = _get_service()
        folder_id   = _get_or_create_folder(service)
        existing_id = _find_file(service, folder_id, f'{slug}.json')

        if not existing_id:
            return {'status': 'not_found', 'message': 'No backup on Drive.'}

        drive_data = _download_json(service, existing_id)
        save_project(slug, drive_data)
        return {
            'status': 'pulled',
            'message': f'Force-pulled from Drive → {len(drive_data.get("expenses",[]))} entries',
        }
    except Exception as e:
        return {'status': 'error', 'message': str(e)}


def list_drive_backups():
    """List all .json files in LedgerJsons folder on Drive."""
    try:
        service   = _get_service()
        folder_id = _get_or_create_folder(service)
        q = f"'{folder_id}' in parents and trashed=false and mimeType='application/json'"
        results = service.files().list(
            q=q,
            fields='files(id, name, modifiedTime, size)',
            orderBy='modifiedTime desc'
        ).execute()
        return {'status': 'ok', 'files': results.get('files', [])}
    except Exception as e:
        return {'status': 'error', 'message': str(e), 'files': []}
