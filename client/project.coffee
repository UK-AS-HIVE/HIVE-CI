Template.project.helpers
  mostRecentBuildSession: ->
    BuildSessions.findOne({projectId: @_id}, {sort: {timestamp: -1}})
  buildSessions: ->
    BuildSessions.find({projectId: @_id}, {sort: {timestamp: -1}})
  rowStyle: (buildSession) ->
    status = buildSession?.status || @status?
    if status == 'Unsupported'
      'background: rgba(255,255,0,0.1);'
    else if status == 'Pass'
      'background: rgba(0,255,0,0.1);'
    else if status == 'Fail'
      'background: rgba(255,0,0,0.1);'
  moment: (date) ->
    moment(date).format('YYYY-MM-DD hh:mm:ss')

Template.project.events
  'click .run-job-button': (e, tpl) ->
    Meteor.call 'buildProject', @_id

