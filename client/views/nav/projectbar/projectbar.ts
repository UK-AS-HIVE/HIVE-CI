import {Template} from 'meteor/templating';
import {Session} from 'meteor/session';

Template.projectbar.helpers({
  project: function() {
    return [
      {
        name: 'Projects',
        active: "active"
      }
    ];
  },
  active: function() {
    if (this.name === Session.get("projectName")) {
      return "active";
    } else {
      return null;
    }
  }
});
