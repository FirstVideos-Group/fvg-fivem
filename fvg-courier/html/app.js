const Courier = (() => {
    let state = {
        onDuty   : false,
        stats    : null,
        levelData: null,
        nextLevel: null,
        activeRun: null,
        timeLeft : 0,
        timerInt : null,
        payload  : null,
    };

    const fmt = (n) => '$' + Number(n).toLocaleString('hu-HU');
    const pad = (n) => String(n).padStart(2, '0');
    const fmtTime = (s) => pad(Math.floor(s / 60)) + ':' + pad(s % 60);

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'openPanel') {
            state.payload  = e.data.data;
            state.stats    = e.data.data.stats;
            state.levelData= e.data.data.levelData;
            state.nextLevel= e.data.data.nextLevel;
            state.activeRun= e.data.data.activeRun;

            renderDashboard();
            renderRunTab();
            renderLeaderboard();
            activateTab('dashboard');
            document.getElementById('overlay').classList.remove('hidden');
        }

        if (action === 'setDuty') {
            state.onDuty = e.data.onDuty;
            if (e.data.stats) state.stats = e.data.stats;
            document.getElementById('courier-hud').classList.toggle('hidden', !state.onDuty);
            updateHUD();
            updateDutyBtn();
        }

        if (action === 'runStarted') {
            state.activeRun = e.data.data;
            state.timeLeft  = e.data.data.timeLimit;
            startTimerUI();
            renderRunTab();
            updateHUD();
        }

        if (action === 'packageDelivered') {
            const d = e.data.data;
            if (state.activeRun) {
                state.activeRun.spots[d.spotIdx - 1].done = true;
                state.activeRun.currentIdx  = d.nextIdx;
                state.activeRun.totalReward = d.totalReward;
            }
            renderRunTab();
            updateHUD();
        }

        if (action === 'runCompleted') {
            stopTimerUI();
            showSummary(e.data.data);
            state.activeRun = null;
            state.stats     = e.data.data.stats;
            renderDashboard();
            renderRunTab();
            updateHUD();
        }

        if (action === 'runEnded' || action === 'runCancelled') {
            stopTimerUI();
            state.activeRun = null;
            renderRunTab();
            updateHUD();
        }

        if (action === 'timerTick') {
            state.timeLeft = e.data.timeLeft;
            updateTimerDisplay();
        }

        if (action === 'syncData') {
            if (e.data.data) state.stats = e.data.data;
        }

        if (action === 'levelUp') {
            if (state.stats) state.stats.level = e.data.levelData.level;
        }
    });

    // ── Tab kezelés ──────────────────────────────────────────
    document.querySelectorAll('.tab').forEach(t =>
        t.addEventListener('click', () => activateTab(t.dataset.tab))
    );
    function activateTab(id) {
        document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === id));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.toggle('active', c.id === 'tab-' + id));
    }

    // ── Irányítópult ─────────────────────────────────────────
    function renderDashboard() {
        const s  = state.stats;
        const ld = state.levelData;
        const nl = state.nextLevel;
        const p  = state.payload;

        if (!s || !ld) return;

        // Szint kártya
        document.getElementById('lc-level').textContent = ld.level + '. szint';
        document.getElementById('lc-title').textContent = ld.label;
        document.getElementById('lc-mult').textContent  = 'x' + ld.rewardMult.toFixed(1);

        // XP progress
        const xpStart  = ld.xpRequired;
        const xpEnd    = nl ? nl.xpRequired : xpStart;
        const xpCurrent= s.xp;
        const pct      = nl ? Math.min(((xpCurrent - xpStart) / (xpEnd - xpStart)) * 100, 100) : 100;
        document.getElementById('xp-fill').style.width    = pct + '%';
        document.getElementById('xp-current').textContent = xpCurrent + ' XP';
        document.getElementById('xp-next').textContent    = nl ? nl.xpRequired + ' XP szükséges' : 'MAX szint';

        // Stat kártyák
        document.getElementById('stat-deliveries').textContent = s.total_deliveries || 0;
        document.getElementById('stat-runs').textContent       = s.total_runs || 0;
        document.getElementById('stat-perfect').textContent    = s.perfect_runs || 0;
        document.getElementById('stat-earned').textContent     = fmt(s.total_earned || 0);

        // Sorozat
        const streak = s.streak || 0;
        document.getElementById('streak-val').textContent  = streak;
        const nextStreakAt = Math.ceil((streak + 1) / 5) * 5;
        document.getElementById('streak-next').textContent = streak % 5 === 0 && streak > 0
            ? '🔥 Sorozat bónusz aktív!'
            : 'Következő bónusz: ' + nextStreakAt + ' körnél';

        // Gomb
        const hasRun = !!state.activeRun;
        const btn    = document.getElementById('start-run-btn');
        btn.disabled = hasRun || !state.onDuty;
        btn.innerHTML= hasRun
            ? `<i class="hgi-stroke hgi-route-02"></i>Kör folyamatban...`
            : `<i class="hgi-stroke hgi-play-circle-02"></i>Új kör indítása`;

        // Jutalom infó
        if (p) {
            const mult = ld.rewardMult || 1;
            document.getElementById('ri-base').textContent   = fmt(Math.floor(p.baseReward * mult)) + ' / csomag';
            document.getElementById('ri-time').textContent   = '+' + fmt(Math.floor((p.timeBonus || 150) * mult));
            document.getElementById('ri-perfect').textContent= '+' + fmt(Math.floor(500 * mult));
        }

        updateDutyBtn();
    }

    function updateDutyBtn() {
        const btn = document.getElementById('duty-btn');
        if (state.onDuty) {
            btn.innerHTML = `<i class="hgi-stroke hgi-stop-circle"></i>Munkából kilépés`;
            btn.classList.add('active');
        } else {
            btn.innerHTML = `<i class="hgi-stroke hgi-play-circle-02"></i>Munkába lépés`;
            btn.classList.remove('active');
        }
    }

    // ── Aktív kör tab ────────────────────────────────────────
    function renderRunTab() {
        const run    = state.activeRun;
        const noRun  = document.getElementById('no-run');
        const runView= document.getElementById('run-view');

        if (!run) {
            noRun.classList.remove('hidden');
            runView.classList.add('hidden');
            return;
        }
        noRun.classList.add('hidden');
        runView.classList.remove('hidden');

        document.getElementById('rtc-reward').textContent = fmt(run.totalReward || 0);
        updateTimerDisplay();

        // Spot lista
        const list = document.getElementById('spots-list');
        list.innerHTML = '';
        run.spots.forEach((spot, i) => {
            const idx     = i + 1;
            const isCurr  = idx === run.currentIdx && !spot.done;
            const isDone  = spot.done;

            const el = document.createElement('div');
            el.className = 'spot-item' + (isCurr ? ' current' : '') + (isDone ? ' done' : '');
            el.innerHTML = `
                <div class="spot-num">
                    ${isDone ? '<i class="hgi-stroke hgi-checkmark-02"></i>' : idx}
                </div>
                <div class="spot-info">
                    <div class="spot-label">${spot.label}</div>
                    <div class="spot-sub">${isCurr ? '📍 Jelenlegi cél' : (isDone ? '✅ Kézbesítve' : '⏳ Várakozás')}</div>
                </div>
                ${isCurr ? `<button class="spot-btn" onclick="setWaypointToSpot(${i})"><i class="hgi-stroke hgi-location-04"></i>Navigáció</button>` : ''}
                ${isDone ? '<i class="hgi-stroke hgi-checkmark-circle-02 spot-status" style="color:var(--success)"></i>' : ''}
            `;
            list.appendChild(el);
        });
    }

    window.setWaypointToSpot = function(idx) {
        const spot = state.activeRun && state.activeRun.spots[idx];
        if (spot) {
            fetch(`https://fvg-courier/setWaypoint`, {
                method: 'POST', body: JSON.stringify({ x: spot.coords.x, y: spot.coords.y })
            });
        }
    };

    // ── Timer UI ─────────────────────────────────────────────
    function updateTimerDisplay() {
        const t    = state.timeLeft;
        const str  = fmtTime(t);
        const urg  = t < 60;

        ['hud-timer', 'rtc-time'].forEach(id => {
            const el = document.getElementById(id);
            if (!el) return;
            el.textContent = str;
            el.classList.toggle('urgent', urg);
        });
        document.getElementById('hud-timer').classList.remove('hidden');
    }

    function startTimerUI() {
        updateTimerDisplay();
    }
    function stopTimerUI() {
        document.getElementById('hud-timer').classList.add('hidden');
        document.getElementById('rtc-time').textContent = '00:00';
    }

    // ── HUD frissítés ────────────────────────────────────────
    function updateHUD() {
        const run = state.activeRun;
        const hud = document.getElementById('courier-hud');
        if (!state.onDuty) { hud.classList.add('hidden'); return; }
        hud.classList.remove('hidden');

        if (!run) {
            document.getElementById('hud-label').textContent = 'Nincs aktív kör – F a depot-nál';
            document.getElementById('hud-progress').classList.add('hidden');
            document.getElementById('hud-reward').classList.add('hidden');
            document.getElementById('hud-timer').classList.add('hidden');
            return;
        }

        const done   = run.spots.filter(s => s.done).length;
        const total  = run.spots.length;
        const pct    = (done / total) * 100;
        const curr   = run.spots[run.currentIdx - 1];

        document.getElementById('hud-label').textContent    = curr ? '📦 ' + curr.label : 'Kör vége!';
        document.getElementById('hud-prog-fill').style.width= pct + '%';
        document.getElementById('hud-prog-text').textContent= done + ' / ' + total;
        document.getElementById('hud-reward-val').textContent = Number(run.totalReward || 0).toLocaleString('hu-HU');

        document.getElementById('hud-progress').classList.remove('hidden');
        document.getElementById('hud-reward').classList.remove('hidden');
    }

    // ── Ranglista ────────────────────────────────────────────
    function renderLeaderboard() {
        const lb   = state.payload && state.payload.leaderboard;
        const list = document.getElementById('lb-list');
        if (!lb || !lb.length) {
            list.innerHTML = '<div style="font-size:12px;color:var(--text-m);padding:16px;text-align:center">Nincs adat</div>';
            return;
        }
        list.innerHTML = '';
        lb.forEach((row, i) => {
            const rank  = i + 1;
            const el    = document.createElement('div');
            el.className= 'lb-item';
            const rankClass = rank === 1 ? 'gold' : rank === 2 ? 'silver' : rank === 3 ? 'bronze' : '';
            el.innerHTML = `
                <div class="lb-rank ${rankClass}">${rank <= 3 ? ['🥇','🥈','🥉'][rank-1] : rank}</div>
                <div class="lb-info">
                    <div class="lb-name">${row.firstname || ''} ${row.lastname || ''}</div>
                    <div class="lb-meta">Szint ${row.level} · ${row.total_deliveries} kézbesítés</div>
                </div>
                <div class="lb-score">${fmt(row.total_earned || 0)}</div>
            `;
            list.appendChild(el);
        });
    }

    // ── Összefoglaló modal ───────────────────────────────────
    function showSummary(data) {
        const body = document.getElementById('sm-body');
        body.innerHTML = `
            <div class="sm-total">
                <div class="sm-total-label">Összes jutalom</div>
                <div class="sm-total-val">${fmt(data.totalReward)}</div>
            </div>
            ${data.isPerfect ? `<div class="sm-perfect-badge"><i class="hgi-stroke hgi-star-02"></i>Tökéletes kör!</div>` : ''}
            ${(data.bonuses || []).map(b => `
                <div class="sm-bonus-row">
                    <span class="sm-bonus-label">${b.label}</span>
                    <span class="sm-bonus-val">+${fmt(b.amount)}</span>
                </div>
            `).join('')}
            <div class="sm-xp-row">
                <i class="hgi-stroke hgi-star-02"></i>
                <span>+${data.xpGained} XP szerzett · Szint: ${data.levelData ? data.levelData.label : ''}</span>
            </div>
        `;
        document.getElementById('summary-modal').classList.remove('hidden');
    }

    function closeModal() {
        document.getElementById('summary-modal').classList.add('hidden');
    }

    // ── Gombok ──────────────────────────────────────────────
    document.getElementById('start-run-btn').addEventListener('click', () => {
        fetch(`https://fvg-courier/startRun`, { method: 'POST', body: JSON.stringify({}) });
    });
    document.getElementById('start-run-btn-2').addEventListener('click', () => {
        fetch(`https://fvg-courier/startRun`, { method: 'POST', body: JSON.stringify({}) });
    });
    document.getElementById('cancel-run-btn').addEventListener('click', () => {
        fetch(`https://fvg-courier/cancelRun`, { method: 'POST', body: JSON.stringify({}) });
    });
    document.getElementById('duty-btn').addEventListener('click', () => {
        fetch(`https://fvg-courier/toggleDuty`, { method: 'POST', body: JSON.stringify({}) });
    });
    document.getElementById('close-btn').addEventListener('click', close);

    function close() {
        document.getElementById('overlay').classList.add('hidden');
        document.getElementById('summary-modal').classList.add('hidden');
        fetch(`https://fvg-courier/close`, { method: 'POST', body: JSON.stringify({}) });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (!document.getElementById('summary-modal').classList.contains('hidden')) { closeModal(); return; }
            close();
        }
    });

    return { closeModal };
})();