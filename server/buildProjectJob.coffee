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
    console.log 'building project '+proj.name
    #Projects.update {_id: @params.projectId}, {$set: {status: 'Building'}}

    BuildSessions.update session._id,
      $set:
        status: 'Building'
        message: 'Fetching...'
        timestamp: Date.now()

    fr = FileRegistry.getFileRoot()

    buildDir = fr + '/sandbox/build'

    orgAndRepo = proj.gitUrl.match(/([a-zA-Z0-9-_.]+)\/([a-zA-Z0-9-_.]+)$/)
    org = orgAndRepo[1]
    repo = orgAndRepo[2].replace '.git', ''
    url = "https://#{Meteor.settings.ghApiToken}:x-oauth-basic@github.com/#{org}/#{repo}"
    @params.cmd = """
      echo Fetch phase
      mkdir -p #{buildDir}
      cd #{buildDir}
      if [[ -e "#{repo}/" ]]
      then
        cd #{repo}
        git reset --hard
        git checkout --
        git clean -dff
        git pull
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
    out = super()
    console.log out

    gitInfo = out.trim().split('\n')
    gitInfo = gitInfo.slice(gitInfo.length-3,gitInfo.length+1)
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

    if !Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/.meteor")
      BuildSessions.update session._id,
        $set:
          status: 'Unsupported'
          message: 'Not a Meteor repository'
          timestamp: Date.now()
      return

    @params.cmd = """
      cd #{fr}/sandbox/build/#{repo}
      coffeelint `find . -name "*.coffee" | grep -v .meteor | grep -v packages`
    """
    BuildSessions.update {'git.commitHash': hash},
      $set:
        message: 'CoffeeLint...'

    out = super()
    console.log out

    clErrors = out.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)?.shift().trim()

    if clErrors? and clErrors != '0 errors'
      BuildSessions.update session._id,
        $set:
          status: 'Fail'
          message: "CoffeeLint found #{clErrors}"
      return

    BuildSessions.update session._id,
      $set:
        status: 'Pass'
        message: 'All phases successful'
        timestamp: Date.now()

