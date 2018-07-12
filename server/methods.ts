import {Projects, BuildSessions, Deployments} from '../lib/collections';
import {BuildProjectJob} from './buildProjectJob';

Meteor.methods({
  buildProject: function(projectId, forceRebuild) {
    var project;
    project = Projects.findOne(projectId);
    console.log("scheduling BuildProjectJob for " + project.name);
    return Deployments.find({
      projectId: projectId
    }).forEach(function(d) {
      return Meteor.call('buildDeployment', d, forceRebuild);
    });
  },
  buildDeployment: function(deployment, forceRebuild) {
    Job.push(new BuildProjectJob({
      deployment: deployment,
      forceRebuild: forceRebuild
    }));
    return BuildSessions.insert({
      projectId: deployment.projectId,
      deploymentId: deployment._id,
      targetHost: deployment.targetHost,
      status: 'Pending',
      message: 'Scheduled to build...',
      timestamp: Date.now()
    });
  }
});
