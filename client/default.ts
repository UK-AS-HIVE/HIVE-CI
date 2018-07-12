import {Meteor} from 'meteor/meteor';
import {Template} from 'meteor/templating';
import {Session} from 'meteor/session';
import {Projects, BuildSessions} from '../lib/collections';

Template["default"].helpers({
  projects: function() {
    return Projects.find({}, {
      sort: {
        pushedAt: -1
      }
    });
  },
  buildSession: function() {
    return BuildSessions.findOne({
      projectId: this._id
    });
  },
  latestStage: function() {
    return _.last(this.stages);
  },
  rowStyle: function() {
    var status;
    status = BuildSessions.findOne({
      projectId: this._id
    }).status;
    if (status === 'Unsupported') {
      return 'background: rgba(255,255,0,0.1);';
    } else if (status === 'Pass') {
      return 'background: rgba(0,255,0,0.1);';
    } else if (status === 'Fail') {
      return 'background: rgba(255,0,0,0.1);';
    }
  },
  moment: function(date) {
    Session.get('tick');
    return moment(date).fromNow();
  }
});

Template["default"].events({
  'click .run-job-button': function(e, tpl) {
    return Meteor.call('buildProject', this._id, true);
  }
});

Meteor.startup(function() {
  return Meteor.setInterval(function() {
    return Session.set('tick', Date.now());
  }, 1000);
});
