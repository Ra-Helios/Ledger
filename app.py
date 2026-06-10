from flask import (Flask, render_template, request, redirect,
                   url_for, jsonify, send_file, flash, session, g)
from modules.expense import (add_expense, get_expenses, get_expense_by_id,
                              update_expense, delete_expense,
                              project_stats, all_projects_summary)
from modules.storage import (load_meta, save_meta, load_project, save_project,
                              list_projects, create_project, delete_project,
                              get_active_slug, set_active_project, backup)
from modules.exporter import export_project
import os

app = Flask(__name__)
app.secret_key = 'multi-ledger-2026-secret'


# ── Context helpers ───────────────────────────────────────────

@app.before_request
def load_globals():
    g.meta      = load_meta()
    g.projects  = list_projects()
    slug = session.get('active_project') or g.meta.get('active_project')
    if slug and any(p['slug'] == slug for p in g.projects):
        g.active_slug = slug
    elif g.projects:
        g.active_slug = g.projects[0]['slug']
    else:
        g.active_slug = None
    g.active_proj = load_project(g.active_slug) if g.active_slug else None


def cur():
    if g.active_proj and g.active_proj.get('currency'):
        return g.active_proj['currency']
    return g.meta.get('currency', '₹')


# ── Home ──────────────────────────────────────────────────────

@app.route('/')
def home():
    summary = all_projects_summary(
        [(p['slug'], p['name'], p['icon']) for p in g.projects]
    )
    grand_total = sum(r['total'] for r in summary)
    return render_template('home.html', summary=summary, grand_total=grand_total)


# ── Switch project ────────────────────────────────────────────

@app.route('/switch/<slug>')
def switch(slug):
    if any(p['slug'] == slug for p in g.projects):
        session['active_project'] = slug
        set_active_project(slug)
    return redirect(request.referrer or url_for('dashboard'))


# ── Dashboard ─────────────────────────────────────────────────

@app.route('/dashboard')
def dashboard():
    if not g.active_slug:
        return redirect(url_for('new_project'))
    stats = project_stats(g.active_slug)
    return render_template('dashboard.html', stats=stats, proj=g.active_proj,
                           slug=g.active_slug, currency=cur())


# ── Expenses List ─────────────────────────────────────────────

@app.route('/expenses')
def expenses():
    if not g.active_slug:
        return redirect(url_for('new_project'))
    filters = {k: request.args.get(k, '') for k in
               ['category','vendor','mode','tag','date_from','date_to',
                'min_amount','max_amount','search','sort']}
    active = {k: v for k, v in filters.items() if v}
    exps  = get_expenses(g.active_slug, active if active else None)
    total = sum(e['amount'] for e in exps)
    return render_template('expenses.html', expenses=exps, proj=g.active_proj,
                           slug=g.active_slug, filters=filters, total=total,
                           currency=cur())


# ── Add Expense ───────────────────────────────────────────────

@app.route('/add', methods=['GET','POST'])
def add():
    if not g.active_slug:
        return redirect(url_for('new_project'))
    if request.method == 'POST':
        add_expense(
            g.active_slug,
            category=request.form['category'],
            vendor=request.form['vendor'],
            amount=request.form['amount'],
            mode=request.form['mode'],
            description=request.form['description'],
            tags=request.form.getlist('tags'),
            date=request.form['date'],
            notes=request.form.get('notes',''),
        )
        flash('Expense added!', 'success')
        return redirect(url_for('expenses'))
    return render_template('add_expense.html', proj=g.active_proj,
                           slug=g.active_slug, expense=None, edit_mode=False,
                           currency=cur())


# ── Edit Expense ──────────────────────────────────────────────

@app.route('/edit/<int:eid>', methods=['GET','POST'])
def edit(eid):
    if not g.active_slug:
        return redirect(url_for('home'))
    exp = get_expense_by_id(g.active_slug, eid)
    if not exp:
        flash('Expense not found.', 'error')
        return redirect(url_for('expenses'))
    if request.method == 'POST':
        update_expense(g.active_slug, eid,
                       category=request.form['category'],
                       vendor=request.form['vendor'],
                       amount=float(request.form['amount']),
                       mode=request.form['mode'],
                       description=request.form['description'],
                       tags=request.form.getlist('tags'),
                       date=request.form['date'],
                       notes=request.form.get('notes',''))
        flash('Expense updated!', 'success')
        return redirect(url_for('expenses'))
    return render_template('add_expense.html', proj=g.active_proj,
                           slug=g.active_slug, expense=exp, edit_mode=True,
                           currency=cur())


# ── Delete Expense ────────────────────────────────────────────

@app.route('/delete/<int:eid>', methods=['POST'])
def delete(eid):
    if g.active_slug:
        delete_expense(g.active_slug, eid)
        flash('Expense deleted.', 'success')
    return redirect(url_for('expenses'))


# ── Analytics ─────────────────────────────────────────────────

@app.route('/analytics')
def analytics():
    if not g.active_slug:
        return redirect(url_for('new_project'))
    stats = project_stats(g.active_slug)
    return render_template('analytics.html', stats=stats, proj=g.active_proj,
                           slug=g.active_slug, currency=cur())


# ── New Project ───────────────────────────────────────────────

@app.route('/projects/new', methods=['GET','POST'])
def new_project():
    if request.method == 'POST':
        name = request.form['name'].strip()
        if not name:
            flash('Project name required.', 'error')
            return redirect(url_for('new_project'))
        cats = [c.strip() for c in request.form.get('categories','').split('\n') if c.strip()]
        slug = create_project(
            name=name,
            icon=request.form.get('icon','📁'),
            description=request.form.get('description',''),
            categories=cats,
        )
        session['active_project'] = slug
        flash(f'Project "{name}" created!', 'success')
        return redirect(url_for('dashboard'))
    return render_template('new_project.html')


# ── Project Settings ──────────────────────────────────────────

@app.route('/projects/settings', methods=['GET','POST'])
def project_settings():
    if not g.active_slug:
        return redirect(url_for('new_project'))
    if request.method == 'POST':
        proj = load_project(g.active_slug)
        proj['name']        = request.form['name'].strip() or proj['name']
        proj['icon']        = request.form.get('icon', proj['icon'])
        proj['description'] = request.form.get('description','')
        proj['currency']    = request.form.get('currency','') or None
        for field in ['categories','payment_modes','tags']:
            raw = request.form.get(field,'')
            items = [x.strip() for x in raw.split('\n') if x.strip()]
            if items:
                proj[field] = items
        save_project(g.active_slug, proj)
        meta = load_meta()
        for p in meta['projects']:
            if p['slug'] == g.active_slug:
                p['name'] = proj['name']
                p['icon'] = proj['icon']
        save_meta(meta)
        flash('Project settings saved!', 'success')
        return redirect(url_for('dashboard'))
    return render_template('project_settings.html', proj=g.active_proj,
                           slug=g.active_slug, currency=cur())


# ── Delete Project ────────────────────────────────────────────

@app.route('/projects/delete/<slug>', methods=['POST'])
def remove_project(slug):
    proj = load_project(slug)
    delete_project(slug)
    session.pop('active_project', None)
    flash(f'Project "{proj["name"]}" deleted.', 'success')
    return redirect(url_for('home'))


# ── Export Excel ──────────────────────────────────────────────

@app.route('/export')
def export():
    if not g.active_slug:
        return redirect(url_for('home'))
    try:
        path = export_project(g.active_slug)
        return send_file(path, as_attachment=True,
                         download_name=os.path.basename(path),
                         mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    except Exception as e:
        flash(f'Export failed: {e}', 'error')
        return redirect(url_for('dashboard'))


# ── Local Backup ──────────────────────────────────────────────

@app.route('/backup', methods=['POST'])
def do_backup():
    ts = backup()
    flash(f'Local backup created — {ts}', 'success')
    return redirect(request.referrer or url_for('home'))


# ── Drive: Push ───────────────────────────────────────────────

@app.route('/drive/push', methods=['POST'])
def drive_push():
    if not g.active_slug:
        flash('No active project.', 'error')
        return redirect(url_for('home'))
    try:
        from modules.drive_sync import push_to_drive
        proj_data = load_project(g.active_slug)
        result    = push_to_drive(g.active_slug, proj_data)

        if result['status'] == 'pushed':
            flash(f'✓ Saved to Google Drive — {result["message"]}', 'success')
            return redirect(request.referrer or url_for('project_settings'))

        elif result['status'] in ('conflict', 'diverged'):
            session['drive_conflict'] = result
            flash('⚠ Drive conflict detected — see below.', 'error')
            return redirect(url_for('project_settings'))

        else:
            flash(f'Drive error: {result["message"]}', 'error')
            return redirect(url_for('project_settings'))

    except Exception as e:
        flash(f'Drive push failed: {e}', 'error')
        return redirect(url_for('project_settings'))


# ── Drive: Pull ───────────────────────────────────────────────

@app.route('/drive/pull', methods=['POST'])
def drive_pull():
    if not g.active_slug:
        flash('No active project.', 'error')
        return redirect(url_for('home'))
    try:
        from modules.drive_sync import pull_from_drive
        result = pull_from_drive(g.active_slug)

        if result['status'] == 'pulled':
            flash(f'✓ Pulled from Google Drive — {result["message"]}', 'success')
            return redirect(url_for('dashboard'))

        elif result['status'] in ('conflict', 'diverged'):
            session['drive_conflict'] = result
            flash('⚠ Drive conflict detected — see below.', 'error')
            return redirect(url_for('project_settings'))

        elif result['status'] == 'not_found':
            flash('No backup found on Drive for this project.', 'error')
            return redirect(url_for('project_settings'))

        else:
            flash(f'Drive error: {result["message"]}', 'error')
            return redirect(url_for('project_settings'))

    except Exception as e:
        flash(f'Drive pull failed: {e}', 'error')
        return redirect(url_for('project_settings'))


# ── Drive: Force pull (user confirmed conflict override) ──────

@app.route('/drive/force_pull', methods=['POST'])
def drive_force_pull():
    if not g.active_slug:
        return redirect(url_for('home'))
    try:
        from modules.drive_sync import force_pull_from_drive
        result = force_pull_from_drive(g.active_slug)
        session.pop('drive_conflict', None)
        if result['status'] == 'pulled':
            flash(f'✓ Force-pulled from Drive — {result["message"]}', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash(f'Drive error: {result["message"]}', 'error')
            return redirect(url_for('project_settings'))
    except Exception as e:
        flash(f'Force pull failed: {e}', 'error')
        return redirect(url_for('project_settings'))


# ── Drive: Dismiss conflict ───────────────────────────────────

@app.route('/drive/dismiss_conflict', methods=['POST'])
def drive_dismiss_conflict():
    session.pop('drive_conflict', None)
    return redirect(url_for('project_settings'))


# ── Drive: Auth status (AJAX) ─────────────────────────────────

@app.route('/api/drive/status')
def drive_status():
    try:
        from modules.drive_sync import is_authenticated, check_credentials_exist
        return jsonify({
            'has_credentials': check_credentials_exist(),
            'authenticated':   is_authenticated(),
        })
    except Exception as e:
        return jsonify({'has_credentials': False, 'authenticated': False, 'error': str(e)})


# ── JSON API ──────────────────────────────────────────────────

@app.route('/api/projects')
def api_projects():
    return jsonify(g.projects)

@app.route('/api/expenses')
def api_expenses():
    if not g.active_slug: return jsonify([])
    return jsonify(get_expenses(g.active_slug))

@app.route('/api/stats')
def api_stats():
    if not g.active_slug: return jsonify({})
    return jsonify(project_stats(g.active_slug))


if __name__ == '__main__':
    app.run(debug=True, port=5050)
