import {Meteor} from 'meteor/meteor';
import {Projects, BuildSessions, Deployments} from '../lib/collections';

Meteor.publishComposite('projectsWithLast', function() {
  return {
    find: function() {
      return Projects.find();
    },
    children: [
      {
        find: function(project) {
          return BuildSessions.find({
            projectId: project._id
          }, {
            sort: {
              timestamp: -1
            },
            limit: 1
          });
        }
      }
    ]
  };
});

Meteor.publishComposite('projectDetail', function(projectName) {
  return {
    find: function() {
      return Projects.find({
        name: projectName
      });
    },
    children: [
      {
        find: function(project) {
          return BuildSessions.find({
            projectId: project._id
          }, {
            limit: 100,
            sort: {
              timestamp: -1
            }
          });
        }
      }, {
        find: function(project) {
          return Deployments.find({
            projectId: project._id
          });
        }
      }
    ]
  };
});
