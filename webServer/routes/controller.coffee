module.exports = (option) ->
  # -------------------------------
  # server instance
  # -------------------------------
  app = option.app
  dataBase = option.database
  sioIndex = require './socket_server'
  sio = sioIndex.socketio

  # ------------------------------
  # EventHandler
  # ------------------------------
  # loginCheck
  loginCheck =  (req, res, next) ->
    console.log req.session
    if (req.session.loginflag)
      next()
    else
      res.render 'login'

  # ------------------------------
  # rooting
  # ------------------------------
  # union root -------------------
  app.get '/', loginCheck, (req, res, next) ->
    username = req.session.username
    res.render 'select', {
      username: username
    }

  app.post '/select', (req, res, next) ->
    postLogininfo = require './login'
    postLogininfo.main(req, res, dataBase)

  app.get '/destroy', (req, res, next) ->
    destroy = require './destroy'
    destroy.main(req, res)
  # union root end --------------

  # students root ---------------
  app.get '/select', loginCheck, (req, res, next) ->
    res.render 'select', {
      username: "#{req.session.username}"
    }

  app.get '/get_questions', (req, res, next) ->
    getQuestions = require './get_questions'
    getQuestions.main(req, res, dataBase)

  app.get '/coding', loginCheck, (req, res, next) ->
    getCodingpage = require './coding'
    getCodingpage.main(req, res, dataBase)

  # socket.io -------------------
  sio.sockets.on 'connection', (socket) ->
    console.log "test -----"
    console.log socket.handshake
    socket.on 'submit_source', (data) ->
      submitSource = require './submit_source'
      submitSource.main(data, socket, sio, dataBase)

  # ready msg ----------------------
  return "controller is setup"

