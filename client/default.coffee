Template.default.helpers
  projects: -> Projects.find({}, {sort: {pushedAt: -1}})
  buildSession: -> BuildSessions.findOne({projectId: @_id})
  latestStage: ->
    _.last @stages
  rowStyle: ->
    status = BuildSessions.findOne({projectId: @_id}).status
    if status == 'Unsupported'
      'background: rgba(255,255,0,0.1);'
    else if status == 'Pass'
      'background: rgba(0,255,0,0.1);'
    else if status == 'Fail'
      'background: rgba(255,0,0,0.1);'
  moment: (date) ->
    Session.get 'tick'
    moment(date).fromNow()

Template.default.events
  'click .run-job-button': (e, tpl) ->
    Meteor.call 'buildProject', @_id

Meteor.startup ->
  Meteor.setInterval ->
    Session.set 'tick', Date.now()
  , 1000

