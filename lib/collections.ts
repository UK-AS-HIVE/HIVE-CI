import {SimpleSchema} from 'meteor/aldeed:simple-schema';

SimpleSchema.messages({
  settingsInvalidJSON: 'Settings must be valid JSON.',
  envVarFormat: 'Environment variables should be one per line.  Names can be capital letters and underscores, separated from values by ='
});

export var Projects = new Mongo.Collection('projects');
(Projects as any).attachSchema(new SimpleSchema({
  name: {
    type: String
  },
  gitUrl: {
    type: String
  },
  pushedAt: {
    type: new Date(),
    optional: true
  }
}));

export var Deployments = new Mongo.Collection('deployments');
(Deployments as any).attachSchema(new SimpleSchema({
  projectId: {
    type: String,
    autoform: {
      type: 'select',
      options: function() {
        return Projects.find({}, {
          sort: {
            name: 1
          }
        }).map(function(p) {
          return {
            label: p.name,
            value: p._id
          };
        });
      }
    }
  },
  branch: {
    type: String,
    defaultValue: 'devel',
    autoform: {
      label: 'Git branch',
      placeholder: 'devel'
    }
  },
  targetHost: {
    type: String,
    autoform: {
      label: 'Deploy to URL',
      placeholder: 'https://...'
    }
  },
  targetHostName: {
    type: String,
    autoform: {
      omit: true
    },
    optional: true
  },
  targetIp: {
    type: String,
    autoform: {
      omit: true
    },
    optional: true
  },
  internalPort: {
    type: Number,
    autoform: {
      placeholder: 'leave blank to auto-assign'
    },
    optional: true
  },
  appInstallUrl: {
    type: String,
    optional: true,
    autoform: {
      label: 'App install URL',
      placeholder: 'https://...'
    }
  },
  settings: {
    type: String,
    custom: function() {
      var e;
      try {
        return JSON.parse(this.value);
      } catch (error) {
        e = error;
        return 'settingsInvalidJSON';
      }
    },
    autoform: {
      label: 'Settings (JSON)',
      type: 'textarea',
      rows: 5,
      placeholder: "{\n  \"settings\": {\n    \"foo\": \"bar\"\n  }\n}"
    }
  },
  basicAuthentication: {
    type: Object,
    optional: true,
    autoform: {
      label: 'Basic Authentication (Optional)'
    }
  },
  'basicAuthentication.prompt': {
    type: String,
    autoform: {
      label: 'Prompt',
      placeholder: 'Authentication Required'
    }
  },
  'basicAuthentication.username': {
    type: String,
    autoform: {
      label: 'Username'
    }
  },
  'basicAuthentication.password': {
    type: String,
    autoform: {
      label: 'Password'
    }
  },
  sshConfig: {
    type: Object,
    optional: true,
    autoform: {
      label: 'SSH config'
    }
  },
  'sshConfig.user': {
    type: String,
    optional: true,
    defaultValue: 'root',
    autoform: {
      label: 'SSH user',
      placeholder: 'root'
    }
  },
  'sshConfig.port': {
    type: Number,
    optional: true,
    defaultValue: 22,
    autoform: {
      label: 'SSH port',
      placeholder: 22
    }
  },
  domainAliases: {
    type: [
      new SimpleSchema({
        alias: {
          type: String,
          regEx: SimpleSchema.RegEx.Domain
        },
        target: {
          type: String,
          regEx: SimpleSchema.RegEx.Domain
        }
      })
    ],
    optional: true
  },
  env: {
    type: String,
    optional: true,
    label: 'Environment Variables',
    custom: function() {
      var e;
      try {
        if (!this.value) {
          return {};
        } else {
          return this.value.split('\n').forEach(function(l) {
            var name, ref, value, whole;
            ref = l.match(/^([A-Z_]+)=(.*)$/), whole = ref[0], name = ref[1], value = ref[2];
            return {
              name: name,
              value: value
            };
          });
        }
      } catch (error) {
        e = error;
        return 'envVarFormat';
      }
    },
    autoform: {
      type: 'textarea'
    }
  }
}));

export var BuildSessions = new Mongo.Collection('buildSessions');
(BuildSessions as any).attachSchema(new SimpleSchema({
  projectId: {
    type: String
  },
  deploymentId: {
    type: String
  },
  timestamp: {
    type: new Date(),
    defaultValue: Date.now
  },
  status: {
    type: String,
    allowedValues: ['Pass', 'Fail', 'Pending', 'Building', 'Unsupported', 'Error']
  },
  targetHost: {
    type: String
  },
  message: {
    type: String,
    optional: true
  },
  'git.commitHash': {
    type: String,
    optional: true
  },
  'git.committerName': {
    type: String,
    optional: true
  },
  'git.commitMessage': {
    type: String,
    optional: true
  },
  'git.commitTag': {
    type: String,
    optional: true
  },
  stages: {
    type: [Object],
    optional: true
  },
  'stages.$.name': {
    type: String
  },
  'stages.$.stdout': {
    type: String
  },
  'stages.$.message': {
    type: String,
    optional: true
  }
}));
