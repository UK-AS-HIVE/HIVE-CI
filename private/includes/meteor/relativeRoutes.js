(function () {
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
        var regex = new RegExp('^' + escapeRegex(subpath));
        if (route.indexOf('/') > -1 && !regex.test(route)) {
            arguments[0] = subpath + route;
        }
        return oldGo.apply(this, arguments);
    };
 
    function escapeRegex(str) {
        return str.replace(/([/\\.?*()^${}|[\]])/g, '\\$1');
    }
})();
