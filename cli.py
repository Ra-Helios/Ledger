#!/usr/bin/env python3
"""
Ledger — Menu-driven CLI
Works on desktop and Termux (Android).
Usage: python cli.py
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from modules.storage import (load_meta, save_meta, list_projects,
                              load_project, save_project,
                              create_project, get_active_slug,
                              set_active_project, backup)
from modules.expense import (add_expense, get_expenses, get_expense_by_id,
                              update_expense, delete_expense)
from datetime import datetime

# ── Terminal helpers ──────────────────────────────────────────

def clr():
    os.system('cls' if os.name == 'nt' else 'clear')

def sep(char='─', width=48):
    print(char * width)

def header(title):
    print()
    sep('═')
    print(f'  {title}')
    sep('═')

def subheader(title):
    print()
    sep()
    print(f'  {title}')
    sep()

def pause():
    input('\n  Press Enter to continue...')

def inp(prompt, allow_blank=False):
    """Get input, strip whitespace. Loops until non-blank unless allow_blank=True."""
    while True:
        val = input(f'  {prompt}: ').strip()
        if val or allow_blank:
            return val
        print('  ✗ This field cannot be empty. Try again.')

def inp_optional(prompt):
    return input(f'  {prompt} (optional, Enter to skip): ').strip()

def choose(prompt, options, allow_back=True):
    """
    Show numbered options, return chosen value.
    options: list of (label, value) tuples
    Returns None if user picks 'b' for back.
    """
    print()
    for i, (label, _) in enumerate(options, 1):
        print(f'  {i}. {label}')
    if allow_back:
        print('  b. Back')
    print()
    while True:
        raw = input(f'  {prompt}: ').strip().lower()
        if allow_back and raw == 'b':
            return None
        try:
            idx = int(raw) - 1
            if 0 <= idx < len(options):
                return options[idx][1]
        except ValueError:
            pass
        print(f'  ✗ Enter a number 1–{len(options)}{", or b to go back" if allow_back else ""}.')

def confirm(prompt):
    """Returns True if user types y/yes."""
    raw = input(f'  {prompt} [y/N]: ').strip().lower()
    return raw in ('y', 'yes')

def fmt_amount(cur, amount):
    return f'{cur}{amount:,.2f}'

# ── Expense table ─────────────────────────────────────────────

def print_expense_table(expenses, currency):
    if not expenses:
        print('\n  No expenses found.')
        return

    # Column widths
    w_id   = 4
    w_date = 12
    w_cat  = 22
    w_desc = 28
    w_amt  = 12
    w_mode = 14

    def row(id_, date, cat, desc, amt, mode):
        id_   = str(id_)[:w_id].ljust(w_id)
        date  = str(date)[:w_date].ljust(w_date)
        cat   = str(cat)[:w_cat].ljust(w_cat)
        desc  = str(desc)[:w_desc].ljust(w_desc)
        amt   = str(amt)[:w_amt].rjust(w_amt)
        mode  = str(mode)[:w_mode].ljust(w_mode)
        return f'  {id_}  {date}  {cat}  {desc}  {amt}  {mode}'

    print()
    print(row('ID', 'Date', 'Category', 'Description', 'Amount', 'Mode'))
    sep('─', w_id + w_date + w_cat + w_desc + w_amt + w_mode + 12)

    total = 0
    for e in expenses:
        amt_str = fmt_amount(currency, e['amount'])
        print(row(e['id'], e['date'], e['category'],
                  e['description'], amt_str, e['mode']))
        total += e['amount']

    sep('─', w_id + w_date + w_cat + w_desc + w_amt + w_mode + 12)
    total_str = fmt_amount(currency, total)
    print(f'  {len(expenses)} entries  |  Total: {total_str}')

def print_expense_detail(e, currency):
    """Print all fields of a single expense."""
    print()
    sep()
    print(f'  ID          : {e["id"]}')
    print(f'  Date        : {e["date"]}')
    print(f'  Category    : {e["category"]}')
    print(f'  Vendor      : {e["vendor"]}')
    print(f'  Description : {e["description"]}')
    print(f'  Amount      : {fmt_amount(currency, e["amount"])}')
    print(f'  Mode        : {e["mode"]}')
    print(f'  Tags        : {", ".join(e.get("tags", [])) or "none"}')
    print(f'  Notes       : {e.get("notes", "") or "none"}')
    sep()

# ── Validate helpers ──────────────────────────────────────────

def inp_date(prompt, default=None):
    """Ask for a date in YYYY-MM-DD format."""
    today = datetime.today().strftime('%Y-%m-%d')
    hint  = f'(YYYY-MM-DD, Enter for {default or today})'
    while True:
        raw = input(f'  {prompt} {hint}: ').strip()
        if not raw:
            return default or today
        try:
            datetime.strptime(raw, '%Y-%m-%d')
            return raw
        except ValueError:
            print('  ✗ Invalid date. Use YYYY-MM-DD format.')

def inp_amount(prompt):
    """Ask for a positive number."""
    while True:
        raw = input(f'  {prompt}: ').strip()
        try:
            val = float(raw)
            if val > 0:
                return val
            print('  ✗ Amount must be greater than 0.')
        except ValueError:
            print('  ✗ Enter a valid number (e.g. 1500 or 299.50).')

def inp_choice_from_list(prompt, items, allow_blank=False):
    """Pick from a numbered list. Returns the chosen string."""
    print()
    for i, item in enumerate(items, 1):
        print(f'  {i}. {item}')
    print()
    while True:
        raw = input(f'  {prompt}: ').strip()
        if allow_blank and not raw:
            return None
        try:
            idx = int(raw) - 1
            if 0 <= idx < len(items):
                return items[idx]
        except ValueError:
            pass
        print(f'  ✗ Enter a number 1–{len(items)}.')

def inp_tags(available_tags):
    """Pick multiple tags by numbers."""
    if not available_tags:
        return []
    print()
    print('  Available tags:')
    for i, t in enumerate(available_tags, 1):
        print(f'    {i}. {t}')
    print()
    raw = input('  Select tags by number, comma-separated (Enter to skip): ').strip()
    if not raw:
        return []
    selected = []
    for part in raw.split(','):
        part = part.strip()
        try:
            idx = int(part) - 1
            if 0 <= idx < len(available_tags):
                selected.append(available_tags[idx])
        except ValueError:
            pass
    return selected

# ── 1. List expenses ──────────────────────────────────────────

def do_list(slug, proj, currency):
    clr()
    header(f'Expenses — {proj["icon"]} {proj["name"]}')
    expenses = get_expenses(slug, {'sort': 'date_desc'})
    print_expense_table(expenses, currency)
    pause()

# ── 2. Add expense ────────────────────────────────────────────

def do_add(slug, proj, currency):
    clr()
    header(f'Add Expense — {proj["icon"]} {proj["name"]}')
    print('  Fill in each field. Required fields cannot be left blank.\n')

    date = inp_date('Date')

    print('\n  Categories:')
    category = inp_choice_from_list('Select category number', proj['categories'])

    vendor = inp('Vendor / Payee')
    description = inp('Description')
    amount = inp_amount(f'Amount ({currency})')

    print('\n  Payment modes:')
    mode = inp_choice_from_list('Select payment mode number', proj['payment_modes'])

    tags = inp_tags(proj['tags'])
    notes = inp_optional('Notes')

    # Confirm
    print()
    sep()
    print('  Review:')
    print(f'    Date        : {date}')
    print(f'    Category    : {category}')
    print(f'    Vendor      : {vendor}')
    print(f'    Description : {description}')
    print(f'    Amount      : {fmt_amount(currency, amount)}')
    print(f'    Mode        : {mode}')
    print(f'    Tags        : {", ".join(tags) or "none"}')
    print(f'    Notes       : {notes or "none"}')
    sep()

    if confirm('Add this expense?'):
        e = add_expense(slug, category, vendor, amount, mode,
                        description, tags, date, notes)
        print(f'\n  ✓ Added as entry #{e["id"]}')
    else:
        print('\n  Cancelled.')
    pause()

# ── 3. Edit expense ───────────────────────────────────────────

def do_edit(slug, proj, currency):
    clr()
    header(f'Edit Expense — {proj["icon"]} {proj["name"]}')

    expenses = get_expenses(slug, {'sort': 'date_desc'})
    print_expense_table(expenses, currency)

    if not expenses:
        pause()
        return

    print()
    raw = input('  Enter ID to edit (b to go back): ').strip().lower()
    if raw == 'b':
        return

    try:
        eid = int(raw)
    except ValueError:
        print('  ✗ Invalid ID.')
        pause()
        return

    e = get_expense_by_id(slug, eid)
    if not e:
        print(f'  ✗ No expense with ID {eid}.')
        pause()
        return

    clr()
    header(f'Editing Entry #{eid}')
    print_expense_detail(e, currency)

    fields = [
        ('Date',        'date'),
        ('Category',    'category'),
        ('Vendor',      'vendor'),
        ('Description', 'description'),
        ('Amount',      'amount'),
        ('Payment Mode','mode'),
        ('Tags',        'tags'),
        ('Notes',       'notes'),
    ]

    while True:
        print()
        sep()
        print('  Which field to edit?')
        for i, (label, key) in enumerate(fields, 1):
            current = e.get(key, '')
            if key == 'amount':
                current = fmt_amount(currency, current)
            elif key == 'tags':
                current = ', '.join(current) if current else 'none'
            print(f'  {i}. {label:<16} current: {current}')
        print('  s. Save & exit')
        print('  b. Discard & back')
        print()

        choice = input('  Choose field number: ').strip().lower()

        if choice == 'b':
            print('\n  Changes discarded.')
            pause()
            return
        if choice == 's':
            break

        try:
            fidx = int(choice) - 1
            if not (0 <= fidx < len(fields)):
                raise ValueError
        except ValueError:
            print('  ✗ Invalid choice.')
            continue

        label, key = fields[fidx]

        if key == 'date':
            new_val = inp_date(f'New {label}', default=e['date'])
            e['date'] = new_val

        elif key == 'category':
            print(f'\n  Current: {e["category"]}')
            new_val = inp_choice_from_list('Select new category', proj['categories'])
            e['category'] = new_val

        elif key == 'mode':
            print(f'\n  Current: {e["mode"]}')
            new_val = inp_choice_from_list('Select new payment mode', proj['payment_modes'])
            e['mode'] = new_val

        elif key == 'amount':
            print(f'  Current: {fmt_amount(currency, e["amount"])}')
            new_val = inp_amount(f'New Amount ({currency})')
            e['amount'] = new_val

        elif key == 'tags':
            print(f'  Current: {", ".join(e.get("tags", [])) or "none"}')
            new_val = inp_tags(proj['tags'])
            e['tags'] = new_val

        elif key == 'notes':
            print(f'  Current: {e.get("notes", "") or "none"}')
            new_val = inp_optional('New Notes')
            e['notes'] = new_val

        else:
            print(f'  Current: {e[key]}')
            new_val = inp(f'New {label}')
            e[key] = new_val

        print(f'  ✓ {label} updated.')

    # Save
    update_expense(slug, eid,
        date=e['date'], category=e['category'], vendor=e['vendor'],
        description=e['description'], amount=e['amount'],
        mode=e['mode'], tags=e['tags'], notes=e['notes'])
    print(f'\n  ✓ Entry #{eid} saved.')
    pause()

# ── 4. Delete expense ─────────────────────────────────────────

def do_delete(slug, proj, currency):
    clr()
    header(f'Delete Expense — {proj["icon"]} {proj["name"]}')

    expenses = get_expenses(slug, {'sort': 'date_desc'})
    print_expense_table(expenses, currency)

    if not expenses:
        pause()
        return

    print()
    raw = input('  Enter ID to delete (b to go back): ').strip().lower()
    if raw == 'b':
        return

    try:
        eid = int(raw)
    except ValueError:
        print('  ✗ Invalid ID.')
        pause()
        return

    e = get_expense_by_id(slug, eid)
    if not e:
        print(f'  ✗ No expense with ID {eid}.')
        pause()
        return

    clr()
    header(f'Delete Entry #{eid}')
    print_expense_detail(e, currency)

    print(f'  You are about to permanently delete this expense.')
    print(f'  Vendor      : {e["vendor"]}')
    print(f'  Description : {e["description"]}')
    print(f'  Amount      : {fmt_amount(currency, e["amount"])}')
    print()

    if confirm('Are you sure you want to delete this? This cannot be undone'):
        delete_expense(slug, eid)
        print(f'\n  ✓ Entry #{eid} deleted.')
    else:
        print('\n  Cancelled. Nothing was deleted.')
    pause()

# ── 5. Project settings ───────────────────────────────────────

def do_project_settings(slug, proj):
    while True:
        clr()
        header(f'Project Settings — {proj["icon"]} {proj["name"]}')

        props = [
            ('Project Name',    'name'),
            ('Icon',            'icon'),
            ('Description',     'description'),
            ('Categories',      'categories'),
            ('Payment Modes',   'payment_modes'),
            ('Tags',            'tags'),
        ]

        for i, (label, key) in enumerate(props, 1):
            val = proj.get(key, '')
            if isinstance(val, list):
                val = ', '.join(val) if val else 'none'
            print(f'  {i}. {label:<18} {val}')

        print('\n  b. Back')
        print()
        choice = input('  Choose field to edit: ').strip().lower()

        if choice == 'b':
            return

        try:
            fidx = int(choice) - 1
            if not (0 <= fidx < len(props)):
                raise ValueError
        except ValueError:
            print('  ✗ Invalid choice.')
            pause()
            continue

        label, key = props[fidx]

        if key in ('name', 'icon', 'description'):
            print(f'\n  Current {label}: {proj.get(key, "")}')
            new_val = inp(f'New {label}')
            proj[key] = new_val
            save_project(slug, proj)
            # sync name/icon in meta
            if key in ('name', 'icon'):
                meta = load_meta()
                for p in meta['projects']:
                    if p['slug'] == slug:
                        p[key] = new_val
                save_meta(meta)
            print(f'  ✓ {label} updated.')
            pause()

        elif key in ('categories', 'payment_modes', 'tags'):
            _edit_list(slug, proj, key, label)

def _edit_list(slug, proj, key, label):
    """Add or delete items from a list field."""
    while True:
        clr()
        subheader(f'Edit {label}')
        items = proj.get(key, [])
        for i, item in enumerate(items, 1):
            print(f'  {i}. {item}')
        print()
        print('  a. Add new item')
        print('  d. Delete an item')
        print('  b. Back')
        print()
        choice = input('  Choice: ').strip().lower()

        if choice == 'b':
            return

        elif choice == 'a':
            new_item = inp(f'New {label[:-1] if label.endswith("s") else label}')
            if new_item in items:
                print(f'  ✗ "{new_item}" already exists.')
            else:
                proj[key].append(new_item)
                save_project(slug, proj)
                print(f'  ✓ Added: {new_item}')
            pause()

        elif choice == 'd':
            if not items:
                print('  ✗ Nothing to delete.')
                pause()
                continue
            print()
            raw = input(f'  Enter number to delete (b to cancel): ').strip().lower()
            if raw == 'b':
                continue
            try:
                idx = int(raw) - 1
                if 0 <= idx < len(items):
                    removed = items[idx]
                    if confirm(f'Delete "{removed}"?'):
                        proj[key].pop(idx)
                        save_project(slug, proj)
                        print(f'  ✓ Deleted: {removed}')
                    else:
                        print('  Cancelled.')
                else:
                    print('  ✗ Invalid number.')
            except ValueError:
                print('  ✗ Invalid input.')
            pause()

# ── 6. Drive push/pull ────────────────────────────────────────

def do_drive(slug, proj):
    clr()
    header(f'Google Drive Sync — {proj["icon"]} {proj["name"]}')

    print('  1. Push local → Drive  (save to Drive)')
    print('  2. Pull Drive → local  (fetch from Drive)')
    print('  b. Back')
    print()
    choice = input('  Choice: ').strip().lower()

    if choice == 'b':
        return

    try:
        from modules.drive_sync import (push_to_drive, pull_from_drive,
                                         force_pull_from_drive, check_credentials_exist)
    except ImportError as e:
        print(f'\n  ✗ Drive module error: {e}')
        print('  Make sure google-auth packages are installed.')
        pause()
        return

    if not check_credentials_exist():
        print('\n  ✗ credentials.json not found in project root.')
        print('  Copy your OAuth credentials file there first.')
        pause()
        return

    if choice == '1':
        print('\n  Pushing to Drive...')
        proj_data = load_project(slug)
        result = push_to_drive(slug, proj_data)

        if result['status'] == 'pushed':
            print(f'\n  ✓ {result["message"]}')

        elif result['status'] == 'diverged':
            print(f'\n  ⚠ BOTH DEVICES HAVE UNSYNCED ENTRIES')
            print(f'\n  This device only  : IDs {result["local_only_ids"]}')
            print(f'  Drive only        : IDs {result["drive_only_ids"]}')
            print(f'\n  Neither side is complete. Pushing will lose Drive-only entries.')
            print('  The safe fix is to manually merge both JSON files first.')
            print()
            if confirm('Force push anyway? Drive-only entries will be PERMANENTLY LOST'):
                from modules.drive_sync import _get_service, _get_or_create_folder, _find_file, _upload
                import json as _json
                service   = _get_service()
                folder_id = _get_or_create_folder(service)
                filename  = f'{slug}.json'
                existing  = _find_file(service, folder_id, filename)
                data_bytes = _json.dumps(proj_data, indent=2, ensure_ascii=False).encode('utf-8')
                _upload(service, folder_id, filename, data_bytes, existing)
                print('\n  ✓ Force pushed. Drive-only entries are gone.')
            else:
                print('\n  Cancelled. Nothing changed.')

        elif result['status'] == 'conflict':
            print(f'\n  ⚠ Drive has entries this device has never seen!')
            print(f'  Drive-only IDs : {result["drive_only_ids"]}')
            print(f'  Pull from Drive first to get those entries.')
            print()
            if confirm('Force push anyway? Drive-only entries will be PERMANENTLY LOST'):
                from modules.drive_sync import _get_service, _get_or_create_folder, _find_file, _upload
                import json as _json
                service   = _get_service()
                folder_id = _get_or_create_folder(service)
                filename  = f'{slug}.json'
                existing  = _find_file(service, folder_id, filename)
                data_bytes = _json.dumps(proj_data, indent=2, ensure_ascii=False).encode('utf-8')
                _upload(service, folder_id, filename, data_bytes, existing)
                print('\n  ✓ Force pushed to Drive.')
            else:
                print('\n  Cancelled.')

        else:
            print(f'\n  ✗ {result["message"]}')

    elif choice == '2':
        print('\n  Pulling from Drive...')
        result = pull_from_drive(slug)

        if result['status'] == 'pulled':
            print(f'\n  ✓ {result["message"]}')

        elif result['status'] == 'diverged':
            print(f'\n  ⚠ BOTH DEVICES HAVE UNSYNCED ENTRIES')
            print(f'\n  This device only  : IDs {result["local_only_ids"]}')
            print(f'  Drive only        : IDs {result["drive_only_ids"]}')
            print(f'\n  Neither side is complete. Pulling will lose local-only entries.')
            print('  The safe fix is to manually merge both JSON files first.')
            print()
            if confirm('Force pull anyway? Local-only entries will be PERMANENTLY LOST'):
                r2 = force_pull_from_drive(slug)
                if r2['status'] == 'pulled':
                    print(f'\n  ✓ {r2["message"]}')
                else:
                    print(f'\n  ✗ {r2["message"]}')
            else:
                print('\n  Cancelled. Local data untouched.')

        elif result['status'] == 'conflict':
            print(f'\n  ⚠ Local has entries Drive has never seen!')
            print(f'  Local-only IDs : {result["local_only_ids"]}')
            print(f'  Pulling will overwrite and lose these entries.')
            print()
            if confirm('Force pull anyway? Local-only entries will be PERMANENTLY LOST'):
                r2 = force_pull_from_drive(slug)
                if r2['status'] == 'pulled':
                    print(f'\n  ✓ {r2["message"]}')
                else:
                    print(f'\n  ✗ {r2["message"]}')
            else:
                print('\n  Cancelled. Local data untouched.')

        elif result['status'] == 'not_found':
            print(f'\n  ✗ {result["message"]}')

        else:
            print(f'\n  ✗ {result["message"]}')

    pause()

# ── Project menu ──────────────────────────────────────────────

def project_menu(slug):
    while True:
        # Always reload project in case settings changed
        proj    = load_project(slug)
        meta    = load_meta()
        currency = proj.get('currency') or meta.get('currency', '₹')

        clr()
        header(f'{proj["icon"]}  {proj["name"]}')
        if proj.get('description'):
            print(f'  {proj["description"]}')
        print()
        print('  1. List expenses')
        print('  2. Add expense')
        print('  3. Edit expense')
        print('  4. Delete expense')
        print('  5. Project settings')
        print('  6. Drive sync')
        print('  b. Back to project list')
        print('  x. Exit')
        print()

        choice = input('  Choice: ').strip().lower()

        if choice == '1':
            do_list(slug, proj, currency)
        elif choice == '2':
            do_add(slug, proj, currency)
        elif choice == '3':
            do_edit(slug, proj, currency)
        elif choice == '4':
            do_delete(slug, proj, currency)
        elif choice == '5':
            do_project_settings(slug, proj)
        elif choice == '6':
            do_drive(slug, proj)
        elif choice == 'b':
            return
        elif choice == 'x':
            clr()
            print('\n  Goodbye! 👋\n')
            sys.exit(0)

# ── Main — project selector ───────────────────────────────────

def main():
    while True:
        clr()
        sep('═')
        print('  📒  LEDGER')
        sep('═')
        print()

        projects = list_projects()

        if not projects:
            print('  No projects found.')
            print('  Run the web app (python app.py) to create a project first.')
            print()
            input('  Press Enter to exit...')
            sys.exit(0)

        print('  Select a project:\n')
        for i, p in enumerate(projects, 1):
            # Load project to show entry count
            try:
                proj_data = load_project(p['slug'])
                count = len(proj_data.get('expenses', []))
                meta  = load_meta()
                cur   = proj_data.get('currency') or meta.get('currency', '₹')
                total = sum(e['amount'] for e in proj_data.get('expenses', []))
                print(f'  {i}. {p["icon"]}  {p["name"]:<24} {count} entries  {cur}{total:,.0f}')
            except Exception:
                print(f'  {i}. {p["icon"]}  {p["name"]}')

        print('\n  x. Exit')
        print()
        choice = input('  Choice: ').strip().lower()

        if choice == 'x':
            clr()
            print('\n  Goodbye! 👋\n')
            sys.exit(0)

        try:
            idx = int(choice) - 1
            if 0 <= idx < len(projects):
                slug = projects[idx]['slug']
                set_active_project(slug)
                project_menu(slug)
            else:
                print('  ✗ Invalid choice.')
                pause()
        except ValueError:
            print('  ✗ Enter a number or x.')
            pause()


if __name__ == '__main__':
    main()
