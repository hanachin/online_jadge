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
  app.get '/check_judge', (req, res, next) ->
    checkJudge = require './check_judge'
    checkJudge.main(req, res)

  app.get '/request_judge', (req, res, next) ->
    jadge = require './judge_source'
    jadge.main(req, res, dataBase)

  # ready msg ----------------------
  return "controller is setup"

