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
    _.pick r, 'name','clone_url','private','pushed_at'

  _.each repos, (r) ->
    Projects.upsert {name: r.name},
      $set:
        gitUrl: r.clone_url
        status: 'Pending'
        pushedAt: Date.parse(r.pushed_at)

  console.log 'got repo list from Github'

scheduleBuildAllProjects = ->
  Projects.find({}, {sort: {pushedAt: -1}}).forEach (proj) ->
    # Only schedule a build if one isnt already pending
    if not Jobs.findOne({name: 'BuildProjectJob', 'params.projectId': proj._id})?
      Meteor.call 'buildProject', proj._id

Meteor.startup ->
  if not Npm.require('cluster').isMaster then return
  if not Meteor.settings.ghApiToken? then return

  update = ->
    getReposFromGithub()
    scheduleBuildAllProjects()

  SyncedCron.add
    name: 'build all projects'
    schedule: (p) -> p.text 'every 5 minutes'
    job: update

