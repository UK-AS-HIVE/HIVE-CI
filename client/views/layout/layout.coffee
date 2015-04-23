Template.layout.events
  'keyup': (e, tpl) ->
    if e.keyCode is 27
      $('#ticketModal').modal('hide')
