"""
storage.py — Multi-project persistence layer.

Layout:
  data/
    meta.json              ← global app settings + project index
    projects/
      <slug>.json          ← per-project expenses + project config
    backups/               ← timestamped zips
"""
import json, os, shutil, re
from datetime import datetime

BASE   = os.path.dirname(__file__)
DATA   = os.path.join(BASE, '..', 'data')
PROJ   = os.path.join(DATA, 'projects')
BACKUP = os.path.join(DATA, 'backups')
META   = os.path.join(DATA, 'meta.json')

DEFAULT_META = {
    "app_name": "Ledger",
    "currency": "₹",
    "active_project": None,
    "projects": []           # list of {slug, name, icon, created}
}

DEFAULT_PROJECT = {
    "name": "",
    "icon": "📁",
    "description": "",
    "created": "",
    "currency": None,        # inherits global if None
    "categories": [],
    "payment_modes": ["Cash", "Gpay", "Bank Transfer", "UPI", "Cheque"],
    "tags": ["materials", "labour", "advance", "food", "transport", "miscellaneous"],
    "next_id": 1,
    "expenses": []
}

CONSTRUCTION_SEED = {
    "name": "Home Renovation",
    "icon": "🏗",
    "description": "House renovation expenses",
    "categories": [
        "Demolishing", "Carpenter Works", "Painting Works",
        "Drainage Works", "Electrical & Plumbing Works",
        "Cement & Sand", "Tiling Works", "Miscellaneous"
    ],
    "expenses": [
        {"id":1,"category":"Demolishing","vendor":"Ashok Engg.","amount":25000,"mode":"Gpay","description":"Demolishing work","tags":["labour"],"date":"2026-05-28","notes":""},
        {"id":2,"category":"Carpenter Works","vendor":"Kumar Carpenter","amount":3720,"mode":"Cash","description":"Carpenter materials","tags":["materials"],"date":"2026-05-28","notes":""},
        {"id":3,"category":"Carpenter Works","vendor":"Kumar Carpenter","amount":4000,"mode":"Cash","description":"Carpenter labour wage","tags":["labour"],"date":"2026-05-28","notes":""},
        {"id":4,"category":"Painting Works","vendor":"Anba Painter","amount":10000,"mode":"Cash","description":"Painter Advance Payment 1","tags":["advance"],"date":"2026-05-28","notes":""},
        {"id":5,"category":"Painting Works","vendor":"Anba Painter","amount":10000,"mode":"Cash","description":"Painter Advance Payment 2","tags":["advance"],"date":"2026-05-30","notes":""},
        {"id":6,"category":"Drainage Works","vendor":"Municipal Corporation Labour","amount":6000,"mode":"Cash","description":"Drainage cleansing","tags":["labour"],"date":"2026-05-28","notes":""},
        {"id":7,"category":"Electrical & Plumbing Works","vendor":"Guna Shakaran","amount":4699,"mode":"Gpay","description":"E&P materials 1","tags":["materials"],"date":"2026-05-28","notes":""},
        {"id":8,"category":"Electrical & Plumbing Works","vendor":"Guna Shakaran","amount":725,"mode":"Cash","description":"E&P material 2","tags":["materials"],"date":"2026-05-29","notes":""},
        {"id":9,"category":"Electrical & Plumbing Works","vendor":"Guna Shakaran","amount":7275,"mode":"Cash","description":"E&P labour wage","tags":["labour"],"date":"2026-05-29","notes":""},
        {"id":10,"category":"Cement & Sand","vendor":"Ashok Engg.","amount":1900,"mode":"Cash","description":"Cement & Sand materials","tags":["materials"],"date":"2026-05-29","notes":""},
        {"id":11,"category":"Cement & Sand","vendor":"Ashok Engg.","amount":1900,"mode":"Cash","description":"Cement & Sand labour wage","tags":["labour"],"date":"2026-05-29","notes":""},
    ],
    "next_id": 12
}


def slugify(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')


def _ensure():
    os.makedirs(PROJ, exist_ok=True)
    os.makedirs(BACKUP, exist_ok=True)
    if not os.path.exists(META):
        _write_json(META, DEFAULT_META)
        # seed Home Renovation project
        create_project(
            CONSTRUCTION_SEED['name'],
            CONSTRUCTION_SEED['icon'],
            CONSTRUCTION_SEED['description'],
            CONSTRUCTION_SEED['categories'],
            seed_expenses=CONSTRUCTION_SEED['expenses'],
            seed_next_id=CONSTRUCTION_SEED['next_id']
        )


def _read_json(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)

def _write_json(path, data):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


# ── Meta (global) ─────────────────────────────────────────────

def load_meta():
    _ensure()
    return _read_json(META)

def save_meta(meta):
    _write_json(META, meta)


# ── Project CRUD ──────────────────────────────────────────────

def list_projects():
    meta = load_meta()
    return meta['projects']

def project_path(slug):
    return os.path.join(PROJ, f'{slug}.json')

def load_project(slug):
    return _read_json(project_path(slug))

def save_project(slug, data):
    _write_json(project_path(slug), data)

def create_project(name, icon='📁', description='', categories=None, payment_modes=None,
                   tags=None, seed_expenses=None, seed_next_id=1):
    meta = load_meta()
    slug = slugify(name)
    # make unique slug
    existing = {p['slug'] for p in meta['projects']}
    base, i = slug, 2
    while slug in existing:
        slug = f'{base}_{i}'; i += 1

    proj = dict(DEFAULT_PROJECT)
    proj.update({
        'name': name, 'icon': icon, 'description': description,
        'created': datetime.now().strftime('%Y-%m-%d'),
        'categories': categories or [],
        'next_id': seed_next_id,
        'expenses': seed_expenses or [],
    })
    if payment_modes: proj['payment_modes'] = payment_modes
    if tags:          proj['tags'] = tags
    _write_json(project_path(slug), proj)

    meta['projects'].append({'slug': slug, 'name': name, 'icon': icon, 'created': proj['created']})
    if meta['active_project'] is None:
        meta['active_project'] = slug
    save_meta(meta)
    return slug

def delete_project(slug):
    meta = load_meta()
    meta['projects'] = [p for p in meta['projects'] if p['slug'] != slug]
    if meta['active_project'] == slug:
        meta['active_project'] = meta['projects'][0]['slug'] if meta['projects'] else None
    save_meta(meta)
    path = project_path(slug)
    if os.path.exists(path):
        os.remove(path)

def get_active_slug():
    meta = load_meta()
    return meta.get('active_project')

def set_active_project(slug):
    meta = load_meta()
    meta['active_project'] = slug
    save_meta(meta)


# ── Next ID ───────────────────────────────────────────────────

def get_next_id(slug):
    proj = load_project(slug)
    nid = proj.get('next_id', 1)
    proj['next_id'] = nid + 1
    save_project(slug, proj)
    return nid


# ── Backup ────────────────────────────────────────────────────

def backup():
    import zipfile
    ts = datetime.now().strftime('%Y%m%d_%H%M%S')
    zpath = os.path.join(BACKUP, f'ledger_backup_{ts}.zip')
    with zipfile.ZipFile(zpath, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.write(META, 'meta.json')
        for fname in os.listdir(PROJ):
            if fname.endswith('.json'):
                zf.write(os.path.join(PROJ, fname), f'projects/{fname}')
    return ts
