module.exports = (option) ->
  # -------------------------------
  # server instance
  # -------------------------------
  app = option.app
  database = option.database

  # ------------------------------
  # EventHandler
  # ------------------------------

  # ------------------------------
  # rooting
  # ------------------------------
  app.get '/request_jadge', (req, res, next) ->
    jadge = require './jadge_source'
    jadge.main(req, res, database)

  # ready msg ----------------------
  return "controller is setup"

