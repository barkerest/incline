
function activateClassedItems(base) {
    if (base === undefined) base = $(document);
    base.find('div.date').datepicker({ format: "yyyy-mm-dd", todayBtn: "linked", todayHighlight: true, clearBtn: true });
    base.find('input.float').regexMask('float');
    base.find('input.integer').regexMask('integer');
    base.find('.double-scroll').doubleScroll({ onlyIfScroll: true, resetOnWindowResize: true });
    base.find('select.select2').select2();
    base.find('a.inline_action').inlineAction();
    base.find('a.inline_form').inlineForm();
}
