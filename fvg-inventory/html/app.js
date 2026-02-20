const Inv = (() => {
    let slots      = [];
    let maxSlots   = 40;
    let maxWeight  = 30.0;
    let currentWeight = 0.0;
    let categories = [];
    let activeCategory = 'all';
    let selectedSlot   = null;
    let dragSlot       = null;
    let amountCallback = null;

    const itemIconMap = {
        food:     'hgi-stroke hgi-hamburger-01',
        medical:  'hgi-stroke hgi-heart-add',
        weapon:   'hgi-stroke hgi-sword-02',
        tool:     'hgi-stroke hgi-wrench-01',
        material: 'hgi-stroke hgi-cube-01',
        drug:     'hgi-stroke hgi-pill',
        misc:     'hgi-stroke hgi-package',
    };

    const catColors = {
        food:'#22c55e', medical:'#ef4444', weapon:'#f59e0b',
        tool:'#38bdf8', material:'#a78bfa', drug:'#ec4899', misc:'#94a3b8',
    };

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;
        if (action === 'open') {
            slots      = e.data.slots      || [];
            maxSlots   = e.data.maxSlots   || 40;
            maxWeight  = e.data.maxWeight  || 30;
            currentWeight = e.data.weight  || 0;
            categories = e.data.categories || [];
            buildCategoryBar();
            renderGrid();
            renderHotbar();
            updateWeight(currentWeight, maxWeight);
            document.getElementById('overlay').classList.remove('hidden');
        }
        if (action === 'syncSlots') {
            slots = e.data.slots || [];
            currentWeight = e.data.weight || 0;
            renderGrid();
            renderHotbar();
            updateWeight(currentWeight, e.data.maxWeight || maxWeight);
        }
    });

    // ── Súlysáv frissítés ────────────────────────────────────
    function updateWeight(weight, max) {
        const pct  = Math.min((weight / max) * 100, 100);
        const fill = document.getElementById('weight-fill');
        const lbl  = document.getElementById('weight-label');
        fill.style.width = pct + '%';
        fill.className   = 'inv-weight-fill' + (pct >= 100 ? ' overload' : pct >= 75 ? ' heavy' : '');
        lbl.textContent  = weight.toFixed(1) + ' / ' + max.toFixed(1) + ' kg';
    }

    // ── Kategória sáv ────────────────────────────────────────
    function buildCategoryBar() {
        const bar = document.getElementById('cat-bar');
        bar.innerHTML = '';
        categories.forEach(cat => {
            const btn = document.createElement('button');
            btn.className = 'cat-btn' + (cat.id === activeCategory ? ' active' : '');
            btn.innerHTML = `<i class="${cat.icon}"></i>${cat.label}`;
            btn.addEventListener('click', () => {
                activeCategory = cat.id;
                bar.querySelectorAll('.cat-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                renderGrid();
            });
            bar.appendChild(btn);
        });
    }

    // ── Slot grid renderelés ──────────────────────────────────
    function renderGrid() {
        const grid = document.getElementById('inv-grid');
        grid.innerHTML = '';

        const slotMap = {};
        slots.forEach(s => { slotMap[s.slot] = s; });

        const filteredSlots = activeCategory === 'all'
            ? slots
            : slots.filter(s => s.category === activeCategory);
        const filteredSlotNums = new Set(filteredSlots.map(s => s.slot));

        for (let i = 1; i <= maxSlots; i++) {
            // Szűrés esetén üres slotokat nem jelenítjük meg
            if (activeCategory !== 'all' && !filteredSlotNums.has(i) && !slotMap[i]) continue;
            if (activeCategory !== 'all' && slotMap[i] && slotMap[i].category !== activeCategory) continue;

            const item = slotMap[i] || null;
            grid.appendChild(buildSlot(i, item));
        }
    }

    function buildSlot(slotNum, item) {
        const el = document.createElement('div');
        el.className  = 'slot' + (item ? ` cat-dot-${item.category || 'misc'}` : ' empty');
        el.dataset.slot = slotNum;

        if (item) {
            // Ikon
            const iconClass = itemIconMap[item.category] || 'hgi-stroke hgi-package';
            el.innerHTML = `
                <div class="slot-icon"><i class="${iconClass}"></i></div>
                <span class="slot-amount">${item.amount > 1 ? 'x' + item.amount : ''}</span>
                ${item.usable ? '<span class="slot-usable"></span>' : ''}
            `;
            el.classList.add(item.usable ? 'slot-usable-border' : '');

            // Drag
            el.draggable = true;
            el.addEventListener('dragstart', () => { dragSlot = slotNum; });
            el.addEventListener('dragend',   () => { dragSlot = null; document.querySelectorAll('.drag-over').forEach(s => s.classList.remove('drag-over')); });

            // Kattintás – jobb klikk kontextus
            el.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                showContextMenu(e.clientX, e.clientY, slotNum, item);
            });

            // Bal klikk – tooltip
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                selectedSlot = slotNum;
                showTooltip(e, slotNum, item);
            });
        }

        // Drop zóna
        el.addEventListener('dragover', (e) => { e.preventDefault(); el.classList.add('drag-over'); });
        el.addEventListener('dragleave', () => el.classList.remove('drag-over'));
        el.addEventListener('drop', (e) => {
            e.preventDefault();
            el.classList.remove('drag-over');
            if (dragSlot && dragSlot !== slotNum) {
                fetch(`https://fvg-inventory/moveSlot`, {
                    method: 'POST',
                    body: JSON.stringify({ from: dragSlot, to: slotNum })
                });
            }
        });

        return el;
    }

    // ── Hotbar ───────────────────────────────────────────────
    function renderHotbar() {
        const hb = document.getElementById('hotbar');
        hb.innerHTML = '';
        const slotMap = {};
        slots.forEach(s => { slotMap[s.slot] = s; });

        // Gyorssáv az első N slot
        for (let i = 1; i <= 5; i++) {
            const item  = slotMap[i] || null;
            const el    = document.createElement('div');
            el.className = 'hotbar-slot';
            el.innerHTML = `<span class="hk-label">${i}</span>`;
            if (item) {
                const iconClass = itemIconMap[item.category] || 'hgi-stroke hgi-package';
                el.innerHTML += `<i class="${iconClass}" style="font-size:22px;color:var(--text-m)"></i>`;
            }
            hb.appendChild(el);
        }
    }

    // ── Tooltip ──────────────────────────────────────────────
    let tooltipVisible = false;
    function showTooltip(e, slotNum, item) {
        const tt = document.getElementById('tooltip');
        document.getElementById('tt-name').textContent   = item.label;
        document.getElementById('tt-cat').textContent    = categoryLabel(item.category);
        document.getElementById('tt-weight').textContent = `Súly: ${(item.weight * item.amount).toFixed(2)} kg`;

        // Metadata
        const metaEl = document.getElementById('tt-meta');
        const meta   = item.metadata || {};
        const metaStr = Object.keys(meta).length
            ? Object.entries(meta).map(([k,v]) => `${k}: ${v}`).join(' · ')
            : '';
        metaEl.textContent = metaStr;
        metaEl.style.display = metaStr ? 'block' : 'none';

        // Akciók
        const actEl = document.getElementById('tt-actions');
        actEl.innerHTML = '';
        if (item.usable) {
            const btn = document.createElement('button');
            btn.className = 'tt-action-btn use';
            btn.innerHTML = `<i class="hgi-stroke hgi-play-circle-02"></i>Használat`;
            btn.addEventListener('click', () => { hideTooltip(); useItem(slotNum); });
            actEl.appendChild(btn);
        }
        const dropBtn = document.createElement('button');
        dropBtn.className = 'tt-action-btn drop';
        dropBtn.innerHTML = `<i class="hgi-stroke hgi-delete-02"></i>Eldobás`;
        dropBtn.addEventListener('click', () => { hideTooltip(); showAmountModal('Eldobás mennyisége', item.amount, (amt) => dropItem(slotNum, amt)); });
        actEl.appendChild(dropBtn);

        // Pozíció
        tt.classList.remove('hidden');
        tooltipVisible = true;
        const x = Math.min(e.clientX + 12, window.innerWidth  - 200);
        const y = Math.min(e.clientY + 12, window.innerHeight - 200);
        tt.style.left = x + 'px';
        tt.style.top  = y + 'px';
    }

    function hideTooltip() {
        document.getElementById('tooltip').classList.add('hidden');
        tooltipVisible = false;
        selectedSlot   = null;
    }

    // ── Kontextus menü ───────────────────────────────────────
    function showContextMenu(x, y, slotNum, item) {
        const menu = document.getElementById('ctx-menu');
        menu.innerHTML = '';

        if (item.usable) {
            addCtxItem(menu, 'hgi-stroke hgi-play-circle-02', 'Használat', 'use', () => useItem(slotNum));
        }
        addCtxItem(menu, 'hgi-stroke hgi-delete-02', 'Eldobás', 'drop', () => {
            showAmountModal('Eldobás mennyisége', item.amount, (amt) => dropItem(slotNum, amt));
        });
        addCtxItem(menu, 'hgi-stroke hgi-information-circle', 'Részletek', '', () => {});

        menu.style.left = Math.min(x, window.innerWidth  - 180) + 'px';
        menu.style.top  = Math.min(y, window.innerHeight - 160) + 'px';
        menu.classList.remove('hidden');
    }

    function addCtxItem(menu, icon, label, cls, cb) {
        const item = document.createElement('div');
        item.className = 'ctx-item ' + cls;
        item.innerHTML = `<i class="${icon}"></i>${label}`;
        item.addEventListener('click', () => { menu.classList.add('hidden'); cb(); });
        menu.appendChild(item);
    }

    // ── Mennyiség modal ──────────────────────────────────────
    function showAmountModal(title, max, callback) {
        amountCallback = callback;
        document.getElementById('am-title').textContent = title;
        const inp = document.getElementById('am-input');
        inp.max   = max;
        inp.value = max;
        document.getElementById('am-confirm').onclick = () => {
            const val = Math.min(Math.max(parseInt(inp.value) || 1, 1), max);
            closeAmountModal();
            callback(val);
        };
        document.getElementById('amount-modal').classList.remove('hidden');
    }

    function closeAmountModal() {
        document.getElementById('amount-modal').classList.add('hidden');
        amountCallback = null;
    }

    // ── Akciók ──────────────────────────────────────────────
    function useItem(slotNum) {
        fetch(`https://fvg-inventory/useItem`, { method: 'POST', body: JSON.stringify({ slot: slotNum }) });
    }

    function dropItem(slotNum, amount) {
        fetch(`https://fvg-inventory/dropItem`, { method: 'POST', body: JSON.stringify({ slot: slotNum, amount }) });
    }

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('btn-close').addEventListener('click', close);

    function close() {
        document.getElementById('overlay').classList.add('hidden');
        document.getElementById('ctx-menu').classList.add('hidden');
        hideTooltip();
        fetch(`https://fvg-inventory/close`, { method: 'POST', body: JSON.stringify({}) });
    }

    // Klikk a panelen kívül → tooltip/ctx bezárás
    document.addEventListener('click', (e) => {
        if (!e.target.closest('#tooltip') && tooltipVisible) hideTooltip();
        if (!e.target.closest('#ctx-menu')) document.getElementById('ctx-menu').classList.add('hidden');
    });

    document.addEventListener('contextmenu', (e) => {
        if (!e.target.closest('.slot')) document.getElementById('ctx-menu').classList.add('hidden');
    });

    // ESC → bezárás
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') close();
    });

    // ── Segéd ────────────────────────────────────────────────
    function categoryLabel(cat) {
        const map = { food:'Élelmiszer', medical:'Orvosi', weapon:'Fegyver', tool:'Szerszám', material:'Anyag', drug:'Kábítószer', misc:'Egyéb' };
        return map[cat] || cat;
    }

    return { closeAmountModal };
})();