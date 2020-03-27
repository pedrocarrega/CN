'use strict';

var utils = require('../utils/writer.js');
var Events = require('../service/EventsService');

module.exports.eventsRatio = function eventsRatio (req, res, next) {
  Events.eventsRatio()
    .then(function (response) {
      utils.writeJson(res, response);
    })
    .catch(function (response) {
      utils.writeJson(res, response);
    });
};
