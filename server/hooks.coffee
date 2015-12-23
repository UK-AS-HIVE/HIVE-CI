Deployments.before.insert (userId, doc) ->
  doc.targetIp = dnsLookup Npm.require('url').parse(doc.targetHost).hostname
  unless doc.internalPort?
    port = (Deployments.findOne({_id: {$ne: doc._id}, targetIp: doc.targetIp}, {sort: {internalPort: -1}})?.internalPort || 2999) + 1
    doc.internalPort = port

Deployments.before.update (userId, doc, fieldNames, modifier, options) ->
  if 'targetHost' in fieldNames
    modifier.$set = modifier.$set || {}
    modifier.$set.targetIp = doc.targetIp = dnsLookup Npm.require('url').parse(doc.targetHost).hostname

  if modifier.$unset?.internalPort? or not doc.internalPort?
    modifier.$set = modifier.$set || {}
    port = (Deployments.findOne({_id: {$ne: doc._id}, targetIp: doc.targetIp}, {sort: {internalPort: -1}})?.internalPort || 2999) + 1
    modifier.$set.internalPort = port
    delete modifier.$unset.internalPort

