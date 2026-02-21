// ═══════════════════════════════════════════════
//   fvg-hud :: NUI logika
// ═══════════════════════════════════════════════

const root = document.getElementById('fvg-hud-root');
let currentPosition = 'bottom-right';

// ── Modul definíciók ─────────────────────────────────────────
const MODULE_DEFS = {
    health:  { label: 'Élet',    icon: 'hgi-stroke hgi-heart-check',    low: 25 },
    shield:  { label: 'Pajzs',   icon: 'hgi-stroke hgi-shield-02',      low: 20 },
    stamina: { label: 'Stamina', icon: 'hgi-stroke hgi-energy-ellipse', low: 15 },
    food:    { label: 'Étel',    icon: 'hgi-stroke hgi-bread-04',       low: 20 },
    water:   { label: 'Ital',    icon: 'hgi-stroke hgi-water',          low: 20 },
    oxygen:  { label: 'Oxigén',  icon: 'hgi-stroke hgi-bubble',        low: 25 },
    stress:  { label: 'Stressz', icon: 'hgi-stroke hgi-mental-health',  low: 70 },
};

const moduleEls = {};

// ── Dispatch alert widget elem ────────────────────────────────
let dispatchEl = null;

function getOrCreateDispatchEl() {
    if (dispatchEl) return dispatchEl;
    const el = document.createElement('div');
    el.id        = 'fvg-dispatch-hud';
    el.className = 'fvg-dispatch-hud hidden';
    root.insertBefore(el, root.firstChild);
    dispatchEl = el;
    return el;
}

function updateDispatchHud(alert) {
    const el = getOrCreateDispatchEl();
    if (!alert) { el.classList.add('hidden'); return; }

    const units      = alert.units || [];
    const color      = alert.color || '#38bdf8';
    const icon       = alert.icon  || 'hgi-stroke hgi-radio-02';
    const prioColors = { 1: '#64748b', 2: '#38bdf8', 3: '#f59e0b', 4: '#ef4444' };
    const prioLabels = { 1: 'ALACSONY', 2: 'KÖZEPES', 3: 'MAGAS', 4: 'KRITIKUS' };
    const prioClr    = prioColors[alert.priority] || '#38bdf8';
    const prioLbl    = prioLabels[alert.priority] || 'AKTÍV';

    el.style.setProperty('--dispatch-clr',  color);
    el.style.setProperty('--dispatch-prio', prioClr);
    el.innerHTML = `
        <div class="fdh-header">
            <i class="fdh-icon ${icon}"></i>
            <div class="fdh-title-block">
                <span class="fdh-title">${escapeHtml(alert.title)}</span>
                <span class="fdh-id">${escapeHtml(alert.id)}</span>
            </div>
            <span class="fdh-prio">${prioLbl}</span>
        </div>
        <div class="fdh-row"><i class="hgi-stroke hgi-location-01"></i><span>${escapeHtml(alert.street || 'Ismeretlen helyszín')}</span></div>
        <div class="fdh-row"><i class="hgi-stroke hgi-clock-01"></i><span>${escapeHtml(alert.createdAt || '–')}</span></div>
        <div class="fdh-row"><i class="hgi-stroke hgi-user-group"></i><span>${units.length} egység csatlakozva</span></div>
        <div class="fdh-row fdh-caller"><i class="hgi-stroke hgi-user-circle"></i><span>${escapeHtml(alert.callerName || 'Ismeretlen')}</span></div>
    `;
    el.classList.remove('hidden');
    el.classList.remove('fdh-enter');
    void el.offsetWidth;
    el.classList.add('fdh-enter');
}

function escapeHtml(str) {
    return String(str)
        .replace(/&/g,'&amp;').replace(/</g,'&lt;')
        .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ── Modul elem létrehozása ─────────────────────────────────
function createModuleEl(id) {
    const def = MODULE_DEFS[id] || { label: id, icon: 'hgi-stroke hgi-dashboard-circle', low: 20 };
    const el  = document.createElement('div');
    el.id        = 'fvg-mod-' + id;
    el.className = `fvg-hud-module fvg-mod-${id} hidden`;
    el.innerHTML = `
        <i class="fvg-module-icon ${def.icon}"></i>
        <div class="fvg-module-body">
            <span class="fvg-module-label">${def.label}</span>
            <div class="fvg-module-bar-track">
                <div class="fvg-module-bar-fill" id="fvg-bar-${id}"></div>
            </div>
        </div>
        <span class="fvg-module-value" id="fvg-val-${id}">–</span>
    `;
    root.appendChild(el);
    moduleEls[id] = el;
    return el;
}

// ── Modul frissítése ───────────────────────────────────────
// FONTOS: registerModule NEM hív updateModule-t (nincs hamis 100%)
function applyModuleValue(id, value, visible) {
    const el  = moduleEls[id];
    if (!el) return;
    const def = MODULE_DEFS[id] || { low: 20 };
    const pct = Math.max(0, Math.min(100, Math.round(value)));

    const bar = document.getElementById('fvg-bar-' + id);
    if (bar) {
        // CSS transition-t kikapcsoljuk ha nagy az ugrás (>30%) – nincs vibráló animáció
        const prevW  = parseFloat(bar.style.width) || 0;
        const jump   = Math.abs(pct - prevW);
        bar.style.transition = jump > 30 ? 'none' : '';
        bar.style.width      = pct + '%';
        bar.classList.toggle('low', pct <= def.low);
    }

    const val = document.getElementById('fvg-val-' + id);
    if (val) val.textContent = pct + '%';

    el.classList.toggle('hidden', !visible);
}

// ── NUI üzenetek fogadása ──────────────────────────────────
window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {

        // init: pozíció beállítása, majd hudReady visszaküldése
        case 'init':
            if (d.position) setPosition(d.position);
            fetch(`https://${GetParentResourceName()}/hudReady`, {
                method:  'POST',
                headers: { 'Content-Type': 'application/json' },
                body:    JSON.stringify({}),
            });
            break;

        // registerModule: CSAK DOM elemet hoz létre, értéket NEM állít
        case 'registerModule':
            if (!moduleEls[d.id]) createModuleEl(d.id);
            if (d.position) setPosition(d.position);
            // láthatóság: ha disabled → hidden, egyébként marad hidden
            // amíg az első valós érték meg nem érkezik
            if (!d.enabled) {
                const el = moduleEls[d.id];
                if (el) el.classList.add('hidden');
            }
            break;

        // updateModule: egyedi érték frissítés (más resourceok használhatják)
        case 'updateModule':
            applyModuleValue(d.id, d.value ?? 0, d.visible ?? true);
            break;

        // batchUpdate: a fő tick által küldött batch – ez az elsődleges út
        case 'batchUpdate': {
            const updates = d.updates;
            if (!Array.isArray(updates)) break;
            for (let i = 0; i < updates.length; i++) {
                const u = updates[i];
                applyModuleValue(u.id, u.value, u.visible);
            }
            break;
        }

        case 'toggleModule':
            if (moduleEls[d.id]) {
                moduleEls[d.id].classList.toggle('hidden', !d.enabled);
            }
            break;

        case 'setPosition':
            setPosition(d.position);
            break;

        case 'dispatchAlert':
            updateDispatchHud(d.alert || null);
            break;
    }
});

// ── Pozíció kezelő ────────────────────────────────────────
function setPosition(pos) {
    currentPosition = pos;
    root.className  = 'pos-' + pos;
}
