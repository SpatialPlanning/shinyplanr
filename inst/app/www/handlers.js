$( document ).ready(function() {
  Shiny.addCustomMessageHandler('fun', function(arg) {
 
  });

  // When the Explore tab (pill value="4") becomes visible, invalidate the
  // leaflet map size so the WebGL canvas recalculates its dimensions, then
  // notify Shiny that the map container is ready.  This inverts the control
  // flow: instead of R using a fixed delay to guess when the browser is ready,
  // the browser tells R exactly when the map has been resized.
  //
  // We target the specific tab pill by its data-bs-target attribute to avoid
  // firing on every tab change.  Bootstrap 5 uses data-bs-toggle="pill" for
  // navbarPage pill tabs.
  $(document).on('shown.bs.tab', function(e) {
    // Extract the target panel id from the activated tab link
    var target = $(e.target).data('bs-target') || $(e.target).attr('href') || '';

    // Find any leaflet map inside the newly visible panel and invalidate its size
    var panel = $(target);
    if (panel.length === 0) {
      // Bootstrap 5 pill tabs inside a tabsetPanel use aria-controls
      var controls = $(e.target).attr('aria-controls');
      if (controls) panel = $('#' + controls);
    }

    // Invalidate all leaflet maps in the visible panel
    panel.find('.leaflet-container').each(function() {
      var mapId = $(this).attr('id');
      if (mapId && HTMLWidgets && HTMLWidgets.find) {
        var widget = HTMLWidgets.find('#' + mapId);
        if (widget && widget.getMap) {
          widget.getMap().invalidateSize();
        }
      }
    });

    // Also trigger a global resize as a fallback
    setTimeout(function() { $(window).trigger('resize'); }, 50);

    // Notify Shiny which tab just became visible so R can react
    if (typeof Shiny !== 'undefined' && Shiny.setInputValue) {
      Shiny.setInputValue('explore_tab_shown', Date.now(), {priority: 'event'});
    }
  });
});
