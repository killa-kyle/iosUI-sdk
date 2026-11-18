'use strict';
const choices = [...document.querySelectorAll('[data-choice]')];
const selected = new Set();
let mode = 'multiple';
function renderSelection() {
  choices.forEach(button => {
    const active = selected.has(button.dataset.choice);
    button.setAttribute('aria-pressed', String(active));
    button.querySelector('i').textContent = active ? '✓' : '＋';
  });
  document.querySelector('#selection-output').textContent = selected.size
    ? `Selected: ${[...selected].join(', ')}` : 'Nothing selected. A clean slate.';
}
choices.forEach((button, index) => {
  button.addEventListener('click', () => {
    const value = button.dataset.choice;
    if (selected.has(value)) selected.delete(value);
    else { if (mode === 'single') selected.clear(); selected.add(value); }
    renderSelection();
  });
  button.addEventListener('keydown', event => {
    if (['ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft', 'Home', 'End'].includes(event.key)) {
      event.preventDefault();
      const delta = ['ArrowUp', 'ArrowLeft'].includes(event.key) ? -1 : 1;
      const next = event.key === 'Home' ? 0 : event.key === 'End' ? choices.length - 1
        : (index + delta + choices.length) % choices.length;
      choices[next].focus();
    }
  });
});
document.querySelectorAll('[name=mode]').forEach(input => input.addEventListener('change', () => {
  mode = input.value;
  if (mode === 'single' && selected.size > 1) {
    const first = selected.values().next().value; selected.clear(); selected.add(first);
  }
  renderSelection();
}));
const range = document.querySelector('#energy');
function renderValue(value) {
  const clamped = Math.min(100, Math.max(0, Math.round(Number(value) / 10) * 10));
  range.value = String(clamped);
  document.querySelector('#value-output').value = String(clamped);
  document.querySelector('.value-orbit>span').style.transform = `rotate(${clamped * 1.8}deg)`;
  document.querySelector('#less').disabled = clamped === 0;
  document.querySelector('#more').disabled = clamped === 100;
}
range.addEventListener('input', () => renderValue(range.value));
document.querySelector('#less').addEventListener('click', () => renderValue(Number(range.value) - 10));
document.querySelector('#more').addEventListener('click', () => renderValue(Number(range.value) + 10));
renderValue(40);
document.querySelector('#reveal').addEventListener('click', event => {
  const button = event.currentTarget;
  const open = button.getAttribute('aria-expanded') !== 'true';
  button.setAttribute('aria-expanded', String(open));
  document.querySelector('#secret').hidden = !open;
  document.querySelector('#reveal-icon').textContent = open ? '−' : '＋';
});
document.querySelector('#copy').addEventListener('click', async event => {
  const button = event.currentTarget;
  try {
    await navigator.clipboard.writeText(document.querySelector('#dependency').textContent);
    button.textContent = 'Copied ✓';
    document.querySelector('#copy-status').textContent = 'Swift package dependency copied.';
    setTimeout(() => { button.textContent = 'Copy ↗'; }, 2000);
  } catch {
    button.textContent = 'Select code below';
    document.querySelector('#copy-status').textContent = 'Clipboard unavailable. Select and copy the code below.';
  }
});
