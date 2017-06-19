// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require incline/bootstrap-datepicker
//= require incline/jquery.doubleScroll
//= require incline/jquery.number
//= require incline/datatables
//= require incline/escapeHtml
//= require incline/regexMask
//= require incline/select2/select2.full
//= require incline/activate_classed_items
//= require incline/inline_actions


// Apply things when document is ready.
$(function() {
    activateClassedItems();
});
