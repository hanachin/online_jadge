exports.setup = (app, http, sio, SessionConfig, mongoose) ->
  socketServer = http.createServer(app)
  exports.socketio = sio.listen(socketServer, {'log level' : 2})
  socketServer.listen(8080)

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

      # Socketがconnectionを貼った時に、sessionにアクセスできるようにする
      mongoose = require 'mongoose'
      mongoose.connect 'mongodb://localhost/lab_sessions'
      Schema = mongoose.Schema
      readScheme = new Schema(
        _id     : String
        data    : Object
        expires : Date
        sid     : String
      )
      Sessions = mongoose.model 'sessions', readScheme
      Sessions.findOne {sid : sessionID}, (err, data) ->
        handshakeData.sessionID = data.data.username
        return callback(null, true)

     ###
      {
        "_id" : ObjectId("51dfec73417c950fa24248eb"),
        "data" : {
          "cookie" : {
            "path" : "/",
            "_expires" : ISODate("2013-07-13T12:18:31.298Z"),
            "originalMaxAge" : 86381801,
            "httpOnly" : false,
            "expires" : ISODate("2013-07-13T12:18:31.298Z"),
            "maxAge" : 86381800,
            "data" : {
              "originalMaxAge" : 86381801,
              "expires" : ISODate("2013-07-13T12:18:31.298Z"),
              "secure" : null,
              "httpOnly" : false,
              "domain" : null,
              "path" : "/"
            }
          },
          "username" : "081320",
          "loginflag" : true
        },
        "expires" : ISODate("2013-07-13T12:18:31.298Z"),
        "sid" : "TzonPfFD09eBV/SosCbNRUKu"
      }
      ###
  return "socket_server setup."
