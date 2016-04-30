exports.dnsLookup = (hostname) ->
  Future = Npm.require 'fibers/future'
  f = new Future()
  Npm.require('dns').lookup hostname, (err, res) ->
    f.return res

  f.wait()


