{getEnv} = require './getEnv.coffee'
{Stages} = require './stages.coffee'

# Identifies type of project and returns an array of build stages
# stage.name - name of stage, for ui
# stage.cmd - shell command to execute
# stage.errorCallback - callback function with which to detect an error or
#   verify proper output of executed cmd.  will be called with a single
#   parameter, the stdout string of the executed process, and should return 0
#   for no error or any other value for error.
exports.getBuildStages = (fr, deployment, project, repo, buildDir, stageDir) ->
  env = getEnv fr, deployment, project, repo, buildDir, stageDir

  if Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/.meteor")
    # Meteor app
    #return _.map [Stages.generateNginx], (s) -> _.extend {env: env}, s
    #return _.map _.omit(availableStages, 'ios', 'android'), (s) -> _.extend {env: env}, s
    _.map [
      'coffeelint',
      'jshint',
      #'spacejam',
      'mocha',
      'gagarin',
      'build',
      'ios',
      'android',
      'generateNginx',
      'deploy'
    ], (stage) -> Stages[stage]

  else if Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/package.js")
    # Meteor package
    return _.map _.pick(availableStages, 'coffeelint', 'jshint', 'spacejam'), (s) -> _.extend {env: env}, s

