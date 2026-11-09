/* Shared desktop navigation: rail labels and section menus on every workspace page. */
(() => {
  const sidebar = document.querySelector('#sidebar');
  if (!sidebar) return;
  try {
    if (document.querySelector('.executive') && !sessionStorage.getItem('pos.workspace.entered')) {
      sessionStorage.setItem('pos.workspace.entered', '1');
      document.body.classList.add('first-workspace-entry');
      setTimeout(() => document.body.classList.remove('first-workspace-entry'), 550);
    }
  } catch {}
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
