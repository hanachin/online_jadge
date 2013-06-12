module.exports = (option) ->
  # -------------------------------
  # server instance
  # -------------------------------
  app = option.app
  database = option.dataBase

  # ------------------------------
  # EventHandler
  # ------------------------------

  # ------------------------------
  # rooting
  # ------------------------------
  app.get '/check_jadge', (req, res, next) ->
    checkJadge = require './check_jadge'
    checkJadge.main(req, res)

  app.get '/request_jadge', (req, res, next) ->
    jadge = require './jadge_source'
    jadge.main(req, res, dataBase)

  # ready msg ----------------------
  return "controller is setup"

