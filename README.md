HIVE-CI
=======

Continuous integration scripts and configuration for HIVE projects. 

### Setup

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

