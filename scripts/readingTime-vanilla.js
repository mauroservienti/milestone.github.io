function calculateReadingTime(element, wordsPerMinute = 270) {
  const text = element.textContent || element.innerText;
  const words = text.trim().split(/\s+/).length;
  const minutes = Math.ceil(words / wordsPerMinute);
  return minutes < 1 ? 'Less than a minute' : minutes + ' min';
}

document.addEventListener('DOMContentLoaded', function() {
  const content = document.querySelector('.post-content');
  const eta = document.querySelector('.eta');
  if (content && eta) {
    eta.textContent = calculateReadingTime(content);
  }
});
