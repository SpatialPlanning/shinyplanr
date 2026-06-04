$( document ).ready(function() {
  Shiny.addCustomMessageHandler('fun', function(arg) {
 
  });

  // selectize.js sets an inline width style on .selectize-input at initialisation.
  // When the widget is inside a splitLayout cell (display: table-cell), the measured
  // width can be the full sidebar width rather than the cell width, causing the input
  // box to overflow its column. Removing the inline width lets the CSS rule
  // (.shiny-input-container .selectize-input { width: 100% }) take over correctly.
  function fixSelectizeWidths() {
    $('.shiny-split-layout .selectize-input').css('width', '');
    $('.shiny-split-layout .selectize-control').css('width', '');
  }

  // Run after a short delay to let selectize finish initialising
  setTimeout(fixSelectizeWidths, 500);
});
