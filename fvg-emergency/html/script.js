const bolos = {};
let toastTimer = null;

window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {

        case 'setAuthorized':
            if (d.authorized) {
                document.getElementById('emergency-hud').classList.remove('hidden');
                setHudPosition(d.position || 'top-left');
            } else {
                document.getElementById('emergency-hud').classList.add('hidden');
            }
            break;

        case 'setCode': {
            const badge = document.getElementById('code-badge');
            const icon  = document.getElementById('code-icon');
            const label = document.getElementById('code-label');
            const note  = document.getElementById('code-note');
            icon.className  = d.data.icon;
            icon.style.color = d.data.color;
            label.textContent = d.data.label;
            label.style.color = d.data.color;
            note.textContent  = d.data.note || '';
            badge.classList.remove('hidden');
            break;
        }

        case 'clearCode':
            document.getElementById('code-badge').classList.add('hidden');
            break;

        case 'incomingCode':
            showToast(d.data);
            break;

        case 'boloIssued':
            addBOLO(d.data);
            break;

        case 'boloCleared':
            removeBOLO(d.id);
            break;

        case 'signal100':
            const bar = document.getElementById('signal100-bar');
            d.active ? bar.classList.remove('hidden') : bar.classList.add('hidden');
            break;

        case 'unitCleared':
            // más egység kódját sem tároljuk kliensen, csak a toast volt
            break;
    }
});

function setHudPosition(pos) {
    const hud = document.getElementById('emergency-hud');
    hud.className = 'hud pos-' + pos.replace('_', '-');
}

function showToast(data) {
    const toast = document.getElementById('incoming-toast');
    const icon  = document.getElementById('toast-icon');
    const label = document.getElementById('toast-label');
    const sub   = document.getElementById('toast-sub');

    icon.className  = data.icon;
    icon.style.color = data.color;
    label.textContent = data.label + ' – ' + (data.issuedBy || '?');
    sub.textContent   = data.note || '';

    toast.classList.add('show');
    toast.classList.remove('hidden');

    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
        toast.classList.remove('show');
    }, 5000);
}

function addBOLO(data) {
    removeBOLO(data.id);
    const list = document.getElementById('bolo-list');
    const card = document.createElement('div');
    card.className  = 'bolo-card';
    card.id         = 'bolo-' + data.id;
    card.innerHTML  = `
        <i class="hgi-stroke hgi-search-02"></i>
        <div class="bolo-info">
            <span class="bolo-plate">BOLO #${data.id} – ${data.plate}</span>
            <span class="bolo-desc">${data.description || ''}</span>
        </div>`;
    list.appendChild(card);
    bolos[data.id] = card;
}

function removeBOLO(id) {
    const card = bolos[id] || document.getElementById('bolo-' + id);
    if (card) { card.remove(); delete bolos[id]; }
}
