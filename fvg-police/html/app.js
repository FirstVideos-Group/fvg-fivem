'use strict';

// ═══════════════════════════════════════════════════════════════
//  STATE
// ═══════════════════════════════════════════════════════════════
const State = {
    open:          false,
    officer:       null,
    modules:       [],
    activeModule:  null,
    stationId:     null,
    onDuty:        false,
    units:         [],
    mdtResults:    [],
    fines:         [],
    fineTypes:     [],
    prisonTime:    null,
};

// ═══════════════════════════════════════════════════════════════
//  NUI
// ═══════════════════════════════════════════════════════════════
function nuiFetch(event, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${event}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data),
    });
}

function GetParentResourceName() {
    return 'fvg-police';
}

// ═══════════════════════════════════════════════════════════════
//  MESSAGE HANDLER
// ═══════════════════════════════════════════════════════════════
window.addEventListener('message', ({ data }) => {
    const { action, payload } = data;
    switch (action) {
        case 'open':             Police.open(payload);             break;
        case 'dutyChanged':      Police.updateDuty(data.duty);    break;
        case 'rankUpdate':       Police.onRankUpdate(data.data);  break;
        case 'unitsUpdated':     Police.onUnitsUpdated(data.units); break;
        case 'unitJoined':       Police.onUnitJoined(data.unit);  break;
        case 'unitDisbanded':    Police.onUnitDisbanded();        break;
        case 'mdtResults':       Police.onMDTResults(data.results); break;
        case 'finesResult':      Police.onFinesResult(data.fines); break;
        case 'fineIssued':       Police.onFineIssued(data.data);  break;
        case 'instalmentPaid':   break;
        case 'prisonStarted':    Prison.start(data.timeLeft, data.reason); break;
        case 'prisonTick':       Prison.tick(data.timeLeft);      break;
        case 'prisonEnded':      Prison.end();                    break;
        case 'csStarted':        Prison.csStart(data.task, data.label); break;
        case 'csStopped':        Prison.csStop();                 break;
    }
});

// ═══════════════════════════════════════════════════════════════
//  POLICE NAMESPACE
// ═══════════════════════════════════════════════════════════════
const Police = {

    // ── Megnyitás ─────────────────────────────────────────────
    open(payload) {
        State.open       = true;
        State.officer    = payload.officer;
        State.modules    = payload.modules;
        State.stationId  = payload.stationId;
        State.onDuty     = payload.officer.duty;
        State.fineTypes  = window._fineTypes || [];

        // Fejléc
        $('#ph-title').textContent = 'LSPD';
        $('#ph-sub').textContent   = payload.stationId
            ? payload.stationId.replace(/_/g, ' ').toUpperCase()
            : 'Mission Row PD';

        // Tiszt adatok
        const o = payload.officer;
        $('#oc-name').textContent = (o.firstname || '') + ' ' + (o.lastname || '');
        $('#oc-rank').textContent = o.rankLabel || 'Újonc';

        // Duty sáv
        this.updateDuty(o.duty);
        $('#stat-online').textContent = (payload.onDuty || 0) + ' rendőr aktív';

        if (o.unit) {
            $('#unit-stat').style.display = 'flex';
            $('#stat-unit').textContent   = 'Egység: ' + o.unit;
        }

        // Modul navigáció (automatikus)
        this.buildModuleNav(payload.modules);

        // Panel megjelenítés
        $('#overlay').classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    },

    // ── Modul navigáció generálás ─────────────────────────────
    buildModuleNav(modules) {
        const nav = $('#module-nav');
        nav.innerHTML = '';

        // Meghatározott sorrend
        const order = ['garage','unit','clothing','storage','weapons','mdt','fines','prison'];
        const sorted = [...modules].sort((a, b) => {
            const ia = order.indexOf(a.id);
            const ib = order.indexOf(b.id);
            return (ia === -1 ? 99 : ia) - (ib === -1 ? 99 : ib);
        });

        sorted.forEach(mod => {
            const btn = document.createElement('button');
            btn.className = 'mod-btn' + (mod.allowed === false ? ' disabled' : '');
            btn.dataset.module = mod.id;
            btn.innerHTML = `
                <i class="${mod.icon}"></i>
                <span class="mod-btn-label">${mod.label}</span>
            `;
            if (mod.allowed !== false) {
                btn.addEventListener('click', () => Police.openModule(mod.id));
            }
            nav.appendChild(btn);
        });
    },

    // ── Modul megnyitás ───────────────────────────────────────
    openModule(id) {
        if (!State.onDuty && id !== 'clothing') {
            // Duty nélkül csak ruházat érhető el
            showNotif('Lépj szolgálatba a funkciók használatához.', 'warning');
            return;
        }
        State.activeModule = id;

        // Nav aktív
        document.querySelectorAll('.mod-btn').forEach(b => {
            b.classList.toggle('active', b.dataset.module === id);
        });

        // Tartalom
        const content = $('#module-content');
        $('#welcome-screen') && ($('#welcome-screen').remove());

        const renders = {
            garage:   () => Police.renderGarage(),
            unit:     () => Police.renderUnit(),
            clothing: () => Police.renderClothing(),
            storage:  () => Police.renderStorage(),
            weapons:  () => Police.renderWeapons(),
            mdt:      () => Police.renderMDT(),
            fines:    () => Police.renderFines(),
            prison:   () => Police.renderPrison(),
        };

        content.innerHTML = renders[id] ? renders[id]() : '<div class="empty-state"><i class="hgi-stroke hgi-puzzle-01"></i><span>Modul betöltési hiba.</span></div>';
        this.bindModuleEvents(id);
    },

    // ── GARÁZS ────────────────────────────────────────────────
    renderGarage() {
        const o     = State.officer;
        const rank  = window._ranks && window._ranks.find(r => r.grade === o.grade);
        const allowedClasses = rank ? rank.vehicle_classes : [];
        const vehicles = window._vehicles || [];
        const classLabels = window._classLabels || {};

        const grouped = {};
        vehicles.forEach(v => {
            if (!grouped[v.class]) grouped[v.class] = [];
            grouped[v.class].push(v);
        });

        const tabs = Object.keys(grouped).map(cls => `
            <button class="cat-tab ${allowedClasses.includes(cls) ? '' : ''}"
                    data-class="${cls}" onclick="Police.filterGarage('${cls}')">
                ${classLabels[cls] || cls}
                ${!allowedClasses.includes(cls) ? '<i class="hgi-stroke hgi-lock-02"></i>' : ''}
            </button>
        `).join('');

        const cards = vehicles.map(v => {
            const locked = !allowedClasses.includes(v.class);
            return `
            <div class="veh-card ${locked ? 'locked' : ''}" data-class="${v.class}">
                <div class="veh-header">
                    <div class="veh-ic"><i class="hgi-stroke hgi-police-car"></i></div>
                    <div>
                        <div class="veh-name">${v.label}</div>
                        <div class="veh-class">${classLabels[v.class] || v.class}
                            ${locked ? '<span style="color:var(--danger)"> · Zárolt</span>' : ''}
                        </div>
                    </div>
                </div>
                <div class="veh-desc">${v.description || ''}</div>
                ${!locked ? `
                <button class="veh-spawn-btn" onclick="Police.spawnVehicle('${v.model}')">
                    <i class="hgi-stroke hgi-car-01"></i>Jármű kivétele
                </button>` : ''}
            </div>`;
        }).join('');

        return `
        <div class="mod-section">
            <div class="section-title">Garázs – Ranghoz kötött járművek</div>
            <div class="info-box accent">
                <i class="hgi-stroke hgi-information-circle"></i>
                <span>A te rangodhoz elérhető osztályok:
                    <strong>${allowedClasses.map(c => classLabels[c] || c).join(', ') || '–'}</strong>
                </span>
            </div>
            <div class="cat-tabs" id="garage-tabs">
                <button class="cat-tab active" data-class="all" onclick="Police.filterGarage('all')">Összes</button>
                ${tabs}
            </div>
            <div class="vehicle-grid" id="garage-grid">${cards}</div>
        </div>`;
    },

    filterGarage(cls) {
        document.querySelectorAll('.cat-tab').forEach(b => {
            b.classList.toggle('active', b.dataset.class === cls);
        });
        document.querySelectorAll('.veh-card').forEach(c => {
            c.style.display = (cls === 'all' || c.dataset.class === cls) ? '' : 'none';
        });
    },

    spawnVehicle(model) {
        nuiFetch('moduleAction', {
            module: 'garage', action: 'spawn',
            payload: { model, stationId: State.stationId }
        });
        Police.close();
    },

    // ── EGYSÉG ────────────────────────────────────────────────
    renderUnit() {
        const o = State.officer;
        const canManage = window._ranks &&
            window._ranks.find(r => r.grade === o.grade)
            ?.permissions?.can_manage_units;

        const unitCards = State.units.length === 0
            ? `<div class="empty-state"><i class="hgi-stroke hgi-user-group"></i><span>Jelenleg nincs aktív egység.</span></div>`
            : State.units.map(u => {
                const isMine  = o.unit === u.id;
                const isLeader= u.leader === 'me'; // szimulálva, szerveren ellenőrzött
                return `
                <div class="unit-card ${isMine ? 'my-unit' : ''}">
                    <div class="uc-icon"><i class="hgi-stroke hgi-radio-02"></i></div>
                    <div class="uc-info">
                        <div class="uc-name">${u.name} ${isMine ? '<span class="rank-badge">Te</span>' : ''}</div>
                        <div class="uc-count">${u.count} tag</div>
                    </div>
                    ${isMine
                        ? `<button class="uc-join leave" onclick="Police.leaveUnit()">
                                <i class="hgi-stroke hgi-logout-02"></i>Elhagyás
                           </button>`
                        : `<button class="uc-join" onclick="Police.joinUnit(${u.id})">
                                <i class="hgi-stroke hgi-login-02"></i>Csatlakozás
                           </button>`
                    }
                </div>`;
            }).join('');

        return `
        <div class="mod-section">
            <div class="section-title">Aktív egységek</div>
            <div class="unit-list" id="unit-list">${unitCards}</div>
        </div>
        ${canManage ? `
        <div class="mod-section">
            <div class="section-title">Új egység létrehozása</div>
            <label class="field-label">Egység neve</label>
            <input class="styled-input" id="unit-name-input" placeholder="pl. Adam-1"/>
            <label class="field-label">Csatorna</label>
            <select class="styled-select" id="unit-ch-select">
                <option value="1">1. csatorna</option>
                <option value="2">2. csatorna</option>
                <option value="3">3. csatorna</option>
            </select>
            <button class="full-btn accent" onclick="Police.createUnit()">
                <i class="hgi-stroke hgi-add-02"></i>Egység létrehozása
            </button>
        </div>` : ''}
        ${o.unit ? `
        <div class="mod-section">
            <button class="full-btn danger" onclick="Police.disbandUnit()">
                <i class="hgi-stroke hgi-delete-02"></i>Egység feloszlatása
            </button>
        </div>` : ''}`;
    },

    createUnit() {
        const name = $('#unit-name-input')?.value?.trim() || 'Adam-1';
        const ch   = $('#unit-ch-select')?.value || '1';
        nuiFetch('moduleAction', {
            module: 'unit', action: 'create',
            payload: { name, channel: parseInt(ch) }
        });
    },

    joinUnit(id) {
        nuiFetch('moduleAction', { module: 'unit', action: 'join', payload: { unitId: id } });
    },

    leaveUnit() {
        nuiFetch('moduleAction', { module: 'unit', action: 'leave', payload: {} });
    },

    disbandUnit() {
        nuiFetch('moduleAction', { module: 'unit', action: 'disband', payload: {} });
    },

    onUnitsUpdated(units) {
        State.units = units;
        if (State.activeModule === 'unit') Police.openModule('unit');
        // Duty badge frissítés
        const myUnit = units.find(u => u.members && u.members.includes('me'));
        $('#db-unit').textContent = myUnit ? 'Egység: ' + myUnit.name : 'Egység: –';
        if (myUnit) {
            $('#unit-stat').style.display = 'flex';
            $('#stat-unit').textContent   = 'Egység: ' + myUnit.name;
        }
    },

    onUnitJoined(unit) {
        State.officer.unit = unit.id;
    },

    onUnitDisbanded() {
        State.officer.unit = null;
        if (State.activeModule === 'unit') Police.openModule('unit');
    },

    // ── RUHÁZAT ───────────────────────────────────────────────
    renderClothing() {
        return `
        <div class="mod-section">
            <div class="section-title">Egyenruha</div>
            <div class="clothing-cards">
                <div class="clothing-card" onclick="Police.wearUniform()">
                    <i class="hgi-stroke hgi-t-shirt"></i>
                    <div class="cc-label">Egyenruha felöltése</div>
                    <div class="cc-sub">Rangnak megfelelő egyenruha</div>
                </div>
                <div class="clothing-card" onclick="Police.wearCivilian()">
                    <i class="hgi-stroke hgi-user-02"></i>
                    <div class="cc-label">Civil ruha</div>
                    <div class="cc-sub">Visszaváltás civil ruhára</div>
                </div>
            </div>
            <div class="info-box warn">
                <i class="hgi-stroke hgi-information-circle"></i>
                <span>A ruházatcsere csak az állomáson belül lehetséges.</span>
            </div>
        </div>`;
    },

    wearUniform() {
        nuiFetch('moduleAction', { module: 'clothing', action: 'wear', payload: {} });
        Police.close();
    },

    wearCivilian() {
        nuiFetch('moduleAction', { module: 'clothing', action: 'civilian', payload: {} });
        Police.close();
    },

    // ── TÁROLÓK ───────────────────────────────────────────────
    renderStorage() {
        const o = State.officer;
        const canShared = window._ranks &&
            window._ranks.find(r => r.grade === o.grade)
            ?.permissions?.can_shared_storage;

        return `
        <div class="mod-section">
            <div class="section-title">Tárolók</div>
            <div class="storage-cards">
                <div class="storage-card" onclick="Police.openStorage('personal')">
                    <i class="hgi-stroke hgi-package-01"></i>
                    <div class="sc-label">Személyes tároló</div>
                    <div class="sc-sub">20 hely · 50 kg</div>
                </div>
                <div class="storage-card ${canShared ? '' : 'locked'}"
                     onclick="${canShared ? "Police.openStorage('shared')" : ''}">
                    <i class="hgi-stroke hgi-archive-02"></i>
                    <div class="sc-label">Közös tároló</div>
                    <div class="sc-sub">${canShared ? '100 hely · 500 kg' : '🔒 Vezető szint szükséges'}</div>
                </div>
            </div>
        </div>`;
    },

    openStorage(type) {
        nuiFetch('moduleAction', {
            module: 'storage',
            action: type === 'personal' ? 'openPersonal' : 'openShared',
            payload: { stationId: State.stationId }
        });
        Police.close();
    },

    // ── FEGYVEREK ─────────────────────────────────────────────
    renderWeapons() {
        const o      = State.officer;
        const rank   = window._ranks && window._ranks.find(r => r.grade === o.grade);
        const loadout= rank ? (rank.weapon_loadout || []) : [];

        const weaponLabels = {
            weapon_pistol:      { label: 'Pisztoly',          icon: 'hgi-stroke hgi-sword-02' },
            weapon_stungun:     { label: 'Sokkoló',           icon: 'hgi-stroke hgi-flash-02' },
            weapon_nightstick:  { label: 'Gumibot',           icon: 'hgi-stroke hgi-baseball-bat' },
            weapon_pumpshotgun: { label: 'Sörétes puska',     icon: 'hgi-stroke hgi-sword-02' },
            weapon_carbinerifle:{ label: 'Karabély',          icon: 'hgi-stroke hgi-sword-02' },
            weapon_sniperrifle: { label: 'Mesterlövész puska',icon: 'hgi-stroke hgi-sword-02' },
            weapon_heavysniper: { label: 'Nehéz mesterlövész',icon: 'hgi-stroke hgi-sword-02' },
        };

        const cards = loadout.length === 0
            ? `<div class="empty-state"><i class="hgi-stroke hgi-sword-02"></i><span>Nincs elérhető fegyver a rangodhoz.</span></div>`
            : loadout.map(w => {
                const wd = weaponLabels[w] || { label: w, icon: 'hgi-stroke hgi-sword-02' };
                return `
                <div class="weapon-card">
                    <div class="wc-icon"><i class="${wd.icon}"></i></div>
                    <div class="wc-info">
                        <div class="wc-name">${wd.label}</div>
                        <div class="wc-ammo">250 töltény</div>
                    </div>
                </div>`;
            }).join('');

        return `
        <div class="mod-section">
            <div class="section-title">Fegyverraktár – Ranghoz kötött készlet</div>
            <div class="weapon-grid">${cards}</div>
        </div>
        <div class="mod-section">
            <button class="full-btn success" onclick="Police.getLoadout()">
                <i class="hgi-stroke hgi-download-02"></i>Teljes készlet kivétele
            </button>
            <button class="full-btn danger" onclick="Police.returnLoadout()">
                <i class="hgi-stroke hgi-upload-02"></i>Fegyverek leadása
            </button>
        </div>`;
    },

    getLoadout() {
        nuiFetch('moduleAction', { module: 'weapons', action: 'getLoadout', payload: {} });
        Police.close();
    },

    returnLoadout() {
        nuiFetch('moduleAction', { module: 'weapons', action: 'returnLoadout', payload: {} });
    },

    // ── MDT ───────────────────────────────────────────────────
    renderMDT() {
        const results = State.mdtResults.length === 0
            ? `<div class="empty-state"><i class="hgi-stroke hgi-search-02"></i><span>Keresj egy személyt a név alapján.</span></div>`
            : State.mdtResults.map(p => this._mdtCard(p)).join('');

        return `
        <div class="mod-section">
            <div class="section-title">MDT – Személyek keresése</div>
            <div class="mdt-search-bar">
                <input class="mdt-input" id="mdt-search" placeholder="Keresztnév Vezetéknév…" />
                <button class="mdt-search-btn" onclick="Police.mdtSearch()">
                    <i class="hgi-stroke hgi-search-02"></i>Keresés
                </button>
            </div>
            <div id="mdt-results">${results}</div>
        </div>`;
    },

    _mdtCard(p) {
        const hasFines  = p.fines && p.fines.length > 0;
        const inPrison  = p.prisonTime && p.prisonTime.timeLeft > 0;
        const tags = `
            ${inPrison ? '<span class="mdt-tag prison">Börtönben</span>' : ''}
            ${hasFines  ? '<span class="mdt-tag wanted">Bírság van</span>' : '<span class="mdt-tag clean">Tiszta</span>'}
        `;
        return `
        <div class="mdt-result-card">
            <div class="mdt-person">
                <div class="mdt-avatar"><i class="hgi-stroke hgi-user-02"></i></div>
                <div style="flex:1">
                    <div class="mdt-name">${p.firstname} ${p.lastname}</div>
                    <div class="mdt-meta">SZN: ${p.identifier} · Születés: ${p.dob || '–'} · Tel: ${p.phone || '–'}</div>
                    <div class="mdt-tags">${tags}</div>
                </div>
            </div>
            ${hasFines ? `
            <div class="section-title" style="margin-bottom:8px">Bírságok (${p.fines.length})</div>
            <div class="fine-list">
                ${p.fines.slice(0,3).map(f => `
                <div class="fine-row ${f.paid ? 'paid' : 'unpaid'}">
                    <div class="fr-icon ${f.paid ? 'paid' : ''}">
                        <i class="hgi-stroke hgi-file-02"></i>
                    </div>
                    <div class="fr-info">
                        <div class="fr-label">${f.label}</div>
                        <div class="fr-meta">${f.created_at || ''}</div>
                        ${f.jail_time > 0 ? `<div class="fr-jail"><i class="hgi-stroke hgi-jail"></i>${f.jail_time} perc börtön</div>` : ''}
                    </div>
                    <div class="fr-amount ${f.paid ? 'paid' : ''}">$${f.amount.toLocaleString('hu-HU')}</div>
                </div>`).join('')}
            </div>` : ''}
            <div class="mdt-actions">
                <button class="mdt-action-btn mab-fine"
                        onclick="Police.openFineModal('${p.identifier}','${p.firstname} ${p.lastname}')">
                    <i class="hgi-stroke hgi-file-02"></i>Bírság
                </button>
                <button class="mdt-action-btn mab-prison"
                        onclick="Police.openPrisonModal('${p.identifier}','${p.firstname} ${p.lastname}')">
                    <i class="hgi-stroke hgi-jail"></i>Börtön
                </button>
                <button class="mdt-action-btn mab-note"
                        onclick="Police.addNote('${p.identifier}')">
                    <i class="hgi-stroke hgi-note-02"></i>Megjegyzés
                </button>
                ${inPrison ? `
                <button class="mdt-action-btn mab-release"
                        onclick="Police.releasePrison('${p.identifier}')">
                    <i class="hgi-stroke hgi-lock-02"></i>Elengedés
                </button>` : ''}
            </div>
        </div>`;
    },

    mdtSearch() {
        const q = $('#mdt-search')?.value?.trim();
        if (!q) return;
        nuiFetch('moduleAction', { module: 'mdt', action: 'search', payload: { query: q } });
    },

    onMDTResults(results) {
        State.mdtResults = results;
        const el = $('#mdt-results');
        if (!el) return;
        el.innerHTML = results.length === 0
            ? `<div class="empty-state"><i class="hgi-stroke hgi-search-02"></i><span>Nincs találat.</span></div>`
            : results.map(p => Police._mdtCard(p)).join('');
    },

    addNote(identifier) {
        const note = prompt('Megjegyzés szövege:');
        if (!note) return;
        nuiFetch('moduleAction', { module: 'mdt', action: 'addNote', payload: { identifier, note } });
    },

    releasePrison(identifier) {
        nuiFetch('moduleAction', { module: 'prison', action: 'release', payload: { identifier } });
    },

    // ── BÍRSÁGOK ──────────────────────────────────────────────
    renderFines() {
        const categories = window._fineCategories || {};
        const fineTypes  = window._fineTypes      || [];

        const catTabs = Object.entries(categories).map(([id, cat], i) => `
            <button class="cat-tab ${i===0?'active':''}" data-cat="${id}"
                    onclick="Police.filterFines('${id}')">
                <i class="${cat.icon}"></i>${cat.label}
            </button>
        `).join('');

        const fineCards = fineTypes.map(ft => `
            <div class="base-card" data-cat="${ft.category}"
                 onclick="Police.openFineModal(null,null,'${ft.id}')">
                <div class="bc-icon"><i class="${categories[ft.category]?.icon || 'hgi-stroke hgi-file-02'}"></i></div>
                <div class="bc-label">${ft.label}</div>
                <div class="bc-sub">$${ft.min.toLocaleString('hu-HU')}–$${ft.max.toLocaleString('hu-HU')}
                    ${ft.jail > 0 ? ` · ${ft.jail} perc börtön` : ''}
                </div>
            </div>
        `).join('');

        return `
        <div class="mod-section">
            <div class="section-title">Bírság kiállítása</div>
            <div class="cat-tabs">${catTabs}</div>
            <div class="card-grid" id="fine-type-grid">${fineCards}</div>
        </div>`;
    },

    filterFines(cat) {
        document.querySelectorAll('.cat-tab').forEach(b => {
            b.classList.toggle('active', b.dataset.cat === cat);
        });
        document.querySelectorAll('#fine-type-grid .base-card').forEach(c => {
            c.style.display = c.dataset.cat === cat ? '' : 'none';
        });
    },

    onFinesResult(fines) {
        State.fines = fines;
    },

    onFineIssued() {
        Police.closeFineModal();
        showNotif('Bírság sikeresen kiállítva.', 'success');
    },

    // ── BÖRTÖN ────────────────────────────────────────────────
    renderPrison() {
        const prisoners = []; // szerver tölti be szükség esetén

        return `
        <div class="mod-section">
            <div class="section-title">Börtön – Gyors bebörtönzés</div>
            <div class="info-box danger">
                <i class="hgi-stroke hgi-jail"></i>
                <span>A bebörtönzéshez keresd meg a személyt az MDT-ben, majd ott használd a börtön funkciót.</span>
            </div>
            <div class="section-title" style="margin-top:16px">Közmunka területek</div>
            ${(window._csLocations || []).map(cs => `
            <div class="base-card" style="margin-bottom:9px">
                <div style="display:flex;align-items:center;gap:10px">
                    <div class="bc-icon"><i class="hgi-stroke hgi-recycle-01"></i></div>
                    <div>
                        <div class="bc-label">${cs.label}</div>
                        <div class="bc-sub">Feladat: ${cs.task}</div>
                    </div>
                </div>
            </div>`).join('')}
        </div>`;
    },

    // ── BÍRSÁG MODAL ──────────────────────────────────────────
    openFineModal(identifier, name, preselect) {
        const fineTypes = window._fineTypes || [];
        const selected  = preselect
            ? fineTypes.find(f => f.id === preselect)
            : fineTypes[0];

        const options = fineTypes.map(ft =>
            `<option value="${ft.id}" ${ft.id === (selected?.id) ? 'selected' : ''}>${ft.label}</option>`
        ).join('');

        $('#fine-modal-body').innerHTML = `
            <label class="field-label">Azonosító</label>
            <input class="styled-input" id="fine-identifier" placeholder="player.identifier" value="${identifier || ''}"/>
            <label class="field-label">Bírság típusa</label>
            <select class="styled-select" id="fine-type" onchange="Police.updateFineRange()">${options}</select>
            <label class="field-label">Összeg ($)</label>
            <div class="range-row">
                <input type="range" class="styled-range" id="fine-amount-range"
                       min="${selected?.min||0}" max="${selected?.max||99999}"
                       value="${selected?.min||0}"
                       oninput="$('#fine-amount-val').textContent='$'+Number(this.value).toLocaleString('hu-HU');$('#fine-amount-num').value=this.value"/>
                <span class="range-val" id="fine-amount-val">$${(selected?.min||0).toLocaleString('hu-HU')}</span>
            </div>
            <input type="hidden" id="fine-amount-num" value="${selected?.min||0}"/>
            ${(selected?.jail||0) > 0 ? `
            <label class="field-label">Börtön idő (perc)</label>
            <div class="range-row">
                <input type="range" class="styled-range" id="fine-jail-range"
                       min="0" max="${selected?.jail||60}" value="${selected?.jail||0}"
                       oninput="$('#fine-jail-val').textContent=this.value+' perc';$('#fine-jail-num').value=this.value"/>
                <span class="range-val" id="fine-jail-val">${selected?.jail||0} perc</span>
            </div>
            <input type="hidden" id="fine-jail-num" value="${selected?.jail||0}"/>` : '<input type="hidden" id="fine-jail-num" value="0"/>'}
            <label class="field-label">Megjegyzés (opcionális)</label>
            <textarea class="styled-textarea" id="fine-note" placeholder="Helyszín, körülmények…"></textarea>
        `;

        $('#fine-confirm').onclick = () => Police.confirmFine();
        $('#fine-modal').classList.remove('hidden');
    },

    updateFineRange() {
        const sel = $('#fine-type');
        if (!sel) return;
        const fineTypes = window._fineTypes || [];
        const ft = fineTypes.find(f => f.id === sel.value);
        if (!ft) return;
        const range = $('#fine-amount-range');
        if (range) {
            range.min   = ft.min;
            range.max   = ft.max;
            range.value = ft.min;
            $('#fine-amount-val').textContent = '$' + Number(ft.min).toLocaleString('hu-HU');
            $('#fine-amount-num').value = ft.min;
        }
    },

    confirmFine() {
        const identifier = $('#fine-identifier')?.value?.trim();
        const typeId     = $('#fine-type')?.value;
        const amount     = parseInt($('#fine-amount-num')?.value || 0);
        const jailTime   = parseInt($('#fine-jail-num')?.value   || 0);
        const note       = $('#fine-note')?.value?.trim() || '';
        if (!identifier || !typeId) { showNotif('Töltsd ki az összes mezőt!', 'warning'); return; }
        nuiFetch('moduleAction', {
            module: 'fines', action: 'issue',
            payload: { identifier, typeId, amount, jailTime, note }
        });
    },

    closeFineModal() {
        $('#fine-modal').classList.add('hidden');
    },

    // ── BÖRTÖN MODAL ──────────────────────────────────────────
    openPrisonModal(identifier, name) {
        $('#prison-modal-body').innerHTML = `
            <label class="field-label">Azonosító</label>
            <input class="styled-input" id="prison-identifier" value="${identifier || ''}" placeholder="player.identifier"/>
            <label class="field-label">Börtön idő (perc)</label>
            <div class="range-row">
                <input type="range" class="styled-range" id="prison-time-range"
                       min="1" max="${window._maxPrison || 60}" value="10"
                       oninput="$('#prison-time-val').textContent=this.value+' perc';$('#prison-time-num').value=this.value"/>
                <span class="range-val" id="prison-time-val">10 perc</span>
            </div>
            <input type="hidden" id="prison-time-num" value="10"/>
            <label class="field-label">Ok</label>
            <input class="styled-input" id="prison-reason" placeholder="Letartóztatás oka…"/>
        `;
        $('#prison-confirm').onclick = () => Police.confirmPrison();
        $('#prison-modal').classList.remove('hidden');
    },

    confirmPrison() {
        const identifier = $('#prison-identifier')?.value?.trim();
        const time       = parseInt($('#prison-time-num')?.value || 10);
        const reason     = $('#prison-reason')?.value?.trim() || '';
        if (!identifier) { showNotif('Add meg az azonosítót!', 'warning'); return; }
        nuiFetch('moduleAction', {
            module: 'prison', action: 'send',
            payload: { identifier, time, reason }
        });
        Police.closePrisonModal();
    },

    closePrisonModal() {
        $('#prison-modal').classList.add('hidden');
    },

    // ── DUTY ──────────────────────────────────────────────────
    toggleDuty() {
        nuiFetch('toggleDuty');
    },

    updateDuty(state) {
        State.onDuty = state;
        const dot    = $('#ds-dot');
        const label  = $('#ds-label');
        const btn    = $('#duty-btn');
        const btnLbl = $('#duty-btn-label');
        const dbDot  = $('#db-dot');

        if (dot)    dot.className    = 'ds-dot ' + (state ? 'on' : 'off');
        if (label)  label.textContent= state ? 'Szolgálatban' : 'Szolgálaton kívül';
        if (btn)    btn.classList.toggle('on-duty', state);
        if (btnLbl) btnLbl.textContent = state ? 'Szolgálatból kilép' : 'Szolgálatba lép';
        if (dbDot)  dbDot.classList.toggle('active', state);

        // Duty badge
        if ($('#duty-badge')) {
            $('#duty-badge').classList.toggle('hidden', !state);
        }

        // Modul nav jogosultság frissítés
        document.querySelectorAll('.mod-btn').forEach(b => {
            if (b.dataset.module !== 'clothing') {
                b.classList.toggle('disabled', !state);
            }
        });
    },

    onRankUpdate(data) {
        if (!State.officer) return;
        State.officer.grade     = data.grade;
        State.officer.rankLabel = data.rankLabel;
        $('#oc-rank').textContent = data.rankLabel;
        $('#db-rank').textContent = data.rankLabel;
    },

    // ── Modul event binding ────────────────────────────────────
    bindModuleEvents(id) {
        if (id === 'mdt') {
            const input = $('#mdt-search');
            if (input) {
                input.addEventListener('keydown', e => {
                    if (e.key === 'Enter') Police.mdtSearch();
                });
            }
        }
        if (id === 'fines') {
            // Első kategória szűrés
            const firstCat = Object.keys(window._fineCategories || {})[0];
            if (firstCat) Police.filterFines(firstCat);
        }
    },

    // ── Panel bezárás ─────────────────────────────────────────
    close() {
        State.open = false;
        $('#overlay').classList.add('hidden');
        document.body.style.overflow = '';
        nuiFetch('close');
    },
};

// ═══════════════════════════════════════════════════════════════
//  PRISON NAMESPACE
// ═══════════════════════════════════════════════════════════════
const Prison = {
    interval: null,

    start(timeLeft, reason) {
        const hud = $('#prison-hud');
        if (hud) hud.classList.remove('hidden');
        this.tick(timeLeft);
    },

    tick(timeLeft) {
        const el = $('#prison-timer');
        if (!el) return;
        const m = Math.floor(timeLeft / 60);
        const s = timeLeft % 60;
        el.textContent = `${m}:${String(s).padStart(2,'0')}`;
    },

    end() {
        const hud = $('#prison-hud');
        if (hud) hud.classList.add('hidden');
    },

    csStart(task, label) {
        const wrap = $('#prison-cs-wrap');
        if (wrap) {
            wrap.style.display = 'flex';
            $('#prison-cs-label').textContent = label || 'Közmunka';
        }
    },

    csStop() {
        const wrap = $('#prison-cs-wrap');
        if (wrap) wrap.style.display = 'none';
    },
};

// ═══════════════════════════════════════════════════════════════
//  SEGÉD
// ═══════════════════════════════════════════════════════════════
function $(sel) { return document.querySelector(sel); }

function showNotif(msg, type) {
    // Saját mini toast ha NUI-ban vagyunk
    const existing = document.querySelector('.nui-toast');
    if (existing) existing.remove();
    const el = document.createElement('div');
    el.className = 'nui-toast';
    const colors = { success:'var(--success)', error:'var(--danger)', warning:'var(--warning)', info:'var(--accent)' };
    el.style.cssText = `
        position:fixed;bottom:24px;right:24px;z-index:99999;
        background:var(--bg-panel);border:1px solid ${colors[type]||colors.info};
        border-left:3px solid ${colors[type]||colors.info};
        border-radius:10px;padding:11px 16px;font-size:12px;font-weight:700;
        color:${colors[type]||colors.info};box-shadow:0 4px 20px rgba(0,0,0,.5);
        animation:slideInLeft .25s ease;
    `;
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 3000);
}

// ── Config adatok NUI-ba injektálás ──────────────────────────
// Ezeket a Lua oldalon a panel megnyitásakor kell a payloadban küldeni
window.addEventListener('message', ({ data }) => {
    if (data.action === 'open') {
        const p = data.payload;
        window._ranks          = p.ranks          || [];
        window._vehicles       = p.vehicles        || [];
        window._classLabels    = p.classLabels     || {};
        window._fineTypes      = p.fineTypes       || [];
        window._fineCategories = p.fineCategories  || {};
        window._csLocations    = p.csLocations     || [];
        window._maxPrison      = p.maxPrison       || 60;
    }
});

// ── Gombok ───────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    $('#close-btn')?.addEventListener('click', Police.close.bind(Police));
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape' && State.open) Police.close();
    });
});