# ---- main --------------------------------------------------
exports.main = (req, res, dataBase) ->
  async   = require 'async'
  fs      = require 'fs'
  cheerio = require 'cheerio'

  # user info ------------
  # 複数のファイルをアップロードする場合は、こいつを回してあげればいい.
  tmp_path = req.files.uploads[0].path
  target_path = "#{__dirname}/../public/uploaded/Question/#{req.files.uploads[0].name}"
  filename = req.files.uploads[0].name
  ip_address = req.ip
  # user info end -------
  # database ------------
  questionTable = dataBase.questionTable
  exampleTable  = dataBase.exampleTable
  answerTable   = dataBase.answerTable
  # database end --------

  req.gradeNo     = ""
  req.lsssonNo    = ""
  req.explanation = ""
  req.questionNo  = ""
  req.input_ex    = []
  req.output_ex   = []
  req.testcase    = []
  req.answer      = []

  async.series([
    (callBack) ->
      mvTmpfile(tmp_path, target_path, fs.rename, callBack)
    (callBack) ->
      xmlParse(req, target_path, fs.readFile, cheerio, callBack)
    (callBack) ->
      questionSave(req, questionTable, callBack)
    (callBack) ->
      exampleSave(req, exampleTable, callBack, 0)
    (callBack) ->
      answerSave(req, answerTable, callBack, 0)
    (callBack) ->
      sendMsg(res, filename, callBack)
  ], (err, results) ->
    if (err)
      throw err
      obj = {
        test: "test"
        files: [{
          filename: filename
          error: true
        }]
      }
      res.json obj
    console.log('questionUpload all done. ' + results)
  )
  console.log "questionUpload ---------- #{ip_address}"
# ---- end main ----------------------------------------------
# ---- mvTmpfile ---------------------------------------------
mvTmpfile = (tmp_path, target_path, fsRename, callBack) ->
  # ファイルリクエストは一時ファイル扱いとして、tmpに適当な名前をつけてあるので
  # target_pathへコピーし、名前を変更する
  fsRename(tmp_path, target_path, (err) ->
    if (err)
      throw err
      console.log "fileupload mv err"
    console.log "tmpFilerename done."
    callBack(null, 1)
  )
# ---- mvTmpfile ---------------------------------------------
# ---- xmlParse ----------------------------------------------
xmlParse = (req, target_path, readFile, cheerio, callBack) ->
  readFile(target_path, 'utf8', (err, read_data) ->
    # ファイルをパースするための準備を行う
    $ = cheerio.load(read_data, {
      ignoreWhitespace: true
      xmlMode: true
    })
    # データをパースして、reqオブジェクトに格納する
    tmp             = $("grade_no").text().replace(/[ ]+/g, '')
    req.gradeNo     = tmp.replace(/^\n/, '')
    tmp             = $("lesson_no").text().replace(/[ ]+/g, '')
    req.lessonNo    = tmp.replace(/^\n/, '')
    tmp             = $("explanation").text().replace(/[ ]+/g, '')
    req.explanation = tmp.replace(/^\n/, '')
    tmp             = $("question_no").text().replace(/[ ]+/g, '')
    req.questionNo  = tmp.replace(/^\n/g, '')
    $('input_ex').each (i, elem) ->
      tmp = $(this).text().replace(/[ ]+/g, '')
      req.input_ex[i] = tmp.replace(/^\n/, '')
    $('output_ex').each (i, elem) ->
      tmp = $(this).text().replace(/[ ]+/g, '')
      req.output_ex[i] = tmp.replace(/^\n/, '')
    $('input').each (i, elem) ->
      tmp = $(this).text().replace(/[ ]+/g, '')
      req.testcase[i] = tmp.replace(/^\n/, '')
    $('output').each (i, elem) ->
      tmp = $(this).text().replace(/[ ]+/g, '')
      req.answer[i] = tmp.replace(/^\n/, '')
    callBack(null, 2)
  )
# ---- xmlParse ----------------------------------------------
# ---- questionSave ------------------------------------------
questionSave = (req, questionTable, callBack) ->
  insert_obj = {
    questionNo : req.questionNo
    gradeNo    : req.gradeNo
    lessonNo   : req.lessonNo
    explanation: req.explanation
  }
  saveData = questionTable.build(insert_obj)

  saveData.save().success () ->
    console.log('questionTable save success')
    callBack(null, 3)
  .error (error) ->
    console.log("questionTable Save Error")
# ---- questionSave ------------------------------------------
# ---- exampleSave -------------------------------------------
exampleSave = (req, exampleTable, callBack, num) ->
  if (req.input_ex.length - 1 < num)
    callBack(null, 4)
    return

  insert_obj = {
    questionNo:  req.questionNo
    input_ex  :  req.input_ex[num]
    output_ex :  req.output_ex[num]
  }
  saveData = exampleTable.build(insert_obj)

  saveData.save().success () ->
    console.log('exampleTable save success')
    exampleSave(req, exampleTable, callBack, num + 1)
  .error (error) ->
    console.log("exampleTable Save Error >> #{error}")
# ---- exampleSave -------------------------------------------
# ---- answerSave --------------------------------------------
answerSave = (req, answerTable, callBack, num) ->
  if (req.answer.length - 1 < num)
    callBack(null, 5)
    return

  insert_obj = {
    questionNo:  req.questionNo
    answer    :  req.answer[num]
    testcase  :  req.testcase[num]
  }
  saveData = answerTable.build(insert_obj)

  saveData.save().success () ->
    console.log('answerTable save success')
    answerSave(req, answerTable, callBack, num + 1)
  .error (error) ->
    console.log("answerTable Save Error")
# ---- answerSave --------------------------------------------
# ---- getNextpage -------------------------------------------
sendMsg = (res, filename, callBack) ->
  obj = {
    test: "test"
    files: [{
      filename: filename
      error: false
    }]
  }
  res.json obj
  callBack(null, 6)
# ---- getNextpage -------------------------------------------
