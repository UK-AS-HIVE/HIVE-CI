exports.Stages = exports.Stages || {}

exports.Stages = _.extend exports.Stages,
  coffeelint:
    name: 'CoffeeLint'
    cmd: """
        CF=`find . -name "*.coffee" | { grep -v .meteor || true; } | { grep -v packages || true; }`
        test -z "${CF}" || coffeelint ${CF}
      """
    errorMessage: (out) ->
      clErrors = out?.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)?.shift()?.trim()
      "CoffeeLint found #{clErrors}"
  jshint:
    name: 'jshint'
    cmd: """
        JF=`find . -name "*.js" | { grep -vE "client/compatibility|public/|\.meteor|packages|.min.js" || true; }`
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
  gagarin:
    name: 'gagarin'
    cmd: """
      if [[ -e .meteor/release && -d tests/gagarin ]]
      then
        chromedriver &
        gagarin -v
      fi
    """
  build:
    name: 'Building Meteor app'
    cmd:
      Assets.getText('scripts/build/meteor.sh') +
      """
        buildMeteor
      """
  ios:
    name: 'Building iOS app'
    cmd:
      Assets.getText('scripts/build/ios.sh') +
      """
        buildIos
      """
  android:
    name: 'Build Android app'
    cmd:
      Assets.getText('scripts/build/android.sh') +
      """
        buildAndroid
      """
  generateNginx:
    name: "Generating nginx reverse proxy configuration"
    func: (fr, deployment, project, repo, buildDir, stageDir) ->
      SSR.compileTemplate 'nginx', Assets.getText 'templates/nginx.html'

      targetUrl = Npm.require('url').parse(deployment.targetHost)

      {dnsLookup} = require './dnsLookup.coffee'
      hostIp = dnsLookup targetUrl.hostname

      Template.nginx.helpers
        eq: (a, b) -> a == b
        targetHostname: -> targetUrl.hostname
        targetProtocol: -> targetUrl.protocol
        appDownloadPath: ->
          if deployment.appInstallUrl
            (Npm.require('url').parse(deployment.appInstallUrl).path || '').replace(/\/$/, '') + '/'
          else
            '/appDownloads/'
        proxiedApps: ->
          deployments = Deployments.find {targetHostName: targetUrl.hostname}
          console.log 'found ' + deployments.count() + ' deployments'
          return deployments
        appPath: ->
          Npm.require('url').parse(@targetHost).path.replace(/\/$/, '') + '/'

      generated = SSR.render 'nginx', @

      console.log generated

      nginxDir = "#{stageDir}/etc/nginx/sites-enabled"

      mkdirp.sync nginxDir
      Npm.require('fs').writeFileSync "#{nginxDir}/#{targetUrl.hostname}.conf", generated
  deploy:
    name: "Deploying to host"
    cmd:
      Assets.getText('scripts/deploy/generateInitd.sh') +
      Assets.getText('scripts/deploy/generateHtmlindex.sh') +
      """
        generateInitd
        generateHtmlindex

        echo "Deploying ${REPO} to ${DEV_SERVER}..."
        cd ${STAGE_DIR}
        rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" var/www/ ${SSH_USER}@${SSH_HOST}:/var/www
        rsync -avz --delete --exclude 'programs/server/node_modules' --exclude 'programs/server/files' -e "ssh -p ${SSH_PORT} -oBatchmode=yes" var/meteor/${REPO} ${SSH_USER}@${SSH_HOST}:/var/meteor
        rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" etc/nginx/sites-enabled/${SSH_HOST}.conf ${SSH_USER}@${SSH_HOST}:/etc/nginx/sites-enabled/${SSH_HOST}.conf
        rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" etc/init.d/ ${SSH_USER}@${SSH_HOST}:/etc/init.d

        echo "Adding meteor-${REPO} to default runlevel and restarting"
        ssh -p ${SSH_PORT} -oBatchMode=yes ${SSH_USER}@${SSH_HOST} << ENDSSH
          #rm /etc/nginx/sites-enabled/*
          #ln -s /etc/nginx/sites-available/${SSH_HOST}.conf /etc/nginx/sites-enabled/${SSH_HOST}.conf
          cd /var/meteor/${REPO}/programs/server && npm install
          update-rc.d meteor-${REPO} defaults
          /etc/init.d/meteor-${REPO} stop; /etc/init.d/meteor-${REPO} start
          service nginx restart
ENDSSH
      """


