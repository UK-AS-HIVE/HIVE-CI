getReposFromGithub = ->
  req = null
  try
    req = HTTP.call 'GET',
      'https://api.github.com/orgs/UK-AS-HIVE/repos?per_page=100',
      auth: Meteor.settings.ghApiToken+':x-oauth-basic'
      headers:
        'User-Agent': 'HIVE-CI'
  catch e
    console.log 'Exception in HTTP call: ', e
    return
  repos = JSON.parse req.content

  repos = _.map repos, (r) ->
    _.pick r, 'name','clone_url','private'

  _.each repos, (r) ->
    Projects.upsert {name: r.name},
      $set:
        gitUrl: r.clone_url
        status: 'Pending'
        lastCheck: Date.now()

  console.log 'got repo list from Github'

scheduleBuildAllProjects = ->
  Projects.find({}).forEach (proj) ->
    Meteor.call 'buildProject', proj._id

Meteor.startup ->
  if not Npm.require('cluster').isMaster then return
  if not Meteor.settings.ghApiToken? then return

  getReposFromGithub()
  scheduleBuildAllProjects()

