### ------- Module dependencies. ------------ ###
express = require 'express'
cluster = require 'cluster'
engine  = require 'ejs-locals'
log4js  = require 'crafity-log4js'
http = require 'http'
sio  = require 'socket.io'
app = express()

### ------- Class --------------------------- ###
class AppConfig
  # 一時ファイルの保存ディレクトリ
  _tmpdir = "#{__dirname}/tmp"
  # ファイル名に拡張子を残すか
  _keepExtention = true
  @port   = 3000
  @views  = "#{__dirname}/views"
  @public = "#{__dirname}/public"
  @engine = "ejs"
  @upload = {
    uploadDir        : _tmpdir
    isKeepExtensions : _keepExtention
  }

class LogConfig
  @log      = "#{__dirname}/logs/"
  @filename = "#{@log}/pxp_log"
  @size   = 1024 * 1024
  @format = '-yyyy-MM-dd'
  # stdoutへの出力を取得
  @stdout = false
  @nolog  = [ '\\.css', '\\.js', '\\.gif', '\\.jpg', '\\.png' ]
  @format = JSON.stringify {
      'method'     : ':method'
      'request'    : ':url'
      'status'     : ':status'
      'user-agent' : ':user-agent'
    }

class SessionConfig
  _sessionstore = require('session-mongoose')(express)
  _path = 'mongodb://localhost/lab_session'
  # trueにするとJavascriptなどからアクセスできなくなる
  _access = false
  # millisec (default: 60000)
  _interval = 60 * 60 * 1000 * 24
  _limit  = new Date(Date.now() + _interval)
  @secret = 'pxp_ss'
  # 60 * 60 * 1000 = 3600000 msec = 1 hour (設定しないとブラウザを終了したときにsessionも切れる
  @store  = new _sessionstore(
    url      : _path
    interval : _interval
  )
  @cookie = {
    httpOnly  : _access
    maxAge    : _limit
  }

### ------- middleware ------------------------ ###
# expressの公式に起動の順番に注意とある
# 順番どおりに起動している
app.configure ->
  app.set 'port', AppConfig.port
  app.set 'views', AppConfig.views
  app.engine 'ejs', engine
  app.set 'view engine', AppConfig.engine
  app.use express.favicon()

  # log -----------------------
  logger = log4js.getLogger 'file'
  log4js.configure(
    appenders : [
      {'type': 'console'}
      {
        'type'       : 'file'
        'filename'   : LogConfig.filename
        'maxLogSize' : LogConfig.size
        'pattern'    : LogConfig.format
        'category'   : 'console'
      }
    ]
    replaceConsole : LogConfig.stdout
  )
  app.use log4js.connectLogger logger, {
    nolog  : LogConfig.nolog
    format : LogConfig.format
  }

  # 応答データの圧縮
  app.use express.compress()

  # upload 先の設置
  # 4Parser -> エラーが無ければ以下の3つを順に実行していく
  # content-type='apllication/json'->middleware/json.jsを使い.req.bodyにJSON.parse()の結果を付与
  # content-type='application/x-www-form-urlencoded'->req.bodyにテキストの一般的なWebFormの入力値を付与
  # content-type='multipart/form-data'->middleware/multipart.jsを使いreq.body, req.files に結果が付与
  # postのリクエスト処理
  app.use express.bodyParser AppConfig.upload

  # session -------------------
  app.use express.cookieParser SessionConfig.secret
  app.use express.session(
    secret : SessionConfig.secret
    store  : SessionConfig.store
    cookie : SessionConfig.cookie
  )
  app.use express.methodOverride()
  app.use express.static AppConfig.public
  return console.log "app opption setup."

### ------- create httpServer.----------------- ###
if (cluster.isMaster)
  server = http.createServer(app)
  # app server listen
  # 起動順序に注意
  # database -> socketServerのsetup
  # socketServerの設定をした後にcontrollerのsetup
  server.listen app.get('port'), ->
    console.log "Master Server listening on #{app.get('port')}"
    # database setup
    database_root = "#{__dirname}/routes/database"
    database = require(database_root)()

    # socketio setup
    socketServer = require "#{__dirname}/routes/socket_server"
    console.log "#{socketServer.setup(app, http, sio)}"

    # controller setup
    timer_id = setTimeout(
      ->
        controller    = "#{__dirname}/routes/controller"
        console.log "#{require(controller)(app: app, database: database)}"
      100
    )

### ------- Error. ----------------------------------------- ###
# nodeがERRによって突然死しないようにする
process.on 'uncaughtException', (err) ->
  console.log "err >  #{err}"
  console.error "uncaughtException >  #{err.stack}"

