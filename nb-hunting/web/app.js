const app = document.getElementById('app');
const title = document.getElementById('title');
const stats = document.getElementById('stats');
const missions = document.getElementById('missions');
const zones = document.getElementById('zones');
const leaderboard = document.getElementById('leaderboard');
const closeBtn = document.getElementById('closeBtn');
const licenseBtn = document.getElementById('licenseBtn');
const loadoutBtn = document.getElementById('loadoutBtn');

const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'nb-hunting';
let latest = null;

function nuiPost(endpoint, data = {}) {
  fetch(`https://${resource}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data)
  });
}

function card(titleText, descText, buttonText, onClick) {
  const el = document.createElement('div');
  el.className = 'card';
  el.innerHTML = `<strong>${titleText}</strong><div>${descText || ''}</div>`;
  if (buttonText) {
    const btn = document.createElement('button');
    btn.textContent = buttonText;
    btn.addEventListener('click', onClick);
    el.appendChild(btn);
  }
  return el;
}

function render(payload) {
  latest = payload;
  const data = payload.hunterData || { level: 1, xp: 0, license: false };
  title.textContent = payload.labels?.title || 'Hunter';
  stats.textContent = `Level: ${data.level} | XP: ${data.xp} | Licens: ${data.license ? 'Ja' : 'Nej'}`;

  missions.innerHTML = '';
  (payload.missions || []).forEach((m) => {
    missions.appendChild(card(m.label, m.description, 'Starta', () => nuiPost('startMission', { id: m.id })));
  });

  zones.innerHTML = '';
  (payload.zones || []).forEach((z) => {
    zones.appendChild(card(z.label, `Radie: ${Math.floor(z.radius)}m`, 'Sätt rutt', () => nuiPost('setRoute', { zoneId: z.id })));
  });

  leaderboard.innerHTML = '';
  (payload.leaderboard || []).forEach((row, index) => {
    leaderboard.appendChild(card(`#${index + 1} ${row.citizenid}`, `XP: ${row.xp} | Lvl: ${row.level} | Kills: ${row.kills}`));
  });

  loadoutBtn.textContent = payload.labels?.requestLoadout || 'Hämta jaktutrustning';

  if (payload.useLicense && !data.license) {
    licenseBtn.classList.remove('hidden');
    licenseBtn.textContent = payload.labels?.buyLicense || 'Köp jaktlicens';
  } else {
    licenseBtn.classList.add('hidden');
  }
}

window.addEventListener('message', (e) => {
  const { action, payload } = e.data || {};
  if (action === 'open') {
    render(payload);
    app.classList.remove('hidden');
  } else if (action === 'close') {
    app.classList.add('hidden');
  } else if (action === 'stats' && latest) {
    latest.hunterData = payload;
    render(latest);
  }
});

closeBtn.addEventListener('click', () => nuiPost('close'));
licenseBtn.addEventListener('click', () => nuiPost('buyLicense'));
loadoutBtn.addEventListener('click', () => nuiPost('requestLoadout'));
document.addEventListener('keyup', (e) => {
  if (e.key === 'Escape') nuiPost('close');
});
