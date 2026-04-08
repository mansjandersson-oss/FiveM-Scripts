const game = document.getElementById('game');
const fishEl = document.getElementById('fish');
const barEl = document.getElementById('bar');
const captureEl = document.getElementById('capture');

let active = false;
let hold = false;
let fishPos = 0.5;
let fishVel = 0;
let fishTarget = 0.5;
let barPos = 0.4;
let barHeight = 0.2;
let capture = 0;
let fishData = null;
let conf = null;
let timer = 0;
let raf = null;

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

function finish(success) {
  active = false;
  if (raf) cancelAnimationFrame(raf);

  const minW = Number(fishData.minWeight || 0.2);
  const maxW = Number(fishData.maxWeight || 1.0);
  const weight = +(minW + Math.random() * (maxW - minW)).toFixed(2);

  fetch(`https://${GetParentResourceName()}/finish`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      success,
      perfect: capture >= (conf.minigame.perfectThreshold || 0.82),
      fish: fishData,
      weight
    })
  });

  game.classList.add('hidden');
}

function chooseNewTarget() {
  fishTarget = Math.random() * 0.9 + 0.05;
}

function tick() {
  if (!active) return;
  const dt = 1 / 60;

  timer -= dt;
  if (timer <= 0) {
    finish(false);
    return;
  }

  if (Math.abs(fishTarget - fishPos) < 0.03) chooseNewTarget();

  const aggression = Number(conf.aggression || 1.0) * Number(conf.minigame.fishAggressionMultiplier || 1.0);
  const baseSpeed = Number(conf.minigame.fishSpeedMin || 0.15) + Math.random() * (Number(conf.minigame.fishSpeedMax || 0.45) - Number(conf.minigame.fishSpeedMin || 0.15));
  const accel = (fishTarget - fishPos) * baseSpeed * aggression;
  fishVel = (fishVel + accel) * 0.92;
  fishPos = clamp(fishPos + fishVel * dt * 4, 0, 1);

  if (hold) {
    barPos -= Number(conf.minigame.barRisePerSecond || 0.9) * dt;
  } else {
    barPos += Number(conf.minigame.barFallPerSecond || 0.72) * dt;
  }
  barPos = clamp(barPos, 0, 1 - barHeight);

  const fishInside = fishPos >= barPos && fishPos <= (barPos + barHeight);
  if (fishInside) {
    capture += Number(conf.minigame.captureFillPerSecond || 0.28) * dt;
  } else {
    capture -= Number(conf.minigame.captureDrainPerSecond || 0.24) * dt;
  }
  capture = clamp(capture, 0, 1);

  if (capture >= 1) {
    finish(true);
    return;
  }

  fishEl.style.top = `${fishPos * 100}%`;
  barEl.style.top = `${barPos * 100}%`;
  barEl.style.height = `${barHeight * 100}%`;
  captureEl.style.width = `${capture * 100}%`;

  raf = requestAnimationFrame(tick);
}

window.addEventListener('message', (e) => {
  const data = e.data;
  if (data.action !== 'start') return;

  conf = data.config;
  fishData = conf.fish;
  barHeight = clamp(Number(conf.barHeight || conf.minigame.barHeight || 0.18), 0.1, 0.4);
  fishPos = Math.random() * 0.7 + 0.15;
  fishVel = 0;
  chooseNewTarget();
  barPos = 0.4;
  capture = 0.2;
  timer = Number(conf.catchWindow || 12);
  active = true;

  game.classList.remove('hidden');
  tick();
});

window.addEventListener('keydown', (e) => {
  if (e.code === 'Space') hold = true;
  if (e.code === 'Escape' && active) finish(false);
});

window.addEventListener('keyup', (e) => {
  if (e.code === 'Space') hold = false;
});
