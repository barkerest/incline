
(function ($){
  $.fn.regexMask = function (mask) {
    if (!mask) {
      throw 'mandatory mask argument missing';
    } else if (mask == 'float') {
      mask = /^-?(\d,)*\d*(\.\d*)?$/;
    } else if (mask == 'integer') {
      mask = /^-?\d*$/;
    } else {
      try {
        mask.test("");
      } catch(e) {
        throw 'mask regex need to support test method';
      }
    }
    $(this).keypress(function (event) {
      if (!event.charCode) return true;
      var part1 = this.value.substring(0,this.selectionStart);
      var part2 = this.value.substring(this.selectionEnd,this.value.length);
      if (!mask.test(part1 + String.fromCharCode(event.charCode) + part2))
        return false;
    });
  };
})(jQuery);


