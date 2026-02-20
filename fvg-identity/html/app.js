const Creator = (() => {
    let currentStep = 1;
    const totalSteps = 4;
    let isNew = true;
    let cfg   = {};

    const data = {
        firstname: '', lastname: '', sex: 0,
        dob: '', age: 25, height: 175, weight: 75, nationality: 'Los Santos',
        appearance: {
            shapeId: 0, skinId: 0,
            hairStyle: 0, hairColor: 0, eyeColor: 0,
            top: 15, topTex: 0, pants: 14, pantsTex: 0,
            shoes: 34, shoesTex: 0, shirt: 15, shirtTex: 0,
        }
    };

    // ── NUI üzenet fogadás ──────────────────────────────────
    window.addEventListener('message', (e) => {
        const { action, config, identity, isNew: _isNew } = e.data;
        if (action === 'openCreator') {
            cfg   = config || {};
            isNew = _isNew !== false;

            // Konfig alkalmazása
            if (cfg.minAge)     document.getElementById('f-age').min    = cfg.minAge;
            if (cfg.maxAge)     document.getElementById('f-age').max    = cfg.maxAge;
            if (cfg.minHeight)  document.getElementById('f-height').min = cfg.minHeight;
            if (cfg.maxHeight)  document.getElementById('f-height').max = cfg.maxHeight;
            if (cfg.minWeight)  document.getElementById('f-weight').min = cfg.minWeight;
            if (cfg.maxWeight)  document.getElementById('f-weight').max = cfg.maxWeight;

            // Meglévő adat betöltése szerkesztőnél
            if (!isNew && identity) {
                loadIdentity(identity);
            }

            // Dinamikus chipek generálása
            buildChips('skintone-chips',  cfg.skinTones  || [], 'skinId',    'app');
            buildChips('hairstyle-chips', cfg.hairStyles || [], 'hairStyle', 'app');
            buildChips('haircolor-chips', cfg.hairColors || [], 'hairColor', 'app');
            buildChips('eyecolor-chips',  cfg.eyeColors  || [], 'eyeColor',  'app');

            // Panel fejléc
            if (!isNew) {
                document.getElementById('panel-title').textContent = 'Karakter szerkesztése';
                document.getElementById('panel-sub').textContent   = 'Módosítsd az adataidat';
                document.getElementById('close-btn').classList.remove('hidden');
            }

            goToStep(1);
            document.getElementById('overlay').classList.remove('hidden');
        }
    });

    // ── Chip lista builder ──────────────────────────────────
    function buildChips(containerId, items, field, group) {
        const cont = document.getElementById(containerId);
        if (!cont) return;
        cont.innerHTML = '';
        items.forEach((item, idx) => {
            const chip = document.createElement('div');
            chip.className   = 'chip' + (idx === 0 ? ' active' : '');
            chip.textContent = item.label || item.id;
            chip.addEventListener('click', () => {
                cont.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
                chip.classList.add('active');
                if (group === 'app') {
                    data.appearance[field] = item.id;
                    previewAppearance();
                }
            });
            cont.appendChild(chip);
        });
    }

    // ── Meglévő identity betöltése ──────────────────────────
    function loadIdentity(identity) {
        document.getElementById('f-firstname').value    = identity.firstname    || '';
        document.getElementById('f-lastname').value     = identity.lastname     || '';
        document.getElementById('f-dob').value          = identity.dob          || '';
        document.getElementById('f-nationality').value  = identity.nationality  || 'Los Santos';

        const age    = identity.age    || 25;
        const height = identity.height || 175;
        const weight = identity.weight || 75;

        document.getElementById('f-age').value    = age;
        document.getElementById('f-height').value = height;
        document.getElementById('f-weight').value = weight;
        updateAge(age); updateHeight(height); updateWeight(weight);

        // Nem
        const sex = identity.sex || 0;
        document.querySelectorAll('.sex-btn').forEach(b => {
            b.classList.toggle('active', parseInt(b.dataset.sex) === sex);
        });
        data.sex = sex;

        // Megjelenés
        if (identity.appearance) {
            Object.assign(data.appearance, identity.appearance);
        }

        Object.assign(data, {
            firstname: identity.firstname, lastname: identity.lastname,
            sex: identity.sex || 0, dob: identity.dob, age, height, weight,
            nationality: identity.nationality || 'Los Santos',
        });
    }

    // ── Lépés navigáció ─────────────────────────────────────
    function goToStep(step) {
        currentStep = step;

        document.querySelectorAll('.step-content').forEach((el, i) => {
            el.classList.toggle('active', i + 1 === step);
        });

        // Lépés jelzők
        document.querySelectorAll('.step').forEach((el, i) => {
            el.classList.remove('active', 'done');
            if (i + 1 === step)  el.classList.add('active');
            if (i + 1 < step)    el.classList.add('done');
        });

        // Dots
        document.querySelectorAll('.dot').forEach((el, i) => {
            el.classList.remove('active', 'done');
            if (i + 1 === step) el.classList.add('active');
            if (i + 1 < step)   el.classList.add('done');
        });

        // Gombok
        const btnBack = document.getElementById('btn-back');
        const btnNext = document.getElementById('btn-next');
        btnBack.disabled = step === 1;
        if (step === totalSteps) {
            btnNext.className = 'nav-btn save';
            btnNext.innerHTML = '<i class="hgi-stroke hgi-checkmark-circle-02"></i>Karakter mentése';
            buildSummary();
        } else {
            btnNext.className = 'nav-btn primary';
            btnNext.innerHTML = 'Következő<i class="hgi-stroke hgi-arrow-right-02"></i>';
        }
    }

    function nextStep() {
        if (currentStep < totalSteps) {
            if (!validateCurrentStep()) return;
            goToStep(currentStep + 1);
            if (currentStep === 2) previewAppearance();
        } else {
            saveIdentity();
        }
    }

    function prevStep() {
        if (currentStep > 1) goToStep(currentStep - 1);
    }

    // ── Validáció ────────────────────────────────────────────
    function validateCurrentStep() {
        if (currentStep === 1) {
            const fn = document.getElementById('f-firstname').value.trim();
            const ln = document.getElementById('f-lastname').value.trim();
            if (!/^[a-zA-ZáéíóöőüűÁÉÍÓÖŐÜŰ\s\-]{2,}$/.test(fn)) {
                document.getElementById('f-firstname').classList.add('error');
                return false;
            }
            if (!/^[a-zA-ZáéíóöőüűÁÉÍÓÖŐÜŰ\s\-]{2,}$/.test(ln)) {
                document.getElementById('f-lastname').classList.add('error');
                return false;
            }
            document.getElementById('f-firstname').classList.remove('error');
            document.getElementById('f-lastname').classList.remove('error');

            data.firstname   = fn;
            data.lastname    = ln;
            data.dob         = document.getElementById('f-dob').value;
            data.nationality = document.getElementById('f-nationality').value;
        }
        return true;
    }

    // ── Input frissítők ──────────────────────────────────────
    function updateAge(v) {
        data.age = parseInt(v);
        document.getElementById('age-display').textContent = v + ' év';
    }
    function updateHeight(v) {
        data.height = parseInt(v);
        document.getElementById('height-display').textContent = v + ' cm';
    }
    function updateWeight(v) {
        data.weight = parseInt(v);
        document.getElementById('weight-display').textContent = v + ' kg';
    }
    function updateAppearance(field, value) {
        data.appearance[field] = parseInt(value);
        document.getElementById('shape-display').textContent =
            data.appearance.shapeId ?? 0;
        previewAppearance();
    }
    function updateClothes(field, value) {
        data.appearance[field] = parseInt(value);
        const map = {
            top:'top', topTex:'toptex', pants:'pants', pantsTex:'pantstex',
            shoes:'shoes', shoesTex:'shoestex', shirt:'shirt', shirtTex:'shirttex'
        };
        const elId = map[field] + '-display';
        const el   = document.getElementById(elId);
        if (el) el.textContent = value;
        previewAppearance();
    }

    // ── Nem toggle ───────────────────────────────────────────
    document.querySelectorAll('.sex-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.sex-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            data.sex = parseInt(btn.dataset.sex);
            previewAppearance();
        });
    });

    // ── Bezárás gomb ─────────────────────────────────────────
    document.getElementById('close-btn').addEventListener('click', () => {
        document.getElementById('overlay').classList.add('hidden');
        fetch(`https://fvg-identity/closeEditor`, { method: 'POST', body: JSON.stringify({}) });
    });

    // ── Valós idejű előnézet ─────────────────────────────────
    let previewTimeout = null;
    function previewAppearance() {
        clearTimeout(previewTimeout);
        previewTimeout = setTimeout(() => {
            fetch(`https://fvg-identity/previewAppearance`, {
                method: 'POST',
                body: JSON.stringify({ sex: data.sex, appearance: data.appearance })
            });
        }, 120);
    }

    // ── Összefoglalás ────────────────────────────────────────
    function buildSummary() {
        // Személyi igazolvány feltöltése
        document.getElementById('sum-name').textContent    = `${data.firstname} ${data.lastname}`;
        document.getElementById('sum-sex').textContent     = data.sex === 1 ? 'Nő' : 'Férfi';
        document.getElementById('sum-dob').textContent     = data.dob || '–';
        document.getElementById('sum-age').textContent     = data.age + ' év';
        document.getElementById('sum-height').textContent  = data.height + ' cm';
        document.getElementById('sum-weight').textContent  = data.weight + ' kg';
        document.getElementById('sum-nationality').textContent = data.nationality;

        // Megjelenés összefoglaló
        const app = data.appearance;
        const rows = [
            { key: 'Arcforma ID',  val: app.shapeId   },
            { key: 'Bőrszín ID',   val: app.skinId    },
            { key: 'Hajstílus ID', val: app.hairStyle  },
            { key: 'Hajszín ID',   val: app.hairColor  },
            { key: 'Szemszín ID',  val: app.eyeColor   },
            { key: 'Felsőtest',    val: `${app.top} / ${app.topTex}`   },
            { key: 'Nadrág',       val: `${app.pants} / ${app.pantsTex}` },
            { key: 'Cipő',         val: `${app.shoes} / ${app.shoesTex}` },
            { key: 'Ing',          val: `${app.shirt} / ${app.shirtTex}` },
        ];
        const cont = document.getElementById('app-sum-rows');
        cont.innerHTML = rows.map(r =>
            `<div class="app-sum-row">
                <span class="app-sum-key">${r.key}</span>
                <span class="app-sum-val">${r.val}</span>
            </div>`
        ).join('');
    }

    // ── Mentés ───────────────────────────────────────────────
    function saveIdentity() {
        const payload = { ...data };
        fetch(`https://fvg-identity/saveIdentity`, {
            method: 'POST',
            body:   JSON.stringify(payload)
        });
        document.getElementById('overlay').classList.add('hidden');
    }

    return { nextStep, prevStep, updateAge, updateHeight, updateWeight, updateAppearance, updateClothes };
})();