const UE = (() => {
    let payload       = null;
    let cooldownInterval = null;
    let cooldownLeft  = 0;

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action } = e.data;

        if (action === 'open') {
            payload = e.data.payload;
            renderBenefit();
            renderJobs();
            renderTasks();
            activateTab('benefit');
            document.getElementById('overlay').classList.remove('hidden');
        }
        if (action === 'syncData') {
            if (payload) {
                payload.data = e.data.data;
                renderBenefit();
                renderTasks();
            }
        }
    });

    // ── Tab kezelés ──────────────────────────────────────────
    document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => activateTab(tab.dataset.tab));
    });

    function activateTab(tabId) {
        document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.toggle('active', c.id === 'tab-' + tabId));
    }

    // ── Segély tab renderelés ────────────────────────────────
    function renderBenefit() {
        if (!payload) return;
        const { data, benefitAmount, maxClaims, cooldown, isUnemployed } = payload;

        // Státusz kártya
        const isEligible = data.eligible && isUnemployed;
        document.getElementById('sc-title').textContent = isUnemployed ? 'Munkanélküli' : 'Foglalkoztatott';
        document.getElementById('sc-sub').textContent   = isEligible
            ? 'Jogosult munkanélküli segélyre'
            : (isUnemployed ? 'Nem jogosult segélyre' : 'Jelenleg állásban vagy');
        const badge = document.getElementById('sc-badge');
        badge.textContent = isEligible ? 'AKTÍV' : 'INAKTÍV';
        badge.className   = 'sc-badge' + (isEligible ? '' : ' inactive');
        document.getElementById('sc-icon').querySelector('i').className =
            isUnemployed ? 'hgi-stroke hgi-user-circle' : 'hgi-stroke hgi-user-check-01';

        // Összefoglaló
        document.getElementById('benefit-amount').textContent = '$' + benefitAmount;
        document.getElementById('claims-used').textContent    = (data.claims_used || 0) + ' / ' + maxClaims;

        // Cooldown számláló
        cooldownLeft = payload.cooldownLeft || 0;
        updateClaimButton();
        startCooldownTimer();

        // Progress
        const used = data.claims_used || 0;
        const pct  = Math.min((used / maxClaims) * 100, 100);
        const fill = document.getElementById('cp-fill');
        fill.style.width = pct + '%';
        fill.className   = 'cp-fill' + (pct >= 100 ? ' maxed' : pct >= 75 ? ' near-max' : '');
        document.getElementById('cp-count').textContent = used + ' / ' + maxClaims;
    }

    function updateClaimButton() {
        if (!payload) return;
        const btn = document.getElementById('claim-btn');
        const { data, maxClaims, isUnemployed } = payload;
        const used = data.claims_used || 0;

        if (!isUnemployed || !data.eligible) {
            btn.disabled  = true;
            btn.className = 'claim-btn';
            btn.innerHTML = `<i class="hgi-stroke hgi-cancel-01"></i>Nem jogosult`;
            document.getElementById('next-claim').textContent = '–';
            return;
        }
        if (used >= maxClaims) {
            btn.disabled  = true;
            btn.className = 'claim-btn';
            btn.innerHTML = `<i class="hgi-stroke hgi-cancel-01"></i>Limit elérve`;
            document.getElementById('next-claim').textContent = '–';
            return;
        }
        if (cooldownLeft > 0) {
            const m = Math.floor(cooldownLeft / 60);
            const s = cooldownLeft % 60;
            btn.disabled  = true;
            btn.className = 'claim-btn cooldown';
            btn.innerHTML = `<i class="hgi-stroke hgi-clock-02"></i>${m}:${String(s).padStart(2,'0')} múlva igényelhető`;
            document.getElementById('next-claim').textContent = m + ' perc ' + s + ' mp';
        } else {
            btn.disabled  = false;
            btn.className = 'claim-btn';
            btn.innerHTML = `<i class="hgi-stroke hgi-money-receive-02"></i>Segély igénylése`;
            document.getElementById('next-claim').textContent = 'Most igényelhető';
        }
    }

    function startCooldownTimer() {
        if (cooldownInterval) clearInterval(cooldownInterval);
        if (cooldownLeft <= 0) return;
        cooldownInterval = setInterval(() => {
            cooldownLeft--;
            updateClaimButton();
            if (cooldownLeft <= 0) clearInterval(cooldownInterval);
        }, 1000);
    }

    document.getElementById('claim-btn').addEventListener('click', () => {
        fetch(`https://fvg-unemployment/claimBenefit`, { method: 'POST', body: JSON.stringify({}) });
    });

    // ── Állások tab renderelés ───────────────────────────────
    function renderJobs() {
        if (!payload) return;
        const grid = document.getElementById('jobs-grid');
        grid.innerHTML = '';

        (payload.jobs || []).forEach(job => {
            const card = document.createElement('div');
            card.className = 'job-card' + (job.isFull ? ' full' : '');

            const applyColor = job.meetsReqs && !job.isFull ? job.color : '#64748b';
            const applyBg    = job.meetsReqs && !job.isFull
                ? `background:${job.color}18;border:1px solid ${job.color}33;color:${job.color}`
                : `background:rgba(100,116,139,0.1);border:1px solid rgba(100,116,139,0.2);color:#64748b`;

            card.innerHTML = `
                <div class="jc-main">
                    <div class="jc-icon" style="background:${job.color}18;border:1px solid ${job.color}30">
                        <i class="${job.icon}" style="color:${job.color}"></i>
                    </div>
                    <div class="jc-info">
                        <div class="jc-title">${job.label}</div>
                        <div class="jc-desc">${job.description}</div>
                        <div class="jc-salary">
                            <i class="hgi-stroke hgi-money-bag-02"></i>
                            $${job.salary.min.toLocaleString()} – $${job.salary.max.toLocaleString()} / műszak
                        </div>
                    </div>
                </div>
                <div class="jc-footer">
                    <div class="jc-slots">
                        <i class="hgi-stroke hgi-user-group"></i>
                        ${job.slots > 0 ? job.currentSlots + ' / ' + job.slots + ' betöltve' : 'Korlátlan'}
                    </div>
                    <button class="jc-apply-btn" style="${applyBg}" ${(job.isFull || !job.meetsReqs) ? 'disabled' : ''}
                        onclick="UE.showJobDetail('${job.id}')">
                        <i class="hgi-stroke hgi-${job.meetsReqs && !job.isFull ? 'file-add' : 'alert-02'}"></i>
                        ${job.isFull ? 'Betelt' : job.meetsReqs ? 'Részletek' : 'Feltétel hiányzik'}
                    </button>
                </div>
            `;
            grid.appendChild(card);
        });
    }

    // ── Állás részlet modal ──────────────────────────────────
    function showJobDetail(jobId) {
        const job = (payload.jobs || []).find(j => j.id === jobId);
        if (!job) return;

        const iconEl = document.getElementById('jm-icon');
        iconEl.className = job.icon;
        iconEl.style.color = job.color;
        document.getElementById('jm-title').textContent = job.label;

        const body = document.getElementById('jm-body');
        body.innerHTML = `
            <div class="detail-row"><span class="detail-key">Pozíció</span><span class="detail-val">${job.label}</span></div>
            <div class="detail-row"><span class="detail-key">Fizetés</span><span class="detail-val" style="color:#22c55e">$${job.salary.min.toLocaleString()} – $${job.salary.max.toLocaleString()}</span></div>
            <div class="detail-row"><span class="detail-key">Helyek</span><span class="detail-val">${job.slots > 0 ? job.currentSlots + ' / ' + job.slots : 'Korlátlan'}</span></div>
            <div class="detail-row" style="border:none"><span class="detail-key">Leírás</span></div>
            <div style="font-size:12px;color:var(--text-s);line-height:1.6;padding:4px 0 10px">${job.description}</div>
            <div style="font-size:11px;font-weight:700;color:var(--text-m);text-transform:uppercase;letter-spacing:.08em;margin-bottom:8px">Követelmények</div>
            <div class="req-list">
                ${buildReqList(job)}
            </div>
        `;

        const footer = document.getElementById('jm-footer');
        const canApply = job.meetsReqs && !job.isFull;
        footer.innerHTML = `
            <button class="modal-cancel-btn" onclick="UE.closeJobModal()">Bezárás</button>
            <button class="modal-apply-btn" ${canApply ? '' : 'disabled'} id="modal-apply-btn">
                <i class="hgi-stroke hgi-${canApply ? 'checkmark-circle-02' : 'cancel-01'}"></i>
                ${canApply ? 'Jelentkezés' : (job.isFull ? 'Betelt' : 'Feltétel hiányzik')}
            </button>
        `;
        if (canApply) {
            document.getElementById('modal-apply-btn').addEventListener('click', () => {
                fetch(`https://fvg-unemployment/applyJob`, { method: 'POST', body: JSON.stringify({ jobId }) });
                closeJobModal();
            });
        }

        document.getElementById('job-modal').classList.remove('hidden');
    }

    function buildReqList(job) {
        const reqs = job.requirements || {};
        const lines = [];
        lines.push(`
            <div class="req-item">
                <i class="hgi-stroke hgi-checkmark-circle-02 req-ok"></i>
                <span>Nincs aktív állás</span>
            </div>
        `);
        if (reqs.minAge) {
            lines.push(`
                <div class="req-item">
                    <i class="hgi-stroke hgi-${job.meetsReqs || reqs.minAge ? 'checkmark-circle-02 req-ok' : 'cancel-01 req-fail'}"></i>
                    <span>Minimum életkor: ${reqs.minAge} év</span>
                </div>
            `);
        }
        if (reqs.license) {
            const hasLic = !job.reqDetails || job.reqDetails.length === 0;
            lines.push(`
                <div class="req-item">
                    <i class="hgi-stroke hgi-${hasLic ? 'checkmark-circle-02 req-ok' : 'cancel-01 req-fail'}"></i>
                    <span>${reqs.license} jogosítvány szükséges</span>
                </div>
            `);
        }
        if (lines.length === 1) {
            lines.push(`<div class="req-item"><i class="hgi-stroke hgi-checkmark-circle-02 req-ok"></i><span>Nincs speciális követelmény</span></div>`);
        }
        return lines.join('');
    }

    function closeJobModal() {
        document.getElementById('job-modal').classList.add('hidden');
    }

    // ── Napi feladatok renderelés ────────────────────────────
    function renderTasks() {
        if (!payload) return;
        const list     = document.getElementById('tasks-list');
        const tasksDone= payload.data.tasks_done || {};
        list.innerHTML = '';

        (payload.tasks || []).forEach(task => {
            const done = !!tasksDone[task.id];
            const el   = document.createElement('div');
            el.className = 'task-card' + (done ? ' done' : '');
            el.innerHTML = `
                <div class="task-check ${done ? 'done' : ''}">
                    ${done ? '<i class="hgi-stroke hgi-checkmark-02"></i>' : ''}
                </div>
                <div class="task-info">
                    <div class="task-label">${task.label}</div>
                    <div class="task-reward">+$${task.reward} jutalom</div>
                </div>
                <button class="task-btn ${done ? 'done' : ''}" data-id="${task.id}">
                    ${done ? '<i class="hgi-stroke hgi-checkmark-circle-02"></i>Kész' : '<i class="hgi-stroke hgi-play-circle-02"></i>Ellenőrzés'}
                </button>
            `;
            if (!done) {
                el.querySelector('.task-btn').addEventListener('click', () => {
                    fetch(`https://fvg-unemployment/checkTask`, {
                        method: 'POST', body: JSON.stringify({ taskId: task.id })
                    });
                });
            }
            list.appendChild(el);
        });
    }

    // ── Bezárás ──────────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', close);

    function close() {
        document.getElementById('overlay').classList.add('hidden');
        if (cooldownInterval) clearInterval(cooldownInterval);
        fetch(`https://fvg-unemployment/close`, { method: 'POST', body: JSON.stringify({}) });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            if (!document.getElementById('job-modal').classList.contains('hidden')) { closeJobModal(); return; }
            close();
        }
    });

    return { showJobDetail, closeJobModal };
})();