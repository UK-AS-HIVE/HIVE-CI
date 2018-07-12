export const dnsLookup = function(hostname) {
  var Future, f;
  Future = Npm.require('fibers/future');
  f = new Future();
  Npm.require('dns').lookup(hostname, function(err, res) {
    return f["return"](res);
  });
  return f.wait();
};
