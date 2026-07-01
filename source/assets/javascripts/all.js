document.addEventListener("DOMContentLoaded", function(){
  // 2.0 preview flag: ?preview=v2 sets it, ?preview=off clears it (persisted in
  // localStorage). The landing pages (/ and /en/) read this to decide whether to
  // route to 2.0.0. Syncing it here lets the param stick from any page, e.g. a
  // shared /en/2.0.0/?preview=v2 link.
  try {
    var previewParam = new URLSearchParams(window.location.search).get('preview');
    if (previewParam === 'v2') { localStorage.setItem('kac-preview', 'v2'); }
    else if (previewParam === 'off' || previewParam === '0') { localStorage.removeItem('kac-preview'); }
  } catch (e) {}

  // Version and/or language selectors. Each option's value is a "lang/version/"
  // path, so changing either one just navigates there — a real spec page when we
  // have that translation, or a generated interstitial when we don't.
  var selects = document.querySelectorAll('.locales select');
  Array.prototype.forEach.call(selects, function(select){
    select.addEventListener('change', function(event){
      var origin = window.location.origin;
      var target = event.currentTarget.selectedOptions[0].value;
      window.location.replace(origin + "/" + target);
    });
  });
  var select = selects[0];

  // On very narrow viewports the language picker collapses behind a globe
  // button (see the max-width query in v2.css). Toggle it open; the select is
  // hidden via CSS until .locales carries data-open. At wider widths the button
  // is display:none and the select shows inline, so this is a no-op there.
  var locales = document.querySelector('.locales');
  var localesToggle = locales && locales.querySelector('.locales-toggle');
  if (locales && localesToggle) {
    var setLocalesOpen = function(open){
      if (open) { locales.setAttribute('data-open', ''); }
      else { locales.removeAttribute('data-open'); }
      localesToggle.setAttribute('aria-expanded', String(open));
    };
    localesToggle.addEventListener('click', function(){
      var open = !locales.hasAttribute('data-open');
      setLocalesOpen(open);
      if (open && select) { select.focus(); }
    });
    document.addEventListener('keydown', function(event){
      if (event.key === 'Escape' && locales.hasAttribute('data-open')) {
        setLocalesOpen(false);
        localesToggle.focus();
      }
    });
    document.addEventListener('click', function(event){
      if (locales.hasAttribute('data-open') && !locales.contains(event.target)) {
        setLocalesOpen(false);
      }
    });
  }

  // Theme switch: system (follow OS) / light / dark, persisted in localStorage.
  // The chosen theme is applied as data-theme on <html>; the CSS maps it to a
  // forced color-scheme, while "system" simply removes the attribute.
  var root = document.documentElement;
  var STORAGE_KEY = 'kac-theme';
  var buttons = document.querySelectorAll('.theme-switch [data-set-theme]');

  function currentTheme(){ return root.getAttribute('data-theme') || 'system'; }

  function syncPressed(){
    var active = currentTheme();
    buttons.forEach(function(button){
      button.setAttribute('aria-pressed', String(button.getAttribute('data-set-theme') === active));
    });
  }

  buttons.forEach(function(button){
    button.addEventListener('click', function(){
      var theme = button.getAttribute('data-set-theme');
      try {
        if (theme === 'system') { localStorage.removeItem(STORAGE_KEY); }
        else { localStorage.setItem(STORAGE_KEY, theme); }
      } catch (e) {}
      if (theme === 'system') { root.removeAttribute('data-theme'); }
      else { root.setAttribute('data-theme', theme); }
      syncPressed();
    });
  });

  syncPressed();

  // Example changelog: collapsed disclosure on narrow screens, always shown on
  // wide ones. Genuinely opening the <details> on wide renders its content
  // natively, independent of how a given browser hides closed-details content
  // (some hide it via content-visibility on ::details-content, which CSS can't
  // always override). The markup stays closed so narrow screens start collapsed.
  var example = document.querySelector('.changelog-example');
  if (example) {
    var wide = window.matchMedia('(min-width: 48rem)');
    var syncExample = function(){ if (wide.matches) { example.open = true; } };
    syncExample();
    if (wide.addEventListener) { wide.addEventListener('change', syncExample); }
    else if (wide.addListener) { wide.addListener(syncExample); }
  }

  // Table of contents: built from the article's headings. A sticky sidebar on
  // wide screens, a "Contents" disclosure on narrow ones. Generated in JS so it
  // stays in sync with the headings and degrades gracefully without scripting.
  var tocHost = document.getElementById('toc');
  var article = document.querySelector('.article-body .content');
  if (tocHost && article) {
    // Skip the What/Why/Who intro cards: they are the page's introduction, not
    // navigable sections, and jumping to one lands inside the triptych rather
    // than at a section start. (The heading-anchor code skips them the same way.)
    var headings = Array.prototype.filter.call(
      article.querySelectorAll('h2[id]'),
      function(h){ return !h.closest('.intro-card'); }
    );
    if (headings.length) {
      var details = document.createElement('details');
      details.className = 'toc-disclosure';
      var summary = document.createElement('summary');
      summary.textContent = 'On this page';
      details.appendChild(summary);

      var nav = document.createElement('nav');
      nav.setAttribute('aria-label', 'Table of contents');

      var list = document.createElement('ul');
      list.className = 'toc-list';
      var linkFor = {};
      headings.forEach(function(h){
        var li = document.createElement('li');
        li.className = 'toc-item';
        var a = document.createElement('a');
        a.href = '#' + h.id;
        a.textContent = h.textContent;
        li.appendChild(a);
        list.appendChild(li);
        linkFor[h.id] = a;
      });
      nav.appendChild(list);
      details.appendChild(nav);
      tocHost.appendChild(details);

      // Collapsible at every width: open by default on wide screens (room for a
      // sidebar), collapsed on narrow ones. Only set the default when crossing
      // the breakpoint, so a deliberate toggle isn't overridden until the layout
      // actually changes.
      var wideToc = window.matchMedia('(min-width: 78rem)');
      details.open = wideToc.matches;
      var syncToc = function(e){ details.open = e.matches; };
      if (wideToc.addEventListener) { wideToc.addEventListener('change', syncToc); }
      else if (wideToc.addListener) { wideToc.addListener(syncToc); }

      // In overlay mode (narrow screens) the open list is a popover, so dismiss
      // it once a section is chosen. In sidebar mode (wide screens) it's a
      // standing rail, so leave it open.
      list.addEventListener('click', function(e){
        if (e.target.closest('a') && !wideToc.matches) { details.open = false; }
      });

      // Scroll-spy: mark the heading nearest the top of the viewport as current.
      if ('IntersectionObserver' in window) {
        var setCurrent = function(id){
          Object.keys(linkFor).forEach(function(key){ linkFor[key].removeAttribute('aria-current'); });
          if (linkFor[id]) { linkFor[id].setAttribute('aria-current', 'true'); }
        };
        var spy = new IntersectionObserver(function(entries){
          entries.forEach(function(e){ if (e.isIntersecting) { setCurrent(e.target.id); } });
        }, { rootMargin: '0px 0px -80% 0px', threshold: 0 });
        headings.forEach(function(h){ spy.observe(h); });
      }
    }
  }

  // Heading anchors: reveal a "#" link on hover/focus to grab a link to each
  // section (the triptych cards are skipped). kramdown only emits ids, so the
  // anchors are added here.
  if (article) {
    article.querySelectorAll('h2[id], h3[id]').forEach(function(h){
      if (h.closest('.intro-card')) { return; }
      var a = document.createElement('a');
      a.className = 'heading-anchor';
      a.href = '#' + h.id;
      a.setAttribute('aria-label', 'Link to “' + h.textContent.trim() + '”');
      // The visible "#" comes from CSS (.heading-anchor::before), so it stays
      // out of copied text and the accessibility tree.
      h.appendChild(a);
    });

    // Fenced code blocks scroll horizontally when a line is too long; make them
    // keyboard-focusable so they can be scrolled without a mouse (WCAG 2.1.1).
    article.querySelectorAll('pre').forEach(function(pre){
      pre.setAttribute('tabindex', '0');
    });

    // The callout asides are notes within the main content, not page-level
    // complementary landmarks; role="note" keeps them out of the landmark map.
    article.querySelectorAll('aside').forEach(function(aside){
      aside.setAttribute('role', 'note');
    });
  }

  // Sticky header: once the hero scrolls out of view, pin the header (CSS reacts
  // to .header-stuck on <html>) so the language and theme controls, and the brand
  // mark, stay reachable while reading the sections.
  var hero = document.querySelector('.hero');
  if (hero && 'IntersectionObserver' in window) {
    var stickObserver = new IntersectionObserver(function(entries){
      document.documentElement.classList.toggle('header-stuck', !entries[0].isIntersecting);
    }, { threshold: 0 });
    stickObserver.observe(hero);
  }
});
