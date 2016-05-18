(function () {
  if (typeof Router !== "undefined" && Router !== null) {
    var url = Meteor.absoluteUrl();
    url = url.replace(/https?:\/\//, '');
    var slash = url.indexOf('/');
    var subpath = url.substring(slash);
    subpath = subpath.substring(0, subpath.length-1);
    var oldRoute = Router.route;
    Router.route = function (name) {
        args = Array.prototype.slice.call(arguments);
        if (args.length > 1 && !Meteor.isServer) {
          if (typeof(args[args.length-1]) === 'function')
            args.push({});
          options = args[args.length-1];
          options.path = subpath + (options.path || name);
        }
        return oldRoute.apply(this, args);
    };

    var oldGo = Router.go;
    Router.go = function (route) {
        var args = Array.prototype.slice.call(arguments);
        var regex = new RegExp('^' + escapeRegex(subpath));
        if (route.indexOf('/') > -1 && !regex.test(route)) {
            args[0] = subpath + route;
        }
        return oldGo.apply(this, args);
    };

    function escapeRegex(str) {
        return str.replace(/([/\\.?*()^${}|[\]])/g, '\\$1');
    }
  }

  if (Meteor.isClient) {
    Template.registerHelper('rootAppUrl', function() {
      if (Meteor.isCordova) {
        return '/'+__meteor_runtime_config__.ROOT_URL_PATH_PREFIX.replace(/\/$/, '');
      } else {
        return __meteor_runtime_config__.ROOT_URL.replace(/\/$/, '');
      }
    });
  }

})();
