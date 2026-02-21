let tickTimer = null;
let isRunning = false;

const root      = document.getElementById('dashcam-root');
const timeReal  = document.getElementById('time-real');
const dateReal  = document.getElementById('date-real');
const gameTime  = document.getElementById('game-time');
const unitLabel = document.getElementById('unit-label');
const speedVal  = document.getElementById('speed-val');
const gpsVal    = document.getElementById('gps-val');

// ── Valós idő ticker ─────────────────────────────────────────────
function startTicker() {
    if (tickTimer) clearInterval(tickTimer);
    tickTimer = setInterval(() => {
        const now = new Date();
        const h   = String(now.getHours()).padStart(2,'0');
        const m   = String(now.getMinutes()).padStart(2,'0');
        const s   = String(now.getSeconds()).padStart(2,'0');
        timeReal.textContent = `${h}:${m}:${s}`;

        const y  = now.getFullYear();
        const mo = String(now.getMonth()+1).padStart(2,'0');
        const d  = String(now.getDate()).padStart(2,'0');
        dateReal.textContent = `${y}-${mo}-${d}`;
    }, 500);
}

function stopTicker() {
    if (tickTimer) { clearInterval(tickTimer); tickTimer = null; }
}

// ── Lua → NUI üzenetek ──────────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {

        case 'start':
            unitLabel.textContent = d.unit || '—';
            speedVal.textContent  = '0';
            gpsVal.textContent    = '— / —';
            gameTime.textContent  = '00:00';

            root.classList.remove('hidden');
            startTicker();
            isRunning = true;
            break;

        case 'update':
            if (!isRunning) break;
            speedVal.textContent = d.speed !== undefined ? d.speed : '0';
            gpsVal.textContent   = d.gps   || '— / —';
            if (d.gameHour !== undefined && d.gameMin !== undefined) {
                const gh = String(d.gameHour).padStart(2,'0');
                const gm = String(d.gameMin).padStart(2,'0');
                gameTime.textContent = `${gh}:${gm}`;
            }
            break;

        case 'stop':
            isRunning = false;
            root.classList.add('hidden');
            stopTicker();
            speedVal.textContent = '0';
            break;
    }
});
