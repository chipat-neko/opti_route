/*
 * Script commun : toggle thème clair/sombre + animations légères.
 */

// ---------- THEME TOGGLE ----------
(function () {
  const root = document.documentElement;
  const btn = document.getElementById('themeToggle');
  const icon = document.getElementById('themeIcon');

  const STORAGE_KEY = 'opti_route_theme';
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved === 'dark') {
    root.setAttribute('data-theme', 'dark');
  } else if (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    root.setAttribute('data-theme', 'dark');
  }

  function updateIcon() {
    const isDark = root.getAttribute('data-theme') === 'dark';
    if (!icon) return;
    icon.innerHTML = isDark
      // Soleil (mode sombre actif, on propose de basculer en clair)
      ? '<circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>'
      // Lune
      : '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>';
  }
  updateIcon();

  if (btn) {
    btn.addEventListener('click', () => {
      const current = root.getAttribute('data-theme');
      const next = current === 'dark' ? 'light' : 'dark';
      if (next === 'dark') {
        root.setAttribute('data-theme', 'dark');
      } else {
        root.removeAttribute('data-theme');
      }
      localStorage.setItem(STORAGE_KEY, next);
      updateIcon();
    });
  }
})();

// ---------- FADE-IN AU SCROLL ----------
(function () {
  // Respecte la préférence accessibilité "réduire animations".
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  // Cible : élements visuels qui méritent un fade-in léger au scroll.
  // Pas de bling-bling, juste une respiration pro.
  const animatableSelector =
    '.feature-card, .step, .phase, .stat-card, .hero-mock, ' +
    '.muted-banner, .cta, .chart-wrap';

  document.addEventListener('DOMContentLoaded', () => {
    const els = document.querySelectorAll(animatableSelector);
    if (els.length === 0) return;

    // État initial : invisible + décalé bas. Transition douce.
    els.forEach((el) => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(16px)';
      el.style.transition =
        'opacity 500ms cubic-bezier(0.22, 1, 0.36, 1), ' +
        'transform 500ms cubic-bezier(0.22, 1, 0.36, 1)';
    });

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const el = entry.target;
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
            observer.unobserve(el);
          }
        });
      },
      { rootMargin: '0px 0px -50px 0px', threshold: 0.1 }
    );

    els.forEach((el) => observer.observe(el));
  });
})();

// ---------- SCROLL-TO-TOP DOUX ----------
(function () {
  // Ancres internes (#section) -> scroll smooth via CSS scroll-behavior
  // déjà actif sur <html>. Ici on ajoute juste un focus pour
  // accessibilité après scroll.
  document.addEventListener('click', (e) => {
    const link = e.target.closest('a[href^="#"]');
    if (!link) return;
    const id = link.getAttribute('href').slice(1);
    if (!id) return;
    const target = document.getElementById(id);
    if (!target) return;
    setTimeout(() => {
      target.setAttribute('tabindex', '-1');
      target.focus({ preventScroll: true });
    }, 500);
  });
})();
