const overlay = document.getElementById('overlay');
const titleEl = document.getElementById('title');
const textEl = document.getElementById('text');
const secondsEl = document.getElementById('seconds');
const ringFg = document.getElementById('ringFg');

const cancelBox = document.getElementById('cancel');
const cancelTitle = document.getElementById('cancelTitle');
const cancelText = document.getElementById('cancelText');

const alertSound = document.getElementById('alertSound');

// Circunferencia del círculo (2πr) con r=54
const CIRC = 2 * Math.PI * 54;
ringFg.style.strokeDasharray = `${CIRC}`;

let countdownTimer = null;

// Fallback beep si no hay archivo OGG disponible o falla autoplay
async function beepFallback() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 660; // A5-ish
    gain.gain.value = 0.08;
    osc.connect(gain).connect(ctx.destination);
    osc.start();
    setTimeout(() => { osc.stop(); ctx.close(); }, 250);
  } catch (_) {}
}

function showAlert({ title, text, duration, sound, soundFile }) {
  if (sound) {
    let tried = false;
    const play = () => {
      if (tried) return;
      tried = true;
      if (soundFile) {
        alertSound.src = soundFile;
        alertSound.currentTime = 0;
        alertSound.volume = 0.6;
        alertSound.play().catch(beepFallback);
      } else {
        beepFallback();
      }
    };
    play();
  }

  titleEl.textContent = title || 'LIMPIEZA DE VEHÍCULOS';
  textEl.textContent = text || 'Se eliminarán vehículos desocupados en breve.';

  overlay.classList.remove('hidden');

  const secs = Math.max(1, Math.floor(duration || 10));
  secondsEl.textContent = `${secs}`;

  // reset ring
  ringFg.style.strokeDashoffset = '0';

  if (countdownTimer) clearInterval(countdownTimer);

  const start = Date.now();
  countdownTimer = setInterval(() => {
    const elapsed = Math.floor((Date.now() - start) / 1000);
    const left = Math.max(0, secs - elapsed);
    secondsEl.textContent = `${left}`;

    const progress = Math.min(1, elapsed / secs);
    ringFg.style.strokeDashoffset = `${CIRC * progress}`;

    if (left <= 0) {
      clearInterval(countdownTimer);
      countdownTimer = null;
      overlay.classList.add('hidden');
    }
  }, 200);
}

function showCancel({ title, text, duration }) {
  overlay.classList.add('hidden');

  cancelTitle.textContent = title || 'LIMPIEZA CANCELADA';
  cancelText.textContent = text || 'Un administrador canceló la limpieza.';

  cancelBox.classList.remove('hidden');
  setTimeout(() => cancelBox.classList.add('hidden'), Math.max(1000, duration || 3000));
}

function toast(text) {
  // Mensaje temporal minimalista (solo para Debug)
  const el = document.createElement('div');
  el.textContent = text;
  el.style.position = 'fixed';
  el.style.bottom = '24px';
  el.style.right = '24px';
  el.style.padding = '10px 12px';
  el.style.background = 'rgba(0,0,0,0.6)';
  el.style.color = '#fff';
  el.style.borderRadius = '8px';
  el.style.fontSize = '14px';
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 3000);
}

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'show') showAlert(data);
  if (data.action === 'cancel') showCancel(data);
  if (data.action === 'toast') toast(data.text || '');
});
