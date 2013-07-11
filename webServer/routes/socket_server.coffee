exports.setup = (app, http, sio, SessionConfig, express) ->
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

      # こんなものないって言われる
      ###
      Socketがconnectionを貼った時に、sessionにアクセスできるようにする
      sessionStore.get sessionID, (err, session) ->
        if (err)
          return callback(err.message, false)
        handshakeData.session =  session
      ###

      return callback(null, true)

  return "socket_server setup."
