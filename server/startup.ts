import {SyncedCron} from 'meteor/percolate:synced-cron';
import {Projects} from '../lib/collections';

var getReposFromGithub, scheduleBuildAllProjects;

getReposFromGithub = function() {
  var e, repos, req;
  req = null;
  try {
    req = HTTP.call('GET', 'https://api.github.com/orgs/UK-AS-HIVE/repos?per_page=100', {
      auth: Meteor.settings.ghApiToken + ':x-oauth-basic',
      headers: {
        'User-Agent': 'HIVE-CI'
      }
    });
  } catch (error) {
    e = error;
    console.log('Exception in HTTP call: ', e);
    return;
  }
  repos = JSON.parse(req.content);
  repos = _.map(repos, function(r) {
    return _.pick(r, 'name', 'clone_url', 'private', 'pushed_at');
  });
  _.each(repos, function(r) {
    return Projects.upsert({
      name: r.name
    }, {
      $set: {
        gitUrl: r.clone_url,
        status: 'Pending',
        pushedAt: Date.parse(r.pushed_at)
      }
    });
  });
  return console.log('got repo list from Github');
};

scheduleBuildAllProjects = function() {
  return Projects.find({}, {
    sort: {
      pushedAt: -1
    }
  }).forEach(function(proj) {
    if (Jobs.findOne({
      name: 'BuildProjectJob',
      'params.deployment.projectId': proj._id
    }) == null) {
      return Meteor.call('buildProject', proj._id);
    }
  });
};

Meteor.startup(function() {
  var update;
  if (!Npm.require('cluster').isMaster) {
    return;
  }
  if (Meteor.settings.ghApiToken == null) {
    return;
  }
  update = function() {
    getReposFromGithub();
    return scheduleBuildAllProjects();
  };
  getReposFromGithub();
  return SyncedCron.add({
    name: 'build all projects',
    schedule: function(p) {
      return p.text('every 5 minutes');
    },
    job: update
  });
});

