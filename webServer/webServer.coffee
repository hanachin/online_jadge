### ------- Module dependencies. --------------------------- ###
express = require 'express'
cluster = require 'cluster'
app = express()
### ------- Module dependencies. --------------------------- ###

### ------- middleware call. ------------------------------- ###
app.configure ->
  app.set 'port', 3000
  app.set 'views', "#{__dirname}/views"
  # template enngine
  engine = require 'ejs-locals'
  app.engine 'ejs', engine
  app.set 'view engine', 'ejs'
  app.use express.favicon()
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
  # 応答データの圧縮
  app.use express.compress(
    level: 4
    # memLevel: 4
    # chunkSize: 16 * 1024
    # windowsBits: 31
    # strategy: 0
    # filter: function(req, res){/* */}
  )
  # upload 先の設置
  # bodyParser -> エラーが無ければ以下の3つを順に実行していく
  # content-type='apllication/json'->middleware/json.jsを使い.req.bodyにJSON.parse()の結果を付与
  # content-type='application/x-www-form-urlencoded'->req.bodyにテキストの一般的なWebFormの入力値を付与
  # content-type='multipart/form-data'->middleware/multipart.jsを使いreq.body, req.files に結果が付与
  bodyParserOptions = {
    uploadDir: "#{__dirname}/tmp"
    isKeepExtensions: true
  }
  app.use express.bodyParser(bodyParserOptions)
  # session 管理 関係
  sessionstore = require('session-mongoose')(express)
  store = new sessionstore(
    url: "mongodb://localhost/lab_session"
    interval: 60 * 60 * 1000 * 24 # expiration check worker run interval in millisec (default: 60000)
  )
  app.use express.cookieParser('pxp_ss')
  app.use express.session(
    # cookie にはいっている sessionId の値が、自分のサーバで設定されたものであることを保証している
    secret: 'pxp_ss'
    store: store
    cookie: {
      # trueにするとJavascriptなどからアクセスできなくなる
      httpOnly: true,
      # 60 * 60 * 1000 = 3600000 msec = 1 hour (設定しないとブラウザを終了したときにsessionも切れる
      maxAge: new Date(Date.now() + 60 * 60 * 1000 * 24)
    }
  )
  app.use express.methodOverride()
  app.use express.static("#{__dirname}/public")
  console.log "configure opption"
### ------- middleware call. ------------------------------- ###

### ------- create httpServer.------------------------------ ###
if (cluster.isMaster)
  http = require 'http'
  server = http.createServer(app)

  # server listen
  server.listen app.get('port'), ->
    console.log "Master Server listening on #{app.get('port')}"

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
### ------- Error. ---------- ------------------------------ ###

