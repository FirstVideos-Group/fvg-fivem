let isRunning   = false;
let realTicker  = null;
let currentName = '';
let currentCs   = '';
let currentUnit = null;

const root        = document.getElementById('bodycam-root');
const officerName = document.getElementById('officer-name');
const officerMeta = document.getElementById('officer-meta');
const timeVal     = document.getElementById('time-val');
const dateVal     = document.getElementById('date-val');
const gpsVal      = document.getElementById('gps-val');
const battPct     = document.getElementById('batt-pct');
const battIcon    = document.getElementById('batt-icon');
const tsInner     = document.getElementById('ts-inner');

// ── Valós idő ticker ─────────────────────────────────────────────
function startTicker() {
    if (realTicker) clearInterval(realTicker);
    realTicker = setInterval(() => {
        const now = new Date();
        const h  = String(now.getHours()).padStart(2,'0');
        const m  = String(now.getMinutes()).padStart(2,'0');
        const s  = String(now.getSeconds()).padStart(2,'0');
        const y  = now.getFullYear();
        const mo = String(now.getMonth()+1).padStart(2,'0');
        const d  = String(now.getDate()).padStart(2,'0');

        const tStr = `${h}:${m}:${s}`;
        const dStr = `${y}-${mo}-${d}`;

        if (timeVal) timeVal.textContent = tStr;
        if (dateVal) dateVal.textContent = dStr;

        // Timestamp csík
        if (tsInner) {
            tsInner.textContent =
                `AXON · BWC · ${tStr} · ${dStr}` +
                (currentCs ? ` · ${currentCs}` : '');
        }
    }, 500);
}

function stopTicker() {
    if (realTicker) { clearInterval(realTicker); realTicker = null; }
}

// ── Akkumulátor frissítés ─────────────────────────────────────────
function updateBattery(level) {
    if (!battPct || !battIcon) return;
    battPct.textContent = level + '%';

    battIcon.classList.remove('low','crit');
    if (level <= 15) {
        battIcon.classList.add('crit');
        // ikon váltás
        battIcon.className = battIcon.className.replace(/hgi-battery-\S+/, 'hgi-battery-empty-01');
    } else if (level <= 35) {
        battIcon.classList.add('low');
        battIcon.className = battIcon.className.replace(/hgi-battery-\S+/, 'hgi-battery-low-01');
    } else {
        battIcon.className = battIcon.className.replace(/hgi-battery-\S+/, 'hgi-battery-full-01');
    }
}

// ── Járőr meta szöveg ─────────────────────────────────────────────
function buildMeta(callsign, unit) {
    let parts = [];
    if (callsign) parts.push(callsign);
    if (unit)     parts.push('EGYSÉG: ' + unit);
    return parts.length ? parts.join(' · ') : '—';
}

// ── NUI üzenetek ─────────────────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {

        case 'start':
            currentName = d.name     || '—';
            currentCs   = d.callsign || '';
            currentUnit = d.unit     || null;

            if (officerName) officerName.textContent = currentName;
            if (officerMeta) officerMeta.textContent = buildMeta(currentCs, currentUnit);
            if (gpsVal)      gpsVal.textContent       = d.gps || '— / —';
            updateBattery(d.battery !== undefined ? d.battery : 87);

            root.classList.remove('hidden');
            startTicker();
            isRunning = true;
            break;

        case 'update':
            if (!isRunning) break;
            if (d.gps !== undefined && gpsVal) gpsVal.textContent = d.gps;
            break;

        case 'battery':
            updateBattery(d.level);
            break;

        case 'stop':
            isRunning = false;
            stopTicker();
            root.classList.add('hidden');
            break;
    }
});
