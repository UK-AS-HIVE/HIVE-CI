Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'
###
  onBeforeAction: ->
    if Meteor.isClient and not Meteor.userId()
      @render 'login'
    else
      @next()
###

Router.map ->
  @route 'default',
    path: '/'
    waitOn: ->
      Meteor.subscribe 'projectsWithLast'

  @route 'project',
    path: '/project/:projectName'
    data: ->
      Projects.findOne({name: @params.projectName})
    waitOn: ->
      Meteor.subscribe 'projectDetail', @params.projectName

  @route 'about',
    path: '/about'
      
  @route 'serveFile',
    path: '/file/:filename'
    where: 'server'
    action: FileRegistry.serveFile

