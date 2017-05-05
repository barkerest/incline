var systemStatus = {

 // method to use for the submission
 method: 'POST',

 // URL to submit against unless submitForm is specified.
 submitUrl: window.location.href,

 // Data to submit to submitUrl unless submitForm is specified.
 submitData: null,

 // If specified, this form will be submitted and the submitUrl and submitData variables will be ignored.
 submitForm: null,

 // The URL to link to when the status completes.
 completionUrl: window.location.href,

 // The label for the status completion button.
 completionLabel: 'Continue',

 // If true, then display a modal dialog over the current page, otherwise redirect to /status/current.
 inline: true,

 // If we are inline, do we want to remove the log?
 inlineNoLog: false,

 // The status urls.
 _curStatusUrl: application_root_offset + '/cko5/status/current',
 _firstStatusUrl: application_root_offset + '/cko5/status/first',
 _moreStatusUrl: application_root_offset + '/cko5/status/more',

 // IDs for the elements to manage.
 idStatusLog:         'status_log',
 idStatusTitle:       'status_title',
 idProgressContainer: 'status_progress_cont',
 idProgress:          'status_progress',
 idCompletButton:     'status_complete',

 // Creates the modal dialog.
 _showDialog: function () {
  $('body')
    .append(
      $('<div id="status_dialog" class="modal fade" tabindex="-1" role="dialog"></div>')
        .append(
          $('<div class="modal-dialog"></div>')
            .append(
              $('<div class="modal-content"></div>')
                .append(
                  $('<div class="modal-header"></div>')
                    .append(
                      $('<h4 class="modal-title"></h4>')
                        .attr('id', this.idStatusTitle)
                        .text('Please wait...')
                    )
                )
                .append(
                  $('<div class="modal-body"></div>')
                    .append(
                      $('<pre></pre>')
                        .attr('id', this.idStatusLog)
                        .css('height', '350px')
                    )
                    .append(
                      $('<div class="progress"></div>')
                        .attr('id', this.idProgressContainer)
                        .append(
                          $('<div class="progress-bar progress-bar-success progress-bar-striped" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>')
                            .attr('id', this.idProgress)
                            .css('min-width', '2em')
                            .text('0%')
                        )
                    )
                )
                .append(
                  $('<div class="modal-footer"></div>')
                    .append(
                      $('<a class="btn btn-primary"></a>')
                        .attr('id', this.idCompletButton)
                        .attr('href', this.completionUrl)
                        .text(this.completionLabel)
                    )

                )
            )
        )
    );
  if (this.inlineNoLog)
  {
   $('#' + this.idStatusLog).remove();
  }
  $('#status_dialog').modal();
 },

 // Destroys the modal dialog.
 hideDialog: function () {
  $('#status_dialog').remove();
 },

 // Submits the data.
 _submit: function () {
  if (this.submitForm) {
   var frm = $(this.submitForm);
   if (frm.length > 0) {
    this.submitUrl = frm.attr('action');
    this.submitData = frm.serialize();
    this.method = (frm.attr('method') || 'POST').toUpperCase();
   }
  }

  if (this.inline) {
   this._showDialog();
  }

  // submit the data and immediately move on.
  $.ajax({
   url: this.submitUrl,
   data: this.submitData,
   method: this.method
  });

  if (this.inline) {
   window.setTimeout('systemStatus.updateStatus(true)', 100);
  }
  else
  {
   // and redirect to the status url.
   window.location.href = this._curStatusUrl + '?u=' + encodeURIComponent(this.completionUrl).replace(' ', '+') + '&l=' + encodeURIComponent(this.completionLabel).replace(' ', '+');
  }
 },

 updateStatus: function (initial) {
  if (initial) {
   $('#' + this.idCompletButton).text(this.completionLabel).attr('href', this.completionUrl).hide();
   $('#' + this.idProgressContainer).hide();
   $('#' + this.idProgress).text('0%').attr('aria-valuenow', 0);
  }
  $.ajax({
   url: ((initial) ? this._firstStatusUrl : this._moreStatusUrl),
   method: 'GET',
   dataType: 'json',
   error: function(xhr, status, message) {
    alert('Failed to query status.\n' + message);
    $('#' + systemStatus.idCompleteButton).show();
   },
   success: function(data, status, xhr) {
    if (data.status) {
     $('#' + systemStatus.idStatusTitle).text(data.status);
    }
    if (data.error) {
     alert('An internal error occurred.\n' + data.contents);
     $('#' + systemStatus.idCompletButton).show();
    } else {
     if (data.contents)
     {
      log = $('#' + systemStatus.idStatusLog);
      log.text(log.text() + data.contents);
     }
     if (data.percentage == '-') {
      if ($('#' + systemStatus.idProgressContainer).is(':visible'))
      {
       data.percentage = '100'
      } else {
       data.percentage = ''
      }
     }
     if (data.percentage) {
      pct = parseInt(data.percentage).toString();
      $('#' + systemStatus.idProgress).text(pct + '%').css('width', pct + '%').attr('aria-valuenow', pct);
      $('#' + systemStatus.idProgressContainer).show();
     } else {
      $('#' + systemStatus.idProgressContainer).hide();
     }
     if (!data.locked) {
      $('#' + systemStatus.idCompletButton).show();
     } else {
      window.setTimeout('systemStatus.updateStatus(false)', 500);
     }
    }
   }
  });
 },

 run: function (options) {
  if (options === undefined) {
   options = {};
  }
  for (var attrName in options) {
   if (options.hasOwnProperty(attrName)) {
    if (this.hasOwnProperty(attrName))
    {
     this[attrName] = options[attrName];
    }
   }
  }
  if (options.update_only) {
   this.updateStatus(true);
  } else {
   this._submit();
  }
 }
};
