module.exports = (option) ->
  # -------------------------------
  # server instance
  # -------------------------------
  app = option.app
  dataBase = option.database

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
  app.get('/', loginCheck, (req, res, next) ->
    username = req.session.username
    res.render 'select', {
      username: username
    }
  )

  app.post('/select', (req, res, next) ->
    postLogininfo = require './login'
    postLogininfo.main(req, res, dataBase)
  )

  app.get('/destroy', (req, res, next) ->
    destroy = require './destroy'
    destroy.main(req, res)
  )
  # union root end --------------

  # students root ---------------
  app.get('/select', loginCheck, (req, res, next) ->
    res.render 'select', {
      username: "#{req.session.username}"
    }
  )

  app.get('/get_questions', (req, res, next) ->
    getQuestions = require './get_questions'
    getQuestions.main(req, res, dataBase)
  )

  app.get('/coding', loginCheck, (req, res, next) ->
    getCodingpage = require './coding'
    getCodingpage.main(req, res, dataBase)
  )

  app.post '/submit_source', (req, res, next) ->
    submitSource = require './submit_source'
    submitSource.main(req, res, dataBase)

  app.get('/ranking', loginCheck, (req, res, next) ->
    if (req.query.questionNo?)
      questionNo = req.query.questionNo
    res.render 'ranking', {
      username: "#{req.session.username}"
    }
  )

  app.get('/get_ranking', (req, res, next) ->
    getRanking = require './get_ranking'
    getRanking.main(req, res, dataBase)
  )

  app.get('/mypage', (req, res, next) ->
    mypage = require './mypage'
    mypage.main(req, res, dataBase)
  )

  app.get('/get_corrects', (req, res, next) ->
    correct_questions = require './get_corrects'
    correct_questions.main(req, res, dataBase)
  )

  app.get('/get_status', (req, res, next) ->
    status_questions = require './get_status'
    status_questions.main(req, res, dataBase)
  )

  app.post('/codeview', (req, res, next) ->
    codeview = require './codeview'
    codeview.main(req, res, dataBase)
  )
  # students root end -----------

  # teachers root ---------------
  app.get('/management_console', (req, res, next) ->
    management_console = require './management_console'
    management_console.main(req, res, dataBase)
  )

  app.get('database_page', (req, res, next) ->
    database_page = require './show_database'
    database_page.main(req, res, dataBase)
  )

  app.get('/show_table', (req, res, next) ->
    show_table = require './show_table'
    show_table.main(req, res, dataBase)
  )

  app.get('/delete_data', (req, res, next) ->
    delete_data = require './delete_data'
    delete_data.main(req, res, dataBase)
  )

  app.get('/upload_page', loginCheck, (req, res, next) ->
    username = req.session.username
    res.render 'upload', {
      username: username
    }
  )

  app.post('/upload_questions', (req, res, next) ->
    uploadQuestions = require './upload_questions'
    uploadQuestions.main(req, res, dataBase)
  )

  app.get('/upload_students', (req, res, next) ->
    upload_students = require './upload_students'
    upload_students.main(req, res, dataBase)
  )

  app.get('/result_page', (req, res, next) ->
    result_page = require './result_page'
    result_page.main(req, res, dataBase)
  )

  app.get('/show_result', (req, res, next) ->
      show_result = require './show_result'
      show_result.main(req, res, dataBase)
  )
  # teachers root end -------------

  # ready msg ----------------------
  return "controller is setup"

