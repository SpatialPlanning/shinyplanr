$( document ).ready(function() {
  Shiny.addCustomMessageHandler('fun', function(arg) {
 
  });

  // Invalidate leaflet map size when a Bootstrap tab becomes visible.
  // When a tab panel is hidden (display:none), the leaflet/WebGL canvas is
  // initialised with zero dimensions.  Triggering a resize after the tab is
  // shown forces leaflet to recalculate the container size and re-render the
  // WebGL layer correctly.
  $(document).on('shown.bs.tab', 'a[data-toggle="tab"], a[data-bs-toggle="tab"]', function() {
    setTimeout(function() {
      $(window).trigger('resize');
    }, 10);
  });
});
