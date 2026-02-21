let warnTimer  = null;
let fineTimer  = null;
let flashTimer = null;

window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || !d.action) return;

    switch (d.action) {
        case 'showWarn':
            showWarn(d.label, d.limit);
            break;
        case 'flash':
            doFlash(d.speed, d.limit, d.fine);
            break;
        case 'setZones':
            // Zónák fogadása (jövőbeli térkép használathoz)
            break;
    }
});

function showWarn(label, limit) {
    const box = document.getElementById('warn-box');
    document.getElementById('warn-sub').textContent =
        label + ' – Határ: ' + limit + ' km/h';
    box.classList.remove('hidden');

    if (warnTimer) clearTimeout(warnTimer);
    warnTimer = setTimeout(() => {
        box.classList.add('hidden');
    }, 5000);
}

function doFlash(speed, limit, fine) {
    // 1. Vaku effekt
    const overlay = document.getElementById('flash-overlay');
    overlay.classList.add('active');
    if (flashTimer) clearTimeout(flashTimer);
    flashTimer = setTimeout(() => overlay.classList.remove('active'), 120);

    // 2. Bírsság popup
    const popup = document.getElementById('fine-popup');
    document.getElementById('fine-speed').textContent =
        speed + ' km/h – Határ: ' + limit + ' km/h';
    document.getElementById('fine-amount').textContent = '-$' + fine.toLocaleString();

    popup.classList.remove('hidden', 'show');
    void popup.offsetWidth;   // reflow
    popup.classList.add('show');

    if (fineTimer) clearTimeout(fineTimer);
    fineTimer = setTimeout(() => {
        popup.classList.remove('show');
        setTimeout(() => popup.classList.add('hidden'), 400);
    }, 4000);
}
