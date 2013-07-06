module.exports = (option) ->
  # -------------------------------
  # server instance
  # -------------------------------
  app = option.app
  dataBase = option.database

  # ------------------------------
  # EventHandler
  # ------------------------------

  # ------------------------------
  # rooting
  # ------------------------------
  app.get '/', (req, res, next) ->
    console.log 'test ------'
    res.send 'test'

  app.get '/request_judge', (req, res, next) ->
    judge = require './judge_source'
    judge.main(req, res, dataBase)

  # ready msg ----------------------
  return "controller is setup"

