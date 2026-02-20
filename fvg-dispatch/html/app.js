const Dispatch = (() => {
    let alerts     = {};
    let alertTypes = {};
    let priorities = [];
    let templates  = {};
    let activeFilter = 'all';
    let searchQuery  = '';
    let prioFilter   = 'all';

    const prioColors = { 1:'#22c55e', 2:'#f59e0b', 3:'#f97316', 4:'#ef4444' };
    const prioLabels = { 1:'Alacsony', 2:'Közepes', 3:'Magas', 4:'Kritikus' };

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'open') {
            alertTypes = e.data.alertTypes || {};
            priorities = e.data.priorities || [];
            templates  = e.data.templates  || {};
            alerts     = {};
            (e.data.alerts || []).forEach(a => { alerts[a.id] = a; });
            buildFilterBar();
            buildNewAlertForm();
            renderList();
            document.getElementById('overlay').classList.remove('hidden');
        }
        if (action === 'addAlert') {
            alerts[e.data.alert.id] = e.data.alert;
            renderList();
        }
        if (action === 'updateAlert') {
            alerts[e.data.alert.id] = e.data.alert;
            renderList();
            // Ha részlet modal nyitva, frissítjük
            if (!document.getElementById('detail-modal').classList.contains('hidden')) {
                const titleEl = document.getElementById('dm-title');
                if (titleEl && titleEl.dataset.id === e.data.alert.id) {
                    openDetail(e.data.alert.id);
                }
            }
        }
        if (action === 'closeAlert') {
            if (alerts[e.data.id]) { alerts[e.data.id].closed = true; }
            renderList();
        }
    });

    // ── Szűrő sáv ────────────────────────────────────────────
    function buildFilterBar() {
        const cont = document.getElementById('filter-types');
        cont.innerHTML = `
            <button class="ftype-btn active" data-type="all">
                <i class="hgi-stroke hgi-grid-view"></i>Összes
            </button>`;

        Object.entries(alertTypes).forEach(([key, def]) => {
            const btn = document.createElement('button');
            btn.className   = 'ftype-btn';
            btn.dataset.type = key;
            btn.style.setProperty('--tc', def.color);
            btn.innerHTML = `<i class="${def.icon}"></i>${def.label}`;
            cont.appendChild(btn);
        });

        cont.querySelectorAll('.ftype-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                activeFilter = btn.dataset.type;
                cont.querySelectorAll('.ftype-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                renderList();
            });
        });
    }

    // ── Keresés és szűrő ─────────────────────────────────────
    document.getElementById('search-input').addEventListener('input', (e) => {
        searchQuery = e.target.value.toLowerCase();
        renderList();
    });
    document.getElementById('prio-filter').addEventListener('change', (e) => {
        prioFilter = e.target.value;
        renderList();
    });

    // ── Lista renderelés ─────────────────────────────────────
    function renderList() {
        const list  = document.getElementById('alerts-list');
        const empty = document.getElementById('empty-state');

        const filtered = Object.values(alerts).filter(a => {
            if (a.closed) return false;
            if (activeFilter !== 'all' && a.type !== activeFilter) return false;
            if (prioFilter   !== 'all' && String(a.priority) !== prioFilter) return false;
            if (searchQuery) {
                const haystack = (a.id + a.title + a.message + a.street + a.callerName).toLowerCase();
                if (!haystack.includes(searchQuery)) return false;
            }
            return true;
        });

        // Rendezés: priority desc
        filtered.sort((a, b) => b.priority - a.priority);

        // Aktív count frissítés
        const totalActive = Object.values(alerts).filter(a => !a.closed).length;
        document.getElementById('active-count').textContent = totalActive;

        // Üres állapot
        if (filtered.length === 0) {
            empty.classList.remove('hidden');
            list.querySelectorAll('.alert-card').forEach(c => c.remove());
            return;
        }
        empty.classList.add('hidden');

        // Meglévő kártyák szinkronizálása
        const existing = new Set([...list.querySelectorAll('.alert-card')].map(c => c.dataset.id));
        const wanted   = new Set(filtered.map(a => a.id));

        // Törölteket kidobjuk
        existing.forEach(id => {
            if (!wanted.has(id)) list.querySelector(`[data-id="${id}"]`)?.remove();
        });

        // Hozzáadjuk / frissítjük
        filtered.forEach((alert, idx) => {
            let card = list.querySelector(`[data-id="${alert.id}"]`);
            if (!card) {
                card = buildAlertCard(alert);
                list.appendChild(card);
            } else {
                // Frissítés
                const newCard = buildAlertCard(alert);
                list.replaceChild(newCard, card);
            }
        });
    }

    function buildAlertCard(alert) {
        const typeDef  = alertTypes[alert.type] || {};
        const prioColor= prioColors[alert.priority] || '#38bdf8';
        const prioLabel= prioLabels[alert.priority] || '';

        const el = document.createElement('div');
        el.className    = `alert-card prio-${alert.priority}`;
        el.dataset.id   = alert.id;
        el.innerHTML = `
            <div class="ac-main">
                <div class="ac-icon" style="background:${typeDef.color || '#38bdf8'}18;border:1px solid ${typeDef.color || '#38bdf8'}30">
                    <i class="${alert.icon || typeDef.icon || 'hgi-stroke hgi-radio-02'}" style="color:${typeDef.color || '#38bdf8'}"></i>
                </div>
                <div class="ac-info">
                    <div class="ac-top">
                        <span class="ac-id">${alert.id}</span>
                        <span class="ac-prio-badge" style="background:${prioColor}18;color:${prioColor};border:1px solid ${prioColor}33">${prioLabel}</span>
                        <span class="ac-time">${alert.createdAt || ''}</span>
                    </div>
                    <div class="ac-title">${alert.title}</div>
                    <div class="ac-msg">${alert.message || ''}</div>
                </div>
            </div>
            <div class="ac-footer">
                <div class="ac-location">
                    <i class="hgi-stroke hgi-location-04"></i>
                    ${alert.street || 'Ismeretlen helyszín'}
                </div>
                <div class="ac-units">
                    <i class="hgi-stroke hgi-user-group"></i>
                    ${(alert.units || []).length} egység
                </div>
            </div>
        `;
        el.addEventListener('click', () => openDetail(alert.id));
        return el;
    }

    // ── Új riasztás form ─────────────────────────────────────
    function buildNewAlertForm() {
        const typeSelect = document.getElementById('na-type');
        typeSelect.innerHTML = '';
        Object.entries(alertTypes).forEach(([key, def]) => {
            const opt = document.createElement('option');
            opt.value = key;
            opt.textContent = def.label;
            typeSelect.appendChild(opt);
        });

        const tplSelect = document.getElementById('na-template');
        tplSelect.innerHTML = '<option value="">– Nincs sablon –</option>';
        Object.entries(templates).forEach(([key, tpl]) => {
            const opt = document.createElement('option');
            opt.value = key;
            opt.textContent = tpl.title;
            tplSelect.appendChild(opt);
        });

        // Sablon autokitöltés
        tplSelect.addEventListener('change', () => {
            const tpl = templates[tplSelect.value];
            if (tpl) {
                document.getElementById('na-title').value   = tpl.title || '';
                document.getElementById('na-priority').value= tpl.priority || 2;
                document.getElementById('na-type').value    = tpl.type || 'police';
            }
        });

        document.getElementById('na-submit').addEventListener('click', submitNewAlert);
    }

    function submitNewAlert() {
        const type    = document.getElementById('na-type').value;
        const prio    = document.getElementById('na-priority').value;
        const tpl     = document.getElementById('na-template').value;
        const title   = document.getElementById('na-title').value.trim();
        const message = document.getElementById('na-message').value.trim();

        if (!title) return;

        fetch(`https://fvg-dispatch/createAlert`, {
            method: 'POST',
            body: JSON.stringify({ type, priority: parseInt(prio), title, message, template: tpl || null })
        });
        closeModal();
        // Input reset
        document.getElementById('na-title').value   = '';
        document.getElementById('na-message').value = '';
        document.getElementById('na-template').value= '';
    }

    // ── Riasztás részlet modal ────────────────────────────────
    function openDetail(alertId) {
        const alert   = alerts[alertId];
        if (!alert) return;
        const typeDef = alertTypes[alert.type] || {};

        document.getElementById('dm-icon').className  = (alert.icon || typeDef.icon || 'hgi-stroke hgi-radio-02');
        document.getElementById('dm-icon').style.color= typeDef.color || '#38bdf8';
        const titleEl = document.getElementById('dm-title');
        titleEl.textContent = alert.title;
        titleEl.dataset.id  = alertId;

        const body = document.getElementById('dm-body');
        const prioColor = prioColors[alert.priority] || '#38bdf8';

        body.innerHTML = `
            <div class="detail-section">
                <div class="detail-title">Riasztás adatai</div>
                <div class="detail-row"><span class="detail-key">Azonosító</span>   <span class="detail-val">${alert.id}</span></div>
                <div class="detail-row"><span class="detail-key">Típus</span>       <span class="detail-val" style="color:${typeDef.color}">${typeDef.label || alert.type}</span></div>
                <div class="detail-row"><span class="detail-key">Prioritás</span>   <span class="detail-val" style="color:${prioColor}">${prioLabels[alert.priority]} (${alert.priority})</span></div>
                <div class="detail-row"><span class="detail-key">Helyszín</span>    <span class="detail-val">${alert.street || '–'}</span></div>
                <div class="detail-row"><span class="detail-key">Bejelentő</span>   <span class="detail-val">${alert.callerName || '–'}</span></div>
                <div class="detail-row"><span class="detail-key">Időpont</span>     <span class="detail-val">${alert.createdAt || '–'}</span></div>
                ${alert.message ? `<div class="detail-row"><span class="detail-key">Leírás</span><span class="detail-val">${alert.message}</span></div>` : ''}
            </div>
            <div class="detail-section">
                <div class="detail-title">Csatolt egységek (${(alert.units || []).length})</div>
                <div class="units-list">
                    ${(alert.units || []).length === 0
                        ? `<div style="font-size:12px;color:var(--text-m);padding:6px 0">Még nincs csatolt egység</div>`
                        : (alert.units || []).map(u => `
                            <div class="unit-item">
                                <i class="${typeDef.icon || 'hgi-stroke hgi-user-circle'}"></i>
                                <span>${u.name}</span>
                                <span style="font-size:10px;color:var(--text-m);margin-left:auto">${u.job || ''}</span>
                            </div>`).join('')
                    }
                </div>
            </div>
        `;

        const footer = document.getElementById('dm-footer');
        footer.innerHTML = '';

        // Navigáció
        if (alert.coords) {
            const navBtn = document.createElement('button');
            navBtn.className = 'dm-action-btn dab-nav';
            navBtn.innerHTML = `<i class="hgi-stroke hgi-location-04"></i>Navigáció`;
            navBtn.addEventListener('click', () => {
                fetch(`https://fvg-dispatch/waypointAlert`, {
                    method: 'POST', body: JSON.stringify({ coords: alert.coords })
                });
                closeDetail();
            });
            footer.appendChild(navBtn);
        }

        // Csatlakozás
        const attachBtn = document.createElement('button');
        attachBtn.className = 'dm-action-btn dab-attach';
        attachBtn.innerHTML = `<i class="hgi-stroke hgi-user-add-01"></i>Csatlakozás`;
        attachBtn.addEventListener('click', () => {
            fetch(`https://fvg-dispatch/attachUnit`, {
                method: 'POST', body: JSON.stringify({ id: alertId })
            });
            closeDetail();
        });
        footer.appendChild(attachBtn);

        // Lezárás
        const closeBtn = document.createElement('button');
        closeBtn.className = 'dm-action-btn dab-close';
        closeBtn.innerHTML = `<i class="hgi-stroke hgi-checkmark-circle-02"></i>Lezárás`;
        closeBtn.addEventListener('click', () => {
            fetch(`https://fvg-dispatch/closeAlert`, {
                method: 'POST', body: JSON.stringify({ id: alertId })
            });
            closeDetail();
        });
        footer.appendChild(closeBtn);

        document.getElementById('detail-modal').classList.remove('hidden');
    }

    function closeDetail() {
        document.getElementById('detail-modal').classList.add('hidden');
    }

    // ── Modál kezelés ────────────────────────────────────────
    document.getElementById('new-alert-btn').addEventListener('click', () => {
        document.getElementById('new-alert-modal').classList.remove('hidden');
    });

    function closeModal() {
        document.getElementById('new-alert-modal').classList.add('hidden');
    }

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', close);

    function close() {
        document.getElementById('overlay').classList.add('hidden');
        document.getElementById('new-alert-modal').classList.add('hidden');
        document.getElementById('detail-modal').classList.add('hidden');
        fetch(`https://fvg-dispatch/close`, { method: 'POST', body: JSON.stringify({}) });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (!document.getElementById('detail-modal').classList.contains('hidden')) { closeDetail(); return; }
            if (!document.getElementById('new-alert-modal').classList.contains('hidden')) { closeModal(); return; }
            close();
        }
    });

    return { closeModal, closeDetail };
})();