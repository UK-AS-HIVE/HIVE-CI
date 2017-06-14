getNodeVersion = (buildDir, repo) ->
  fs = Npm.require('fs')
  meteorRelease = fs.readFileSync "#{buildDir}/#{repo}/.meteor/release"
  if meteorRelease.indexOf("@1.4") > -1
    return "4.5.0"
  else if meteorRelease.indexOf("@1.3") > -1
    return "0.10.46"
  else
    return "0.10"

exports.getEnv = (fr, deployment, project, repo, buildDir, stageDir) ->
  targetHref = deployment.targetHost.replace(/\/$/, '') + '/'
  targetUrl = Npm.require('url').parse targetHref
  appInstallUrl = ''
  if deployment.appInstallUrl?.trim().length > 0
    appInstallUrl = Npm.require('url').parse(deployment.appInstallUrl).path || ''
  console.log "APP INSTALL URL: #{appInstallUrl}"
  _.extend _.pick(process.env,
      'HOME', 'LANG', 'PATH', 'NVM_BIN', 'NVM_DIR', 'NVM_NODEJS_ORG_MIRROR', 'NVM_PATH', 'SHELL', 'SHLVL', 'TERM', 'USER'),
    METEOR_VERSION: 'something?'
    GH_API_TOKEN: Meteor.settings.ghApiToken
    ORG_PREFIX: Meteor.settings.orgName
    ORG_REVERSE_URL: Meteor.settings.orgReverseUrl
    REPO: repo
    ORIG_DIR: fr+'../../private'
    DEV_SERVER: targetHref
    BUILD_DIR: buildDir
    STAGE_DIR: stageDir
    ANDROID_HOME: process.env.ANDROID_HOME || (process.env.HOME + '/.meteor/android_bundle/android-sdk')
    NODE_VERSION: getNodeVersion(buildDir, repo)
    INITD_ENVVARS: deployment.env?.split('\n').map((l) -> 'export ' + l).join('\n') || ''
    SSH_HOST: targetUrl.hostname
    SSH_USER: deployment.sshConfig?.user || 'root'
    SSH_PORT: deployment.sshConfig?.port || 22
    APP_INTERNAL_PORT: deployment.internalPort
    TARGET_HREF: targetHref
    TARGET_HOSTNAME: targetUrl.hostname
    TARGET_APP_PATH: appInstallUrl.replace(/\/$/, '') + '/'
    TARGET_PATH: targetUrl.path.replace(/^\//, '')
    TARGET_PROTOCOL: targetUrl.protocol
    TARGET_PORT: targetUrl.port || if targetUrl.protocol == 'https:' then 443 else 80
    URIENC_TARGET_HREF: encodeURIComponent(targetHref)
    URIENC_TARGET_HOSTNAME: encodeURIComponent(targetUrl.hostname)
    URIENC_TARGET_PATH: encodeURIComponent(targetUrl.path.replace(/\/$/, ''))
    URIENC_TARGET_PROTOCOL: encodeURIComponent(targetUrl.protocol)
    URIENC_TARGET_PORT: encodeURIComponent(targetUrl.port || if targetUrl.protocol == 'https' then 443 else 80)

