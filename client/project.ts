import {Template} from 'meteor/templating';
import {Meteor} from 'meteor/meteor';
import {BuildSessions, Deployments} from '../lib/collections';

Template.project.onCreated(function() {
  (window as any).Deployments = Deployments;
});

Template.project.helpers({
  mostRecentBuildSession: function() {
    return BuildSessions.findOne({
      projectId: this._id
    }, {
      sort: {
        timestamp: -1
      }
    });
  },
  buildSessions: function() {
    return BuildSessions.find({
      projectId: this._id
    }, {
      sort: {
        timestamp: -1
      }
    });
  },
  rowStyle: function(buildSession) {
    var status;
    status = (buildSession != null ? buildSession.status : void 0) || (this.status != null);
    if (status === 'Unsupported') {
      return 'background: rgba(255,255,0,0.1);';
    } else if (status === 'Pass') {
      return 'background: rgba(0,255,0,0.1);';
    } else if (status === 'Fail') {
      return 'background: rgba(255,0,0,0.1);';
    }
  },
  moment: function(date) {
    return moment(date).format('YYYY-MM-DD hh:mm:ss');
  },
  stdout: function() {
    var stages;
    window.requestAnimationFrame(function() {
      return $('textarea').scrollTop(99999);
    });
    stages = _.map(this.stages, function(s) {
      return "== begin stage " + s.name + " ==\n" + s.stdout + "\n== end stage " + s.name + " ==";
    });
    return stages.join('\n\n');
  },
  deployment: function() {
    return Deployments.find({
      projectId: this._id
    });
  }
});

Template.project.events({
  'click .run-job-button': function(e, tpl) {
    return Meteor.call('buildProject', this._id, true);
  },
  'click .run-deployment-button': function(e, tpl) {
    return Meteor.call('buildDeployment', this, true);
  }
});
