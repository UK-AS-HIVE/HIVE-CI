Meteor.methods
  buildProject: (projectId, forceRebuild) ->
    project = Projects.findOne projectId
    console.log "scheduling BuildProjectJob for #{project.name}"
    Deployments.find({projectId: projectId}).forEach (d) ->
      Meteor.call 'buildDeployment', d, forceRebuild
    #Projects.update projectId, {$set: {status: 'Pending'}}
  buildDeployment: (deployment, forceRebuild) ->
    Job.push new BuildProjectJob
      deployment: deployment
      forceRebuild: forceRebuild
    BuildSessions.insert
      projectId: deployment.projectId
      deploymentId: deployment._id
      targetHost: deployment.targetHost
      status: 'Pending'
      message: 'Scheduled to build...'
      timestamp: Date.now()

