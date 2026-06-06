document.addEventListener("DOMContentLoaded", function(){
  var select = document.querySelector('.locales select');
  if (select) {
    select.addEventListener('change', function(event){
      origin = window.location.origin;
      languageCode = event.currentTarget.selectedOptions[0].value
      window.location.replace(origin + "/" + languageCode)
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
    var headings = article.querySelectorAll('h2[id]');
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
      a.textContent = '#';
      h.appendChild(a);
    });
  }
});
