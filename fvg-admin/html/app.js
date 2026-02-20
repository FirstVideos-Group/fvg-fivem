/* ╔══════════════════════════════════════════════════╗
   ║          fvg-admin :: app.js                     ║
   ╚══════════════════════════════════════════════════╝ */

const App = (() => {
    let state = {
        role: 'player',
        players: [],
        selectedSrc: null,
        weathers: [],
        vehicles: [],
        banDurations: [],
        permissions: {},
        banList: [],
        noclipOn: false,
    };

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action, data, playerList, bans } = e.data;
        if (action === 'open') {
            state = { ...state, ...data };
            state.players  = data.playerList || [];
            state.noclipOn = false;
            renderAll();
            document.getElementById('overlay').classList.remove('hidden');
        }
        if (action === 'updatePlayers') {
            state.players = playerList || [];
            renderPlayerList();
            if (state.selectedSrc) renderPlayerDetail(state.selectedSrc);
        }
        if (action === 'receiveBanList') {
            state.banList = bans || [];
            renderBanList();
        }
    });

    // ── Tab kezelés ─────────────────────────────────────────
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            tab.classList.add('active');
            document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
        });
    });

    // ── Bezárás ─────────────────────────────────────────────
    document.getElementById('btn-close').addEventListener('click', () => {
        document.getElementById('overlay').classList.add('hidden');
        fetch(`https://fvg-admin/close`, { method: 'POST', body: JSON.stringify({}) });
    });

    // ── Frissítés ────────────────────────────────────────────
    document.getElementById('btn-refresh').addEventListener('click', refreshPlayers);

    function refreshPlayers() {
        fetch(`https://fvg-admin/refreshPlayers`, { method: 'POST', body: JSON.stringify({}) });
    }

    // ── Keresés ──────────────────────────────────────────────
    document.getElementById('search-input').addEventListener('input', renderPlayerList);

    // ── Render függvények ────────────────────────────────────

    function renderAll() {
        document.getElementById('role-badge').textContent = state.role;
        renderPlayerList();
        renderVehicles();
        renderWeathers();
    }

    function renderPlayerList() {
        const query  = document.getElementById('search-input').value.toLowerCase();
        const list   = document.getElementById('player-list');
        list.innerHTML = '';

        const filtered = state.players.filter(p =>
            p.name.toLowerCase().includes(query) ||
            (p.firstname + ' ' + p.lastname).toLowerCase().includes(query) ||
            String(p.source).includes(query)
        );

        if (filtered.length === 0) {
            list.innerHTML = '<div class="empty-state"><i class="hgi-stroke hgi-search-02"></i>Nincs találat</div>';
            return;
        }

        filtered.forEach(p => {
            const pingClass = p.ping < 80 ? 'ping-ok' : p.ping < 150 ? 'ping-mid' : 'ping-bad';
            const fullName  = (p.firstname + ' ' + p.lastname).trim() || p.name;
            const item = document.createElement('div');
            item.className = 'player-item' + (p.source === state.selectedSrc ? ' selected' : '');
            item.innerHTML = `
                <div class="pi-avatar"><i class="hgi-stroke hgi-user-circle"></i></div>
                <div class="pi-info">
                    <div class="pi-name">${fullName}</div>
                    <div class="pi-sub">ID: ${p.source} · ${p.role}</div>
                </div>
                <span class="pi-ping ${pingClass}">${p.ping}ms</span>
            `;
            item.addEventListener('click', () => selectPlayer(p.source));
            list.appendChild(item);
        });
    }

    function selectPlayer(src) {
        state.selectedSrc = src;
        renderPlayerList();
        renderPlayerDetail(src);
    }

    function renderPlayerDetail(src) {
        const p   = state.players.find(pl => pl.source === src);
        const col = document.getElementById('player-detail');
        if (!p) { col.innerHTML = '<div class="no-selection"><i class="hgi-stroke hgi-user-circle"></i><span>Játékos nem található</span></div>'; return; }

        const fullName = (p.firstname + ' ' + p.lastname).trim() || p.name;
        const food     = p.needs ? Math.round(p.needs.food)  : 100;
        const water    = p.needs ? Math.round(p.needs.water) : 100;
        const stress   = p.stress != null ? Math.round(p.stress) : 0;
        const stressColor = stress < 26 ? '#22c55e' : stress < 51 ? '#3b82f6' : stress < 76 ? '#f59e0b' : '#ef4444';
        const foodColor   = food  > 30 ? '#22c55e' : food  > 10 ? '#f59e0b' : '#ef4444';
        const waterColor  = water > 30 ? '#22c55e' : water > 10 ? '#f59e0b' : '#ef4444';

        col.innerHTML = `
            <!-- Info fejléc -->
            <div class="detail-header">
                <div class="detail-avatar"><i class="hgi-stroke hgi-user-circle"></i></div>
                <div class="detail-info">
                    <div class="detail-name">${fullName}</div>
                    <div class="detail-id">ID: ${p.source} · ${p.identifier || 'N/A'}</div>
                </div>
            </div>

            <!-- Stat csíkok -->
            <div class="server-card" style="margin-bottom:10px">
                <div class="stat-row">
                    <span class="stat-label">Éhség</span>
                    <div class="stat-track"><div class="stat-fill" style="width:${food}%;background:${foodColor}"></div></div>
                    <span class="stat-val" style="color:${foodColor}">${food}%</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Szomj</span>
                    <div class="stat-track"><div class="stat-fill" style="width:${water}%;background:${waterColor}"></div></div>
                    <span class="stat-val" style="color:${waterColor}">${water}%</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Stressz</span>
                    <div class="stat-track"><div class="stat-fill" style="width:${stress}%;background:${stressColor}"></div></div>
                    <span class="stat-val" style="color:${stressColor}">${stress}%</span>
                </div>
            </div>

            <!-- Gyors akciók -->
            <div class="action-section">
                <div class="action-section-title">Gyors akciók</div>
                <div class="action-grid">
                    <button class="action-btn success" onclick="App.revive(${src})"><i class="hgi-stroke hgi-heart-check"></i>Revive</button>
                    <button class="action-btn accent"  onclick="App.teleportTo(${src})"><i class="hgi-stroke hgi-location-04"></i>Teleport oda</button>
                    <button class="action-btn accent"  onclick="App.teleportToMe(${src})"><i class="hgi-stroke hgi-arrow-down-02"></i>Teleport ide</button>
                    <button class="action-btn"         onclick="App.spectate(${src})"><i class="hgi-stroke hgi-eye"></i>Spectate</button>
                    <button class="action-btn warning" onclick="App.freezeModal(${src})"><i class="hgi-stroke hgi-snowflake"></i>Freeze</button>
                    <button class="action-btn warning" onclick="App.godmodeModal(${src})"><i class="hgi-stroke hgi-shield-energy"></i>God mód</button>
                    <button class="action-btn danger"  onclick="App.kickModal(${src})"><i class="hgi-stroke hgi-logout-02"></i>Kick</button>
                    <button class="action-btn danger"  onclick="App.banModal(${src})"><i class="hgi-stroke hgi-ban"></i>Ban</button>
                </div>
            </div>

            <!-- Értékek szerkesztés -->
            <div class="action-section">
                <div class="action-section-title">Értékek módosítása</div>
                <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:10px;padding:14px">
                    <div class="slider-row" style="margin-bottom:8px">
                        <label style="font-size:11px;color:var(--text-m);width:70px">Éhség</label>
                        <input type="range" min="0" max="100" value="${food}" id="sl-food-${src}"
                            oninput="document.getElementById('sv-food-${src}').textContent=this.value+'%'"/>
                        <span class="slider-val" id="sv-food-${src}">${food}%</span>
                    </div>
                    <div class="slider-row" style="margin-bottom:8px">
                        <label style="font-size:11px;color:var(--text-m);width:70px">Szomj</label>
                        <input type="range" min="0" max="100" value="${water}" id="sl-water-${src}"
                            oninput="document.getElementById('sv-water-${src}').textContent=this.value+'%'"/>
                        <span class="slider-val" id="sv-water-${src}">${water}%</span>
                    </div>
                    <div class="slider-row" style="margin-bottom:12px">
                        <label style="font-size:11px;color:var(--text-m);width:70px">Stressz</label>
                        <input type="range" min="0" max="100" value="${stress}" id="sl-stress-${src}"
                            oninput="document.getElementById('sv-stress-${src}').textContent=this.value+'%'"/>
                        <span class="slider-val" id="sv-stress-${src}">${stress}%</span>
                    </div>
                    <button class="action-btn success full" onclick="App.applyValues(${src})">
                        <i class="hgi-stroke hgi-checkmark-circle-02"></i>Értékek mentése
                    </button>
                </div>
            </div>

            <!-- Karakter adatok -->
            <div class="action-section">
                <div class="action-section-title">Karakter szerkesztés</div>
                <div style="background:var(--bg-card);border:1px solid var(--border);border-radius:10px;padding:14px">
                    <div class="edit-row">
                        <label>Keresztnév</label>
                        <input class="edit-input" id="ed-fn-${src}" value="${p.firstname || ''}"/>
                    </div>
                    <div class="edit-row">
                        <label>Vezetéknév</label>
                        <input class="edit-input" id="ed-ln-${src}" value="${p.lastname || ''}"/>
                    </div>
                    <button class="action-btn accent full" style="margin-top:4px" onclick="App.savePlayerInfo(${src})">
                        <i class="hgi-stroke hgi-floppy-disk"></i>Adatok mentése
                    </button>
                </div>
            </div>
        `;
    }

    function renderVehicles() {
        const cont = document.getElementById('veh-categories');
        cont.innerHTML = '';
        (state.vehicles || []).forEach(cat => {
            const div = document.createElement('div');
            div.className = 'veh-category';
            div.innerHTML = `<div class="veh-cat-title">${cat.label}</div><div class="veh-grid" id="vg-${cat.label}"></div>`;
            cont.appendChild(div);
            const grid = div.querySelector('.veh-grid');
            cat.vehicles.forEach(model => {
                const btn = document.createElement('div');
                btn.className = 'veh-item';
                btn.textContent = model;
                btn.addEventListener('click', () => spawnVehicle(model));
                grid.appendChild(btn);
            });
        });
    }

    function renderWeathers() {
        const grid = document.getElementById('weather-grid');
        grid.innerHTML = '';
        (state.weathers || []).forEach(w => {
            const btn = document.createElement('div');
            btn.className = 'weather-item';
            btn.textContent = w;
            btn.addEventListener('click', () => {
                document.querySelectorAll('.weather-item').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                fetch(`https://fvg-admin/setWeather`, { method:'POST', body: JSON.stringify({ weather: w }) });
            });
            grid.appendChild(btn);
        });
    }

    function renderBanList() {
        const query = (document.getElementById('ban-search').value || '').toLowerCase();
        const list  = document.getElementById('ban-list');
        list.innerHTML = '';

        const filtered = state.banList.filter(b =>
            b.name.toLowerCase().includes(query) || b.identifier.toLowerCase().includes(query)
        );

        if (filtered.length === 0) {
            list.innerHTML = '<div class="empty-state"><i class="hgi-stroke hgi-information-circle"></i>Nincs aktív ban</div>';
            return;
        }

        filtered.forEach(ban => {
            const isPerm   = ban.permanent == 1;
            const expLabel = isPerm ? 'Örökre' : ban.expires_at;
            const item     = document.createElement('div');
            item.className = 'ban-item';
            item.innerHTML = `
                <div class="ban-item-info">
                    <div class="ban-item-name">${ban.name}</div>
                    <div class="ban-item-id">${ban.identifier}</div>
                    <div class="ban-item-reason">${ban.reason}</div>
                </div>
                <span class="ban-item-expiry ${isPerm ? 'ban-permanent' : 'ban-temp'}">${expLabel}</span>
                <button class="action-btn success" style="padding:7px 10px;font-size:11px" onclick="App.unban('${ban.identifier}')">
                    <i class="hgi-stroke hgi-checkmark-circle-02"></i>Felold
                </button>
            `;
            list.appendChild(item);
        });
    }

    // ── Modális ablakok ──────────────────────────────────────

    function showModal(title, bodyHTML, actions) {
        document.getElementById('modal-title').textContent = title;
        document.getElementById('modal-body').innerHTML    = bodyHTML;
        const actDiv = document.getElementById('modal-actions');
        actDiv.innerHTML = '';
        actions.forEach(a => {
            const btn = document.createElement('button');
            btn.className   = 'action-btn ' + (a.cls || '');
            btn.innerHTML   = a.label;
            btn.addEventListener('click', a.fn);
            actDiv.appendChild(btn);
        });
        document.getElementById('modal').classList.remove('hidden');
    }

    function closeModal() {
        document.getElementById('modal').classList.add('hidden');
    }

    function kickModal(src) {
        const p = state.players.find(pl => pl.source === src);
        showModal(`Kick – ${p?.name || src}`,
            `<div class="edit-row"><label>Ok</label><input class="edit-input" id="kick-reason" placeholder="Indok..." /></div>`,
            [
                { label: '<i class="hgi-stroke hgi-cancel-01"></i>Mégsem', cls: '', fn: closeModal },
                { label: '<i class="hgi-stroke hgi-logout-02"></i>Kirúgás', cls: 'danger', fn: () => {
                    const reason = document.getElementById('kick-reason').value || 'Admin által kirúgva';
                    fetch(`https://fvg-admin/kickPlayer`, { method:'POST', body: JSON.stringify({ src, reason }) });
                    closeModal();
                }}
            ]
        );
    }

    function banModal(src) {
        const p = state.players.find(pl => pl.source === src);
        const durationOpts = (state.banDurations || []).map((d, i) =>
            `<option value="${d.minutes}" ${i === 0 ? 'selected' : ''}>${d.label}</option>`
        ).join('');
        showModal(`Ban – ${p?.name || src}`,
            `<div class="edit-row"><label>Ok</label><input class="edit-input" id="ban-reason" placeholder="Indok..."/></div>
             <div class="edit-row"><label>Időtartam</label>
             <select class="edit-input" id="ban-duration">${durationOpts}</select></div>`,
            [
                { label: '<i class="hgi-stroke hgi-cancel-01"></i>Mégsem', cls: '', fn: closeModal },
                { label: '<i class="hgi-stroke hgi-ban"></i>Kitiltás', cls: 'danger', fn: () => {
                    const reason  = document.getElementById('ban-reason').value || 'Szabálysértés';
                    const minutes = parseInt(document.getElementById('ban-duration').value);
                    fetch(`https://fvg-admin/banPlayer`, { method:'POST', body: JSON.stringify({ src, reason, minutes }) });
                    closeModal();
                }}
            ]
        );
    }

    function freezeModal(src) {
        showModal('Freeze / Unfreeze',
            `<p style="font-size:13px;color:var(--text-s)">Lefagyasszuk vagy felengedjük a játékost?</p>`,
            [
                { label: '<i class="hgi-stroke hgi-cancel-01"></i>Mégsem', cls: '', fn: closeModal },
                { label: '<i class="hgi-stroke hgi-play"></i>Felengesztés', cls: 'success', fn: () => {
                    fetch(`https://fvg-admin/freezePlayer`, { method:'POST', body: JSON.stringify({ src, state: false }) });
                    closeModal();
                }},
                { label: '<i class="hgi-stroke hgi-snowflake"></i>Freeze', cls: 'warning', fn: () => {
                    fetch(`https://fvg-admin/freezePlayer`, { method:'POST', body: JSON.stringify({ src, state: true }) });
                    closeModal();
                }},
            ]
        );
    }

    function godmodeModal(src) {
        showModal('God mód',
            `<p style="font-size:13px;color:var(--text-s)">God módot bekapcsoljuk vagy kikapcsoljuk?</p>`,
            [
                { label: '<i class="hgi-stroke hgi-cancel-01"></i>Mégsem', cls: '', fn: closeModal },
                { label: '<i class="hgi-stroke hgi-shield-energy"></i>Be', cls: 'success', fn: () => {
                    fetch(`https://fvg-admin/setGodmode`, { method:'POST', body: JSON.stringify({ src, state: true }) });
                    closeModal();
                }},
                { label: '<i class="hgi-stroke hgi-shield-off"></i>Ki', cls: 'warning', fn: () => {
                    fetch(`https://fvg-admin/setGodmode`, { method:'POST', body: JSON.stringify({ src, state: false }) });
                    closeModal();
                }},
            ]
        );
    }

    // ── Nyilvános akció metódusok ────────────────────────────

    function revive(src) {
        fetch(`https://fvg-admin/revivePlayer`, { method:'POST', body: JSON.stringify({ src }) });
    }
    function teleportTo(src) {
        fetch(`https://fvg-admin/teleportTo`, { method:'POST', body: JSON.stringify({ src }) });
    }
    function teleportToMe(src) {
        fetch(`https://fvg-admin/teleportToMe`, { method:'POST', body: JSON.stringify({ src }) });
    }
    function spectate(src) {
        fetch(`https://fvg-admin/spectatePlayer`, { method:'POST', body: JSON.stringify({ src }) });
    }
    function applyValues(src) {
        const food   = parseInt(document.getElementById('sl-food-' + src)?.value  || 100);
        const water  = parseInt(document.getElementById('sl-water-' + src)?.value || 100);
        const stress = parseInt(document.getElementById('sl-stress-' + src)?.value || 0);
        fetch(`https://fvg-admin/setNeeds`,  { method:'POST', body: JSON.stringify({ src, food, water }) });
        fetch(`https://fvg-admin/setStress`, { method:'POST', body: JSON.stringify({ src, stress }) });
    }
    function savePlayerInfo(src) {
        const firstname = document.getElementById('ed-fn-' + src)?.value || '';
        const lastname  = document.getElementById('ed-ln-' + src)?.value || '';
        fetch(`https://fvg-admin/setPlayerInfo`, { method:'POST', body: JSON.stringify({ src, firstname, lastname }) });
    }
    function spawnVehicle(model) {
        fetch(`https://fvg-admin/spawnVehicle`, { method:'POST', body: JSON.stringify({ model }) });
    }
    function deleteVehicle() {
        fetch(`https://fvg-admin/deleteVehicle`, { method:'POST', body: JSON.stringify({}) });
    }
    function fixVehicle() {
        fetch(`https://fvg-admin/fixVehicle`, { method:'POST', body: JSON.stringify({}) });
    }
    function setTime() {
        const hour   = document.getElementById('time-hour').value;
        const minute = document.getElementById('time-minute').value;
        fetch(`https://fvg-admin/setTime`, { method:'POST', body: JSON.stringify({ hour: parseInt(hour), minute: parseInt(minute) }) });
    }
    function announce() {
        const msg = document.getElementById('announce-input').value;
        if (!msg.trim()) return;
        fetch(`https://fvg-admin/announce`, { method:'POST', body: JSON.stringify({ message: msg }) });
        document.getElementById('announce-input').value = '';
    }
    function toggleNoclip() {
        state.noclipOn = !state.noclipOn;
        const btn = document.getElementById('noclip-btn');
        btn.classList.toggle('active', state.noclipOn);
        btn.innerHTML = `<i class="hgi-stroke hgi-fly"></i>Noclip ${state.noclipOn ? 'kikapcsolás' : 'bekapcsolás'}`;
        fetch(`https://fvg-admin/toggleNoclip`, { method:'POST', body: JSON.stringify({ state: state.noclipOn }) });
    }
    function getBanList() {
        fetch(`https://fvg-admin/getBanList`, { method:'POST', body: JSON.stringify({}) });
    }
    function filterBans() {
        renderBanList();
    }
    function unban(identifier) {
        fetch(`https://fvg-admin/unbanPlayer`, { method:'POST', body: JSON.stringify({ identifier }) });
        state.banList = state.banList.filter(b => b.identifier !== identifier);
        renderBanList();
    }

    // ── Publikus interface ───────────────────────────────────
    return {
        revive, teleportTo, teleportToMe, spectate,
        applyValues, savePlayerInfo, spawnVehicle,
        deleteVehicle, fixVehicle, setTime, announce,
        toggleNoclip, getBanList, filterBans, unban,
        kickModal, banModal, freezeModal, godmodeModal,
        closeModal,
    };
})();