// Jitak Flutter Web Core Loader
window.addEventListener('load', function(ev) {
  _flutter.loader.loadEntrypoint({
    serviceWorker: {
      serviceWorkerVersion: null,
    },
    onEntrypointLoaded: function(engineInitializer) {
      engineInitializer.initializeEngine().then(function(appRunner) {
        appRunner.runApp();
      });
    }
  });
});
