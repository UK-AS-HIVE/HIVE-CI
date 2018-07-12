import {Meteor} from 'meteor/meteor';
import {Template} from 'meteor/templating';

Template.navbar.events({
  'click a[id=logout]': function() {
    return Meteor.logout();
  }
});
