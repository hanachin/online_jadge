### ------- Module dependencies. --------------------------- ###
express = require 'express'
cluster = require 'cluster'
app = express()
### ------- Module dependencies. --------------------------- ###

### ------- middleware call. ------------------------------- ###
app.configure ->
  app.set 'port', 3001
  # log ファイル 関係
  log4js = require 'crafity-log4js'
  logger = log4js.getLogger 'file'
  log4js.configure(
    # ログファイルの出力先
    appenders: [
      {'type': 'console'}
      {'type': 'file', 'filename': "#{__dirname}/logs/pxp_lab.log", 'maxLogSize': 1024 * 1024, 'pattern': '-yyyy-MM-dd', 'category': 'console'}
    ]
    # stdoutへの出力を取得
    replaceConsole: true
  )
  app.use log4js.connectLogger(logger,
     # アクセスログを出力する際に無視する拡張子
    nolog: [ '\\css', '\\.js', '\\.gif', '\\.jpg', '\\.png' ],
     # アクセスログのフォーマット（JSON 形式）
    format: JSON.stringify {
      'method': ':method'
      'request': ':url'
      'status': ':status'
      'user-agent': ':user-agent'
    }
  )
  app.use express.methodOverride()
  app.use express.static("#{__dirname}/public")
  console.log "configure opption"
### ------- middleware call. ------------------------------- ###

### ------- create httpServer.------------------------------ ###
if (cluster.isMaster)
  num_cpu = require('os').cpus().length
  workerID = 0
  while (workerID < num_cpu)
    new_worker_env = {}
    new_worker_env["WORKER_NAME"] = "worker#{workerID}"
    new_worker_env["WORKER_PORT"] = 3001 + workerID
    new_worker_env["WORKER_STATE"] = false
    worker = cluster.fork(new_worker_env)
    workerID++
else
  http = require 'http'
  server = http.createServer(app)
  # server listen
  server.listen process.env["WORKER_PORT"], ->
    console.log "Master Server listening on #{process.env["WORKER_PORT"]}"

    # database setup
    database_root = "#{__dirname}/routes/database"
    database = require(database_root)()

    # rooting start
    # databaseを設定した後にcontrollerのsetup
    # controllerの設定をした後にsocket_moduleのsetup
    timer_id = setTimeout(
      ->
        controller_root = "#{__dirname}/routes/controller"
        console.log "#{require(controller_root)(app: app, database: database)}"
      100
    )
### ------- create httpServer.------------------------------ ###
### ------- Error. ----------------------------------------- ###
# nodeがERRによって落ちないようにする
process.on 'uncaughtException', (err) ->
  console.log "err >  #{err}"
  console.error "uncaughtException >  #{err.stack}"
### ------- Error. ----------------------------------------- ###

