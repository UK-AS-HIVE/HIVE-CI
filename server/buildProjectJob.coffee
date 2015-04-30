Meteor.methods
  buildProject: (projectId) ->
    console.log "scheduling BuildProjectJob for #{projectId}"
    #Projects.update projectId, {$set: {status: 'Pending'}}
    Job.push new BuildProjectJob
      projectId: projectId
    BuildSessions.insert
      projectId: projectId
      status: 'Pending'
      message: 'Scheduled to build...'
      timestamp: Date.now()

class @BuildProjectJob extends ExecJob
  handleJob: ->
    proj = Projects.findOne(@params.projectId)
    session = BuildSessions.findOne({projectId: @params.projectId}, {sort: {timestamp: -1}})
    console.log '*** building project '+proj.name+' ***'
    #Projects.update {_id: @params.projectId}, {$set: {status: 'Building'}}

    BuildSessions.update session._id,
      $set:
        status: 'Building'
        message: 'Fetching...'
        timestamp: Date.now()

    fr = FileRegistry.getFileRoot()

    buildDir = fr + '/sandbox/build'
    stageDir = fr + '/sandbox/stage'

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
      git checkout `git log --all --format="%H" -1`
      git log --all --format="%H" -1
      git log --all --format="%s" -1
      git log --all --format="%cn" -1
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

    if !Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/.meteor") #&& !Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/package.js")
      BuildSessions.update session._id,
        $set:
          status: 'Unsupported'
          message: 'Not a Meteor repository'
          timestamp: Date.now()
      return

    env = _.extend process.env,
      METEOR_VERSION: 'something?'
      GH_API_TOKEN: Meteor.settings.ghApiToken
      ORG_PREFIX: Meteor.settings.orgName
      ORG_REVERSE_URL: Meteor.settings.orgReverseUrl
      REPO: repo
      ORIG_DIR: fr+'../../private'
      DEV_SERVER: Meteor.settings.devServer
      BUILD_DIR: buildDir
      STAGE_DIR: stageDir

    # stage.name - name of stage, for ui
    # stage.cmd - shell command to execute
    # stage.errorCallback - callback function with which to detect an error or
    #   verify proper output of executed cmd.  will be called with a single
    #   parameter, the stdout string of the executed process, and should return 0
    #   for no error or any other value for error.
    stages =
      [
        name: 'CoffeeLint'
        cmd: """
            CF=`find . -name "*.coffee" | grep -v .meteor | grep -v packages`
            test -z "${CF}" || coffeelint ${CF}
          """
        errorMessage: (out) ->
          clErrors = out?.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)?.shift()?.trim()
          "CoffeeLint found #{clErrors}"
      ,
        name: 'jshint'
        cmd: """
            JF=`find . -name "*.js" | grep -v .meteor | grep -v packages`
            test -z "${JF}" || jshint ${JF}
          """
        errorMessage: (out) ->
          "jshint found " + out?.trim().split('\n').pop()
      ,
        name: 'spacejam'
        cmd: """
          if [[ -e .meteor/release && -d packages ]]
          then
            spacejam test-packages packages/*
          fi
          if [[ -e package.js ]]
          then
           spacejam test-packages ./
          fi
        """
      ,
        name: 'Building Meteor app'
        cmd:
          Assets.getText('includes/meteor/meteorFunctions.sh') +
          """
            buildMeteor
          """
        env: env
      ,
        name: 'Building iOS app'
        cmd:
          Assets.getText('includes/meteor/iosFunctions.sh') +
          """
            buildIos
          """
        env: env
      ,
        name: 'Build Android app'
        cmd:
          Assets.getText('includes/meteor/meteorFunctions.sh') +
          """
            buildAndroid
          """
        env: env
      ]

    for s in stages
      @params.cmd = """
        cd #{fr}/sandbox/build/#{repo}
        #{s.cmd}
      """
      @params.env = s.env
      BuildSessions.update session._id,
        $set:
          message: s.name
      console.log "=== begin stage #{s.name} (#{repo}) ==="
      ex = super()
      console.log ex.stdout
      if ex.code != 0
        console.log 'FAILURE'
      else
        console.log 'SUCCESS'
      console.log "=== end stage #{s.name} (#{repo}) ==="

      if ex.code != 0
        msg = if s.errorMessage? then s.errorMessage(ex.stdout) else "#{s.name} returned exit code #{ex.code}"
        check msg, String
        BuildSessions.update session._id,
          $set:
            status: 'Fail'
            message: msg
          $push:
            stages:
              name: s.name
              stdout: ex.stdout
        return

    BuildSessions.update session._id,
      $set:
        status: 'Pass'
        message: 'All phases successful'
        timestamp: Date.now()

