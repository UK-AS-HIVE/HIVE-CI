class @BuildProjectJob extends ExecJob
  handleJob: ->
    deployment = @params.deployment
    proj = Projects.findOne(deployment.projectId)
    session = BuildSessions.findOne({deploymentId: deployment._id}, {sort: {timestamp: -1}})
    console.log '*** building project '+proj.name+' for '+deployment.targetHost+' ***'
    #Projects.update {_id: @params.projectId}, {$set: {status: 'Building'}}

    BuildSessions.update session._id,
      $set:
        status: 'Building'
        message: 'Fetching...'
        timestamp: Date.now()

    fr = FileRegistry.getFileRoot()

    targetUrl = Npm.require('url').parse(deployment.targetHost)
    buildDir = fr + 'sandbox/build'
    console.log targetUrl.hostname

    {dnsLookup} = require '/imports/stages/dnsLookup.coffee'
    stageDir = fr + 'sandbox/stage/' + dnsLookup(targetUrl.hostname)

    orgAndRepo = proj.gitUrl.match(/([a-zA-Z0-9-_.]+)\/([a-zA-Z0-9-_.]+)$/)
    org = orgAndRepo[1]
    repo = orgAndRepo[2].replace '.git', ''
    url = "https://#{Meteor.settings.ghApiToken}:x-oauth-basic@github.com/#{org}/#{repo}"
    @params.cmd = """
      mkdir -p #{buildDir}
      cd #{buildDir}
      if [[ -e "#{repo}/" ]]
      then
        cd #{repo}
        git reset --hard
        git checkout --
        git clean -dff
        git fetch
      else
        git clone --depth=1 #{url}
        cd #{repo}
      fi

      git fetch origin '+refs/heads/*:refs/remotes/origin/*'
      #git checkout `git log --all --format="%H" -1`
      git checkout origin/#{deployment.branch}
      #git pull
      git log --format="%H" -1
      git log --format="%s" -1
      git log --format="%cn" -1
    """
    ex = super()
    out = ex.stdout
    console.log out

    gitInfo = out.trim().split('\n')
    if gitInfo.length >= 3
      gitInfo = gitInfo.slice(gitInfo.length-3,gitInfo.length+1)
    else
      gitInfo = [null, null, null]
    hash = gitInfo[0]
    subject = gitInfo[1]
    author = gitInfo[2]
    console.log 'gitInfo ', gitInfo

    if not hash? then hash = 'unknown'
    if not author? then author = 'unknown'
    if not subject? then subject = 'No commit message.'

    console.log "hash: #{hash}"
    BuildSessions.update session._id,
      $set:
        message: 'Cloned successfully'
        timestamp: Date.now()
        git:
          commitHash: hash
          committerName: author
          commitMessage: subject
      $push:
        stages:
          name: 'Fetch'
          stdout: out

    if deployment.settings?
      Npm.require('fs').writeFileSync buildDir + "/#{repo}/settings.json", deployment.settings

    # TODO: better way of checking for already-built commit?
    unless @params.forceRebuild
      previous = BuildSessions.find({deploymentId: @params.deployment._id}, {sort: {timestamp: -1}, limit: 2}).fetch()
      if previous.length >= 2 && hash == previous.pop().git?.commitHash
        console.log "No changes since last check"
        BuildSessions.remove {_id: session._id}
        return

    {getBuildStages} = require '/imports/stages/getBuildStages.coffee'
    stages = getBuildStages fr, deployment, proj, repo, buildDir, stageDir

    if !stages
      BuildSessions.update session._id,
        $set:
          status: 'Unsupported'
          message: 'Not a supported type of repository'
          timestamp: Date.now()
      return

    for s in stages
      if s.cmd?
        @params.cmd = """
          set -ex
          cd #{fr}/sandbox/build/#{repo}
          #{s.cmd}
        """
        @params.env = s.env
      BuildSessions.update session._id,
        $set:
          message: s.name
      console.log "=== begin stage #{s.name} (#{repo}) ==="
      if s.cmd?
        ex = super()
        console.log ex.stdout
        if ex.code != 0
          console.log 'FAILURE'
        else
          console.log 'SUCCESS'
      else if s.func?
        try
          s.func.call @, fr, deployment, proj, repo, buildDir, stageDir
          ex =
            code: 0
            stdout: ''
        catch exception
          ex =
            code: 1
            stdout: exception.toString()
      console.log "=== end stage #{s.name} (#{repo}) ==="

      BuildSessions.update session._id,
        $push:
          stages:
            name: s.name
            stdout: ex.stdout

      if ex.code != 0
        msg = if s.errorMessage? then s.errorMessage(ex.stdout) else "#{s.name} returned exit code #{ex.code}"
        check msg, String
        BuildSessions.update session._id,
          $set:
            status: 'Fail'
            message: msg
        return

    # TODO: notify

    BuildSessions.update session._id,
      $set:
        status: 'Pass'
        message: 'All phases successful'
        timestamp: Date.now()

  
