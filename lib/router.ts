import {Router} from 'meteor/iron:router';
import {Projects} from './collections';

Router.configure({
  layoutTemplate: 'layout',
  loadingTemplate: 'loading'
});


/*
  onBeforeAction: ->
    if Meteor.isClient and not Meteor.userId()
      @render 'login'
    else
      @next()
  */

Router.map(function() {
  this.route('default', {
    path: '/',
    waitOn: function() {
      return Meteor.subscribe('projectsWithLast');
    }
  });
  this.route('project', {
    path: '/project/:projectName',
    data: function() {
      return Projects.findOne({
        name: this.params.projectName
      });
    },
    waitOn: function() {
      return Meteor.subscribe('projectDetail', this.params.projectName);
    }
  });
  this.route('about', {
    path: '/about'
  });
  return this.route('serveFile', {
    path: '/file/:filename',
    where: 'server',
    action: FileRegistry.serveFile
  });
});
