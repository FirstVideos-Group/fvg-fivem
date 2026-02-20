const Bank = (() => {
    let accounts    = { checking: { balance: 0, iban: '' }, savings: { balance: 0, iban: '' } };
    let cash        = 0;
    let txData      = { checking: [], savings: [] };
    let txTypes     = {};
    let limits      = {};
    let isATM       = false;
    let internalFrom= 'checking';
    let internalTo  = 'savings';

    const fmt = (n) => '$' + Math.abs(Number(n)).toLocaleString('hu-HU');

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'open') {
            const p = e.data.payload;
            accounts = p.accounts || accounts;
            cash     = p.cash    || 0;
            txData   = p.transactions || { checking: [], savings: [] };
            txTypes  = p.txTypes || {};
            limits   = p.limits  || {};
            isATM    = p.mode === 'atm';

            updateBalances();
            renderTransactions('checking');
            updateInternalVisual();
            renderATMMode();
            activateTab('actions');
            document.getElementById('overlay').classList.remove('hidden');
        }
        if (action === 'syncAccounts') {
            accounts = e.data.accounts;
            updateBalances();
            updateInternalVisual();
        }
        if (action === 'syncCash') {
            cash = e.data.cash;
            document.getElementById('bal-cash').textContent = fmt(cash);
        }
    });

    // ── ATM mód (korlátozott) ────────────────────────────────
    function renderATMMode() {
        document.querySelectorAll('.atm-hide').forEach(el =>
            el.classList.toggle('hidden', isATM)
        );
        document.getElementById('ph-title').textContent = isATM ? 'ATM' : 'Maze Bank';
        if (isATM) {
            // Csak checking, savings rejtés ATM-nél
            document.getElementById('dep-account').innerHTML = '<option value="checking">Folyószámla</option>';
            document.getElementById('with-account').innerHTML = '<option value="checking">Folyószámla</option>';
        }
    }

    // ── Egyenlegek frissítése ────────────────────────────────
    function updateBalances() {
        const ch = accounts.checking || {};
        const sv = accounts.savings  || {};
        document.getElementById('bal-checking').textContent = fmt(ch.balance || 0);
        document.getElementById('bal-savings').textContent  = fmt(sv.balance || 0);
        document.getElementById('bal-cash').textContent     = fmt(cash);
        document.getElementById('iban-checking').textContent= ch.iban || '–';
        document.getElementById('iban-savings').textContent = sv.iban || '–';
    }

    // ── Tab kezelés ──────────────────────────────────────────
    document.querySelectorAll('.tab').forEach(t =>
        t.addEventListener('click', () => {
            if (!t.classList.contains('hidden')) activateTab(t.dataset.tab);
        })
    );
    function activateTab(id) {
        document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === id));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.toggle('active', c.id === 'tab-' + id));
        if (id === 'history') {
            renderTransactions(document.getElementById('hist-account').value);
        }
        if (id === 'internal') updateInternalVisual();
    }

    document.getElementById('hist-account').addEventListener('change', (e) => {
        renderTransactions(e.target.value);
    });

    // ── Tranzakció lista ─────────────────────────────────────
    function renderTransactions(accType) {
        const list = document.getElementById('tx-list');
        const txs  = txData[accType] || [];

        if (!txs.length) {
            list.innerHTML = `<div class="empty-state"><i class="hgi-stroke hgi-file-not-found"></i><span>Nincs tranzakció</span></div>`;
            return;
        }

        list.innerHTML = '';
        txs.forEach(tx => {
            const typeDef = txTypes[tx.type] || txTypes.other || { label: tx.type, icon: 'hgi-stroke hgi-bank', color: '#8899b4' };
            const isPos   = tx.amount > 0;
            const el      = document.createElement('div');
            el.className  = 'tx-item';
            el.innerHTML  = `
                <div class="tx-icon" style="background:${typeDef.color}18;border:1px solid ${typeDef.color}30">
                    <i class="${typeDef.icon}" style="color:${typeDef.color}"></i>
                </div>
                <div class="tx-info">
                    <div class="tx-type">${typeDef.label}</div>
                    <div class="tx-desc">${tx.description || '–'}${tx.firstname ? ' · ' + tx.firstname + ' ' + tx.lastname : ''}</div>
                    <div class="tx-date">${tx.created_at ? tx.created_at.toString().substring(0,16) : ''}</div>
                </div>
                <div class="tx-right">
                    <div class="tx-amount ${isPos ? 'positive' : 'negative'}">
                        ${isPos ? '+' : ''}${isPos ? fmt(tx.amount) : '-'+fmt(tx.amount)}
                    </div>
                    <div class="tx-bal">Egyenleg: ${fmt(tx.balance_after)}</div>
                </div>
            `;
            list.appendChild(el);
        });
    }

    // ── Gyors összeg ─────────────────────────────────────────
    function quickAmount(inputId, val) {
        const input = document.getElementById(inputId);
        if (val === 'all') {
            input.value = cash;
        } else if (val === 'int-max') {
            const from  = accounts[internalFrom];
            input.value = from ? from.balance : 0;
        } else {
            input.value = val;
        }
        updateTransferFee();
    }

    // ── Tranzakciós díj frissítés ────────────────────────────
    function updateTransferFee() {
        const fee  = limits.transferFee || 0;
        const feeEl= document.getElementById('tr-fee');
        if (fee > 0) {
            const amount  = parseInt(document.getElementById('tr-amount').value) || 0;
            const feeAmt  = Math.floor(amount * fee / 100);
            document.getElementById('tr-fee-val').textContent = fmt(feeAmt);
            feeEl.style.display = 'flex';
        } else {
            feeEl.style.display = 'none';
        }
    }
    document.getElementById('tr-amount').addEventListener('input', updateTransferFee);

    // ── Belső átvezetés vizuál ───────────────────────────────
    function updateInternalVisual() {
        const from = accounts[internalFrom] || {};
        const to   = accounts[internalTo]   || {};
        document.getElementById('iv-from-label').textContent = internalFrom === 'checking' ? 'Folyószámla' : 'Megtakarítás';
        document.getElementById('iv-to-label').textContent   = internalTo   === 'checking' ? 'Folyószámla' : 'Megtakarítás';
        document.getElementById('iv-from-bal').textContent   = fmt(from.balance || 0);
        document.getElementById('iv-to-bal').textContent     = fmt(to.balance   || 0);
        document.getElementById('iv-from-bal').closest('.iv-from').querySelector('i').className =
            internalFrom === 'checking' ? 'hgi-stroke hgi-bank' : 'hgi-stroke hgi-piggy-bank';
        document.getElementById('iv-to-bal').closest('.iv-to').querySelector('i').className =
            internalTo === 'checking' ? 'hgi-stroke hgi-bank' : 'hgi-stroke hgi-piggy-bank';
    }

    function swapInternal() {
        [internalFrom, internalTo] = [internalTo, internalFrom];
        document.getElementById('iv-swap').classList.toggle('swapped');
        updateInternalVisual();
    }

    // ── Műveletek ────────────────────────────────────────────
    function deposit() {
        const amount  = parseInt(document.getElementById('dep-amount').value) || 0;
        const accType = document.getElementById('dep-account').value;
        if (amount <= 0) return;
        fetch(`https://fvg-banking/deposit`, {
            method: 'POST', body: JSON.stringify({ amount, accType })
        });
        document.getElementById('dep-amount').value = '';
    }

    function withdraw() {
        const amount  = parseInt(document.getElementById('with-amount').value) || 0;
        const accType = document.getElementById('with-account').value;
        if (amount <= 0) return;
        fetch(`https://fvg-banking/withdraw`, {
            method: 'POST', body: JSON.stringify({ amount, accType, isATM })
        });
        document.getElementById('with-amount').value = '';
    }

    function transfer() {
        const iban   = document.getElementById('tr-iban').value.trim().toUpperCase();
        const amount = parseInt(document.getElementById('tr-amount').value) || 0;
        const desc   = document.getElementById('tr-desc').value.trim();
        if (!iban || amount <= 0) return;
        fetch(`https://fvg-banking/transfer`, {
            method: 'POST', body: JSON.stringify({ iban, amount, description: desc || null })
        });
        document.getElementById('tr-iban').value   = '';
        document.getElementById('tr-amount').value = '';
        document.getElementById('tr-desc').value   = '';
    }

    function internalTransfer() {
        const amount = parseInt(document.getElementById('int-amount').value) || 0;
        if (amount <= 0) return;
        fetch(`https://fvg-banking/internalTransfer`, {
            method: 'POST', body: JSON.stringify({ fromType: internalFrom, toType: internalTo, amount })
        });
        document.getElementById('int-amount').value = '';
    }

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', close);
    function close() {
        document.getElementById('overlay').classList.add('hidden');
        fetch(`https://fvg-banking/close`, { method: 'POST', body: JSON.stringify({}) });
    }
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') close();
    });

    return { quickAmount, swapInternal, deposit, withdraw, transfer, internalTransfer };
})();