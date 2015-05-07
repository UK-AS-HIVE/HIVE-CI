@Projects = new Mongo.Collection 'projects'
@Projects.attachSchema new SimpleSchema
  name:
    type: String
  gitUrl:
    type: String
  pushedAt:
    type: new Date()

@BuildSessions = new Mongo.Collection 'buildSessions'
@BuildSessions.attachSchema new SimpleSchema
  projectId:
    type: String
  #jobId:
  #  type: String
  timestamp:
    type: new Date()
    defaultValue: Date.now
  status:
    type: String
    allowedValues: ['Pass', 'Fail', 'Pending', 'Building', 'Unsupported', 'Error']
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



