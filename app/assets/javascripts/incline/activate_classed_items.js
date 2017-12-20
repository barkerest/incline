
function activateClassedItems(base) {
	var dropbase;
    if (base === undefined){
		base = $(document);
		dropbase = $('body');
	}else{
		dropbase = base;
	}
    base.find('div.date').datepicker({ format: "mm/dd/yyyy", todayBtn: "linked", todayHighlight: true, clearBtn: true });
    base.find('input.float').regexMask('float');
    base.find('input.integer').regexMask('integer');
    base.find('.double-scroll').doubleScroll({ onlyIfScroll: true, resetOnWindowResize: true });
    base.find('select.select2').select2({ dropdownParent: dropbase });
    base.find('a.inline_action').inlineAction();
    base.find('a.inline_form').inlineForm();
}
