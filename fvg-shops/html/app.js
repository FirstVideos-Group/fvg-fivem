const Shop = (() => {
    let state = {
        shopId       : null,
        shopLabel    : '',
        items        : [],
        categories   : {},
        paymentMethod: 'cash',
        allowedPay   : 'both',
        cashBalance  : 0,
        bankBalance  : 0,
        activeCategory: 'all',
        cart         : {},   // itemName → qty
        stock        : {},   // itemName → currentStock
        modalItem    : null,
        modalQty     : 1,
    };

    const fmt    = (n) => '$' + Number(n).toLocaleString('hu-HU');
    const fmtNum = (n) => Number(n).toLocaleString('hu-HU');

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'open') {
            const p        = e.data.payload;
            state.shopId   = p.shopId;
            state.shopLabel= p.shopLabel;
            state.items    = p.items || [];
            state.categories = p.categories || {};
            state.allowedPay = p.paymentMethod || 'both';
            state.cashBalance= p.cashBalance || 0;
            state.bankBalance= p.bankBalance || 0;
            state.cart     = {};
            state.activeCategory = 'all';

            // Stock feltöltés
            state.stock = {};
            state.items.forEach(item => {
                state.stock[item.item] = item.stock;
            });

            // Alapértelmezett fizetési mód
            if (state.allowedPay === 'cash')  state.paymentMethod = 'cash';
            if (state.allowedPay === 'bank')  state.paymentMethod = 'bank';
            if (state.allowedPay === 'both')  state.paymentMethod = 'cash';

            render();
            document.getElementById('overlay').classList.remove('hidden');
        }

        if (action === 'stockUpdate') {
            state.stock[e.data.item] = e.data.stock;
            updateItemCard(e.data.item);
        }

        if (action === 'stockSync') {
            Object.assign(state.stock, e.data.stock);
            renderItems();
        }

        if (action === 'purchaseSuccess') {
            const d = e.data.data;
            showToast(`${d.label} x${d.quantity} – ${fmt(d.total)}`, d.payment);
            renderCartBar();
        }
    });

    // ── Render ───────────────────────────────────────────────
    function render() {
        renderHeader();
        renderCategories();
        renderPayToggle();
        renderItems();
        renderCartBar();
    }

    function renderHeader() {
        document.getElementById('ph-title').textContent = state.shopLabel;
        document.getElementById('ph-sub').textContent   = state.items.length + ' termék elérhető';
        document.getElementById('chip-cash').textContent= fmt(state.cashBalance);
        document.getElementById('chip-bank').textContent= fmt(state.bankBalance);

        const bankChip = document.getElementById('chip-bank-wrap');
        bankChip.style.display = state.allowedPay === 'cash' ? 'none' : 'flex';
    }

    function renderCategories() {
        const bar = document.getElementById('cat-bar');
        bar.innerHTML = '';

        // Összes gomb
        const allBtn = document.createElement('button');
        allBtn.className  = 'cat-btn' + (state.activeCategory === 'all' ? ' active' : '');
        allBtn.innerHTML  = '<i class="hgi-stroke hgi-grid-view"></i>Mind';
        allBtn.onclick    = () => setCategory('all');
        bar.appendChild(allBtn);

        // Kategóriák a bolt itemjeiből
        const usedCats = [...new Set(state.items.map(i => i.category))];
        usedCats.forEach(catKey => {
            const cat = state.categories[catKey];
            if (!cat) return;
            const btn     = document.createElement('button');
            btn.className = 'cat-btn' + (state.activeCategory === catKey ? ' active' : '');
            btn.innerHTML = `<i class="${cat.icon}"></i>${cat.label}`;
            btn.onclick   = () => setCategory(catKey);
            bar.appendChild(btn);
        });
    }

    function setCategory(cat) {
        state.activeCategory = cat;
        document.querySelectorAll('.cat-btn').forEach(b =>
            b.classList.toggle('active', b.textContent.trim() === (cat === 'all' ? 'Mind' : (state.categories[cat] && state.categories[cat].label)))
        );
        renderItems();
    }

    function renderPayToggle() {
        const wrap = document.getElementById('pay-toggle');
        if (state.allowedPay !== 'both') {
            wrap.style.display = 'none'; return;
        }
        wrap.style.display = 'flex';
        document.querySelectorAll('.pay-btn').forEach(b => {
            b.classList.toggle('active', b.dataset.method === state.paymentMethod);
            b.onclick = () => {
                state.paymentMethod = b.dataset.method;
                renderPayToggle();
            };
        });
    }

    function renderItems() {
        const grid    = document.getElementById('items-grid');
        const query   = document.getElementById('search-input').value.toLowerCase();

        const filtered = state.items.filter(item => {
            const catOk   = state.activeCategory === 'all' || item.category === state.activeCategory;
            const queryOk = !query || item.label.toLowerCase().includes(query);
            return catOk && queryOk;
        });

        grid.innerHTML = '';

        if (!filtered.length) {
            grid.innerHTML = `<div class="empty-grid"><i class="hgi-stroke hgi-search-02"></i><span>Nincs találat</span></div>`;
            return;
        }

        filtered.forEach(item => {
            const card = createItemCard(item);
            grid.appendChild(card);
        });
    }

    function createItemCard(item) {
        const stock    = state.stock[item.item];
        const hasStock = stock === null || stock === undefined || stock === 999 || stock > 0;
        const inCart   = (state.cart[item.item] || 0) > 0;

        const el       = document.createElement('div');
        el.className   = 'item-card' + (!hasStock ? ' out-of-stock' : '') + (inCart ? ' in-cart' : '');
        el.dataset.item= item.item;

        let stockLabel = '';
        let stockClass = '';
        if (stock === null || stock === undefined || stock === 999) {
            stockLabel = '∞ készleten';
        } else if (stock === 0) {
            stockLabel = 'Elfogyott'; stockClass = 'none';
        } else if (stock <= 5) {
            stockLabel = stock + ' db maradt'; stockClass = 'low';
        } else {
            stockLabel = stock + ' db készleten';
        }

        el.innerHTML = `
            <div class="ic-icon"><i class="${item.icon}"></i></div>
            <div class="ic-label">${item.label}</div>
            <div class="ic-desc">${item.description || ''}</div>
            <div class="ic-footer">
                <div class="ic-price">${fmt(item.price)}</div>
                <div class="ic-stock ${stockClass}">${stockLabel}</div>
            </div>
            <div class="ic-cart-badge">${state.cart[item.item] || ''}</div>
        `;

        if (hasStock) {
            el.onclick = () => openBuyModal(item);
        }
        return el;
    }

    function updateItemCard(itemName) {
        const existing = document.querySelector(`[data-item="${itemName}"]`);
        if (!existing) return;
        const item = state.items.find(i => i.item === itemName);
        if (!item) return;
        const newCard  = createItemCard(item);
        existing.replaceWith(newCard);
    }

    // ── Kosár ────────────────────────────────────────────────
    function getCartTotal() {
        let total = 0;
        for (const [itemName, qty] of Object.entries(state.cart)) {
            const item = state.items.find(i => i.item === itemName);
            if (item) total += item.price * qty;
        }
        return total;
    }

    function getCartCount() {
        return Object.values(state.cart).reduce((a, b) => a + b, 0);
    }

    function renderCartBar() {
        const count  = getCartCount();
        const total  = getCartTotal();
        const btn    = document.getElementById('cart-btn');
        const label  = document.getElementById('cart-label');
        const totEl  = document.getElementById('cart-total');

        label.textContent = count > 0 ? count + ' tétel a kosárban' : 'Kosár üres';
        totEl.textContent = fmt(total);
        btn.disabled = count === 0;
    }

    // ── Vásárlás modal ───────────────────────────────────────
    function openBuyModal(item) {
        state.modalItem = item;
        state.modalQty  = state.cart[item.item] || 1;

        document.getElementById('bm-title').textContent = item.label;
        renderModal();
        document.getElementById('buy-modal').classList.remove('hidden');
    }

    function renderModal() {
        const item    = state.modalItem;
        if (!item) return;
        const qty     = state.modalQty;
        const total   = item.price * qty;
        const payIcon = state.paymentMethod === 'cash'
            ? 'hgi-stroke hgi-money-bag-02' : 'hgi-stroke hgi-bank';
        const payLabel= state.paymentMethod === 'cash' ? 'Készpénz' : 'Bankszámla';
        const maxQty  = item.maxPerPurchase || 10;
        const stockVal= state.stock[item.item];
        const maxStock= (stockVal === null || stockVal === undefined || stockVal === 999) ? maxQty : Math.min(maxQty, stockVal);

        document.getElementById('bm-body').innerHTML = `
            <div class="bm-item-row">
                <div class="bm-icon"><i class="${item.icon}"></i></div>
                <div>
                    <div class="bm-name">${item.label}</div>
                    <div class="bm-desc">${item.description || ''}</div>
                </div>
            </div>
            <div class="qty-row">
                <button class="qty-btn" onclick="Shop.changeQty(-1)">−</button>
                <div class="qty-val" id="bm-qty">${qty}</div>
                <button class="qty-btn" onclick="Shop.changeQty(1)">+</button>
                <div class="qty-max">Max: ${maxStock}</div>
            </div>
            <div class="bm-total-row">
                <span class="bm-total-label">Összesen</span>
                <span class="bm-total-val" id="bm-total">${fmt(total)}</span>
            </div>
            <div class="bm-pay-row">
                <i class="${payIcon}"></i>
                <span>Fizetési mód: <strong>${payLabel}</strong></span>
            </div>
        `;

        document.getElementById('bm-confirm').onclick = confirmBuy;
    }

    function changeQty(delta) {
        const item    = state.modalItem;
        if (!item) return;
        const maxQty  = item.maxPerPurchase || 10;
        const stockVal= state.stock[item.item];
        const maxStock= (stockVal === null || stockVal === undefined || stockVal === 999) ? maxQty : Math.min(maxQty, stockVal);
        state.modalQty= Math.max(1, Math.min(state.modalQty + delta, maxStock));
        document.getElementById('bm-qty').textContent   = state.modalQty;
        document.getElementById('bm-total').textContent = fmt(item.price * state.modalQty);
    }

    function confirmBuy() {
        const item = state.modalItem;
        if (!item) return;

        // Kosárba helyezés
        state.cart[item.item] = state.modalQty;

        // Azonnal elküldjük (nincs checkout késleltetés)
        fetch(`https://fvg-shops/buy`, {
            method: 'POST',
            body: JSON.stringify({
                shopId       : state.shopId,
                item         : item.item,
                quantity     : state.modalQty,
                paymentMethod: state.paymentMethod,
            })
        });

        closeModal();
        updateItemCard(item.item);
        renderCartBar();

        // Kosár törlés visszajelzés után
        setTimeout(() => {
            delete state.cart[item.item];
            updateItemCard(item.item);
            renderCartBar();
        }, 2000);
    }

    function checkout() {
        // Ha kosárban van valami és nem egyenként fizet
        if (getCartCount() === 0) return;
        // Közvetlen vásárlás – nincs checkout összesítő
        // Az összes elem már be van küldve confirmBuy-ban
    }

    function closeModal() {
        document.getElementById('buy-modal').classList.add('hidden');
        state.modalItem = null;
        state.modalQty  = 1;
    }

    // ── Toast ────────────────────────────────────────────────
    function showToast(text, payment) {
        const existing = document.querySelector('.purchase-toast');
        if (existing) existing.remove();
        const toast    = document.createElement('div');
        toast.className= 'purchase-toast';
        const icon     = payment === 'bank' ? 'hgi-stroke hgi-bank' : 'hgi-stroke hgi-money-bag-02';
        toast.innerHTML= `<i class="${icon}"></i>${text}`;
        document.body.appendChild(toast);
        setTimeout(() => toast.remove(), 2200);
    }

    // ── Keresés ──────────────────────────────────────────────
    document.getElementById('search-input').addEventListener('input', renderItems);

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', closeShop);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeShop(); });

    function closeShop() {
        document.getElementById('overlay').classList.add('hidden');
        document.getElementById('buy-modal').classList.add('hidden');
        fetch(`https://fvg-shops/close`, { method: 'POST', body: JSON.stringify({}) });
    }

    return { checkout, changeQty, closeModal };
})();