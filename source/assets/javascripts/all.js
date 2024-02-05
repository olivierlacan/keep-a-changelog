document.addEventListener("DOMContentLoaded", function(){
  var select = document.querySelector('.locales select');
  select.addEventListener('change', function(event){
    origin = window.location.origin;
    languageCode = event.currentTarget.selectedOptions[0].value
    window.location.replace(origin + "/" + languageCode)
  });
});
