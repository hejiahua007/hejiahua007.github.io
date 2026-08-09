(function () {
  'use strict';

  var root = document.documentElement;
  var themeButton = document.querySelector('[data-theme-toggle]');
  var navButton = document.querySelector('[data-nav-toggle]');
  var nav = document.querySelector('[data-primary-nav]');
  var sidebar = document.querySelector('[data-vault-sidebar]');
  var overlay = document.querySelector('[data-directory-overlay]');
  var directoryOpen = document.querySelector('[data-directory-open]');
  var directoryClose = document.querySelector('[data-directory-close]');

  function setTheme(theme) {
    root.dataset.theme = theme;
    localStorage.setItem('garden-theme', theme);
  }

  if (themeButton) {
    themeButton.addEventListener('click', function () {
      setTheme(root.dataset.theme === 'dark' ? 'light' : 'dark');
    });
  }

  if (navButton && nav) {
    navButton.addEventListener('click', function () {
      var open = nav.classList.toggle('is-open');
      navButton.setAttribute('aria-expanded', String(open));
    });
    nav.addEventListener('click', function (event) {
      if (event.target.closest('a')) {
        nav.classList.remove('is-open');
        navButton.setAttribute('aria-expanded', 'false');
      }
    });
  }

  function setDirectory(open) {
    if (!sidebar || !overlay || !directoryOpen) return;
    sidebar.classList.toggle('is-open', open);
    overlay.classList.toggle('is-open', open);
    directoryOpen.setAttribute('aria-expanded', String(open));
    document.body.style.overflow = open ? 'hidden' : '';
  }

  if (directoryOpen) directoryOpen.addEventListener('click', function () { setDirectory(true); });
  if (directoryClose) directoryClose.addEventListener('click', function () { setDirectory(false); });
  if (overlay) overlay.addEventListener('click', function () { setDirectory(false); });

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
      setDirectory(false);
      if (nav && navButton) {
        nav.classList.remove('is-open');
        navButton.setAttribute('aria-expanded', 'false');
      }
    }
  });

  var treeDetails = Array.prototype.slice.call(document.querySelectorAll('[data-tree-path]'));
  var storedTree = {};
  try { storedTree = JSON.parse(localStorage.getItem('garden-tree-state') || '{}'); } catch (_error) { storedTree = {}; }

  treeDetails.forEach(function (details) {
    var path = details.getAttribute('data-tree-path');
    if (Object.prototype.hasOwnProperty.call(storedTree, path) && !details.querySelector('[aria-current="page"]')) {
      details.open = storedTree[path];
    }
    details.addEventListener('toggle', function () {
      storedTree[path] = details.open;
      localStorage.setItem('garden-tree-state', JSON.stringify(storedTree));
    });
  });

  document.querySelectorAll('[data-folder-link]').forEach(function (link) {
    link.addEventListener('click', function (event) { event.stopPropagation(); });
  });

  var currentTreeItem = document.querySelector('.vault-tree [aria-current="page"]');
  if (currentTreeItem) {
    var parent = currentTreeItem.parentElement;
    while (parent && parent !== document.body) {
      if (parent.tagName === 'DETAILS') parent.open = true;
      parent = parent.parentElement;
    }
    currentTreeItem.scrollIntoView({ block: 'center' });
  }
}());

