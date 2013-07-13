exports.setup = (app, http, sio, SessionConfig, mongoose) ->
  socketServer = http.createServer(app)
  exports.socketio = sio.listen(socketServer, {'log level' : 2})
  socketServer.listen(8080)

  # 接続はサービスをセットアップするときのみ行う（接続が重複する
  mongoose = require 'mongoose'
  mongoose.connect 'mongodb://localhost/lab_sessions'

  # mongoDBのコレクションを定義
  Schema = mongoose.Schema
  readScheme = new Schema(
    _id     : String
    data    : Object
    expires : Date
    sid     : String
  )
  # 接続
  Sessions = mongoose.model 'sessions', readScheme

  # socket.ioの初期化処理
  exports.socketio.configure () ->
    exports.socketio.set 'authorization', (handshakeData, callback) ->
      if (!handshakeData.headers.cookie)
        return callback('not found Cookie', false)

      # handshakeDataからcookieデータを抽出
      cookie = handshakeData.headers.cookie
      cookie = cookie.replace(/\s+/g, '')
      cookies = cookie.split(';')

      # cookieをパース
      for c in cookies
        parse = c.split('=')
        cookies[parse[0]] = parse[1]

      # connect.sidが署名された状態なので、それを取り外している。
      parse = cookies['connect.sid'].replace(/s%3A/, '')
      index = parse.indexOf('.')
      sessionID = parse.substr(0, index)
      sessionID = decodeURIComponent(sessionID)

      # find
      Sessions.findOne {sid : sessionID}, (err, data) ->
        handshakeData.sessionID = data.data.username
        return callback(null, true)

  return "socket_server setup."
