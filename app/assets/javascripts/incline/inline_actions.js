function inlineForm(url) {

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
            $.ajax({
                method: method.toUpperCase(),
                url: path,
                dataType: 'json',
                success: function (data, status, xhr) {
                    var ts = (new Date().getTime() / 100) % 864000;
                    if (data.invalidRequest) {
                        alert('Invalid request.');
                    } else if (data.messages) {
                        for (var message in data.messages) {
                            var html = '<div id="alert-' + ts.toString() + '" class="alert alert-' + escapeHTML(message.type) + ' alert-dismissible fade in" role="alert">' +
                                    '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
                                    escapeHTML(message.text) +
                                    '</div>';

                            $('#incline_body_container').prepend(html);
                            window.setTimeout("$('#alert-" + ts.toString() + "').alert('close');", 5000);

                            ts++;
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


        });
    };
    $.fn.inlineForm = function (e) {

    };
})(jQuery);