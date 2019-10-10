var getNodeVersion;

getNodeVersion = function(buildDir, repo) {
  var fs, meteorRelease;
  fs = Npm.require('fs');
  meteorRelease = fs.readFileSync(buildDir + "/" + repo + "/.meteor/release");
  if (meteorRelease.indexOf("@1.8") > -1) {
    return "8.15.1";
  } else if (meteorRelease.indexOf("@1.7") > -1) {
    return "8.11.4";
  } else if (meteorRelease.indexOf("@1.6") > -1) {
    return "8.11.4";
  } else if (meteorRelease.indexOf("@1.5.") > -1) {
    return "4.8.4";
  } else if (meteorRelease.indexOf("@1.4") > -1) {
    return "4.5.0";
  } else if (meteorRelease.indexOf("@1.3") > -1) {
    return "0.10.46";
  } else {
    throw "unsupported Meteor version - not sure which node version to use";
  }
};

export const getEnv = function(fr, deployment, project, repo, buildDir, stageDir) {
  var appInstallUrl, ref, ref1, ref2, ref3, targetHref, targetUrl;
  targetHref = deployment.targetHost.replace(/\/$/, '') + '/';
  targetUrl = Npm.require('url').parse(targetHref);
  appInstallUrl = '';
  if (((ref = deployment.appInstallUrl) != null ? ref.trim().length : void 0) > 0) {
    appInstallUrl = Npm.require('url').parse(deployment.appInstallUrl).path || '';
  }
  console.log("APP INSTALL URL: " + appInstallUrl);
  return _.extend(_.pick(process.env, 'HOME', 'LANG', 'PATH', 'NVM_BIN', 'NVM_DIR', 'NVM_NODEJS_ORG_MIRROR', 'NVM_PATH', 'SHELL', 'SHLVL', 'TERM', 'USER'), {
    METEOR_VERSION: 'something?',
    GH_API_TOKEN: Meteor.settings.ghApiToken,
    ORG_PREFIX: Meteor.settings.orgName,
    ORG_REVERSE_URL: Meteor.settings.orgReverseUrl,
    REPO: repo,
    ORIG_DIR: fr + '../../private',
    DEV_SERVER: targetHref,
    BUILD_DIR: buildDir,
    STAGE_DIR: stageDir,
    ANDROID_HOME: process.env.ANDROID_HOME || (process.env.HOME + '/.meteor/android_bundle/android-sdk'),
    NODE_VERSION: getNodeVersion(buildDir, repo),
    INITD_ENVVARS: ((ref1 = deployment.env) != null ? ref1.split('\n').map(function(l) {
      return 'export ' + l;
    }).join('\n') : void 0) || '',
    SSH_HOST: targetUrl.hostname,
    SSH_USER: ((ref2 = deployment.sshConfig) != null ? ref2.user : void 0) || 'root',
    SSH_PORT: ((ref3 = deployment.sshConfig) != null ? ref3.port : void 0) || 22,
    APP_INTERNAL_PORT: deployment.internalPort,
    TARGET_HREF: targetHref,
    TARGET_HOSTNAME: targetUrl.hostname,
    TARGET_APP_PATH: appInstallUrl.replace(/\/$/, '') + '/',
    TARGET_PATH: targetUrl.path.replace(/^\//, ''),
    TARGET_PROTOCOL: targetUrl.protocol,
    TARGET_PORT: targetUrl.port || (targetUrl.protocol === 'https:' ? 443 : 80),
    URIENC_TARGET_HREF: encodeURIComponent(targetHref),
    URIENC_TARGET_HOSTNAME: encodeURIComponent(targetUrl.hostname),
    URIENC_TARGET_PATH: encodeURIComponent(targetUrl.path.replace(/\/$/, '')),
    URIENC_TARGET_PROTOCOL: encodeURIComponent(targetUrl.protocol),
    URIENC_TARGET_PORT: encodeURIComponent(targetUrl.port || (targetUrl.protocol === 'https' ? 443 : 80))
  });
};

