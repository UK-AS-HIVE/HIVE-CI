HIVE-CI
=======

Continuous integration scripts and configuration for HIVE projects. 

### Setting up the CI machine

Have a settings.json file that looks something like this:

    {
      "ghApiToken": "createYourToken",
      "orgName": "UK-AS-HIVE",
      "orgReverseUrl": "edu.uky.as",
      "appsServer": "https://apps.domain.com",
      "devServer": "apps-dev.domain.com"
      "appSettings": {
        "MyApp": {
          "whatever": "..."
        }
      }
    }

Make sure you have dependencies installed:
    $ npm install -g coffeelint jshint spacejam

Then, assuming you have installed Meteor, type:

    $ meteor --settings=settings.json

Navigate to http://localhost:3000 in your browser to access the dashboard.

### Setting up Meteor host machines

Expected hosting environment is nginx-1.4, node 0.10, mongo 3.0, and postfix on
Ubuntu 14.04, with imagemagick, ghostscript, and ffmpeg installed.

Vagrant is recommended for quickly setting up a sample environment to deploy
to, using the Vagrantfile in the repository.

### Notes

This app uses `differential:workers` package to execute jobs from a queue on
the server.  Builds of repositories are scheduled periodically, triggered by
webhook, or manually invoked.

Repositories are built in order of most recent push to Github.  The following
stages are computed for each repository in turn.

* fetch
* varying build stage based on identified project type
  * lint (meteor app, meteor package, drupal module)
  * build (meteor app)
  * test (meteor app, meteor package, drupal module)
  * stage (meteor app)
* deploy
  * update config based on staged contents
  * rsync
* notify (TODO)
  * email
  * irc bot
  * curl

