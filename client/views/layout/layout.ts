import {Template} from 'meteor/templating';

Template.layout.events({
  'keyup': function(e, tpl) {
    if (e.keyCode === 27) {
      return $('#ticketModal').modal('hide');
    }
  }
});
