Meteor.publishComposite 'projectsWithLast', ->
  find: ->
    Projects.find()
  children: [
      find: (project) ->
        BuildSessions.find({projectId: project._id}, {sort: {timestamp: -1}, limit: 1})
    ]

Meteor.publishComposite 'projectDetail', (projectName) ->
  find: ->
    Projects.find name: projectName
  children: [
    {
      find: (project) ->
        BuildSessions.find({projectId: project._id}, {limit: 100, sort: {timestamp: -1}})
    }
  ,
    {
      find: (project) ->
        Deployments.find({projectId: project._id})
    }
  ]

