/* Shared desktop navigation: rail labels and section menus on every workspace page. */
(() => {
  const sidebar = document.querySelector('#sidebar');
  if (!sidebar) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const content = document.querySelector('.page-content');
  let cleanupTimer;
  let animated = [];

  function finishEntry() {
    clearTimeout(cleanupTimer);
    document.body.classList.remove('workspace-entry', 'shell-intro');
    for (const element of animated) {
      element.classList.remove('module-stage');
      element.style.removeProperty('--stage-index');
    }
    animated = [];
  }

  function playEntry() {
    finishEntry();
    if (reduced.matches || document.hidden) return;
    sidebar.querySelectorAll('.nav-link').forEach((link, index) =>
      link.style.setProperty('--nav-index', Math.min(index, 8)));
    if (!content.querySelector('.executive')) {
      // Stage existing blocks. The POS catalog and cart are independent regions.
      const blocks = [...content.children].filter(el =>
        !el.matches('script,style,dialog,noscript,[hidden]') && el.getClientRects().length);
      for (const block of blocks) {
        const regions = block.matches('[data-pos-form]') ? block.querySelectorAll('.pos-layout > *') : [block];
        animated.push(...regions);
      }
      animated.forEach((element, index) => {
        element.style.setProperty('--stage-index', Math.min(index, 6));
        element.classList.add('module-stage');
      });
    }
    document.body.classList.add('workspace-entry', 'shell-intro');
    cleanupTimer = setTimeout(finishEntry, 1800);
  }

  playEntry();
  window.addEventListener('pagehide', finishEntry);
  window.addEventListener('pageshow', event => { if (event.persisted) playEntry(); });
  reduced.addEventListener('change', () => { if (reduced.matches) finishEntry(); });
  const label = document.querySelector('#rail-label');
  const compact = () => innerWidth >= 1024 && document.documentElement.classList.contains('sidebar-compact');
  function show(link) {
    if (!compact()) return;
    const box = link.getBoundingClientRect();
    label.textContent = link.getAttribute('aria-label');
    label.style.left = (sidebar.getBoundingClientRect().right + 10) + 'px';
    label.style.top = (box.top + box.height / 2) + 'px';
    label.hidden = false;
  }
  function hide() { label.hidden = true; }
  sidebar.querySelectorAll('.nav-link').forEach(link => link.removeAttribute('title'));
  for (const type of ['pointerover','focusin']) {
    sidebar.addEventListener(type, event => {
      const link = event.target.closest('.nav-link');
      if (link) show(link);
    });
  }
  for (const type of ['pointerout','focusout']) {
    sidebar.addEventListener(type, event => {
      if (!event.relatedTarget?.closest?.('.nav-link')) hide();
    });
  }
  sidebar.querySelector('nav').addEventListener('scroll', hide, {passive:true});
  document.querySelector('.sidebar-toggle').addEventListener('click', hide);
  window.addEventListener('resize', hide);
  window.addEventListener('pagehide', hide);

  const menus = [...document.querySelectorAll('.workspace-menu, .profile-menu')];
  menus.forEach(menu => menu.addEventListener('toggle', () => {
    if (menu.open) menus.forEach(other => { if (other !== menu) other.open = false; });
  }));
  document.addEventListener('click', event => {
    menus.forEach(menu => { if (!menu.contains(event.target)) menu.open = false; });
  });
  document.addEventListener('keydown', event => {
    if (event.key !== 'Escape') return;
    hide();
    const menu = menus.find(item => item.open);
    if (menu) {
      menu.open = false;
      menu.querySelector('summary').focus();
    }
  });
  // Preserve the rail's scroll position when Django serves the next module.
  const nav = sidebar.querySelector('nav');
  try {
    nav.scrollTop = Number(sessionStorage.getItem('pos.rail.scroll')) || 0;
    const active = nav.querySelector('[aria-current=page]');
    if (active) {
      const item = active.getBoundingClientRect(), bounds = nav.getBoundingClientRect();
      if (item.top < bounds.top || item.bottom > bounds.bottom) nav.scrollTop += item.top - bounds.top;
    }
    window.addEventListener('pagehide', () => sessionStorage.setItem('pos.rail.scroll', nav.scrollTop));
  } catch {}
})();
