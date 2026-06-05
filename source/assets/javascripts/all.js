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
});
