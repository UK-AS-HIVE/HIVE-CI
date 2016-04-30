Deployments.before.insert (userId, doc) ->
  {dnsLookup} = require '/imports/stages/dnsLookup.coffee'
  doc.targetHostName = Npm.require('url').parse(doc.targetHost).hostname
  doc.targetIp = dnsLookup doc.targetHostName
  unless doc.internalPort?
    port = (Deployments.findOne({_id: {$ne: doc._id}, targetIp: doc.targetIp}, {sort: {internalPort: -1}})?.internalPort || 2999) + 1
    doc.internalPort = port

Deployments.before.update (userId, doc, fieldNames, modifier, options) ->
  if 'targetHost' in fieldNames
    modifier.$set = modifier.$set || {}
    modifier.$set.targetHostName = doc.targetHostName = Npm.require('url').parse(doc.targetHost).hostname
    {dnsLookup} = require '/imports/stages/dnsLookup.coffee'
    modifier.$set.targetIp = doc.targetIp = dnsLookup doc.targetHostName

  if modifier.$unset?.internalPort? or not doc.internalPort?
    modifier.$set = modifier.$set || {}
    port = (Deployments.findOne({_id: {$ne: doc._id}, targetIp: doc.targetIp}, {sort: {internalPort: -1}})?.internalPort || 2999) + 1
    modifier.$set.internalPort = port
    delete modifier.$unset.internalPort

