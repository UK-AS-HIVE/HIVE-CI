(function () {
    var url = Meteor.absoluteUrl();
    url = url.replace(/https?:\/\//, '');
    var slash = url.indexOf('/');
    var subpath = url.substring(slash);
    subpath = subpath.substring(0, subpath.length-1);
    var oldRoute = Router.route;
    Router.route = function (name, options) {
        if (options)
          arguments[1].path = subpath + options.path;
        return oldRoute.apply(this, arguments);
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
