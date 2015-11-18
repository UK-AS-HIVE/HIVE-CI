getEnv = (fr, deployment, project, repo, buildDir, stageDir) ->
  targetUrl = Npm.require('url').parse(deployment.targetHost)
  appInstallUrl = ''
  if deployment.appInstallUrl?.trim().length > 0
    appInstallUrl = Npm.require('url').parse(deployment.appInstallUrl).path || ''
  console.log "APP INSTALL URL: #{appInstallUrl}"
  _.extend process.env,
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
    SSH_HOST: targetUrl.hostname
    SSH_USER: deployment.sshConfig?.user || 'root'
    SSH_PORT: deployment.sshConfig?.port || 22
    TARGET_HOSTNAME: targetUrl.hostname
    TARGET_APP_PATH: appInstallUrl.replace(/\/$/, '') + '/'
    TARGET_PATH: targetUrl.path
    TARGET_PROTOCOL: targetUrl.protocol
    TARGET_PORT: targetUrl.port || if targetUrl.protocol == 'https:' then 443 else 80
    URIENC_TARGET_HOSTNAME: encodeURIComponent(targetUrl.hostname)
    URIENC_TARGET_PATH: encodeURIComponent(targetUrl.path.replace(/^\//, ''))
    URIENC_TARGET_PROTOCOL: encodeURIComponent(targetUrl.protocol)
    URIENC_TARGET_PORT: encodeURIComponent(targetUrl.port || if targetUrl.protocol == 'https' then 443 else 80)

availableStages =
  coffeelint:
    name: 'CoffeeLint'
    cmd: """
        CF=`find . -name "*.coffee" | grep -v .meteor | grep -v packages`
        test -z "${CF}" || coffeelint ${CF}
      """
    errorMessage: (out) ->
      clErrors = out?.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)?.shift()?.trim()
      "CoffeeLint found #{clErrors}"
  jshint:
    name: 'jshint'
    cmd: """
        JF=`find . -name "*.js" | grep -v "client/compatibility" | grep -v "public/" | grep -v .meteor | grep -v packages | grep -v .min.js`
        test -z "${JF}" || jshint ${JF}
      """
    errorMessage: (out) ->
      "jshint found " + out?.trim().split('\n').pop()
  spacejam:
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
  build:
    name: 'Building Meteor app'
    cmd:
      Assets.getText('includes/meteor/meteorFunctions.sh') +
      """
        buildMeteor
      """
  ios:
    name: 'Building iOS app'
    cmd:
      Assets.getText('includes/meteor/iosFunctions.sh') +
      """
        buildIos
      """
  android:
    name: 'Build Android app'
    cmd:
      Assets.getText('includes/meteor/meteorFunctions.sh') +
      """
        buildAndroid
      """
  deploy:
    name: "Deploying to host"
    cmd:
      Assets.getText('includes/deploy/generateInitd.sh') +
      Assets.getText('includes/deploy/generateNginx.sh') +
      Assets.getText('includes/deploy/generateHtmlindex.sh') +
      """
        generateInitd
        generateHtmlindex
        generateNginx

        echo "Deploying ${REPO} to ${DEV_SERVER}..."
        cd ${STAGE_DIR}
        rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" var/www/ ${SSH_USER}@${SSH_HOST}:/var/www
        rsync -avz --delete --exclude 'programs/server/node_modules' --exclude 'files/' -e "ssh -p ${SSH_PORT} -oBatchmode=yes" var/meteor/${REPO} ${SSH_USER}@${SSH_HOST}:/var/meteor
        rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" etc/nginx/sites-available/${SSH_HOST}.conf ${SSH_USER}@${SSH_HOST}:/etc/nginx/sites-available/${SSH_HOST}.conf
        rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" etc/init.d/ ${SSH_USER}@${SSH_HOST}:/etc/init.d

        echo "Adding meteor-${REPO} to default runlevel and restarting"
        ssh -p ${SSH_PORT} -oBatchMode=yes ${SSH_USER}@${SSH_HOST} << ENDSSH
          rm /etc/nginx/sites-enabled/*
          ln -s /etc/nginx/sites-available/${SSH_HOST}.conf /etc/nginx/sites-enabled/${SSH_HOST}.conf
          cd /var/meteor/${REPO}/programs/server && npm install
          update-rc.d meteor-${REPO} defaults
          /etc/init.d/meteor-${REPO} stop; /etc/init.d/meteor-${REPO} start
          service nginx restart
ENDSSH
      """

# Identifies type of project and returns an array of build stages
# stage.name - name of stage, for ui
# stage.cmd - shell command to execute
# stage.errorCallback - callback function with which to detect an error or
#   verify proper output of executed cmd.  will be called with a single
#   parameter, the stdout string of the executed process, and should return 0
#   for no error or any other value for error.
@getBuildStages = (fr, deployment, project, repo, buildDir, stageDir) ->
  env = getEnv fr, deployment, project, repo, buildDir, stageDir

  if Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/.meteor")
    # Meteor app
    return _.map _.omit(availableStages, 'ios', 'android'), (s) -> _.extend {env: env}, s
  else if Npm.require('fs').existsSync("#{fr}/sandbox/build/#{repo}/package.js")
    # Meteor package
    return _.map _.pick(availableStages, 'coffeelint', 'jshint', 'spacejam'), (s) -> _.extend {env: env}, s

