SimpleSchema.messages
  settingsInvalidJSON: 'Settings must be valid JSON.'
  envVarFormat: 'Environment variables should be one per line.  Names can be capital letters and underscores, separated from values by ='


@Projects = new Mongo.Collection 'projects'
@Projects.attachSchema new SimpleSchema
  name:
    type: String
  gitUrl:
    type: String
  pushedAt:
    type: new Date()
    optional: true

@Deployments = new Mongo.Collection 'deployments'
@Deployments.attachSchema new SimpleSchema
  projectId:
    type: String
    autoform:
      type: 'select'
      options: ->
        Projects.find({},{sort: {name: 1}}).map (p) ->
          label: p.name, value: p._id
  branch:
    type: String
    defaultValue: 'devel'
    autoform:
      label: 'Git branch'
      placeholder: 'devel'
  targetHost:
    type: String
    autoform:
      label: 'Deploy to URL'
      placeholder: 'https://...'
  targetHostName:
    type: String
    autoform:
      omit: true
    optional: true
  targetIp:
     type: String
     autoform:
       omit: true
     #denyInsert: true
     optional: true
  internalPort:
    type: Number
    autoform:
    #  omit: true
      placeholder: 'leave blank to auto-assign'
    optional: true
  appInstallUrl:
    type: String
    optional: true
    autoform:
      label: 'App install URL'
      placeholder: 'https://...'
  settings:
    type: String
    custom: ->
      try
        JSON.parse @value
      catch e
        'settingsInvalidJSON'
    autoform:
      label: 'Settings (JSON)'
      type: 'textarea'
      rows: 5
      placeholder: """
{
  "settings": {
    "foo": "bar"
  }
}
"""
  sshConfig:
    type: Object
    optional: true
    autoform:
      label: 'SSH config'
  'sshConfig.user':
    type: String
    optional: true
    defaultValue: 'root'
    autoform:
      label: 'SSH user'
      placeholder: 'root'
  'sshConfig.port':
    type: Number
    optional: true
    defaultValue: 22
    autoform:
      label: 'SSH port'
      placeholder: 22
  domainAliases:
    type: [new SimpleSchema
        alias:
          type: String
          regEx: SimpleSchema.RegEx.Domain
        target:
          type: String
          regEx: SimpleSchema.RegEx.Domain
      ]
    optional: true
  env:
    type: String
    optional: true
    label: 'Environment Variables'
    custom: ->
      try
        @value.split('\n').forEach (l) ->
          [whole, name, value, ...] = l.match /^([A-Z_]+)=(.*)$/
          name: name
          value: value
      catch e
        'envVarFormat'
    autoform:
      type: 'textarea'

@BuildSessions = new Mongo.Collection 'buildSessions'
@BuildSessions.attachSchema new SimpleSchema
  projectId:
    type: String
  deploymentId:
    type: String
  #jobId:
  #  type: String
  timestamp:
    type: new Date()
    defaultValue: Date.now
  status:
    type: String
    allowedValues: ['Pass', 'Fail', 'Pending', 'Building', 'Unsupported', 'Error']
  targetHost:
    type: String
  message:
    type: String
    optional: true
  'git.commitHash':
    type: String
    optional: true
  'git.committerName':
    type: String
    optional: true
  'git.commitMessage':
    type: String
    optional: true
  'git.commitTag':
    type: String
    optional: true
  stages:
    type: [Object]
    optional: true
  'stages.$.name':
    type: String
  'stages.$.stdout':
    type: String
  'stages.$.message':
    type: String
    optional: true



