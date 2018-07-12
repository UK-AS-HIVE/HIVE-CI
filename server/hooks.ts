import {Deployments} from '../lib/collections';
import {dnsLookup} from '../imports/stages/dnsLookup';

var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Deployments.before.insert(function(userId, doc) {
  var port, ref;
  doc.targetHostName = Npm.require('url').parse(doc.targetHost).hostname;
  doc.targetIp = dnsLookup(doc.targetHostName);
  if (doc.internalPort == null) {
    port = (((ref = Deployments.findOne({
      _id: {
        $ne: doc._id
      },
      targetIp: doc.targetIp
    }, {
      sort: {
        internalPort: -1
      }
    })) != null ? ref.internalPort : void 0) || 2999) + 1;
    return doc.internalPort = port;
  }
});

Deployments.before.update(function(userId, doc, fieldNames, modifier, options) {
  var port, ref, ref1;
  if (indexOf.call(fieldNames, 'targetHost') >= 0) {
    modifier.$set = modifier.$set || {};
    modifier.$set.targetHostName = doc.targetHostName = Npm.require('url').parse(doc.targetHost).hostname;
    modifier.$set.targetIp = doc.targetIp = dnsLookup(doc.targetHostName);
  }
  if ((((ref = modifier.$unset) != null ? ref.internalPort : void 0) != null) || (doc.internalPort == null)) {
    modifier.$set = modifier.$set || {};
    port = (((ref1 = Deployments.findOne({
      _id: {
        $ne: doc._id
      },
      targetIp: doc.targetIp
    }, {
      sort: {
        internalPort: -1
      }
    })) != null ? ref1.internalPort : void 0) || 2999) + 1;
    modifier.$set.internalPort = port;
    return delete modifier.$unset.internalPort;
  }
});
