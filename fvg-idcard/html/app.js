const Card = (() => {
    let payload     = null;
    let isOwner     = false;
    let isCheck     = false;
    let targetSrc   = null;
    let selectedWantedLevel = 0;

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'openCard') {
            payload  = e.data.payload;
            isOwner  = payload.owner  === true;
            isCheck  = payload.isCheck=== true;
            targetSrc= payload.data?.player_id ?? null;

            renderAll();
            document.getElementById('overlay').classList.remove('hidden');

            // Felmutatás gomb csak saját nézetben
            const showBtn = document.getElementById('show-btn');
            if (isOwner) showBtn.classList.remove('hidden');
            else         showBtn.classList.add('hidden');

            // Panel fejléc szöveg
            const title = isCheck
                ? 'Igazolvány ellenőrzés'
                : (isOwner ? 'Személyi igazolvány' : 'Bemutatott igazolvány');
            document.getElementById('ph-title').textContent = title;
            document.getElementById('ph-sub').textContent   =
                payload.shownBy ? payload.shownBy + ' igazolványa' : 'Los Santos Állam';

            // Aktív tab visszaállítás
            activateTab('identity');
        }
    });

    // ── Tab kezelés ──────────────────────────────────────────
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => activateTab(tab.dataset.tab));
    });

    function activateTab(tabId) {
        document.querySelectorAll('.tab').forEach(t => {
            t.classList.toggle('active', t.dataset.tab === tabId);
        });
        document.querySelectorAll('.tab-content').forEach(c => {
            c.classList.toggle('active', c.id === 'tab-' + tabId);
        });
    }

    // ── Render fő ────────────────────────────────────────────
    function renderAll() {
        if (!payload || !payload.data) return;
        const { identity, licenses, wanted } = payload.data;
        const cardTypes  = payload.cardTypes  || [];
        const wantedLvls = payload.wantedLvls || [];

        renderIDCard(identity, wanted, wantedLvls);
        renderIdentityDetail(identity);
        renderLicenses(licenses, cardTypes);
        renderWanted(wanted, wantedLvls);
    }

    // ── ID kártya vizuál ─────────────────────────────────────
    function renderIDCard(identity, wanted, wantedLvls) {
        if (!identity) return;
        const fullName = (identity.firstname + ' ' + identity.lastname).trim();

        document.getElementById('idc-name').textContent       = fullName || '–';
        document.getElementById('idc-dob').textContent        = identity.dob || '–';
        document.getElementById('idc-sex').textContent        = identity.sex === 1 ? 'Nő' : 'Férfi';
        document.getElementById('idc-hw').textContent         = (identity.height || '–') + ' cm / ' + (identity.weight || '–') + ' kg';
        document.getElementById('idc-nationality').textContent= identity.nationality || '–';
        document.getElementById('idc-issued').textContent     = 'Los Santos Önkormányzat';

        // MRZ generálás (dekoratív)
        const mrz1 = ('ID<<' + padMRZ(identity.lastname)  + '<<' + padMRZ(identity.firstname)).substring(0, 30);
        const mrz2 = (padMRZ(String(identity.player_id || '').padStart(9,'0')) + '<<<<<<<<<<<<<<').substring(0, 30);
        document.getElementById('idc-mrz').textContent = mrz1 + '\n' + mrz2;

        // Körözési banner
        const wLevel  = wanted?.level || 0;
        const banner  = document.getElementById('wanted-banner');
        const banText = document.getElementById('wanted-banner-text');
        if (wLevel > 0) {
            const wDef = wantedLvls[wLevel] || {};
            banner.classList.remove('hidden');
            banner.style.background = (wDef.color || '#ef4444') + 'dd';
            banText.textContent = 'KÖRÖZÖTT SZEMÉLY – ' + (wDef.label || '').toUpperCase();
        } else {
            banner.classList.add('hidden');
        }
    }

    function padMRZ(str) {
        return (str || '').toUpperCase().replace(/\s/g, '<').substring(0, 13).padEnd(13, '<');
    }

    // ── Személyi adatok ──────────────────────────────────────
    function renderIdentityDetail(identity) {
        if (!identity) return;
        const cont = document.getElementById('identity-detail');
        const fields = [
            { label: 'Keresztnév',  val: identity.firstname  },
            { label: 'Vezetéknév',  val: identity.lastname   },
            { label: 'Nem',         val: identity.sex === 1 ? 'Nő' : 'Férfi' },
            { label: 'Kor',         val: (identity.age || '–') + ' év' },
            { label: 'Magasság',    val: (identity.height || '–') + ' cm' },
            { label: 'Súly',        val: (identity.weight || '–') + ' kg' },
            { label: 'Születési dátum', val: identity.dob },
            { label: 'Nemzetiség',  val: identity.nationality },
        ];
        cont.innerHTML = fields.map(f => `
            <div class="info-card">
                <div class="ic-label">${f.label}</div>
                <div class="ic-val">${f.val || '–'}</div>
            </div>
        `).join('');
    }

    // ── Engedélyek ───────────────────────────────────────────
    function renderLicenses(licenses, cardTypes) {
        const grid = document.getElementById('licenses-grid');
        grid.innerHTML = '';

        cardTypes.forEach(ct => {
            if (ct.id === 'id') return; // személyi külön tab

            const lic    = licenses?.[ct.id] || null;
            const card   = document.createElement('div');
            let statusClass = 'missing', statusLabel = 'Nincs', statusIcon = 'hgi-stroke hgi-cancel-01';

            if (lic) {
                if (lic.suspended) {
                    statusClass = 'suspended'; statusLabel = 'Felfüggesztve'; statusIcon = 'hgi-stroke hgi-alert-02';
                } else {
                    statusClass = 'valid'; statusLabel = 'Érvényes'; statusIcon = 'hgi-stroke hgi-checkmark-circle-02';
                }
            }

            card.className = `license-card ${statusClass}`;
            card.innerHTML = `
                <div class="lic-icon" style="background:${ct.color}18;border:1px solid ${ct.color}33">
                    <i class="${ct.icon}" style="color:${ct.color}"></i>
                </div>
                <div class="lic-info">
                    <div class="lic-name">${ct.label}</div>
                    ${lic?.categories ? `<div class="lic-cats">Kategória: ${lic.categories}</div>` : ''}
                    <div class="lic-sub">${lic ? 'Kiadva: ' + (lic.issued_at?.substring(0,10) || '–') : 'Nem rendelkezik engedéllyel'}</div>
                    ${lic?.expires_at ? `<div class="lic-sub">Lejár: ${lic.expires_at.substring(0,10)}</div>` : ''}
                    ${(isCheck || !isOwner) && lic ? renderAdminLicActions(ct.id, lic) : ''}
                </div>
                <div class="lic-status status-${statusClass}">
                    <i class="hgi-stroke ${statusIcon}"></i>${statusLabel}
                </div>
            `;
            grid.appendChild(card);
        });
    }

    function renderAdminLicActions(licType, lic) {
        if (!isCheck) return '';
        return `
            <div class="lic-admin-actions">
                ${lic.suspended
                    ? `<button class="lic-action-btn lab-restore" onclick="Card.toggleSuspend('${licType}', false)"><i class="hgi-stroke hgi-checkmark-circle-02"></i>Visszaállítás</button>`
                    : `<button class="lic-action-btn lab-suspend" onclick="Card.toggleSuspend('${licType}', true)"><i class="hgi-stroke hgi-alert-02"></i>Felfüggesztés</button>`
                }
            </div>
        `;
    }

    // ── Körözés tab ──────────────────────────────────────────
    function renderWanted(wanted, wantedLvls) {
        const section = document.getElementById('wanted-section');
        const level   = wanted?.level || 0;
        const wDef    = wantedLvls[level] || { label: 'Nincs', color: '#22c55e' };

        // Csillagok
        const stars = Array.from({ length: 5 }, (_, i) =>
            `<i class="hgi-stroke hgi-star${i < level ? '' : '-off'} ${i < level ? 'star-on' : 'star-off'}"></i>`
        ).join('');

        section.innerHTML = `
            <div class="wanted-card">
                <div class="wanted-level-display"
                     style="color:${wDef.color};border-color:${wDef.color}33;background:${wDef.color}11">
                    ${level}
                </div>
                <div class="wanted-stars">${stars}</div>
                <div class="wanted-level-label" style="color:${wDef.color}">${wDef.label}</div>
                ${wanted?.reason ? `<div class="wanted-reason">${wanted.reason}</div>` : ''}
            </div>
        `;

        // Admin form
        const adminForm = document.getElementById('wanted-admin');
        if (isCheck) {
            adminForm.classList.remove('hidden');
            buildWantedLevelBtns(wantedLvls, level);
            document.getElementById('wa-submit').addEventListener('click', submitWanted);
        } else {
            adminForm.classList.add('hidden');
        }
    }

    function buildWantedLevelBtns(wantedLvls, current) {
        selectedWantedLevel = current;
        const cont = document.getElementById('wanted-level-btns');
        cont.innerHTML = '';
        wantedLvls.forEach(w => {
            const btn = document.createElement('button');
            btn.className = 'wl-btn' + (w.level === current ? ' active' : '');
            btn.textContent = w.level;
            btn.style.setProperty('--wc', w.color);
            btn.addEventListener('click', () => {
                selectedWantedLevel = w.level;
                cont.querySelectorAll('.wl-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            });
            cont.appendChild(btn);
        });
    }

    function submitWanted() {
        const reason = document.getElementById('wa-reason').value.trim();
        fetch(`https://fvg-idcard/setWanted`, {
            method: 'POST',
            body: JSON.stringify({ targetSrc, level: selectedWantedLevel, reason })
        });
    }

    // ── Engedély felfüggesztés toggle ────────────────────────
    function toggleSuspend(licType, state) {
        fetch(`https://fvg-idcard/suspendLicense`, {
            method: 'POST',
            body: JSON.stringify({ targetSrc, licenseType: licType, state })
        });
    }

    // ── Legközelebbi játékosnak felmutatás ───────────────────
    function showToNearest() {
        fetch(`https://fvg-idcard/showToNearest`, { method: 'POST', body: JSON.stringify({}) });
        close();
    }

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', close);

    function close() {
        document.getElementById('overlay').classList.add('hidden');
        fetch(`https://fvg-idcard/close`, { method: 'POST', body: JSON.stringify({}) });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') close();
    });

    return { showToNearest, toggleSuspend };
})();