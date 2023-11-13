document.addEventListener("DOMContentLoaded", function(){
  var select = document.querySelector('.locales select');
  select.addEventListener('change', function(event){
    origin = window.location.origin;
    languageCode = event.currentTarget.selectedOptions[0].value
    window.location.replace(origin + "/" + languageCode)
  });

  var faqHeaders = document.querySelectorAll('.frequently-asked-questions h4');

  for (var i = 0; i < faqHeaders.length; ++i) {
    header = faqHeaders[i]
    header.addEventListener('click', toggleVisibility);
  }

  function toggleVisibility(event) {
    element = event.target;
    element.classList.toggle('is-visible')

    lastParagraph = element.nextElementSibling;
    paragraphs = [];
    paragraphs.push(lastParagraph);

    while (lastParagraph.nextElementSibling && lastParagraph.nextElementSibling.tagName == "P") {
      lastParagraph = lastParagraph.nextElementSibling;
      paragraphs.push(lastParagraph)
    }

    for (var i = 0; i < paragraphs.length; ++i) {
      paragraph = paragraphs[i]
      paragraph.classList.toggle('is-visible');
    }
  }
});
