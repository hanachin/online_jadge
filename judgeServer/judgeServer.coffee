 ## ------- Module dependencies. --------------------------- ###
express = require 'express'
cluster = require 'cluster'
http = require 'http'

app = express()

### ------- Class ------------------------------------------ ###
class AppConfig
  # 一時ファイルの保存ディレクトリ
  _tmpdir = "#{__dirname}/tmp"
  # ファイル名に拡張子を残すか
  _keepExtention = true
  @port   = 3001
  @public = "#{__dirname}/public"

class LogConfig
  @log      = "#{__dirname}/logs/"
  @filename = "#{@log}/pxp_log"
  @size   = 1024 * 1024
  @format = '-yyyy-MM-dd'
  # stdoutへの出力を取得
  @stdout = false
  @nolog  = ['\\.js']
  @format = JSON.stringify {
      'method'     : ':method'
      'request'    : ':url'
      'status'     : ':status'
      'user-agent' : ':user-agent'
    }

### ------- middleware call. ------------------------------- ###
app.configure ->
  # log ファイル 関係
  logger = log4js.getLogger 'file'
  log4js.configure(
    # ログファイルの出力先
    appenders: [
      {'type' : 'console'}
      {
        'type'       : 'file'
        'filename'   : LogConfig.filename
        'maxLogSize' : LogConfig.size
        'pattern'    : LogConfig.format
        'category'   : 'console'
      }
    ]
    # stdoutへの出力を取得
    replaceConsole : LogConfig.stdout
  )
  app.use log4js.connectLogger logger,
    nolog  : LogConfig.nolog
    format : LogConfig.format

  app.use express.methodOverride()
  app.use express.static AppConfig.public
  console.log "configure opption"

### ------- create httpServer.------------------------------ ###
if (cluster.isMaster)
  num_cpu = require('os').cpus().length
  workerID = 0
  while (workerID < num_cpu)
    new_worker_env = {}
    new_worker_env["WORKER_NAME"] = "worker#{workerID}"
    new_worker_env["WORKER_PORT"] = AppConfig.port + workerID
    new_worker_env["WORKER_STATE"] = false
    worker = cluster.fork(new_worker_env)
    workerID++
else
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

### ------- Error. ----------------------------------------- ###
# nodeがERRによって落ちないようにする
process.on 'uncaughtException', (err) ->
  console.log "err >  #{err}"
  console.error "uncaughtException >  #{err.stack}"

