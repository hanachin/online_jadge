exports.setup = (app, http, sio, SessionConfig) ->
  socketServer = http.createServer(app)
  exports.socketio = sio.listen(socketServer, {'log level' : 2})
  socketServer.listen(8080)

  exports.socketio.configure () ->
    exports.socketio.set 'authorization', (handshakeData, callback) ->
     if (!handshakeData.headers.cookie)
        return callback('not found Cookie', false)

      cookie = handshakeData.headers.cookie
      cookies = cookie.split(';')
      for c in cookies
        parse = c.split('=')
        cookies[parse[0]] = parse[1]

      # handshakeData に保存
      handshakeData.sessionID = cookies[' connect.sid'].split('.')[0].substring(2)

      console.log "handshakeDATA"
      console.log handshakeData.sessionID

      return callback(null, true)

  return "socket_server setup."
