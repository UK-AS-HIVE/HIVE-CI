import {SSR} from 'meteor/meteorhacks:ssr';
import {mkdirp} from 'meteor/netanelgilad:mkdirp';
import {dnsLookup} from './dnsLookup';
import {Deployments} from '../../lib/collections';
import { execSync } from 'child_process';

export const generateNginx = {
  name: "Generating nginx reverse proxy configuration",
  func: function(fr, deployment, project, repo, buildDir, stageDir) {
    var generated, hostIp, nginxDir, targetUrl;
    SSR.compileTemplate('nginx', Assets.getText('templates/nginx.html'));
    targetUrl = Npm.require('url').parse(deployment.targetHost);
    hostIp = dnsLookup(targetUrl.hostname);
    Template.nginx.helpers({
      eq: function(a, b) {
        return a === b;
      },
      targetHostname: function() {
        return targetUrl.hostname;
      },
      domainAliases: function() {
        return deployment.domainAliases;
      },
      targetProtocol: function() {
        return targetUrl.protocol;
      },
      appDownloadPath: function() {
        if (deployment.appInstallUrl) {
          return (Npm.require('url').parse(deployment.appInstallUrl).path || '').replace(/\/$/, '') + '/';
        } else {
          return '/appDownloads/';
        }
      },
      proxiedApps: function() {
        var deployments;
        deployments = Deployments.find({
          targetHostName: targetUrl.hostname
        });
        console.log('found ' + deployments.count() + ' deployments');
        return deployments;
      },
      appPath: function() {
        return Npm.require('url').parse(this.targetHost).path.replace(/\/$/, '') + '/';
      },
      escapeChars: function(s) {
        return s.replace(/[ "'{};$\\]/g, function (m) {
          return "\\"+m;
        });
      },
      repo: function() {
        return repo;
      }
    });
    generated = SSR.render('nginx', this);
    console.log(generated);
    nginxDir = stageDir + "/etc/nginx/sites-enabled";
    mkdirp.sync(nginxDir);
    Npm.require('fs').writeFileSync(nginxDir + "/" + targetUrl.hostname + ".conf", generated);

    if (deployment.basicAuthentication && deployment.basicAuthentication.username && deployment.basicAuthentication.password) {
      let htpasswdDir = stageDir + "/etc/nginx/htpasswd";
      mkdirp.sync(htpasswdDir);
      let htpasswdFile = `${htpasswdDir}/${repo}`
      execSync(`htpasswd -bc ${htpasswdFile} ${deployment.basicAuthentication.username} ${deployment.basicAuthentication.password}`);
    }
  }
};
