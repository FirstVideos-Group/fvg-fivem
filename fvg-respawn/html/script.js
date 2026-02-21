// ── State ─────────────────────────────────────────────────────
let selfRespawnDelay  = 60;
let injuredTimeout    = 300;
let timerInterval     = null;
let deathStartTime    = null;

// ── NUI üzenetek fogadása ─────────────────────────────────────
window.addEventListener('message', (e) => {
    const data = e.data;
    if (!data || !data.action) return;

    switch (data.action) {

        case 'showDeath':
            selfRespawnDelay = data.delay   || 60;
            injuredTimeout   = data.timeout || 300;
            deathStartTime   = Date.now();
            showDeathScreen();
            startTimer();
            break;

        case 'hideDeath':
            hideDeathScreen();
            break;

        case 'selfRespawnAvailable':
            enableSelfRespawn();
            break;
    }
});

// ── Halál képernyő megjelenítés ───────────────────────────────
function showDeathScreen() {
    document.getElementById('death-screen').classList.remove('hidden');
    document.getElementById('self-respawn-btn').classList.add('hidden');
    document.getElementById('respawn-hint').classList.remove('hidden');
    document.getElementById('countdown').textContent = selfRespawnDelay;
    document.getElementById('timer-bar').style.width = '0%';
}

function hideDeathScreen() {
    document.getElementById('death-screen').classList.add('hidden');
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

// ── Timer frissítés ───────────────────────────────────────────
function startTimer() {
    if (timerInterval) clearInterval(timerInterval);

    timerInterval = setInterval(() => {
        const elapsed = (Date.now() - deathStartTime) / 1000;
        const pct     = Math.min((elapsed / injuredTimeout) * 100, 100);

        document.getElementById('timer-bar').style.width = pct + '%';

        const remaining = Math.max(0, Math.ceil(selfRespawnDelay - elapsed));
        document.getElementById('countdown').textContent = remaining;

        if (elapsed >= selfRespawnDelay) {
            enableSelfRespawn();
        }
    }, 1000);
}

// ── Önrespawn gomb engedélyezés ───────────────────────────────
function enableSelfRespawn() {
    const btn  = document.getElementById('self-respawn-btn');
    const hint = document.getElementById('respawn-hint');
    btn.classList.remove('hidden');
    hint.classList.add('hidden');
}

// ── Önrespawn kérés ───────────────────────────────────────────
function selfRespawn() {
    const btn = document.getElementById('self-respawn-btn');
    btn.disabled = true;
    btn.innerHTML = '<i class="hgi-stroke hgi-loading-03"></i> Feldolgozás...';

    fetch('https://fvg-respawn/selfRespawn', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    })
    .then(r => r.json())
    .then(res => {
        if (res !== 'ok') {
            btn.disabled = false;
            btn.innerHTML = '<i class="hgi-stroke hgi-hospital-01"></i> Kórházi ellátás kérése';
        }
    })
    .catch(() => {
        btn.disabled = false;
        btn.innerHTML = '<i class="hgi-stroke hgi-hospital-01"></i> Kórházi ellátás kérése';
    });
}
