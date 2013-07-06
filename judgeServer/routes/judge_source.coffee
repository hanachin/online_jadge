class DateFormat
  _digits = (digits, n) ->
    if "#{n}".length >= digits
      "#{n}"
    else
      pad = digits - "#{n}".length
      "#{(new Array(pad + 1)).join("0")}#{n}"

  constructor : () ->
    @date = new Date()

  toString : () ->
    year  = @date.getFullYear()
    month = _digits 2, @date.getMonth() + 1
    d  = _digits 2, @date.getDate()
    hour  = _digits 2, @date.getHours()
    min   = _digits 2, @date.getMinutes()
    sec   = _digits 2, @date.getSeconds()
    "#{year}/#{month}/#{d} #{hour}:#{min}:#{sec}"

  @format: () ->
    "#{new DateFormat}"

# main root -----------
exports.main = (req, res, dataBase) ->
  # module ------------
  fs            = require 'fs'
  child_process = require 'child_process'
  async         = require 'async'
  # module end --------

  # database ---------
  seq              = dataBase.seq
  submitTable      = dataBase.submitTable
  answerTable      = dataBase.answerTable
  testcaseTable    = dataBase.testcaseTable
  correcterTable   = dataBase.correcterTable
  submitQueueTable = dataBase.submitQueueTable
  # database --------

  req.username      = req.query.username
  req.questionNo    = req.query.questionNo
  req.source        = req.query.source
  req.argTestcase   = []
  req.argStdout     = []
  req.argAnswer     = []
  req.compile_error = ""
  req.stderr     = ""
  req.result     = ""
  req.dir        = "#{req.socket._idleStart}-#{req.username}"
  req.dir_path   = "#{__dirname}/../public/source/#{req.dir}"

  async.series([
    (callBack) ->
      console.log "user 1st ---------------------------------------"
      console.log "replaceSource - #{DateFormat.format()}"
      console.log "workerID -> #{process.env["WORKER_PORT"]}"
      replaceSource(req, req.source, callBack)
    (callBack) ->
      console.log "makeDir - #{DateFormat.format()}"
      makeDir(req.dir_path, fs.mkdir, callBack)
    (callBack) ->
      console.log "writeSource - #{DateFormat.format()}"
      writeSource(req.questionNo, req.source, req.dir_path, fs.writeFile, callBack)
    (callBack) ->
      console.log "writeTestcase - #{DateFormat.format()}"
      writeTestcase(req, req.questionNo, req.dir_path, answerTable, fs.writeFileSync, callBack)
    (callBack) ->
      console.log "compileSource - #{DateFormat.format()}"
      compileSource(req, req.questionNo, req.dir_path, child_process.exec, callBack)
    (callBack) ->
      console.log "executeSource - #{DateFormat.format()}"
      executeSource(req, req.questionNo, req.dir_path, child_process.exec, callBack)
    (callBack) ->
      console.log "compareSource - #{DateFormat.format()}"
      compareSource(req, callBack)
    (callBack) ->
      console.log "saveResult - #{DateFormat.format()}"
      saveResult(req, req.questionNo, req.username, req.source, submitTable, correcterTable, callBack)
    (callBack) ->
      console.log "removeDir - #{DateFormat.format()}"
      removeDir(req.questionNo, req.dir_path, child_process.exec, callBack)
    (callBack) ->
      console.log "sendMsg - #{DateFormat.format()}"
      sendMsg(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.send(500, err)
    process.env["WORKER_STATE"] = false
    console.log "request end - #{DateFormat.format()}"
    console.log "end user 1st ---------------------------------------"
  )
# main root end --------
# replaceSource ----------
# 文字の置換（今のところは改行コードのみ
replaceSource = (req, source, callBack) ->
  #  キャリッジリターンの削除
  req.source = source.replace(/\r\n/g, '\n')
  callBack(null, 2)

# makeDir -------------
# 作業用ディレクトリの作成
makeDir = (path, mkdir, callBack) ->
  mkdir path, '0777', (err) ->
    if (err)
      console.log "#{path} make_dir err -> #{err}"
      return
    #console.log "mkdir -> #{path}"
    callBack(null, 3)

# writeSource --------
# プログラムを書き出す
writeSource = (questionNo, source, path, fswrite, callBack) ->
  fswrite "#{path}/#{questionNo}.c", source, (err) ->
    if (err)
      console.log "#{path} fswrite error -> #{err}"
      return
    #console.log "fswrite -> #{path}"
    callBack(null, 4)

# writeTestcase -----
# テストケースの書き出し
writeTestcase = (req, questionNo, path, answerTable, fswrite, callBack) ->
  answerTable.findAll(
    where : {
      questionNo : questionNo
    }
    order : 'id'
  ).success (columns) ->
    if (columns[0]?)
      for column, i in columns
        if (column.testcase isnt '')
          testcase_path = "#{path}/#{questionNo}#{i}.txt"
          req.argTestcase[i]  = "#{questionNo}#{i}.txt"
          fswrite(testcase_path, column.testcase)
        req.argAnswer[i]    = column.answer
        #console.log "fswrite_test -> #{path}"
    callBack(null, 5)

# compile_source -----
# プログラムのコンパイル
compileSource = (req, questionNo, path, exec, callBack) ->
  exec "gcc -Wall -o #{path}/#{questionNo}.out #{path}/#{questionNo}.c", (err, stdout, stderr) ->
  # stdoutもerrorもほとんど同じ error -> command failedが出るとか
    if (err)
      req.result = 'Compile Error'
      err = new String(err)
      tmp = new RegExp(req.dir_path, 'g')
      req.compile_error = err.replace(tmp, '')
      console.log "Compile Error -> #{err}"
      #console.log "#{path} -> compile!"
    callBack(null, 6)

# execute_source --------------
# プログラムの実行をさせる
executeSource = (req, questionNo, path, exec, callBack) ->
  if (req.result isnt '')
    callBack(null, 7)
    return
  if (0 < req.argTestcase.length)
    inputExecute(req, questionNo, path, exec, callBack, 0)
    return
  noinputExecute(req, questionNo, path, exec, callBack, 0)

# noinput_execute ------------
# 入力のないプログラムの実行
noinputExecute = (req, questionNo, path, exec, callBack, num) ->
  exePath = "#{path}/#{questionNo}.out"
  exec exePath, {
    timeout: 3000
    maxBuffer: 65536
  }, (err, stdout, stderr) ->
    if (err)
      err = new String(err)
      tmp   = new RegExp(req.dir_path, 'g')
      req.stderr = err.replace(tmp, '')
      req.result = executeError(num, err)
      callBack(null, 7)
      return

    req.argStdout[num] = stdout.replace(/\r\n$/, '')
    callBack(null, 7)

# input_execute ------------
# 入力のあるプログラムの実行
inputExecute = (req, questionNo, path, exec, callBack, num) ->
  if (num >= req.argTestcase.length)
    callBack(null, 7)
    return

  exePath   = "#{path}/#{questionNo}.out"
  testPath  = "#{path}/#{req.argTestcase[num]}"
  cmd       = "#{exePath} < #{testPath}"

  # maxBuffer:default -> 200 * 1024
  # timeout:default ->  0
  # killSignal: default -> 'SIGTERM'
  exec cmd, {
    timeout: 3000
    maxBuffer: 65536
  }, (err, stdout, stderr) ->
    if (err)
      err = new String(err)
      tmp   = new RegExp(req.dir_path, 'g')
      req.stderr = err.replace(tmp, '')
      req.result = executeError(num, err)
      callBack(null, 7)
      return

    req.argStdout[num] = stdout.replace(/\r?\n$/, '')
    inputExecute(req, questionNo, path, exec, callBack, num + 1)

# error_signal -----------------------
# プログラムの実行結果から、エラーコードを割り振る
executeError = (num, err) ->
  signal = err.toString()
  if (0 < signal.indexOf('maxBuffer'))
    return 'Segmentation Fault'

  if (0 < signal.indexOf('Command'))
    return 'Time Limit Exceeded'

  return "不明なエラーです"

# compareSource ---------------------
# 実行結果の比較
compareSource = (req, callBack) ->
  stdouts = req.argStdout
  answers = req.argAnswer
  result = req.result

  console.log "実行結果 + 解答"
  console.log stdouts
  console.log answers

  if (result isnt '')
    console.log "#{req.ip} result err : #{result}"
  else
    for answer, i in answers
      if (stdout[i] isnt answer)
        kondo_check = kondoMethod(stdout[i], answer)
        console.log "kondo_check: #{kondo_check}"
        if (kondo_check is true)
          req.result = "Accept"
        else
          req.result = "Wrong Answer"
          break
      else
        req.result = "Accept"
  callBack(null, 8)

# saveResult ------------
# データベースへプログラムを格納
saveResult = (req, questionNo, username, source, submitTable, correcterTable, callBack) ->
  insert_obj = {
    userID      : username
    questionNo  : questionNo
    source      : source
    time        : DateFormat.format()
    result      : req.result
  }
  saveData = submitTable.build(insert_obj)
  saveData.save().success () ->
    console.log 'DB save success'
    callBack(null, 9)

# remove_dir --------------
# 作業ファイルの削除
removeDir = (questionNo, path, exec, callBack) ->
  cmd = "rm -rf #{path}/"
  exec(cmd, {}, (err, stdout, stderr) ->
    if (err)
      console.log "rm error -> #{err}"
  )
  callBack(null, 10)

# send_message -------------
# 結果の送信
sendMsg = (req, res, callBack) ->
  obj = {
    cmperr : req.compile_error
    stderr : req.stderr
    result : req.result
  }
  res.send('200', obj)
  callBack(null, 12)

# kondoMethod -------------
kondoMethod = (stdout, answer) ->
  stdout = replaceFullsizeChar(stdout)
  answer = replaceFullsizeChar(answer)
  if (stdout is answer)
    return true
  stdout = toUpper(stdout)
  answer = toUpper(answer)
  if (stdout is answer)
    return true
  stdout = replaceEqualsign(stdout)
  if (stdout is answer)
    return true
  stdout = skipTable(stdout)
  if (stdout is answer)
    return true
  stdout = pulloutNumber(stdout)
  answer = pulloutNumber(answer)
  if (stdout is '' or answer is '')
    return false
  if (stdout is answer)
    return true
  return false
# kondoMethod end --------
# replaceFullsizeChar ----
replaceFullsizeChar = (string) ->
  # 全角文字 -> 半角文字
  translation = string.replace /[！-～]/g, (str) ->
    return String.fromCharCode(str.charCodeAt(0) - 0xFEE0)

# toUpper ----------------
toUpper = (string) ->
  # 小文字 -> 大文字に変換
  translation = string.toUpperCase()

# replaceEqualsign -------
replaceEqualsign = (string) ->
  translation = string.replace(/:/g, '=')

# skipTable --------------
skipTable = (string) ->
  # スキップテーブル (空白を削除)
  translation = string.replace(/[ ]+/g, '')

# pulloutDecimal ---------
pulloutNumber = (string) ->
  # プログラムの解答から小数を抜き出す
  # 数値が少ない場合は自動的に小数第二位まで0詰め
  number = ''
  for c, i in string
    if ('0' <= c <= '9')
      number += c
    if (c is '.')
      decimal1 = string[i + 1] ? '0'
      decimal2 = string[i + 2] ? '0'
      number += decimal1 + decimal2
      break
  return number
# pulloutDecimal ---------
