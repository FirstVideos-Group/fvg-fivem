// ═══════════════════════════════════════════════
//   fvg-hud :: NUI logika
// ═══════════════════════════════════════════════

const root = document.getElementById('fvg-hud-root');
let currentPosition = 'bottom-right';

// ── Modul definíciók ─────────────────────────────────────────
const MODULE_DEFS = {
    health:  { label: 'Élet',    icon: 'hgi-stroke hgi-heart-check',          low: 25 },
    shield:  { label: 'Pajzs',   icon: 'hgi-stroke hgi-shield-02',            low: 20 },
    stamina: { label: 'Stamina', icon: 'hgi-stroke hgi-energy-ellipse',       low: 15 },
    food:    { label: 'Étel',    icon: 'hgi-stroke hgi-bread-04',             low: 20 },
    water:   { label: 'Ital',    icon: 'hgi-stroke hgi-water',                low: 20 },
    oxygen:  { label: 'Oxigén',  icon: 'hgi-stroke hgi-bubble',              low: 25 },
    stress:  { label: 'Stressz', icon: 'hgi-stroke hgi-mental-health',        low: 70 },
};

// Tárolt modul elemek
const moduleEls = {};

// ── Modul elem létrehozása ─────────────────────────────────
function createModuleEl(id) {
    const def = MODULE_DEFS[id] || { label: id, icon: 'hgi-stroke hgi-dashboard-circle', low: 20 };
    const el  = document.createElement('div');

    el.id        = 'fvg-mod-' + id;
    el.className = `fvg-hud-module fvg-mod-${id} hidden`;

    // Belépési irány pozíció szerint
    const enterClass = currentPosition.includes('right') ? 'enter-right' : 'enter-left';

    el.innerHTML = `
        <i class="fvg-module-icon ${def.icon}"></i>
        <div class="fvg-module-body">
            <span class="fvg-module-label">${def.label}</span>
            <div class="fvg-module-bar-track">
                <div class="fvg-module-bar-fill" id="fvg-bar-${id}" style="width:100%"></div>
            </div>
        </div>
        <span class="fvg-module-value" id="fvg-val-${id}">100%</span>
    `;

    root.appendChild(el);
    moduleEls[id] = el;

    // Belépési animáció rövid késéssel
    requestAnimationFrame(() => {
        el.classList.add(enterClass);
        setTimeout(() => el.classList.remove(enterClass), 400);
    });

    return el;
}

// ── Modul frissítése ───────────────────────────────────────
function updateModule(id, value, visible) {
    const el = moduleEls[id];
    if (!el) return;

    const def = MODULE_DEFS[id] || { low: 20 };
    const pct = Math.max(0, Math.min(100, Math.round(value)));

    // Sáv
    const bar = document.getElementById('fvg-bar-' + id);
    if (bar) {
        bar.style.width = pct + '%';
        if (pct <= def.low) {
            bar.classList.add('low');
        } else {
            bar.classList.remove('low');
        }
    }

    // Érték szöveg
    const val = document.getElementById('fvg-val-' + id);
    if (val) val.textContent = pct + '%';

    // Láthatóság (animált)
    if (visible) {
        el.classList.remove('hidden');
    } else {
        el.classList.add('hidden');
    }
}

// ── NUI üzenetek fogadása ──────────────────────────────────
window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {

        case 'init':
            if (d.position) setPosition(d.position);
            // Jelzi hogy készen vagyunk
            fetch(`https://${GetParentResourceName()}/hudReady`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            break;

        case 'registerModule':
            if (!moduleEls[d.id]) createModuleEl(d.id);
            if (d.position) setPosition(d.position);
            if (!d.enabled) {
                const el = moduleEls[d.id];
                if (el) el.classList.add('hidden');
            }
            break;

        case 'updateModule':
            updateModule(d.id, d.value ?? 100, d.visible ?? true);
            break;

        case 'toggleModule':
            if (moduleEls[d.id]) {
                if (d.enabled) {
                    moduleEls[d.id].classList.remove('hidden');
                } else {
                    moduleEls[d.id].classList.add('hidden');
                }
            }
            break;

        case 'setPosition':
            setPosition(d.position);
            break;
    }
});

// ── Pozíció kezelő ────────────────────────────────────────
function setPosition(pos) {
    currentPosition = pos;
    root.className = 'pos-' + pos;
}