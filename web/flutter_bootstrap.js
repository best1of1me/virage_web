// Custom Flutter web bootstrap.
// 1. Removes the branded boot loader only once the app is actually running.
// 2. Shows a friendly retry message if startup takes too long.
{{flutter_js}}
{{flutter_build_config}}

(function () {
  var loader = document.getElementById('boot-loader');
  var failure = document.getElementById('boot-failure');
  var hidden = false;

  function hideLoader() {
    if (hidden || !loader) return;
    hidden = true;
    // A short delay lets the first Flutter frame paint behind the loader.
    // setTimeout (not requestAnimationFrame) so it still runs in a background tab.
    setTimeout(function () {
      loader.classList.add('is-hidden');
      try {
        performance.mark('virage:app-visible');
      } catch (e) {
        /* ignore */
      }
      setTimeout(function () {
        if (loader.parentNode) loader.parentNode.removeChild(loader);
      }, 400);
    }, 80);
  }

  function showFailure() {
    if (hidden) return;
    var ring = loader && loader.querySelector('.boot-ring');
    if (ring && ring.parentNode) ring.parentNode.removeChild(ring);
    if (failure) failure.style.display = 'block';
  }

  var timeout = setTimeout(showFailure, 60000);

  try {
    _flutter.loader
      .load({
        onEntrypointLoaded: async function (engineInitializer) {
          var appRunner = await engineInitializer.initializeEngine();
          await appRunner.runApp();
          clearTimeout(timeout);
          hideLoader();
        },
      })
      .then(function () {
        // Fallback: some engine versions resolve load() before the first frame.
        setTimeout(hideLoader, 1500);
      })
      .catch(function (error) {
        console.error('Flutter failed to start:', error);
        clearTimeout(timeout);
        showFailure();
      });
  } catch (error) {
    console.error('Flutter failed to start:', error);
    clearTimeout(timeout);
    showFailure();
  }
})();
