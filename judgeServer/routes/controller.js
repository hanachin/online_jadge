// Generated by CoffeeScript 1.4.0

module.exports = function(option) {
  var app, database;
  app = option.app;
  database = option.dataBase;
  app.get('/check_judge', function(req, res, next) {
    var checkJudge;
    checkJudge = require('./check_judge');
    return checkJudge.main(req, res);
  });
  app.get('/request_judge', function(req, res, next) {
    var jadge;
    jadge = require('./jadge_source');
    return jadge.main(req, res, dataBase);
  });
  return "controller is setup";
};
