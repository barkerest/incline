// Data Tables Helper Methods
// (C) 2017 Beau Barker (beau@barkerest.com)

/*
 * JSON format:
 *  {
 *      // (optional) set to true to indicate an invalid request to the server, default is false.
 *      "invalidRequest": false,
 *      // (optional) an array of messages to display to the user.
 *      "messages": [
 *          {
 *              // (required) "info", "warning", "danger", "success"
 *              "type": "info",
 *              // (required) the message to display.
 *              "text": "The action was successful."
 *          }
 *      ],
 *      // (optional) an array of data to update the data table with.
 *      "data": [
 *          {
 *              // (required) the unique ID for this row.
 *              "DT_RowId": "my_model_1",
 *              // (required) the "show" path for the model.
 *              "DT_Path": "/incline/my_model/1",
 *              // (optional) "update" or "remove", default is "update".
 *              "DT_RowAction": "update",
 *              // (optional) "info", "warning", "danger", "success"
 *              "DT_RowClass": "info",
 *
 *              // then model details such as:
 *              "name": "John Doe",
 *              "age": 35,
 *              "email": "jdoe@example.com",
 *              "occupation": "Mechanic"
 *          }
 *      ]
 *  }
 */


var inclineInline = {
    action: function(path, method) {
        if (!(method)) method = 'get';
        if (path.indexOf('?') >= 0) {
            path += '&inline=1';
        } else {
            path += '?inline=1';
        }
        $.ajax({
            method: method.toUpperCase(),
            url: path,
            dataType: 'json',
            success: function (data, status, xhr) {
                inclineInline._handle_json_result(data);
            },
            error: function (xhr, status, error) {
                inclineInline._handle_error(status, error);
            }
        });
    },

    form: function(req_path, req_method) {
        if (!(req_method)) req_method = 'get';
        if (req_path.indexOf('?') >= 0) {
            req_path += '&inline=1';
        } else {
            req_path += '?inline=1';
        }

        // first request should return HTML.
        $.ajax({
            method: req_method.toUpperCase(),
            url: req_path,
            dataType: 'html',
            success: function (data, status, xhr) {
                inclineInline._handle_form_response(data, status, xhr);
            },
            error: function (xhr, status, error) {
                inclineInline._handle_error(status, error);
            }
        });
    },

    _handle_json_result: function(data) {
        var ts = Math.round((new Date().getTime() / 100) % 864000, 0);
        var i;
        if (data.invalidRequest) {
            // Should probably come up with a more informative alert.
            this._handle_error('invalid request', 'invalid request');
        } else {
            // build alerts that clear after 5 seconds.
            if (data.messages) {
                var messageCount = data.messages.length;
                var alertDiv = $('#incline_dynamic_alerts');
                for (i = 0; i < messageCount; i++) {
                    var message = data.messages[i];
                    var html = '<div id="alert-' + ts.toString() + '" class="alert alert-' + escapeHTML(message.type) + ' alert-dismissible fade in" role="alert">' +
                        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
                        escapeHTML(message.text) +
                        '</div>';
                    var close = '$(\'#alert-' + ts.toString() + '\').alert(\'close\');';
                    alertDiv.prepend(html);
                    window.setTimeout(close, 5000);
                    ts++;
                }
            }
            // update rows in the data table.
            if (data.data) {
                var dataCount = data.data.length;
                for (i = 0; i < dataCount; i++) {
                    var item = data.data[i];
                    var row = $('#' + item.DT_RowId);
                    if (row.length > 0) {
                        var table = row.parents('table');
                        if ($.fn.dataTable.isDataTable(table))
                        {
                            var table_id = table.attr('id');
                            table = table.dataTable().api();
                            if (item.DT_RowAction === 'remove') {
                                table.row('#' + item.DT_RowId).remove();    // remove the row from the DT.
                                table.draw('page');                         // refresh the current page.
                            } else {
                                table.row('#' + item.DT_RowId).data(item);  // refresh the row in the DT.
                                inclineInline._go_to_record(item);          // find and hilight the record.
                            }
                        }
                    } else if (dataCount == 1) {
                        // no row found and there is only one record returned, focus on that record.
                        inclineInline._go_to_record(item);
                    }
                }
            }
        }
    },

    _handle_form_response: function (data, status, xhr) {
        var type = xhr.getResponseHeader('Content-Type').toLowerCase().trim();
        if (type.indexOf(';') >= 0)
            type = type.substring(0, type.indexOf(';')).trim();

        if (type === 'application/json') {
            // json response
            this._destroy_dialog();
            this._handle_json_result(data);
        } else if (type === 'text/html') {
            // html response
            this._set_dialog(data);
        } else {
            // unsupported response
            this._destroy_dialog();
            this._handle_error('invalid response', 'invalid response');
        }
    },

    _handle_error: function (status, error) {
        this._destroy_dialog(); // no matter what, the dialog should be destroyed.

        // Should probably come up with more informative error alerts.
        if (status === 'error') {
            alert(error);
        } else {
            alert(status);
        }
    },

    _dialog: false,

    _create_dialog: function () {
        if (!(this._dialog))
        {
            var body = $('body');
            var modal = $('<div class="modal fade" id="incline_inline_form" tabindex="-1" role="dialog" aria-labelledby="incline_inline_form_title" style="display: none;">' +
                '<div class="modal-dialog" role="document">' +
                '<div class="modal-content">' +
                '<div class="modal-header">' +
                '<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
                '<h4 class="modal-title" id="incline_inline_form_title"></h4>' +
                '</div>' +
                '<div class="modal-body" id="incline_inline_form_body"></div>' +
                '<div class="modal-footer" id="incline_inline_form_footer"></div>' +
                '</div></div></div>');

            body.prepend(modal);
            modal = $('#incline_inline_form');
            modal.on('hidden.bs.modal', function (e) {
                modal.remove();
                inclineInline._dialog = false;
            });
            this._dialog = true;
        }
    },

    _set_dialog: function (html) {
        var title;
        var body;
        var footer;
        var tmp;
        var dup;
        var panel;
        var panel_parent;
        var align_regex = /^(.*\s)?(row(\s.*)?|col-(xs|sm|md|lg)-.*)$/;
        var panel_regex = /^(.*\s)?panel(\s.*)?$/;

        // add html to DOM under a hidden div for processing.
        tmp = $('<div></div>').css('display','none');
        $('body').append(tmp);
        tmp.html(html);
        html = tmp;

        this._create_dialog();

        // get the parts of the modal to update.
        title = $('#incline_inline_form_title');
        body = $('#incline_inline_form_body');
        footer = $('#incline_inline_form_footer');

        // reset
        title.text('');
        body.empty();
        footer.empty();

        tmp = html.find('form');
        if (tmp.length == 1) {  // support one and only one form in the resulting HTML.
            // we have a form in the html that needs to be modified accordingly.
            var form_method = tmp.attr('method');
            var form_url = tmp.attr('action');
            var form_id = tmp.attr('id');

            // make sure the inline parameter is set.
            tmp.append('<input type="hidden" name="inline" value="1" />');

            // override submit to make sure the submission occurs via ajax.
            tmp.submit(function (e) {
                var form_data = $('#' + form_id).serialize();
                e.preventDefault();

                // prevent double submission.
                tmp.find('input,button,select,textarea').prop('disabled', true);

                $.ajax({
                    type: form_method.toUpperCase(),
                    url: form_url,
                    data: form_data,
                    success: function(data, status, xhr) {
                        inclineInline._handle_form_response(data, status, xhr);
                    },
                    error: function(xhr, status, error) {
                        inclineInline._handle_error(status, error);
                    }
                });
            });
        }

        // cancel links and buttons
        tmp = html.find('a,button,input[type=button]').filter(function() { return $(this).text().toLowerCase() === 'cancel'; });
        if (tmp.length > 0) {
            tmp.click(function (e) {
                e.preventDefault();
                inclineInline._destroy_dialog();
            });
        }

        // global title recognition, first H1 or H2 element.
        tmp = html.find('h1');
        if (tmp.length < 1) tmp = html.find('h2');
        if (tmp.length > 0) {
            tmp = tmp.first();
            title.text(tmp.text());
            // only remove if there is no additional HTML markup.
            if (tmp.html() === tmp.text())
            {
                tmp.remove();
            }
        }

        // put the error messages in place.
        tmp = html.find('#error_explanation');
        if (tmp.length > 0) {
            tmp.detach();
            body.prepend(tmp);
        }

        // put the alert messages in place.
        tmp = html.find('.alert');
        if (tmp.length > 0) {
            tmp.detach();
            body.prepend(tmp);
        }

        // remove outside alignment DIVs.
        while ((tmp = html.children()) && tmp.length == 1 && align_regex.test(tmp.attr('class'))) {
            tmp.detach();
            html.append(tmp.children());
        }

        // If the html has one child and that child is a form, then look inside the form.
        panel_parent = html;
        panel = panel_parent.children();
        if (panel.length == 1 && panel[0].tagName.toUpperCase() === 'FORM') {
            panel_parent = panel;
            panel = panel_parent.children(':not(input[type=hidden])'); // ignore hidden inputs
        }

        // now if there is only one child and that child is a panel, we can rip it apart.
        if (panel.length == 1 && panel[0].tagName.toUpperCase() === 'DIV' && panel_regex.test(panel.attr('class'))) {
            panel.detach();

            if ((tmp = panel.children('.panel-heading')) && tmp.length > 0) {
                title.text(tmp.text());
            }

            tmp = panel.children('table,.panel-body');
            if (tmp.length > 0) {
                tmp.removeClass('panel-body');
                tmp.detach();
                panel_parent.append(tmp);
            }

            tmp = panel.children('.panel-footer');
            if (tmp.length > 0) {
                tmp.removeClass('panel-footer');
                tmp.detach();
                // now we have a conundrum.
                if (panel_parent[0].tagName.toUpperCase() === 'FORM') {
                    // since the footer might contain controls for the form, we need it to be in the form.
                    panel_parent.append(tmp);
                } else {
                    // or the form doesn't wrap the footer, so we can just use the footer.
                    footer.append(tmp.children());
                }
            }
        }

        // we are done modifying the HTML and we can add it.
        html.detach();
        body.append(html.contents());

        // footer should only be visible if it has contents.
        if (footer.children().length > 0 || footer.text() !== '') {
            footer.show();
        } else {
            footer.hide();
        }

        // make sure the dialog is visible.
        tmp = $('#incline_inline_form');
        if (tmp.is(':hidden')) {
            tmp.modal('show');
            tmp.on('shown.bs.modal', function () {
                activateClassedItems(tmp);
            });
        } else {
            // make sure the classed items are activated.
            activateClassedItems(tmp);
        }
    },

    _destroy_dialog: function () {
        if (this._dialog) {
            var dlg = $('#incline_inline_form');
            if (dlg.length > 0) {
                if (dlg.is(':hidden')) {
                    dlg.remove();
                } else {
                    dlg.modal('hide');
                }
            }
            this._dialog = false;
        }
    },

    _go_to_record: function (data) {
        var table = $('table.dataTable');
        var params;
        var i;
        var row_id = '#' + data.DT_RowId;
        var query_start = data.DT_Path.indexOf('?');
        var base_path = (query_start >= 0) ? data.DT_Path.substr(0, query_start) : data.DT_Path;

        if (table.length < 1) return;

        table = table.dataTable().api();

        i = data.DT_RowId.lastIndexOf('_');

        params = table.ajax.params();
        params.draw = -1;
        params.locate_id = data.DT_RowId.substring(i + 1);

        $.ajax({
            url: base_path + '/locate',
            method: 'POST',
            dataType: 'json',
            data: params,
            success: function(data) {
                var recNum = data.record;
                if (recNum > -1) {
                    var pageLen = table.page.len();
                    var pageNum;

                    if (pageLen < 1) return;

                    // avoid division by zero.
                    if (recNum === 0) {
                        pageNum = 0;
                    } else {
                        pageNum = Math.floor(recNum / pageLen);
                    }

                    // set the page number and refresh the datatable only if we are on a different page or the row isn't visible.
                    if (table.page() != pageNum || $(row_id).length < 1) {
                        table.page(pageNum).draw('page');
                    }

                    // hilite the row (give DOM a quick chance to update).
                    window.setTimeout(function() { inclineInline._hilite_fade(row_id); }, 250 );
                }
            }
        });

    },

    _hilite_fade: function (selector) {
        // 2s hilite pulse from any bg color to yellow and then back.
        $(selector).addClass('cell-fade').addClass('cell-hilite');
        window.setTimeout(function() {
            $(selector).removeClass('cell-hilite');
            window.setTimeout(function() {
                $(selector).removeClass('cell-fade');
            }, 1000);
        }, 1000);
    },
};

/*
 * Generates an AJAX request to load an HTML fragment from the server.
 * When the HTML fragment is returned, it is displayed in a modal dialog over the current page.
 * If a form is present in the returned HTML, the 'submit' event is hooked to submit inline via AJAX.
 * If the form submission returns HTML, the returned HTML overwrites the previous HTML.
 * If the form submission returns JSON, the JSON is is used to update the page.
 */
function inlineForm(req_path,req_method) {
    inclineInline.form(req_path, req_method);
}

/*
 * Generates an AJAX request to the server and expects a JSON result.
 * The JSON is used to update the page.
 */
function inlineAction(path, method) {
    inclineInline.action(path, method);
}

(function ($){
    // inlineAction should return JSON data.
    // If "invalidRequest" is set in the response then an alert is generated.
    // Otherwise, if "messages" are set in the response then we display them.
    $.fn.inlineAction = function () {
        var item = $(this);
        if (item.length > 1) {
            item.each($.fn.inlineAction);
        } else {
            var path = item.attr('href');
            var method = item.attr('data-method');
            if (!(method)) method = 'get';
    
            item.click(function (e) {
                e.preventDefault();
                inclineInline.action(path, method);
            });
        }
    };
    $.fn.inlineForm = function () {
        var item =$(this);
        if (item.length > 1) {
            item.each($.fn.inlineForm);
        } else {
            var path = item.attr('href');
            var method = item.attr('data-method');
            if (!(method)) method = 'get';
    
            item.click(function (e) {
                e.preventDefault();
                inclineInline.form(path, method);
            });
        }
    };
})(jQuery);

