# ---- main --------------------------------------------------
exports.main = (req, res, dataBase) ->
  async = require 'async'

  # user info -------------------
  username   = req.session.username
  questionNo = req.query.questionNo
  ip_address = req.ip
  # user info end ---------------

  # database -------------------
  questionTable = dataBase.questionTable
  exampleTable  = dataBase.exampleTable
  # database end ---------------

  #
  req.questionNo    = ""
  req.explanation   = ""
  req.examples      = ""
  req.argInput_ex   = []
  req.argOutput_ex  = []

  # ここらへん、渡す関数全部最後にcallback取るので、部分適用ができればスッキリしそう。
  # けど、JavaScriptでやるのだるそうだし、かえって読みづらくデバッグしづらくなりそうな気もするのでそれは無しかな。
  # これcallbackを取って引数に渡すようにラップしてるのが微妙な感じするので、
  # getExplanationがcallbackの引数のみ取ればよいようにすればいいんじゃないかな。
  # 例えばreqやquestionNoを引数で引き回してるのをクラスに包むとか?
  # class Coding
  #   constructor: (@req, @res, @dataBase) ->
  #     @questionNo = @req.query.questionNo
  #     @questionTable = @dataBase.questionTable
  #
  #   getExplanation: (callback) =>
  #     questionTable.find(where: {questionNo: @questionNo}).success((columns) ->
  #       if (columns?)
  #         @req.questionNo  = columns.questionNo
  #         @req.explanation = columns.explanation
  #       callBack(null, 1)
  #     ).error((err) ->
  #       console.log "coding Question_table Err >> #{err}"
  #     )
  # こんな感じにしておけば、
  # coding = new Coding(req, res, database)
  # async.series([coding.getExplanation])
  # こんな感じで書けそうな気がします。
  # getExplanationがfat arrowなのにちゅういです。

  async.series([
    (callBack) ->
      getExplanation(req, questionNo, questionTable, callBack)
    (callBack) ->
      getExamples(req, questionNo, exampleTable, callBack)
    (callBack) ->
      createExamples(req, callBack)
    (callBack) ->
      getNextpage(req, res, username, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "coding all done. #{result}"
  )
  console.log "coding ---------- #{ip_address}"
# ---- end main ----------------------------------------------
# ---- getExplanation ----------------------------------------
getExplanation = (req, questionNo, questionTable, callBack) ->
  questionTable.find(where: {questionNo: questionNo}).success((columns) ->
    if (columns?)
      req.questionNo  = columns.questionNo
      req.explanation = columns.explanation
    callBack(null, 1)
  ).error((err) ->
    console.log "coding Question_table Err >> #{err}"
  )
# ---- getExplanation ----------------------------------------
# ---- getExamples -------------------------------------------
getExamples = (req, questionNo, exampleTable, callBack) ->
  exampleTable.findAll(where: {questionNo: questionNo}).success((columns) ->
    if (columns?)
      # whileではなくfor inを使いたい
      i   = 0
      len = columns.length
      while (i < len)
        req.argInput_ex[i]  = columns[i].input_ex.replace(/[ ]+/g, '')
        req.argOutput_ex[i] = columns[i].output_ex.replace(/[ ]+/g, '')
        i++
    callBack(null, 2)
  ).error((err) ->
    console.log "coding Example_table Err >> #{err}"
  )
# ---- getExamples --------------------------------------------
# ---- createExamples -----------------------------------------
createExamples = (req, callBack) ->
  line = '<td style="width:8%; text-align:center;"> -----> </td>'
  input_ex  = req.argInput_ex
  output_ex = req.argOutput_ex

  # whileではなくfor inを使いたい
  i = 0
  len = req.argInput_ex.length
  while (i < len)
    pre_input  = "<td style='font-size:20px; width:50%; text-align:center;'><pre style='font-size: 16px; padding: 10px; line-height:25px;'>#{input_ex[i]}</pre></td>"
    pre_output = "<td style='font-size:20px; width:50%; text-align:center;'><pre style='font-size: 16px; padding: 10px; line-height:25px;'>#{output_ex[i]}</pre></td>"
    req.examples += "<tr>#{pre_input} #{line} #{pre_output}</tr>"
    i++
  # このexamplesをtableで出す部分、テンプレート使ったらもっとすっきりいけそう?
  req.examples = "<table style='width:80%; margin:auto;'>#{req.examples}</table>"
  callBack(null, 3)
# ---- createNextpage -----------------------------------------
# ---- getNextpage --------------------------------------------
# ejs に問題名、問題文、入力例、出力例を記述
getNextpage = (req, res, username, callBack) ->
  res.render 'coding', {
    username    : username
    questionNo  : req.questionNo
    explanation : req.explanation
    example     : req.examples
  }
  callBack(null, 4)
# ---- getNextpage end ----------------------------------------
