@Stages = {} || @Stages

@dnsLookup = (hostname) ->
  Future = Npm.require 'fibers/future'
  f = new Future()
  Npm.require('dns').lookup hostname, (err, res) ->
    f.return res

  f.wait()

Stages.generateNginx =
  name: "Generating nginx reverse proxy configuration"
  func: (fr, deployment, project, repo, buildDir, stageDir) ->
    SSR.compileTemplate 'nginx', Assets.getText 'templates/nginx.html'

    targetUrl = Npm.require('url').parse(deployment.targetHost)

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

    nginxDir = "#{stageDir}/etc/nginx/sites-available"

    mkdirp.sync nginxDir
    Npm.require('fs').writeFileSync "#{nginxDir}/#{targetUrl.hostname}.conf", generated

