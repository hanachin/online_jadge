// Generated by CoffeeScript 1.4.0

module.exports = function(option) {
  var app, database;
  app = option.app;
  database = option.dataBase;
  app.get('/check_jadge', function(req, res, next) {
    var checkJadge;
    checkJadge = require('./check_jadge');
    return checkJadge.main(req, res);
  });
  app.get('/request_jadge', function(req, res, next) {
    var jadge;
    jadge = require('./jadge_source');
    return jadge.main(req, res, dataBase);
  });
  return "controller is setup";
};