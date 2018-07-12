import {getEnv} from './getEnv';
import {Stages} from './stages';

export const getBuildStages = function(fr, deployment, project, repo, buildDir, stageDir) {
  var env;
  env = getEnv(fr, deployment, project, repo, buildDir, stageDir);
  if (Npm.require('fs').existsSync(fr + "/sandbox/build/" + repo + "/.meteor")) {
    return _.map(['coffeelint', 'jshint', 'mocha', 'gagarin', 'build', 'ios', 'android', 'generateNginx', 'deploy'], function(stage) {
      return Stages[stage];
    });
  } else if (Npm.require('fs').existsSync(fr + "/sandbox/build/" + repo + "/package.js")) {
    return _.map(_.pick(availableStages, 'coffeelint', 'jshint', 'spacejam'), function(s) {
      return _.extend({
        env: env
      }, s);
    });
  }
};
