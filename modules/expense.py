from .storage import load_project, save_project
from collections import defaultdict
from datetime import datetime


def add_expense(slug, category, vendor, amount, mode, description,
                tags=None, date=None, notes=''):
    # Load once, bump next_id, append expense, save once.
    # Previously get_next_id() was a separate load+save which caused the
    # subsequent save_project() here to overwrite next_id back — freezing it at 12.
    proj = load_project(slug)
    nid = proj.get('next_id', 1)
    proj['next_id'] = nid + 1
    exp = {
        'id': nid,
        'category': category,
        'vendor': vendor,
        'amount': float(amount),
        'mode': mode,
        'description': description,
        'tags': tags or [],
        'date': date or datetime.today().strftime('%Y-%m-%d'),
        'notes': notes,
    }
    proj['expenses'].append(exp)
    save_project(slug, proj)
    return exp


def get_expenses(slug, filters=None):
    proj = load_project(slug)
    expenses = list(proj['expenses'])
    if not filters:
        return sorted(expenses, key=lambda x: x['date'], reverse=True)
    f = filters
    if f.get('category'):
        expenses = [e for e in expenses if e['category'] == f['category']]
    if f.get('vendor'):
        expenses = [e for e in expenses if f['vendor'].lower() in e['vendor'].lower()]
    if f.get('mode'):
        expenses = [e for e in expenses if e['mode'] == f['mode']]
    if f.get('tag'):
        expenses = [e for e in expenses if f['tag'] in e.get('tags', [])]
    if f.get('date_from'):
        expenses = [e for e in expenses if e['date'] >= f['date_from']]
    if f.get('date_to'):
        expenses = [e for e in expenses if e['date'] <= f['date_to']]
    if f.get('min_amount'):
        expenses = [e for e in expenses if e['amount'] >= float(f['min_amount'])]
    if f.get('max_amount'):
        expenses = [e for e in expenses if e['amount'] <= float(f['max_amount'])]
    if f.get('search'):
        s = f['search'].lower()
        expenses = [e for e in expenses if
                    s in e['description'].lower() or
                    s in e['vendor'].lower() or
                    s in e['category'].lower() or
                    s in e.get('notes', '').lower()]
    sort = f.get('sort', 'date_desc')
    if sort == 'date_asc':    expenses = sorted(expenses, key=lambda x: x['date'])
    elif sort == 'date_desc': expenses = sorted(expenses, key=lambda x: x['date'], reverse=True)
    elif sort == 'amount_asc':  expenses = sorted(expenses, key=lambda x: x['amount'])
    elif sort == 'amount_desc': expenses = sorted(expenses, key=lambda x: x['amount'], reverse=True)
    elif sort == 'id_asc':    expenses = sorted(expenses, key=lambda x: x['id'])
    elif sort == 'id_desc':   expenses = sorted(expenses, key=lambda x: x['id'], reverse=True)
    return expenses


def get_expense_by_id(slug, eid):
    proj = load_project(slug)
    for e in proj['expenses']:
        if e['id'] == int(eid):
            return e
    return None


def update_expense(slug, eid, **kwargs):
    proj = load_project(slug)
    for i, e in enumerate(proj['expenses']):
        if e['id'] == int(eid):
            for k, v in kwargs.items():
                if v is not None:
                    proj['expenses'][i][k] = v
            save_project(slug, proj)
            return proj['expenses'][i]
    return None


def delete_expense(slug, eid):
    proj = load_project(slug)
    before = len(proj['expenses'])
    proj['expenses'] = [e for e in proj['expenses'] if e['id'] != int(eid)]
    if len(proj['expenses']) < before:
        save_project(slug, proj)
        return True
    return False


# ── Analytics ─────────────────────────────────────────────────

def _cat_bd(exps):
    d = defaultdict(float)
    for e in exps: d[e['category']] += e['amount']
    return dict(sorted(d.items(), key=lambda x: x[1], reverse=True))

def _vendor_bd(exps):
    d = defaultdict(float)
    for e in exps: d[e['vendor']] += e['amount']
    return dict(sorted(d.items(), key=lambda x: x[1], reverse=True))

def _mode_bd(exps):
    d = defaultdict(float)
    for e in exps: d[e['mode']] += e['amount']
    return dict(d)

def _tag_bd(exps):
    d = defaultdict(float)
    for e in exps:
        for t in e.get('tags', []): d[t] += e['amount']
    return dict(sorted(d.items(), key=lambda x: x[1], reverse=True))

def _monthly(exps):
    d = defaultdict(float)
    for e in exps: d[e['date'][:7]] += e['amount']
    return dict(sorted(d.items()))

def _daily(exps):
    d = defaultdict(float)
    for e in exps: d[e['date']] += e['amount']
    return dict(sorted(d.items()))


def project_stats(slug, expenses=None):
    if expenses is None:
        expenses = get_expenses(slug)
    total = sum(e['amount'] for e in expenses)
    cash  = sum(e['amount'] for e in expenses if e['mode'] == 'Cash')
    return {
        'total': total,
        'count': len(expenses),
        'cash': cash,
        'digital': total - cash,
        'avg': total / len(expenses) if expenses else 0,
        'category_breakdown': _cat_bd(expenses),
        'vendor_breakdown':   _vendor_bd(expenses),
        'mode_breakdown':     _mode_bd(expenses),
        'tag_breakdown':      _tag_bd(expenses),
        'monthly':            _monthly(expenses),
        'daily':              _daily(expenses),
    }


def all_projects_summary(slugs_and_names):
    rows = []
    for slug, name, icon in slugs_and_names:
        try:
            exps  = get_expenses(slug)
            total = sum(e['amount'] for e in exps)
            rows.append({'slug': slug, 'name': name, 'icon': icon,
                         'total': total, 'count': len(exps)})
        except Exception:
            pass
    return rows
