# main root -------------
exports.main = (req, res, dataBase) ->
  async = require 'async'

  # user info --------
  username      = req.session.username
  gradeNo       = req.query.gradeNo
  lessonNo      = req.query.lessonNo
  ip_address    = req.ip
  # end user info ----

  # instance ---------
  req.argQuestions  = []
  req.argCorrecters = []
  req.argStatus     = []
  req.argResJSON    = []
  # instance ---------

  # database ---------
  seq = dataBase.seq
  questionTable = dataBase.questionTable
  submitTable = dataBase.submitTable
  correcterTable = dataBase.correcterTable
  # database ---------

  ## submitTable -> CorrecterTableに変更するかもしれない
  async.series([
    (callBack) ->
      getQuestions(req, gradeNo, lessonNo, questionTable, callBack)
    (callBack) ->
      # 各問題の正解者を取得する
      argQuestions = req.argQuestions
      getCorrecters(req, username, argQuestions, seq, callBack, 0)
    (callBack) ->
      # 正解したことがあるかの取得
      argQuestions = req.argQuestions
      getUserCorrect(req, username, argQuestions, submitTable, callBack, 0)
    (callBack) ->
      # JSONデータを作成する
      createJSON(req, callBack)
    (callBack) ->
      # JSONデータを返信する
      sendJSON(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "getQuestions all done. #{result}"
  )
  console.log "getQuestions ---------- #{ip_address}"
# main root end ----------
# get_questions ----------
# 問題リストの取得
getQuestions = (req, gradeNo, lessonNo, questionTable, callBack) ->
  questionTable.findAll(where: {gradeNo: gradeNo, lessonNo: lessonNo}).success (columns) ->
   if (columns[0]?)
      i = 0
      len = columns.length
      while (i < len)
        req.argQuestions[i] = columns[i].questionNo
        i++
    callBack(null, 1)
  .error (err) ->
    console.log "select QuestionTable Err >> #{err}"
# get_questions end -------
# getCorrecters -----------
# 同じ学年の正解者リストの取得
getCorrecters = (req, username, argQuestions, seq, callBack, num) ->
  if (num > argQuestions.length - 1)
    callBack(null, 2)
    return

  cmd = "SELECT DISTINCT userID FROM Submit_table WHERE questionNo='#{argQuestions[num]}' and result='Accept'"
  seq.query(cmd, null, {raw: true}).success (columns) ->
    if (columns?)
      req.argCorrecters[num] = columns.length
      console.log req.argCorrecters[num]
    else
      req.argCorrecters[num] = 0
    getCorrecters(req, username, argQuestions, seq, callBack, num + 1)
  .error (err) ->
    console.log "select CorrecterTable Err >> #{err}"
# getCorrecters end -------
# getUserSubmit -----------
# 問題に正解したかことがあるかどうかの取得
getUserCorrect = (req, username, argQuestions, submitTable, callBack, num) ->
  if (num > argQuestions.length - 1)
    callBack(null, 3)
    return

  submitTable.find(where: {userID: username, questionNo: argQuestions[num], result: 'Accept'}).success (columns) ->
    if (columns?)
      req.argStatus[num] = "AC"
    else
      req.argStatus[num] = "WA"
    getUserCorrect(req, username, argQuestions, submitTable, callBack, num + 1)
  .error (err) ->
    console.log "select CorrecterTable Err >> #{err}"
# getUserSubmit end ------
# createJSON -------------
# jsonの作成
createJSON = (req, callBack) ->
  i = 0
  len = req.argQuestions.length
  while (i < len)
    req.argResJSON[i] = {
      questionNo: req.argQuestions[i]
      correcters: req.argCorrecters[i]
      state: req.argStatus[i]
    }
    i++
  callBack(null, 4)
# createJSON end --------
# response --------------
# jsonの返信
sendJSON = (req, res, callBack) ->
  res.json req.argResJSON
  callBack(null, 5)
# response end ----------
