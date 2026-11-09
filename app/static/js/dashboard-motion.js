/* Coordinate presentation only. Numeric targets always come from the rendered page. */
(() => {
  const preference = matchMedia('(prefers-reduced-motion: reduce)');
  const currency = new Intl.NumberFormat('es-GT', {minimumFractionDigits: 2, maximumFractionDigits: 2});
  const integer = new Intl.NumberFormat('es-GT', {maximumFractionDigits: 0});
  let previous = new Map();
  let finishCounters = () => {};
  let observer;

  function cssNumber(style, name) {
    return parseFloat(style.getPropertyValue(name));
  }

  function counters(root, initial, animate) {
    finishCounters();
    const style = getComputedStyle(root);
    const speed = cssNumber(style, '--motion-speed');
    const duration = cssNumber(style, '--counter-ms') * speed;
    const start = performance.now();
    const targets = new Map();
    const jobs = [];
    for (const [index, node] of [...root.querySelectorAll('[data-counter]')].entries()) {
      const key = node.closest('.metric').querySelector('.metric-name').textContent.trim();
      const target = Number(node.dataset.counter);
      const money = node.hasAttribute('data-money');
      const format = money ? n => 'Q ' + currency.format(n) : n => integer.format(n);
      const from = initial ? 0 : previous.get(key) ?? target;
      const final = format(target);
      // Expose one stable value to assistive technology throughout interpolation.
      const spoken = document.createElement('span');
      spoken.className = 'sr-only';
      spoken.textContent = final;
      const visual = document.createElement('span');
      visual.setAttribute('aria-hidden', 'true');
      visual.textContent = final;
      node.replaceChildren(spoken, visual);
      targets.set(key, target);
      if (!animate || from === target) continue;
      const delay = initial ? (cssNumber(style, '--kpi-start-ms') + index * cssNumber(style, '--kpi-step-ms')) * speed : 0;
      visual.textContent = format(from);
      jobs.push({visual, target, from, format, final, delay});
    }
    previous = targets;
    let frame;
    finishCounters = () => {
      cancelAnimationFrame(frame);
      for (const job of jobs) job.visual.textContent = job.final;
    };
    function tick(now) {
      let pending = false;
      for (const job of jobs) {
        const progress = Math.max(0, Math.min(1, (now - start - job.delay) / duration));
        const value = job.from + (job.target - job.from) * (1 - (1 - progress) ** 3);
        const text = progress === 1 ? job.final : job.format(value);
        if (text !== job.visual.textContent) job.visual.textContent = text;
        if (progress < 1) pending = true;
      }
      if (pending) frame = requestAnimationFrame(tick);
    }
    if (jobs.length) frame = requestAnimationFrame(tick);
  }

  function lowerPanels(root, initial) {
    const started = performance.now();
    const speed = cssNumber(getComputedStyle(root), "--motion-speed");
    observer?.disconnect();
    if (!('IntersectionObserver' in window)) return;
    observer = new IntersectionObserver(entries => {
      let index = 0;
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const panel = entry.target;
        panel.style.setProperty('--panel-index', index++);
        const wait = initial ? Math.max(0, 1040 * speed - (performance.now() - started)) : 0;
        panel.style.setProperty('--panel-wait', wait + 'ms');
        panel.classList.add('panel-reveal');
        observer.unobserve(panel);
      }
    });
    root.querySelectorAll('.secondary > .sheet, .activity-grid > .sheet').forEach(panel => observer.observe(panel));
  }

  function present(initial) {
    const root = document.querySelector('.executive');
    if (!root) return;
    const animate = !preference.matches && !document.hidden;
    counters(root, initial, animate);
    if (!animate) return;
    if (initial) {
      document.body.classList.add('shell-intro');
      document.querySelectorAll('.sidebar .nav-link').forEach((link, index) =>
        link.style.setProperty('--nav-index', Math.min(index, 8)));
      root.classList.add('dashboard-intro');
    } else {
      root.classList.add('dashboard-refresh');
    }
    lowerPanels(root, initial);
  }

  function settle() {
    finishCounters();
    observer?.disconnect();
    document.body.classList.remove('shell-intro');
    const root = document.querySelector('.executive');
    root?.classList.remove('dashboard-intro', 'dashboard-refresh');
    root?.querySelectorAll('.panel-reveal,.chart-reveal').forEach(el => el.classList.remove('panel-reveal', 'chart-reveal'));
  }

  present(true);
  document.addEventListener('dashboard:updated', () => present(false));
  document.addEventListener('visibilitychange', () => { if (document.hidden) settle(); });
  preference.addEventListener('change', () => { if (preference.matches) settle(); });
})();
