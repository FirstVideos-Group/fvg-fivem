const Autoshop = (() => {
    let state = {
        dealershipId    : null,
        dealerLabel     : '',
        vehicles        : [],
        categories      : {},
        cashBalance     : 0,
        bankBalance     : 0,
        ownedVehicles   : [],
        instalments     : [],
        instalmentOptions:[],
        enableInstalments: true,
        allowBank       : true,
        allowCash       : true,
        sellBackPct     : 0.65,
        downPaymentPct  : 0.20,
        discount        : null,
        spawnPoint      : null,
        testDriveTime   : 180,
        // Modal állapot
        modalVehicle    : null,
        paymentMethod   : 'cash',
        instalmentOption: null,
        activeCategory  : 'all',
    };

    const fmt = (n) => '$' + Number(n).toLocaleString('hu-HU');
    const pad = (n) => String(n).padStart(2, '0');
    const fmtTime = (s) => pad(Math.floor(s / 60)) + ':' + pad(s % 60);

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'open') {
            const p = e.data.payload;
            Object.assign(state, {
                dealershipId    : p.dealershipId,
                dealerLabel     : p.dealerLabel,
                vehicles        : p.vehicles || [],
                categories      : p.categories || {},
                cashBalance     : p.cashBalance || 0,
                bankBalance     : p.bankBalance || 0,
                ownedVehicles   : p.ownedVehicles || [],
                instalments     : p.instalments || [],
                instalmentOptions: p.instalmentOptions || [],
                enableInstalments: p.enableInstalments !== false,
                allowBank       : p.allowBank !== false,
                allowCash       : p.allowCash !== false,
                sellBackPct     : p.sellBackPct || 0.65,
                downPaymentPct  : p.downPaymentPct || 0.20,
                discount        : p.discount || null,
                spawnPoint      : p.spawnPoint,
                testDriveTime   : p.testDriveTime || 180,
                activeCategory  : 'all',
                paymentMethod   : 'cash',
            });
            render();
            activateTab('browse');
            document.getElementById('overlay').classList.remove('hidden');
        }

        if (action === 'purchaseSuccess') {
            closeModal();
            document.getElementById('overlay').classList.add('hidden');
        }

        if (action === 'sellSuccess') {
            state.ownedVehicles = state.ownedVehicles.filter(v => v.plate !== e.data.data.plate);
            renderOwned();
        }

        if (action === 'instalmentPaid') {
            const d = e.data.data;
            if (d.done) {
                state.instalments = state.instalments.filter(i => true);
            }
            renderInstalments();
        }

        if (action === 'testDriveStarted') {
            document.getElementById('testdrive-hud').classList.remove('hidden');
            updateTDTimer(e.data.timeLeft);
        }

        if (action === 'testDriveTick') {
            updateTDTimer(e.data.timeLeft);
        }

        if (action === 'testDriveEnded') {
            document.getElementById('testdrive-hud').classList.add('hidden');
        }
    });

    // ── Render fő ────────────────────────────────────────────
    function render() {
        document.getElementById('ph-title').textContent = state.dealerLabel;
        document.getElementById('ph-sub').textContent   = state.vehicles.length + ' jármű elérhető';
        document.getElementById('chip-cash').textContent= fmt(state.cashBalance);
        document.getElementById('chip-bank').textContent= fmt(state.bankBalance);

        renderCategories();
        renderVehicles();
        renderOwned();
        renderInstalments();
    }

    // ── Tab kezelés ──────────────────────────────────────────
    document.querySelectorAll('.tab').forEach(t =>
        t.addEventListener('click', () => activateTab(t.dataset.tab))
    );
    function activateTab(id) {
        document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === id));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.toggle('active', c.id === 'tab-' + id));
    }

    // ── Kategóriák ───────────────────────────────────────────
    function renderCategories() {
        const scroller = document.getElementById('cat-scroller');
        scroller.innerHTML = '';

        const allBtn  = document.createElement('button');
        allBtn.className  = 'cat-btn' + (state.activeCategory === 'all' ? ' active' : '');
        allBtn.innerHTML  = '<i class="hgi-stroke hgi-grid-view"></i>Mind';
        allBtn.onclick    = () => { state.activeCategory = 'all'; renderCategories(); renderVehicles(); };
        scroller.appendChild(allBtn);

        const usedCats = [...new Set(state.vehicles.map(v => v.category))];
        usedCats.forEach(catKey => {
            const cat = state.categories[catKey];
            if (!cat) return;
            const btn     = document.createElement('button');
            btn.className = 'cat-btn' + (state.activeCategory === catKey ? ' active' : '');
            btn.innerHTML = `<i class="${cat.icon}"></i>${cat.label}`;
            btn.onclick   = () => { state.activeCategory = catKey; renderCategories(); renderVehicles(); };
            scroller.appendChild(btn);
        });
    }

    // ── Jármű lista ──────────────────────────────────────────
    function renderVehicles() {
        const list   = document.getElementById('vehicle-list');
        const query  = document.getElementById('veh-search').value.toLowerCase();
        const sort   = document.getElementById('sort-select').value;

        let filtered = state.vehicles.filter(v => {
            const catOk   = state.activeCategory === 'all' || v.category === state.activeCategory;
            const queryOk = !query || v.label.toLowerCase().includes(query) || v.model.toLowerCase().includes(query);
            return catOk && queryOk;
        });

        filtered.sort((a, b) => {
            if (sort === 'price_asc')  return a.price - b.price;
            if (sort === 'price_desc') return b.price - a.price;
            if (sort === 'speed')      return (b.stats?.speed || 0) - (a.stats?.speed || 0);
            if (sort === 'name')       return a.label.localeCompare(b.label);
            return 0;
        });

        list.innerHTML = '';
        if (!filtered.length) {
            list.innerHTML = `<div class="empty-state"><i class="hgi-stroke hgi-car-01"></i><span>Nincs találat</span></div>`;
            return;
        }

        filtered.forEach(veh => {
            const catDef = state.categories[veh.category] || {};
            const el     = document.createElement('div');
            el.className = 'vehicle-card';

            const origPrice = veh.origPrice && veh.origPrice !== veh.price
                ? `<div class="vc-orig">${fmt(veh.origPrice)}</div>` : '';
            const discBadge = state.discount
                ? `<span class="discount-badge">-${Math.round((1 - state.discount) * 100)}%</span>` : '';

            el.innerHTML = `
                <div class="vc-icon"><i class="${catDef.icon || 'hgi-stroke hgi-car-01'}"></i></div>
                <div class="vc-info">
                    <div class="vc-name">${veh.label} ${discBadge}</div>
                    <div class="vc-cat">${catDef.label || veh.category}</div>
                    <div class="vc-desc">${veh.description || ''}</div>
                </div>
                <div class="vc-stats">
                    ${renderStatBar('Sebesség', 'speed', veh.stats?.speed || 0)}
                    ${renderStatBar('Kezelés', 'handling', veh.stats?.handling || 0)}
                    ${renderStatBar('Fékezés', 'braking', veh.stats?.braking || 0)}
                    ${renderStatBar('Gyorsulás', 'acceleration', veh.stats?.acceleration || 0)}
                </div>
                <div class="vc-right">
                    ${origPrice}
                    <div class="vc-price">${fmt(veh.price)}</div>
                    <div class="vc-actions">
                        <button class="vc-btn test-btn">
                            <i class="hgi-stroke hgi-steering-wheel"></i>Teszt
                        </button>
                        <button class="vc-btn buy-btn">
                            <i class="hgi-stroke hgi-shopping-cart-02"></i>Venni
                        </button>
                    </div>
                </div>
            `;

            el.querySelector('.test-btn').addEventListener('click', (ev) => {
                ev.stopPropagation();
                startTestDrive(veh);
            });
            el.querySelector('.buy-btn').addEventListener('click', (ev) => {
                ev.stopPropagation();
                openBuyModal(veh);
            });

            list.appendChild(el);
        });
    }

    function renderStatBar(label, cls, val) {
        return `
            <div class="stat-row">
                <div class="stat-row-label">${label}</div>
                <div class="stat-bar"><div class="stat-fill ${cls}" style="width:${val}%"></div></div>
                <div class="stat-val">${val}</div>
            </div>
        `;
    }

    // ── Keresés + rendezés ───────────────────────────────────
    document.getElementById('veh-search').addEventListener('input', renderVehicles);
    document.getElementById('sort-select').addEventListener('change', renderVehicles);

    // ── Saját járművek ───────────────────────────────────────
    function renderOwned() {
        const list = document.getElementById('owned-list');
        if (!state.ownedVehicles.length) {
            list.innerHTML = `<div class="empty-state"><i class="hgi-stroke hgi-garage"></i><span>Nincs saját járműved</span></div>`;
            return;
        }
        list.innerHTML = '';
        state.ownedVehicles.forEach(veh => {
            const catDef   = state.categories[veh.category] || {};
            const sellPrice= Math.floor((veh.price || 0) * state.sellBackPct);
            const hasInst  = veh.inst_status === 'active';
            const el       = document.createElement('div');
            el.className   = 'owned-card';
            el.innerHTML   = `
                <div class="oc-icon"><i class="${catDef.icon || 'hgi-stroke hgi-car-01'}"></i></div>
                <div class="oc-info">
                    <div class="oc-name">${veh.label}</div>
                    <div class="oc-plate">${veh.plate}</div>
                    <div class="oc-cat">${catDef.label || veh.category}</div>
                </div>
                <div class="oc-right">
                    <div class="oc-price">Vételár: ${fmt(veh.price || 0)}</div>
                    <div class="oc-sell-price">${fmt(sellPrice)}</div>
                    ${hasInst ? '<div class="oc-inst"><i class="hgi-stroke hgi-credit-card"></i> Aktív részlet</div>' : ''}
                    <button class="sell-btn" ${hasInst ? 'disabled title="Részlet miatt nem adható el"' : ''}>
                        <i class="hgi-stroke hgi-money-send-02"></i>Eladás
                    </button>
                </div>
            `;
            if (!hasInst) {
                el.querySelector('.sell-btn').addEventListener('click', () => {
                    if (confirm('Biztosan eladod? Visszaváltási ár: ' + fmt(sellPrice))) {
                        fetch('https://fvg-autoshop/sellVehicle', {
                            method: 'POST', body: JSON.stringify({ plate: veh.plate })
                        });
                    }
                });
            }
            list.appendChild(el);
        });
    }

    // ── Részletek ────────────────────────────────────────────
    function renderInstalments() {
        const list = document.getElementById('inst-list');
        if (!state.instalments.length) {
            list.innerHTML = `<div class="empty-state"><i class="hgi-stroke hgi-credit-card"></i><span>Nincs aktív részletfizetés</span></div>`;
            return;
        }
        list.innerHTML = '';
        state.instalments.forEach(inst => {
            const pct    = Math.round((inst.months_paid / inst.months_total) * 100);
            const el     = document.createElement('div');
            el.className = 'inst-card';
            el.innerHTML = `
                <div class="ic-header">
                    <div class="ic-icon"><i class="hgi-stroke hgi-car-01"></i></div>
                    <div>
                        <div class="ic-name">${inst.label}</div>
                        <div class="ic-plate">${inst.plate}</div>
                    </div>
                </div>
                <div class="inst-progress">
                    <div class="ip-bar"><div class="ip-fill" style="width:${pct}%"></div></div>
                    <div class="ip-labels">
                        <span>${inst.months_paid} / ${inst.months_total} hónap</span>
                        <span>${pct}%</span>
                    </div>
                </div>
                <div class="inst-details">
                    <div class="id-item">
                        <div class="id-label">Havi törlesztő</div>
                        <div class="id-val" style="color:var(--purple)">${fmt(inst.monthly_amount)}</div>
                    </div>
                    <div class="id-item">
                        <div class="id-label">Fizetve</div>
                        <div class="id-val" style="color:var(--success)">${fmt(inst.paid_amount)}</div>
                    </div>
                    <div class="id-item">
                        <div class="id-label">Maradék</div>
                        <div class="id-val" style="color:var(--danger)">${fmt(inst.total_amount - inst.paid_amount)}</div>
                    </div>
                </div>
                <button class="pay-inst-btn" data-id="${inst.vehicle_id}">
                    <i class="hgi-stroke hgi-credit-card"></i>Havi törlesztő fizetése – ${fmt(inst.monthly_amount)}
                </button>
            `;
            el.querySelector('.pay-inst-btn').addEventListener('click', () => {
                fetch('https://fvg-autoshop/payInstalment', {
                    method: 'POST',
                    body: JSON.stringify({ vehicleId: inst.vehicle_id, paymentMethod: state.paymentMethod })
                });
            });
            list.appendChild(el);
        });
    }

    // ── Vásárlás modal ───────────────────────────────────────
    function openBuyModal(veh) {
        state.modalVehicle   = veh;
        state.paymentMethod  = state.allowCash ? 'cash' : 'bank';
        state.instalmentOption = null;
        renderBuyModal();
        document.getElementById('bm-title').textContent = veh.label + ' megvásárlása';
        document.getElementById('buy-modal').classList.remove('hidden');
    }

    function renderBuyModal() {
        const veh  = state.modalVehicle;
        const body = document.getElementById('bm-body');
        const catDef = state.categories[veh.category] || {};

        const downPayment = Math.floor(veh.price * state.downPaymentPct);
        const instOptHTML = state.enableInstalments ? `
            <div class="id-label" style="font-size:10px;font-weight:700;color:var(--text-m);text-transform:uppercase;letter-spacing:.08em;">
                Részletfizetési opciók
            </div>
            <div class="inst-selector" id="inst-selector">
                <div class="inst-opt ${state.instalmentOption === null ? '' : ''}" data-opt="" onclick="Autoshop.selectInstalment(null)">
                    <i class="hgi-stroke hgi-money-bag-02" style="color:var(--success)"></i>
                    <div class="inst-opt-info">
                        <div class="inst-opt-label">Teljes fizetés</div>
                        <div class="inst-opt-sub">Nincs kamat, azonnali</div>
                    </div>
                    <div class="inst-opt-monthly" style="color:var(--success)">${fmt(veh.price)}</div>
                </div>
                ${state.instalmentOptions.map((opt, i) => {
                    const total   = Math.floor((veh.price - downPayment) * (1 + opt.interestRate));
                    const monthly = Math.ceil(total / opt.months);
                    return `
                        <div class="inst-opt" data-opt="${i+1}" onclick="Autoshop.selectInstalment(${i+1})">
                            <i class="hgi-stroke hgi-credit-card" style="color:var(--purple)"></i>
                            <div class="inst-opt-info">
                                <div class="inst-opt-label">${opt.months} hónapos részlet</div>
                                <div class="inst-opt-sub">${opt.interestRate > 0 ? opt.interestRate * 100 + '% kamat' : 'Kamatmentes'} · Foglalón: ${fmt(downPayment)}</div>
                            </div>
                            <div class="inst-opt-monthly">${fmt(monthly)}/hó</div>
                        </div>
                    `;
                }).join('')}
            </div>
            <div class="down-payment-row" id="down-row" style="${state.instalmentOption === null ? 'display:none' : ''}">
                <span>Szükséges foglalón:</span>
                <strong>${fmt(downPayment)}</strong>
            </div>
        ` : '';

        body.innerHTML = `
            <div class="bm-veh-row">
                <div class="bm-veh-icon"><i class="${catDef.icon || 'hgi-stroke hgi-car-01'}"></i></div>
                <div>
                    <div class="bm-veh-name">${veh.label}</div>
                    <div class="bm-veh-price">${fmt(veh.price)}</div>
                </div>
            </div>
            <div class="id-label" style="font-size:10px;font-weight:700;color:var(--text-m);text-transform:uppercase;letter-spacing:.08em;">
                Fizetési mód
            </div>
            <div class="pay-selector">
                ${state.allowCash ? `
                <div class="pay-opt ${state.paymentMethod === 'cash' ? 'active' : ''}" onclick="Autoshop.setPayment('cash')">
                    <i class="hgi-stroke hgi-money-bag-02"></i>
                    <span>Készpénz</span>
                    <strong style="color:var(--warning)">${fmt(state.cashBalance)}</strong>
                </div>` : ''}
                ${state.allowBank ? `
                <div class="pay-opt ${state.paymentMethod === 'bank' ? 'active' : ''}" onclick="Autoshop.setPayment('bank')">
                    <i class="hgi-stroke hgi-bank"></i>
                    <span>Bankszámla</span>
                    <strong style="color:var(--accent)">${fmt(state.bankBalance)}</strong>
                </div>` : ''}
            </div>
            ${instOptHTML}
            <div class="info-row">
                <i class="hgi-stroke hgi-information-circle"></i>
                <span>A vásárlás után a jármű a garázs-rendszerben lesz elérhető.</span>
            </div>
        `;

        updateInstSelection();

        document.getElementById('bm-confirm').onclick = confirmBuy;
    }

    function updateInstSelection() {
        document.querySelectorAll('.inst-opt').forEach(el => {
            const opt = el.dataset.opt;
            el.classList.toggle('active',
                opt === '' ? state.instalmentOption === null : parseInt(opt) === state.instalmentOption
            );
        });
        const downRow = document.getElementById('down-row');
        if (downRow) downRow.style.display = state.instalmentOption === null ? 'none' : 'flex';
    }

    function selectInstalment(opt) {
        state.instalmentOption = opt;
        updateInstSelection();
    }

    function setPayment(method) {
        state.paymentMethod = method;
        renderBuyModal();
    }

    function confirmBuy() {
        const veh = state.modalVehicle;
        if (!veh) return;
        fetch('https://fvg-autoshop/buyVehicle', {
            method: 'POST',
            body: JSON.stringify({
                model           : veh.model,
                dealershipId    : state.dealershipId,
                paymentMethod   : state.paymentMethod,
                instalmentOption: state.instalmentOption,
            })
        });
    }

    function closeModal() {
        document.getElementById('buy-modal').classList.add('hidden');
        state.modalVehicle    = null;
        state.instalmentOption= null;
    }

    // ── Tesztvezetés ─────────────────────────────────────────
    function startTestDrive(veh) {
        fetch('https://fvg-autoshop/testDrive', {
            method: 'POST',
            body: JSON.stringify({
                model      : veh.model,
                spawnPoint : state.spawnPoint,
                timeLimit  : state.testDriveTime,
            })
        });
        document.getElementById('overlay').classList.add('hidden');
    }

    function endTestDrive() {
        fetch('https://fvg-autoshop/endTestDrive', {
            method: 'POST', body: JSON.stringify({})
        });
    }

    function updateTDTimer(timeLeft) {
        const el  = document.getElementById('td-timer');
        el.textContent = fmtTime(timeLeft);
        el.classList.toggle('urgent', timeLeft < 30);
    }

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', close);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
    function close() {
        document.getElementById('overlay').classList.add('hidden');
        closeModal();
        fetch('https://fvg-autoshop/close', { method: 'POST', body: JSON.stringify({}) });
    }

    return { selectInstalment, setPayment, closeModal, endTestDrive };
})();