const game = document.getElementById('game');
const panel = document.querySelector('.panel');
const fishEl = document.getElementById('fish');
const barEl = document.getElementById('bar');
const captureEl = document.getElementById('capture');
const timerEl = document.getElementById('timer');
const zoneEl = document.getElementById('zone');
const fishNameEl = document.getElementById('fishName');
const capturePercentEl = document.getElementById('capturePercent');
const barBonusEl = document.getElementById('barBonus');
const readerBonusEl = document.getElementById('readerBonus');
const statusEl = document.getElementById('status');

let active = false;
let hold = false;
let fishPos = 0.5;
let fishVel = 0;
let fishTarget = 0.5;
let barPos = 0.4;
let barHeight = 0.2;
let capture = 0;
let conf = null;
let timer = 0;
let catchId = null;
let raf = null;
let lastFrame = 0;

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));
const percent = (value, decimals = 0) => `${(value * 100).toFixed(decimals)}%`;

function resourceName() {
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'nb-fishing';
}

async function nui(event, data) {
  try {
    await fetch(`https://${resourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });
  } catch {
    // Local browser preview saknar FiveM-callbacks.
  }
}

function readableFishName(fish) {
  const label = fish?.label || fish?.name || fish?.item || 'Fisk';
  return String(label)
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

function setStatus(text) {
  statusEl.textContent = text;
}

function render() {
  const meterHeight = barEl.parentElement.clientHeight;
  const fishY = fishPos * meterHeight;
  const barY = barPos * meterHeight;

  fishEl.style.transform = `translate(-50%, ${fishY - 12}px)`;
  barEl.style.transform = `translateY(${barY}px)`;
  barEl.style.height = `${barHeight * 100}%`;
  captureEl.style.width = percent(capture);
  timerEl.textContent = Math.max(0, timer).toFixed(1);
  capturePercentEl.textContent = percent(capture);

  panel.classList.toggle('danger', capture < 0.18);
}

function finish(success) {
  if (!active) return;

  active = false;
  hold = false;
  if (raf) cancelAnimationFrame(raf);

  void nui('finish', {
    success,
    perfect: capture >= (conf?.minigame?.perfectThreshold || 0.82),
    catchId,
  });

  game.classList.add('hidden');
}

function chooseNewTarget() {
  fishTarget = Math.random() * 0.88 + 0.06;
}

function tick(now = performance.now()) {
  if (!active) return;

  const dt = clamp((now - lastFrame) / 1000 || 1 / 60, 1 / 120, 1 / 24);
  lastFrame = now;
  timer -= dt;

  if (timer <= 0) {
    setStatus('Fisken slet sig.');
    finish(false);
    return;
  }

  if (Math.abs(fishTarget - fishPos) < 0.025) chooseNewTarget();

  const minSpeed = Number(conf.minigame.fishSpeedMin || 0.15);
  const maxSpeed = Number(conf.minigame.fishSpeedMax || 0.45);
  const speed = minSpeed + Math.random() * (maxSpeed - minSpeed);
  const aggression = Number(conf.aggression || 1.0) * Number(conf.minigame.fishAggressionMultiplier || 1.0);
  const accel = (fishTarget - fishPos) * speed * aggression;

  fishVel = (fishVel + accel) * 0.91;
  fishPos = clamp(fishPos + fishVel * dt * 4, 0, 1);

  if (hold) {
    barPos -= Number(conf.minigame.barRisePerSecond || 0.9) * dt;
  } else {
    barPos += Number(conf.minigame.barFallPerSecond || 0.72) * dt;
  }
  barPos = clamp(barPos, 0, 1 - barHeight);

  const fishInside = fishPos >= barPos && fishPos <= barPos + barHeight;
  panel.classList.toggle('locked', fishInside);

  if (fishInside) {
    capture += Number(conf.minigame.captureFillPerSecond || 0.28) * dt;
    setStatus('Bra kontroll. Håll fisken i zonen.');
  } else {
    capture -= Number(conf.minigame.captureDrainPerSecond || 0.24) * dt;
    setStatus(hold ? 'Släpp lite för att fånga upp rörelsen.' : 'Håll för att lyfta kontrollzonen.');
  }
  capture = clamp(capture, 0, 1);

  if (capture >= 1) {
    setStatus('Fångad!');
    finish(true);
    return;
  }

  render();
  raf = requestAnimationFrame(tick);
}

function startMinigame(config) {
  conf = config;
  catchId = config.catchId;
  barHeight = clamp(Number(config.barHeight || config.minigame.barHeight || 0.18), 0.1, 0.42);
  fishPos = Math.random() * 0.7 + 0.15;
  fishVel = 0;
  chooseNewTarget();
  barPos = 0.4;
  capture = 0.2;
  timer = Number(config.catchWindow || 12);
  hold = false;
  active = true;
  lastFrame = performance.now();

  const effects = config.skillEffects || {};
  zoneEl.textContent = config.zoneLabel || 'Fiskevatten';
  fishNameEl.textContent = readableFishName(config.fish);
  barBonusEl.textContent = percent(Number(effects.steadyHands || 0), 1);
  readerBonusEl.textContent = percent(Number(effects.fishReader || 0), 1);
  setStatus('Håll mellanslag eller musknapp för att höja baren.');

  game.classList.remove('hidden');
  render();
  raf = requestAnimationFrame(tick);
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action !== 'start') return;

  if (raf) cancelAnimationFrame(raf);
  startMinigame(data.config);
});

window.addEventListener('keydown', (event) => {
  if (event.code === 'Space') {
    event.preventDefault();
    hold = true;
  }

  if (event.code === 'Escape' && active) {
    finish(false);
  }
});

window.addEventListener('keyup', (event) => {
  if (event.code === 'Space') {
    event.preventDefault();
    hold = false;
  }
});

window.addEventListener('pointerdown', () => {
  hold = true;
});

window.addEventListener('pointerup', () => {
  hold = false;
});

window.addEventListener('blur', () => {
  hold = false;
});

if (new URLSearchParams(window.location.search).has('preview')) {
  startMinigame({
    catchId: 'preview',
    zoneLabel: 'Del Perro Pier',
    fish: { label: 'Gyllene tonfisk' },
    aggression: 0.85,
    barHeight: 0.24,
    catchWindow: 14,
    skillEffects: {
      steadyHands: 0.06,
      fishReader: 0.12,
    },
    minigame: {
      barRisePerSecond: 0.9,
      barFallPerSecond: 0.72,
      captureFillPerSecond: 0.28,
      captureDrainPerSecond: 0.24,
      fishSpeedMin: 0.15,
      fishSpeedMax: 0.45,
      fishAggressionMultiplier: 1.0,
      barHeight: 0.18,
      perfectThreshold: 0.82,
    },
  });
}
