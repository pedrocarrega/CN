'use strict';
const db = require('./db.json'); //to remove later

/**
 * Shows the ratio of all 3 event types: view, cart and purchase
 *
 * returns List
 **/
exports.eventsRatio = function() {
  return new Promise(function(resolve, reject) {
    var examples = {};
    examples['application/json'] = [ {
  "eventTime" : "2000-01-23T04:56:07.000+00:00",
  "count" : 6.02745618307040320615897144307382404804229736328125,
  "eventType" : "view",
  "ratio" : 0.8008281904610115
}, {
  "eventTime" : "2000-01-23T04:56:07.000+00:00",
  "count" : 6.02745618307040320615897144307382404804229736328125,
  "eventType" : "view",
  "ratio" : 0.8008281904610115
} ];
    if (Object.keys(examples).length > 0) {
      resolve(examples[Object.keys(examples)[0]]);
    } else {
      resolve();
    }
  });
}

