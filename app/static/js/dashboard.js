/* Delegation also handles the page fragment returned after a date filter. */
(() => {
  const tooltip = document.createElement('div');
  tooltip.className = 'graph-tooltip';
  tooltip.hidden = true;
  document.body.append(tooltip);

  function showTip(element) {
    const bounds = element.getBoundingClientRect();
    tooltip.textContent = element.dataset.tip;
    tooltip.hidden = false;
    const x = bounds.left + bounds.width / 2 - tooltip.offsetWidth / 2;
    tooltip.style.left = Math.max(8, Math.min(x, innerWidth - tooltip.offsetWidth - 8)) + 'px';
    tooltip.style.top = Math.max(6, bounds.top - tooltip.offsetHeight - 7) + 'px';
  }

  for (const eventName of ['pointerover', 'focusin']) {
    document.addEventListener(eventName, event => {
      const target = event.target.closest('[data-tip]');
      if (target) showTip(target);
    });
  }
  function hideTip() { tooltip.hidden = true; }
  for (const eventName of ['pointerout', 'focusout', 'submit']) {
    document.addEventListener(eventName, hideTip);
  }
  window.addEventListener('scroll', hideTip, {passive: true});
  document.addEventListener('click', event => {
    const choice = event.target.closest('button[data-view]');
    if (!choice) return;
    const panel = choice.closest('[data-switcher]');
    for (const button of panel.querySelectorAll('[data-view]')) {
      button.setAttribute('aria-pressed', String(button === choice));
    }
    for (const pane of panel.querySelectorAll('[data-pane]')) {
      pane.hidden = pane.dataset.pane !== choice.dataset.view;
      if (!pane.hidden) window.Enterprise.pulse(pane);
    }
  });
})();
