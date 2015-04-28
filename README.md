HIVE-CI
=======

Continuous integration scripts and configuration for HIVE projects. 

Setup
-----

Have a settings.json file that looks something like this:

    {
      "ghApiToken": "createYourToken",
      "orgName": "UK-AS-HIVE",
      "orgReverseUrl": "edu.uky.as",
      "appsServer": "https://apps.domain.com",
      "devServer": "https://apps-dev.domain.com"
    }

Make sure you have dependencies installed:
    $ npm install -g coffeelint jshint spacejam

Then, assuming you have installed Meteor, type:

    $ meteor --settings=settings.json

Navigate to http://localhost:3000 in your browser to access the dashboard.

