exports.Stages = _.extend {},
  require('./coffeelint.coffee'),
  require('./jshint.coffee'),
  require('./spacejam.coffee'),
  require('./gagarin.coffee'),
  require('./build.coffee'),
  require('./ios.coffee'),
  require('./android.coffee'),
  require('./generateNginx.coffee'),
  require('./deploy.coffee')

