function inlineForm(url) {

}

function inline_action(path, method) {
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
            var ts = Math.round((new Date().getTime() / 100) % 864000, 0);
            var i;
            if (data.invalidRequest) {
                alert('Invalid request.');
            } else {
                if (data.messages) {
                    var messageCount = data.messages.length;
                    for (i = 0; i < messageCount; i++) {
                        var message = data.messages[i];
                        var html = '<div id="alert-' + ts.toString() + '" class="alert alert-' + escapeHTML(message.type) + ' alert-dismissible fade in" role="alert">' +
                            '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
                            escapeHTML(message.text) +
                            '</div>';
                        var close = '$(\'#alert-' + ts.toString() + '\').alert(\'close\');';
                        $('#incline_dynamic_alerts').prepend(html);
                        window.setTimeout(close, 5000);
                        ts++;
                    }
                }
                if (data.data) {
                    var dataCount = data.messages.length;
                    for (i = 0; i < dataCount; i++) {
                        var item = data.data[i];
                        var table = $('#' + item.DT_RowId).parents('table');
                        if ($.fn.dataTable.isDataTable(table))
                        {
                            table = $(table).dataTable().api();
                            if (item.DT_RowAction === 'remove') {
                                table.row('#' + item.DT_RowId).remove();
                            } else {
                                table.row('#' + item.DT_RowId).data(item);
                            }
                        }
                    }
                }
            }
        },
        error: function (xhr, status, error) {
            if (status === error) {
                alert(error);
            } else {
                alert(status);
            }
        }
    });
}

(function ($){
    // inlineAction should return JSON data.
    // If "invalidRequest" is set in the response then an alert is generated.
    // Otherwise, if "messages" are set in the response then we display them.
    $.fn.inlineAction = function () {
        var item = $(this);
        var path = item.attr('href');
        var method = item.attr('data-method');
        if (!(method)) method = 'get';

        item.click(function (e) {
            e.preventDefault();
            inline_action(path, method);
        });
    };
    $.fn.inlineForm = function (e) {

    };
})(jQuery);