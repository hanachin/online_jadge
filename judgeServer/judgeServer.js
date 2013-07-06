// Generated by CoffeeScript 1.6.2
var AppConfig, LogConfig, app, cluster, express, http, new_worker_env, num_cpu, server, worker, workerID;

express = require('express');

cluster = require('cluster');

http = require('http');

app = express();

/* ------- Class ------------------------------------------
*/


AppConfig = (function() {
  var _keepExtention, _tmpdir;

  function AppConfig() {}

  _tmpdir = "" + __dirname + "/tmp";

  _keepExtention = true;

  AppConfig.port = 3001;

  AppConfig["public"] = "" + __dirname + "/public";

  return AppConfig;

})();

LogConfig = (function() {
  function LogConfig() {}

  LogConfig.log = "" + __dirname + "/logs/";

  LogConfig.filename = "" + LogConfig.log + "/pxp_log";

  LogConfig.size = 1024 * 1024;

  LogConfig.format = '-yyyy-MM-dd';

  LogConfig.stdout = false;

  LogConfig.nolog = ['\\.js'];

  LogConfig.format = JSON.stringify({
    'method': ':method',
    'request': ':url',
    'status': ':status',
    'user-agent': ':user-agent'
  });

  return LogConfig;

})();

/* ------- middleware call. -------------------------------
*/


app.configure(function() {
  var logger;

  logger = log4js.getLogger('file');
  log4js.configure({
    appenders: [
      {
        'type': 'console'
      }, {
        'type': 'file',
        'filename': LogConfig.filename,
        'maxLogSize': LogConfig.size,
        'pattern': LogConfig.format,
        'category': 'console'
      }
    ],
    replaceConsole: LogConfig.stdout
  });
  app.use(log4js.connectLogger(logger, {
    nolog: LogConfig.nolog,
    format: LogConfig.format
  }));
  app.use(express.methodOverride());
  app.use(express["static"](AppConfig["public"]));
  return console.log("configure opption");
});

/* ------- create httpServer.------------------------------
*/


if (cluster.isMaster) {
  num_cpu = require('os').cpus().length;
  workerID = 0;
  while (workerID < num_cpu) {
    new_worker_env = {};
    new_worker_env["WORKER_NAME"] = "worker" + workerID;
    new_worker_env["WORKER_PORT"] = AppConfig.port + workerID;
    new_worker_env["WORKER_STATE"] = false;
    worker = cluster.fork(new_worker_env);
    workerID++;
  }
} else {
  server = http.createServer(app);
  server.listen(process.env["WORKER_PORT"], function() {
    var database, database_root, timer_id;

    console.log("Master Server listening on " + process.env["WORKER_PORT"]);
    database_root = "" + __dirname + "/routes/database";
    database = require(database_root)();
    return timer_id = setTimeout(function() {
      var controller_root;

      controller_root = "" + __dirname + "/routes/controller";
      return console.log("" + (require(controller_root)({
        app: app,
        database: database
      })));
    }, 100);
  });
}

/* ------- Error. -----------------------------------------
*/


process.on('uncaughtException', function(err) {
  console.log("err >  " + err);
  return console.error("uncaughtException >  " + err.stack);
});
