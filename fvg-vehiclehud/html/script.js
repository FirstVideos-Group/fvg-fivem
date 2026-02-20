// ═══════════════════════════════════════════════
//   fvg-vehiclehud :: NUI logika
// ═══════════════════════════════════════════════

const root = document.getElementById('fvg-vhud-root');
let currentPosition = 'bottom-left';

// ── Modul vizuális definíciók ────────────────────────────────
const MODULE_DEFS = {
    engine:       { label: 'Motor',       icon: 'hgi-stroke hgi-car-03',           type: 'status'   },
    speed:        { label: 'Sebesség',    icon: 'hgi-stroke hgi-speedometer-02',   type: 'speed'    },
    rpm:          { label: 'Fordulat',    icon: 'hgi-stroke hgi-dashboard-speed',  type: 'bar'      },
    gear:         { label: 'Fokozat',     icon: 'hgi-stroke hgi-steering',         type: 'gear'     },
    lights:       { label: 'Lámpák',      icon: 'hgi-stroke hgi-sun-03',           type: 'lights'   },
    seatbelt:     { label: 'Bizt. öv',    icon: 'hgi-stroke hgi-seat-belt',        type: 'status'   },
    enginehealth: { label: 'Motor állapot', icon: 'hgi-stroke hgi-wrench-02',      type: 'bar'      },
    fuel:         { label: 'Üzemanyag',   icon: 'hgi-stroke hgi-fuel-station',     type: 'bar'      },
    siren:        { label: 'Sziréna',     icon: 'hgi-stroke hgi-siren',            type: 'status'   },
};

const moduleEls = {};

// ── Modul HTML sablonok típusonként ──────────────────────────
function buildModuleHTML(id, def) {
    const icon = `<i class="fvg-module-icon ${def.icon}"></i>`;

    switch (def.type) {
        case 'speed':
            return `${icon}
            <div class="fvg-module-body">
                <span class="fvg-module-label">${def.label}</span>
            </div>
            <span class="fvg-module-value speed-val" id="fvg-val-${id}">
                0<span class="speed-unit" id="fvg-unit-${id}">km/h</span>
            </span>`;

        case 'gear':
            return `${icon}
            <div class="fvg-module-body">
                <span class="fvg-module-label">${def.label}</span>
            </div>
            <span class="fvg-module-value gear-val" id="fvg-val-${id}">1</span>`;

        case 'bar':
            return `${icon}
            <div class="fvg-module-body">
                <span class="fvg-module-label">${def.label}</span>
                <div class="fvg-module-bar-track">
                    <div class="fvg-module-bar-fill" id="fvg-bar-${id}" style="width:100%"></div>
                </div>
            </div>
            <span class="fvg-module-value" id="fvg-val-${id}">100%</span>`;

        case 'lights':
            return `${icon}
            <div class="fvg-module-body">
                <span class="fvg-module-label">${def.label}</span>
                <div class="lights-row">
                    <div class="light-dot" id="fvg-light-low-${id}"  title="Tompított"></div>
                    <div class="light-dot" id="fvg-light-high-${id}" title="Teli fény"></div>
                    <div class="light-dot" id="fvg-light-indl-${id}" title="Bal index"></div>
                    <div class="light-dot" id="fvg-light-indr-${id}" title="Jobb index"></div>
                </div>
            </div>
            <span class="fvg-module-value" id="fvg-val-${id}">–</span>`;

        case 'status':
        default:
            return `${icon}
            <div class="fvg-module-body">
                <span class="fvg-module-label">${def.label}</span>
            </div>
            <span class="fvg-status-badge badge-off" id="fvg-val-${id}">–</span>`;
    }
}

// ── Modul létrehozása ────────────────────────────────────────
function createModuleEl(id) {
    const def = MODULE_DEFS[id] || { label: id, icon: 'hgi-stroke hgi-dashboard-circle', type: 'bar' };
    const el  = document.createElement('div');
    el.id        = 'fvg-mod-' + id;
    el.className = `fvg-hud-module fvg-mod-${id} hidden`;
    el.innerHTML = buildModuleHTML(id, def);

    root.appendChild(el);
    moduleEls[id] = el;

    const enterClass = currentPosition.includes('right') ? 'enter-right' : 'enter-left';
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            el.classList.add(enterClass);
            setTimeout(() => el.classList.remove(enterClass), 400);
        });
    });
    return el;
}

// ── Modul frissítők típusonként ──────────────────────────────
const updaters = {
    engine: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const val = document.getElementById('fvg-val-' + id);
        if (val) {
            val.className = 'fvg-status-badge ' + (data.running ? 'badge-on' : 'badge-off');
            val.textContent = data.running ? 'Jár' : 'Leállva';
        }
        // Accent szín váltás
        el.style.setProperty('--module-clr', data.running ? 'var(--clr-engine)' : 'var(--clr-engine-off)');
        setVisible(el, data.visible ?? true);
    },

    speed: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const val = document.getElementById('fvg-val-' + id);
        const unit= document.getElementById('fvg-unit-' + id);
        if (val)  val.childNodes[0].textContent = data.value ?? 0;
        if (unit) unit.textContent = data.unit === 'mph' ? 'mph' : 'km/h';
        setVisible(el, data.visible ?? true);
    },

    rpm: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const pct = Math.round((data.value ?? 0) * 100);
        const bar = document.getElementById('fvg-bar-' + id);
        const val = document.getElementById('fvg-val-' + id);
        if (bar) {
            bar.style.width = pct + '%';
            bar.classList.toggle('redline', !!data.redline);
            el.style.setProperty('--module-clr', data.redline ? 'var(--clr-rpm-red)' : 'var(--clr-rpm)');
        }
        if (val) val.textContent = pct + '%';
        setVisible(el, data.visible ?? true);
    },

    gear: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const val = document.getElementById('fvg-val-' + id);
        if (val) val.textContent = data.label ?? data.gear ?? '1';
        setVisible(el, data.visible ?? true);
    },

    lights: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const low  = document.getElementById('fvg-light-low-'  + id);
        const high = document.getElementById('fvg-light-high-' + id);
        const indL = document.getElementById('fvg-light-indl-' + id);
        const indR = document.getElementById('fvg-light-indr-' + id);
        const val  = document.getElementById('fvg-val-' + id);

        if (low)  low.className  = 'light-dot' + (data.lights   ? ' active-low'  : '');
        if (high) high.className = 'light-dot' + (data.highbeam ? ' active-high' : '');
        if (indL) indL.className = 'light-dot' + ((data.indicator === 1 || data.indicator === 3) ? ' active-ind' : '');
        if (indR) indR.className = 'light-dot' + ((data.indicator === 2 || data.indicator === 3) ? ' active-ind' : '');

        const labels = [];
        if (data.lights)                                   labels.push('Tompított');
        if (data.highbeam)                                 labels.push('Teli');
        if (data.indicator === 1)                          labels.push('← Bal');
        if (data.indicator === 2)                          labels.push('Jobb →');
        if (data.indicator === 3)                          labels.push('Vész');
        if (val) val.textContent = labels.length ? labels.join(' · ') : '–';

        setVisible(el, data.visible ?? true);
    },

    seatbelt: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const val = document.getElementById('fvg-val-' + id);
        if (val) {
            val.className   = 'fvg-status-badge ' + (data.fastened ? 'badge-on' : 'badge-off');
            val.textContent = data.fastened ? 'Becsatolva' : 'Nincs';
        }
        el.style.setProperty('--module-clr', data.fastened ? 'var(--clr-seatbelt-on)' : 'var(--clr-seatbelt-off)');
        setVisible(el, data.visible ?? true);
    },

    enginehealth: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const bar = document.getElementById('fvg-bar-' + id);
        const val = document.getElementById('fvg-val-' + id);
        const pct = data.value ?? 100;
        if (bar) {
            bar.style.width = pct + '%';
            bar.className   = 'fvg-module-bar-fill ' + (data.status === 'crit' ? 'crit' : data.status === 'warn' ? 'warn' : '');
        }
        if (val) val.textContent = pct + '%';
        const clr = data.status === 'crit' ? 'var(--clr-enghealth-crit)'
                  : data.status === 'warn' ? 'var(--clr-enghealth-warn)'
                  : 'var(--clr-enghealth-ok)';
        el.style.setProperty('--module-clr', clr);
        setVisible(el, data.visible ?? true);
    },

    fuel: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const bar = document.getElementById('fvg-bar-' + id);
        const val = document.getElementById('fvg-val-' + id);
        const pct = data.value ?? 100;
        if (bar) {
            bar.style.width = pct + '%';
            bar.classList.toggle('low', !!data.low);
        }
        if (val) val.textContent = pct + '%';
        el.style.setProperty('--module-clr', data.low ? 'var(--clr-fuel-low)' : 'var(--clr-fuel)');
        setVisible(el, data.visible ?? true);
    },

    siren: (id, data) => {
        const el  = moduleEls[id]; if (!el) return;
        const val = document.getElementById('fvg-val-' + id);
        if (val) {
            val.className   = 'fvg-status-badge ' + (data.active ? 'badge-siren' : 'badge-off');
            val.textContent = data.active ? 'Aktív' : 'Ki';
        }
        setVisible(el, data.visible ?? false);
    },
};

function setVisible(el, v) {
    if (v) el.classList.remove('hidden');
    else   el.classList.add('hidden');
}

// ── NUI üzenetek ─────────────────────────────────────────────
window.addEventListener('message', function(e) {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'init':
            if (d.position) setPosition(d.position);
            fetch(`https://${GetParentResourceName()}/vHudReady`, {
                method: 'POST', headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            break;

        case 'registerModule':
            if (!moduleEls[d.id]) createModuleEl(d.id);
            if (d.position) setPosition(d.position);
            break;

        case 'updateModule':
            if (!moduleEls[d.id]) createModuleEl(d.id);
            const def = MODULE_DEFS[d.id];
            const type = def ? def.type : 'bar';
            const updater = updaters[d.id] || updaters[type];
            if (updater) updater(d.id, d.data || {});
            break;

        case 'toggleModule':
            if (moduleEls[d.id]) {
                moduleEls[d.id].classList.toggle('hidden', !d.enabled);
            }
            break;

        case 'setHudVisible':
            root.classList.toggle('fvg-vhud-hidden',  !d.visible);
            root.classList.toggle('fvg-vhud-visible', !!d.visible);
            break;

        case 'setPosition':
            setPosition(d.position);
            break;
    }
});

function setPosition(pos) {
    currentPosition = pos;
    root.className = root.className.replace(/pos-\S+/, '');
    root.classList.add('pos-' + pos);
}