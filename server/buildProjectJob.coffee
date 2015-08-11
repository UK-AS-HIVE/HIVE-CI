Meteor.methods
  buildProject: (projectId, forceRebuild) ->
    console.log "scheduling BuildProjectJob for #{projectId}"
    Deployments.find({projectId: projectId}).forEach (d) ->
      Meteor.call 'buildDeployment', d, forceRebuild
    #Projects.update projectId, {$set: {status: 'Pending'}}
  buildDeployment: (deployment, forceRebuild) ->
    Job.push new BuildProjectJob
      deployment: deployment
      forceRebuild: forceRebuild
    BuildSessions.insert
      projectId: deployment.projectId
      deploymentId: deployment._id
      targetHost: deployment.targetHost
      status: 'Pending'
      message: 'Scheduled to build...'
      timestamp: Date.now()

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
    stageDir = fr + 'sandbox/stage/' + targetUrl.hostname

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
      git pull
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

    stages = @getBuildStages fr, deployment, proj, repo, buildDir, stageDir

    if !stages
      BuildSessions.update session._id,
        $set:
          status: 'Unsupported'
          message: 'Not a supported type of repository'
          timestamp: Date.now()
      return

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

    # TODO: notify

    BuildSessions.update session._id,
      $set:
        status: 'Pass'
        message: 'All phases successful'
        timestamp: Date.now()

  # Identifies type of project and returns an array of build stages
  # stage.name - name of stage, for ui
  # stage.cmd - shell command to execute
  # stage.errorCallback - callback function with which to detect an error or
  #   verify proper output of executed cmd.  will be called with a single
  #   parameter, the stdout string of the executed process, and should return 0
  #   for no error or any other value for error.
  getBuildStages: (fr, deployment, project, repo, buildDir, stageDir) ->
    targetUrl = Npm.require('url').parse(deployment.targetHost)
    appInstallUrl = if deployment.appInstallUrl?.length then Npm.require('url').parse(deployment.appInstallUrl).path || '' else {path: ''}
    sshHost = targetUrl.hostname
    sshUser = deployment.sshConfig?.user || 'root'
    sshPort = deployment.sshConfig?.port || 22
    env = _.extend process.env,
      METEOR_VERSION: 'something?'
      GH_API_TOKEN: Meteor.settings.ghApiToken
      ORG_PREFIX: Meteor.settings.orgName
      ORG_REVERSE_URL: Meteor.settings.orgReverseUrl
      REPO: repo
      ORIG_DIR: fr+'../../private'
      DEV_SERVER: deployment.targetHost.replace(/\/$/, '') + '/'
      BUILD_DIR: buildDir
      STAGE_DIR: stageDir
      ANDROID_HOME: process.env.ANDROID_HOME || (process.env.HOME + '/.meteor/android_bundle/android-sdk')
      TARGET_HOSTNAME: sshHost
      TARGET_APP_PATH: appInstallUrl.path
      TARGET_PATH: targetUrl.path
      TARGET_PROTOCOL: targetUrl.protocol
      TARGET_PORT: targetUrl.port || if targetUrl.protocol == 'https:' then 443 else 80

    if Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/.meteor")
      # Meteor app
      return [
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
            JF=`find . -name "*.js" | grep -v .meteor | grep -v packages | grep -v .min.js`
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
      ,
        name: "Deploying to #{deployment.targetHost}"
        cmd:
          Assets.getText('includes/deploy/generateInitd.sh') +
          Assets.getText('includes/deploy/generateNginx.sh') +
          Assets.getText('includes/deploy/generateHtmlindex.sh') +
          """
            generateInitd
            generateNginx
            generateHtmlindex

            echo "Deploying #{repo} to #{deployment.targetHost}..."
            cd #{stageDir}
            rsync -avz -e "ssh -p #{sshPort} -oBatchMode=yes" var/www/ #{sshUser}@#{sshHost}:/var/www
            rsync -avz --delete --exclude 'programs/server/node_modules' --exclude 'files/' -e "ssh -p #{sshPort} -oBatchmode=yes" var/meteor/#{repo} #{sshUser}@#{sshHost}:/var/meteor
            rsync -avz -e "ssh -p #{sshPort} -oBatchMode=yes" etc/nginx/sites-available/#{sshHost}.conf #{sshUser}@#{sshHost}:/etc/nginx/sites-available/#{sshHost}.conf
            rsync -avz -e "ssh -p #{sshPort} -oBatchMode=yes" etc/init.d/ #{sshUser}@#{sshHost}:/etc/init.d

            echo "Adding meteor-#{repo} to default runlevel and restarting"
            ssh -p #{sshPort} -oBatchMode=yes #{sshUser}@#{sshHost} << ENDSSH
              rm /etc/nginx/sites-enabled/*
              ln -s /etc/nginx/sites-available/#{sshHost}.conf /etc/nginx/sites-enabled/#{sshHost}.conf
              cd /var/meteor/#{repo}/programs/server && npm install
              update-rc.d meteor-#{repo} defaults
              /etc/init.d/meteor-#{repo} stop; /etc/init.d/meteor-#{repo} start
              service nginx restart
ENDSSH
          """
      ]
    else if Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/package.js")
      return [
        name: 'CoffeeLint'
        cmd: """
            CF=`find . -name "*.coffee"`
            test -z "${CF}" || coffeelint ${CF}
          """
        errorMessage: (out) ->
          clErrors = out?.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)?.shift()?.trim()
          "CoffeeLint found #{clErrors}"
      ,
        name: 'jshint'
        cmd: """
            JF=`find . -name "*.js" | grep -v .min.js`
            test -z "${JF}" || jshint ${JF}
          """
        errorMessage: (out) ->
          "jshint found " + out?.trim().split('\n').pop()
      ,
        name: 'spacejam'
        cmd: "spacejam test-packages ./"
      ]


