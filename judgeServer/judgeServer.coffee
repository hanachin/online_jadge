 ## ------- Module dependencies. --------------------------- ###
express = require 'express'
cluster = require 'cluster'
log4js  = require 'crafity-log4js'
http = require 'http'

app = express()

### ------- Class ------------------------------------------ ###
node_config = require '../node-config.json'
config = require "../config"
AppConfig = new config.AppConfig(3001, __dirname)
LogConfig = new config.LogConfig(__dirname)

### ------- middleware call. ------------------------------- ###
app.configure ->
  # log -----------------------
  logger = log4js.getLogger 'file'
  log4js.configure(
    # ログファイルの出力先
    appenders: [
      {'type' : 'console'}
      {
        'type'       : 'file'
        'filename'   : LogConfig.getName()
        'maxLogSize' : LogConfig.getSize()
        'pattern'    : LogConfig.getPattern()
        'category'   : 'console'
      }
    ]
    # stdoutへの出力を取得
    replaceConsole : LogConfig.getStdout()
  )
  app.use log4js.connectLogger logger,
    nolog  : LogConfig.getNolog()
    format : LogConfig.format()

  app.use express.methodOverride()
  app.use express.static AppConfig.getPublic()
  console.log "configure opption"

### ------- create httpServer.------------------------------ ###
if (cluster.isMaster)
  num_cpu = require('os').cpus().length
  workerID = 0
  while (workerID < num_cpu)
    new_worker_env = {}
    new_worker_env["WORKER_NAME"] = "worker#{workerID}"
    new_worker_env["WORKER_PORT"] = AppConfig.getPort() + workerID
    new_worker_env["WORKER_STATE"] = false
    worker = cluster.fork(new_worker_env)
    workerID++
else
  server = http.createServer(app)
  # server listen
  server.listen process.env["WORKER_PORT"], ->
    console.log "Master Server listening on #{process.env["WORKER_PORT"]}"

    # database setup
    database_root = "../db/database"
    database = require(database_root)(config : node_config)

    # rooting start
    # databaseを設定した後にcontrollerのsetup
    # controllerの設定をした後にsocket_moduleのsetup
    timer_id = setTimeout(
      ->
        controller_root = "#{__dirname}/routes/controller"
        console.log "#{require(controller_root)(app: app, database: database)}"
      100
    )

### ------- Error. ----------------------------------------- ###
# nodeがERRによって落ちないようにする
process.on 'uncaughtException', (err) ->
  console.log "err >  #{err}"
  console.error "uncaughtException >  #{err.stack}"

