const container = document.getElementById('fvg-notify-container');
let notifyId = 0;

window.addEventListener('message', function(event) {
    const data = event.data;
    if (!data || data.action !== 'notify') return;

    // Pozíció beállítása
    container.className = 'pos-' + (data.position || 'top-right');

    createNotification(data);
});

function createNotification(data) {
    const id      = ++notifyId;
    const type     = data.type     || 'info';
    const title    = data.title    || 'Értesítés';
    const message  = data.message  || '';
    const duration = data.duration || 4000;
    const icon     = data.icon     || 'hgi-stroke hgi-information-circle';

    const el = document.createElement('div');
    el.classList.add('fvg-notify', type);
    el.dataset.id = id;

    el.innerHTML = `
        <i class="notify-icon ${icon}"></i>
        <div class="notify-body">
            <span class="notify-title">${escapeHtml(title)}</span>
            <span class="notify-message">${escapeHtml(message)}</span>
        </div>
        <button class="notify-close" title="Bezárás">
            <i class="hgi-stroke hgi-cancel-01"></i>
        </button>
        <div class="notify-progress">
            <div class="notify-progress-bar"></div>
        </div>
    `;

    container.appendChild(el);

    // Bemenet animáció
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            el.classList.add('show');
        });
    });

    // Haladásjelző sáv animáció
    const bar = el.querySelector('.notify-progress-bar');
    bar.style.transition = `transform ${duration}ms linear`;
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            bar.style.transform = 'scaleX(0)';
        });
    });

    // Automatikus eltüntetés
    const timer = setTimeout(() => closeNotify(el), duration);

    // Bezárás gomb
    el.querySelector('.notify-close').addEventListener('click', () => {
        clearTimeout(timer);
        closeNotify(el);
    });
}

function closeNotify(el) {
    el.classList.remove('show');
    el.classList.add('hide');
    setTimeout(() => {
        el.remove();
        fetch(`https://${GetParentResourceName()}/notifyClosed`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: el.dataset.id })
        });
    }, 350);
}

function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}