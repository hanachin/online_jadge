### ------- Module dependencies. ------------ ###
express = require 'express'
cluster = require 'cluster'
engine  = require 'ejs-locals'
log4js  = require 'crafity-log4js'
http = require 'http'
sio  = require 'socket.io'
mongoose = require 'mongoose'
app = express()

### ------- Class --------------------------- ###
node_config = require '../node-config.json'
config = require "../config"

AppConfig = new config.AppConfig(3000, __dirname)
LogConfig = new config.LogConfig(__dirname)

class SessionConfig
  _connect = require 'connect'
  _sessionstore = require('session-mongoose')(express)
  _path = 'mongodb://localhost/lab_sessions'
  # trueにするとJavascriptなどからアクセスできなくなる
  _access = false
  # millisec (default: 60000)
  # 60 * 60 * 1000 = 3600000 msec = 1 hour (設定しないとブラウザを終了したときにsessionも切れる
  _interval = 60 * 60 * 1000 * 24
  _limit  = new Date(Date.now() + _interval)
  _secret = node_config.session.session_secret
  @getMemoryStore : () ->
    _sessionstore
  @getSecret : () ->
    _secret
  @getStore  : () ->
    new _sessionstore(
      secret   : _secret
      url      : _path
      interval : _interval
    )
  @getCookie : () ->
    {
      httpOnly  : _access
      maxAge    : _limit
    }

### ------- middleware ------------------------ ###
# expressの公式に起動の順番に注意とある
# 順番どおりに起動している
app.configure ->
  app.set 'port',  AppConfig.getPort()
  app.set 'views', AppConfig.getView()
  app.engine 'ejs', engine
  app.set 'view engine', AppConfig.getEngine()
  app.use express.favicon()

  # log -----------------------
  logger = log4js.getLogger 'file'
  log4js.configure(
    appenders : [
      {'type': 'console'}
      {
        'type'       : 'file'
        'filename'   : LogConfig.getName()
        'maxLogSize' : LogConfig.getSize()
        'pattern'    : LogConfig.getPattern()
        'category'   : 'console'
      }
    ]
    replaceConsole : LogConfig.getStdout()
  )
  app.use log4js.connectLogger logger, {
    nolog  : LogConfig.getNolog()
    format : LogConfig.format()
  }

  # 応答データの圧縮
  app.use express.compress()

  # upload 先の設置
  # 4Parser -> エラーが無ければ以下の3つを順に実行していく
  # content-type='apllication/json'->middleware/json.jsを使い.req.bodyにJSON.parse()の結果を付与
  # content-type='application/x-www-form-urlencoded'->req.bodyにテキストの一般的なWebFormの入力値を付与
  # content-type='multipart/form-data'->middleware/multipart.jsを使いreq.body, req.files に結果が付与
  # postのリクエスト処理
  app.use express.bodyParser AppConfig.upload()

  # session -------------------
  app.use express.cookieParser SessionConfig.getSecret()
  app.use express.session(
    secret : SessionConfig.getSecret()
    store  : SessionConfig.getStore()
    cookie : SessionConfig.getCookie()
  )

  app.use express.methodOverride()
  app.use express.static AppConfig.getPublic()

  console.log "app opption setup."

### ------- create httpServer.----------------- ###
if (cluster.isMaster)
  # app server listen
  server = http.createServer(app)
  # 起動順序に注意
  # database -> socketServerのsetup
  # socketServerの設定をした後にcontrollerのsetup
  server.listen app.get('port'), ->
    console.log "Master Server listening on #{app.get('port')}"
    # database setup
    database_root = "../db/database"
    database = require(database_root)(config : node_config)

    # socketio setup
    socketServer = require "#{__dirname}/routes/socket_server"
    console.log "#{socketServer.setup(app, http, sio, SessionConfig, mongoose)}"

    # controller setup
    timer_id = setTimeout(
      ->
        controller = "#{__dirname}/routes/controller"
        console.log "#{require(controller)(app : app, database : database)}"
      100
    )

### ------- Error. ----------------------------------------- ###
# nodeがERRによって突然死しないようにする
process.on 'uncaughtException', (err) ->
  console.log "err >  #{err}"
  console.error "uncaughtException >  #{err.stack}"

