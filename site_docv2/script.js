// ════════════════════════════════════════════════════════════════
// opti_route — Document d'évolution produit (site_docv2)
// Script global : bascule clair/sombre + état actif du menu.
// Aucun framework, vanilla JS minimaliste.
// ════════════════════════════════════════════════════════════════

(function () {
  'use strict';

  // ----------------------------------------------------------------
  // Bascule du thème clair/sombre
  // ----------------------------------------------------------------
  // Lecture de la préférence stockée en localStorage, sinon on suit
  // la préférence système (prefers-color-scheme).
  const STORAGE_KEY = 'optiroute_v2_theme';

  function getInitialTheme() {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'light' || stored === 'dark') return stored;
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    return prefersDark ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    const icon = document.getElementById('themeIcon');
    if (!icon) return;
    // Icône lune pour mode clair (= "passer en sombre"),
    // icône soleil pour mode sombre (= "passer en clair").
    icon.innerHTML = theme === 'dark'
      ? '<circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>'
      : '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>';
  }

  // Initialisation immédiate pour éviter le flash de thème incorrect.
  applyTheme(getInitialTheme());

  // Branchement du bouton dès que le DOM est prêt.
  document.addEventListener('DOMContentLoaded', function () {
    applyTheme(getInitialTheme());
    const btn = document.getElementById('themeToggle');
    if (btn) {
      btn.addEventListener('click', function () {
        const current = document.documentElement.getAttribute('data-theme') || 'light';
        const next = current === 'dark' ? 'light' : 'dark';
        localStorage.setItem(STORAGE_KEY, next);
        applyTheme(next);
      });
    }

    // ----------------------------------------------------------------
    // Marquage du lien menu actif (état visuel "page courante")
    // ----------------------------------------------------------------
    // On compare le nom de fichier de l'URL courante avec chaque
    // href des liens du menu. Match exact -> classe .active.
    const currentFile = (window.location.pathname.split('/').pop() || 'index.html');
    const links = document.querySelectorAll('.nav-links a[href]');
    links.forEach(function (link) {
      const linkFile = (link.getAttribute('href') || '').split('/').pop();
      if (linkFile === currentFile) {
        link.classList.add('active');
      }
    });
  });
})();
