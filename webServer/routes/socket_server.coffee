exports.setup = (app, http, sio) ->
  socketServer = http.createServer(app)
  exports.socketio = sio.listen(socketServer, {'log level' : 2})
  socketServer.listen(8080)

  exports.socketio.configure () ->
    exports.socketio.set 'authorization', (handshakeData, callback) ->
      # クッキーの名前をキーとして 配列に追加する
      cookie = handshakeData.headers.cookie
      cookies = cookie.split(';')
      for c in cookies
        parse = c.split('=')
        cookies[parse[0]] = parse[1]

      if (!handshakeData.headers.cookie)
        return callback('not found Cookie', false)

      # handshakeData に保存
      handshakeData.sessionID = cookies['connect.sid']
      return callback(null, true)

  return "socket_server setup."

