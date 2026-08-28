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
  var filterInput = document.querySelector('[data-vault-filter]');
  var filterClear = document.querySelector('[data-vault-filter-clear]');
  var filterStatus = document.querySelector('[data-vault-filter-status]');
  var lastDirectoryTrigger = null;

  function readStorage(key, fallback) {
    try {
      var value = localStorage.getItem(key);
      return value === null ? fallback : value;
    } catch (_error) {
      return fallback;
    }
  }

  function writeStorage(key, value) {
    try { localStorage.setItem(key, value); } catch (_error) { /* Storage can be unavailable. */ }
  }

  function updateThemeControl() {
    if (!themeButton) return;
    var dark = root.dataset.theme === 'dark';
    themeButton.setAttribute('aria-pressed', String(dark));
    themeButton.setAttribute('aria-label', dark ? '切换到浅色模式' : '切换到深色模式');
  }

  function setTheme(theme) {
    root.dataset.theme = theme;
    writeStorage('garden-theme', theme);
    updateThemeControl();
  }

  if (themeButton) {
    updateThemeControl();
    themeButton.addEventListener('click', function () {
      setTheme(root.dataset.theme === 'dark' ? 'light' : 'dark');
    });
  }

  function setNavigation(open) {
    if (!nav || !navButton) return;
    nav.classList.toggle('is-open', open);
    navButton.setAttribute('aria-expanded', String(open));
    navButton.querySelector('.sr-only').textContent = open ? '关闭导航' : '打开导航';
  }

  if (navButton && nav) {
    navButton.addEventListener('click', function () {
      var open = !nav.classList.contains('is-open');
      setNavigation(open);
      if (open) {
        var firstLink = nav.querySelector('a');
        if (firstLink) firstLink.focus();
      }
    });
    nav.addEventListener('click', function (event) {
      if (event.target.closest('a')) {
        setNavigation(false);
      }
    });
    document.addEventListener('click', function (event) {
      if (nav.classList.contains('is-open') && !nav.contains(event.target) && !navButton.contains(event.target)) {
        setNavigation(false);
      }
    });
  }

  function setDirectory(open) {
    if (!sidebar || !overlay || !directoryOpen) return;
    if (open) lastDirectoryTrigger = document.activeElement;
    sidebar.classList.toggle('is-open', open);
    overlay.classList.toggle('is-open', open);
    directoryOpen.setAttribute('aria-expanded', String(open));
    document.body.style.overflow = open ? 'hidden' : '';
    if (open && directoryClose) {
      window.requestAnimationFrame(function () { directoryClose.focus(); });
    } else if (!open && lastDirectoryTrigger && typeof lastDirectoryTrigger.focus === 'function') {
      lastDirectoryTrigger.focus();
      lastDirectoryTrigger = null;
    }
  }

  if (directoryOpen) directoryOpen.addEventListener('click', function () { setDirectory(true); });
  if (directoryClose) directoryClose.addEventListener('click', function () { setDirectory(false); });
  if (overlay) overlay.addEventListener('click', function () { setDirectory(false); });

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
      setDirectory(false);
      setNavigation(false);
      if (navButton) navButton.focus();
    }
    if (event.key === 'Tab' && sidebar && sidebar.classList.contains('is-open')) {
      var focusable = Array.prototype.slice.call(sidebar.querySelectorAll('a[href], button:not([disabled]), input:not([disabled])'));
      if (!focusable.length) return;
      var first = focusable[0];
      var last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  });

  var treeDetails = Array.prototype.slice.call(document.querySelectorAll('[data-tree-path]'));
  var storedTree = {};
  try { storedTree = JSON.parse(readStorage('garden-tree-state', '{}')); } catch (_error) { storedTree = {}; }

  treeDetails.forEach(function (details) {
    var path = details.getAttribute('data-tree-path');
    if (Object.prototype.hasOwnProperty.call(storedTree, path) && !details.querySelector('[aria-current="page"]')) {
      details.open = storedTree[path];
    }
    details.addEventListener('toggle', function () {
      if (filterInput && filterInput.value.trim()) return;
      storedTree[path] = details.open;
      writeStorage('garden-tree-state', JSON.stringify(storedTree));
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
    currentTreeItem.scrollIntoView({ block: 'nearest' });
  }

  function normalize(value) {
    return value.toLocaleLowerCase('zh-CN').replace(/\s+/g, ' ').trim();
  }

  function restoreTreeState() {
    treeDetails.forEach(function (details) {
      var hasCurrent = Boolean(details.querySelector('[aria-current="page"]'));
      var path = details.getAttribute('data-tree-path');
      details.open = hasCurrent || (Object.prototype.hasOwnProperty.call(storedTree, path) && storedTree[path]);
    });
  }

  function applyVaultFilter() {
    if (!filterInput) return;
    var query = normalize(filterInput.value);
    var fileItems = Array.prototype.slice.call(document.querySelectorAll('[data-tree-file]'));
    var nodeItems = Array.prototype.slice.call(document.querySelectorAll('[data-tree-node]'));

    if (filterClear) filterClear.hidden = !query;
    if (!query) {
      fileItems.concat(nodeItems).forEach(function (item) { item.hidden = false; });
      restoreTreeState();
      if (filterStatus) filterStatus.textContent = '';
      return;
    }

    fileItems.forEach(function (item) {
      item.hidden = normalize(item.textContent).indexOf(query) === -1;
    });

    nodeItems.slice().reverse().forEach(function (node) {
      var folderLink = node.querySelector(':scope > details > summary a');
      var directMatch = folderLink && normalize(folderLink.textContent).indexOf(query) !== -1;
      if (directMatch) {
        node.querySelectorAll('[data-tree-node], [data-tree-file]').forEach(function (child) { child.hidden = false; });
      }
      var descendantMatch = Boolean(node.querySelector('[data-tree-node]:not([hidden]), [data-tree-file]:not([hidden])'));
      node.hidden = !(directMatch || descendantMatch);
      var details = node.querySelector(':scope > details');
      if (details && !node.hidden) details.open = true;
    });

    var visibleFiles = fileItems.filter(function (item) { return !item.hidden; }).length;
    var visibleFolders = nodeItems.filter(function (item) { return !item.hidden; }).length;
    if (filterStatus) {
      filterStatus.textContent = visibleFiles + visibleFolders > 0
        ? '找到 ' + visibleFolders + ' 个文件夹、' + visibleFiles + ' 篇文章'
        : '没有找到匹配内容';
    }
  }

  if (filterInput) filterInput.addEventListener('input', applyVaultFilter);
  if (filterClear) filterClear.addEventListener('click', function () {
    filterInput.value = '';
    applyVaultFilter();
    filterInput.focus();
  });
}());
