{{flutter_js}}
{{flutter_build_config}}

// Emoji and symbols that Roboto lacks come from this site (gfonts/, see
// web/gfonts/README.md) instead of fonts.gstatic.com, so the web version
// makes no requests to third parties.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: "gfonts/",
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
