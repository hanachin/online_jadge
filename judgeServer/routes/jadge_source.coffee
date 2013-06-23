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

  req.username   = ""
  req.questionNo = ""
  req.source     = ""
  req.dir        = ""
  req.dir_path   = ""
  req.queueID    = ""
  req.argTestcase   = []
  req.argStdout     = []
  req.argAnswer     = []
  req.compile_error = ""
  req.stderr     = ""
  req.result     = ""

  # time -----------
  req.startTime = getTimestamp()
  req.endTime = ""
  # time -----------

  async.series([
    (callBack) ->
      process.env["WORKER_STATE"] = true
    (callBack) ->
      getQueueContents(req, seq, submitQueueTable, callBack)
    (callBack) ->
      replaceSource(req, req.source, callBack)
    (callBack) ->
      makeDir(req.dir_path, fs.mkdir, callBack)
    (callBack) ->
      writeSource(req.questionNo, req.source, req.dir_path, fs.writeFile, callBack)
    (callBack) ->
      writeTestcase(req, req.questionNo, req.dir_path, answerTable, fs.writeFileSync, callBack)
    (callBack) ->
      compileSource(req, req.questionNo, req.dir_path, child_process.exec, callBack)
    (callBack) ->
      executeSource(req, req.questionNo, req.dir_path, child_process.exec, callBack)
   (callBack) ->
      compareSource(req, callBack)
    (callBack) ->
      req.endTime = getTimestamp()
      saveResult(req, req.questionNo, req.username, req.source, submitTable, correcterTable, callBack)
    (callBack) ->
      removeDir(req.questionNo, req.dir_path, child_process.exec, callBack)
    (callBack) ->
      removeQueue(req.queueID, submitQueueTable, callBack)
    (callBack) ->
      sendMsg(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      removeQueue(seq, submitQueueTable)
      res.send(500, err)
    process.env["WORKER_STATE"] = false
    console.log "#{req.ip} -> submit all done. #{result}"
  )
# main root end --------
# getSubmitQueue ---------
getQueueContents = (req, seq, submitQueueTable, callBack) ->
  lock_cmd = '''
    UPDATE SubmitQueue_table SET id=LAST_INSERT_ID(id),
    locked_until=NOW() + INTERVAL 5 SECOND
    WHERE locked_until < NOW() ORDER BY id LIMIT 1;
  '''
  find_cmd = 'SELECT LAST_INSERT_ID();'

  seq.query(lock_cmd).success () ->
    seq.query(find_cmd).success (id) ->
      submitQueueTable.find({where: {id: id[0]['LAST_INSERT_ID()']}}).success (columns) ->
        req.queuID     = columns.id
        req.username   = columns.userID
        req.questionNo = columns.questionNo
        req.source     = columns.source
        req.dir        = "#{req.socket._idleStart}-#{req.username}"
        req.dir_path   = "#{__dirname}/../public/source/#{req.dir}"
        callBack(null, 1)
  .error (error) ->
    console.log "submit SubmitQueue_table err > #{error}"

# getSubmitQueue ---------
# replaceSource ----------
# 文字の置換（今のところは改行コードのみ
replaceSource = (req, source, callBack) ->
  #  キャリッジリターンの削除
  req.source = source.replace(/\r\n/g, '\n')
  callBack(null, 2)
# replace_cr end ------
# makeDir -------------
# 作業用ディレクトリの作成
makeDir = (path, mkdir, callBack) ->
  mkdir(path, '0777', (err) ->
    if (err)
      console.log "#{path} make_dir err -> #{err}"
      return
    console.log "mkdir -> #{path}"
    callBack(null, 3)
  )
# makeDir end ----------
# writeSource --------
# プログラムを書き出す
writeSource = (questionNo, source, path, fswrite, callBack) ->
  fswrite("#{path}/#{questionNo}.c", source, (err) ->
    if (err)
      console.log "#{path} fswrite error -> #{err}"
      return
    console.log "fswrite -> #{path}"
    callBack(null, 4)
  )
# writeSource end -----
# writeTestcase -----
# テストケースの書き出し
writeTestcase = (req, questionNo, path, answerTable, fswrite, callBack) ->
  answerTable.findAll({where: {questionNo: questionNo}, order: 'id'}).success (columns) ->
    if (columns[0]?)
      i   = 0
      len = columns.length
      while (i < len)
        testcase_path = "#{path}/#{questionNo}#{i}.txt"
        fswrite(testcase_path, columns[i].testcase)
        req.argTestcase[i]  = "#{questionNo}#{i}.txt"
        req.argAnswer[i]    = columns[i].answer
        console.log "fswrite_test -> #{path}"
        i++
    callBack(null, 5)
# write_testcase end ---
# compile_source -----
# プログラムのコンパイル
compileSource = (req, questionNo, path, exec, callBack) ->
  exec("gcc -Wall -o #{path}/#{questionNo}.out #{path}/#{questionNo}.c", (error, stdout, stderr) ->
  # stdoutもerrorもほとんど同じ error -> command failedが出るとか
    if (error)
      req.result = 'Compile Error'
      error = new String(error)
      tmp   = new RegExp(req.dir_path, 'g')
      req.compile_error = error.replace(tmp, '')
      console.log "Compile Error -> #{error}"
    console.log "#{path} -> compile!"
    callBack(null, 6)
  )
# compile_source end ----------
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
# execute_source end ---------
# noinput_execute ------------
# 入力のないプログラムの実行
noinputExecute = (req, questionNo, path, exec, callBack, num) ->
  exePath = "#{path}/#{questionNo}.out"
  exec(exePath, {timeout: 3000, maxBuffer: 65536}, (error, stdout, stderr) ->
      if (error)
        error = new String(error)
        tmp   = new RegExp(req.dir_path, 'g')
        req.stderr = error.replace(tmp, '')
        req.result = executeError(num, error)
        callBack(null, 7)
        return
    req.argStdout[num] = stdout.replace(/\r\n$/, '')
    callBack(null, 7)
  )
# noinput_execute end ------
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
  exec(cmd, {timeout: 3000, maxBuffer: 65536}, (error, stdout, stderr) ->
    if (error)
      error = new String(error)
      tmp   = new RegExp(req.dir_path, 'g')
      req.stderr = error.replace(tmp, '')
      req.result = executeError(num, error)
      callBack(null, 7)
      return

    req.argStdout[num] = stdout.replace(/\r?\n$/, '')
    inputExecute(req, questionNo, path, exec, callBack, num + 1)
  )
# input_execute end ------
# error_signal -----------------------
# プログラムの実行結果から、エラーコードを割り振る
executeError = (num, error) ->
  signal = error.toString()
  if (0 < signal.indexOf('maxBuffer'))
    return 'Segmentation Fault'

  if (0 < signal.indexOf('Command'))
    return 'Time Limit Exceeded'

  return "不明なエラーです"
# error_signal end ------------------
# compareSource ---------------------
# 実行結果の比較
compareSource = (req, callBack) ->
  stdout = req.argStdout
  answer = req.argAnswer
  result = req.result

  console.log stdout
  console.log answer

  if (result isnt '')
    console.log "#{req.ip} result error : #{result}"
  else
    i = 0
    len = answer.length
    while (i < len)
      if (stdout[i] isnt answer[i])
        kondo_check = kondoMethod(stdout[i], answer[i])
        console.log "kondo_check: #{kondo_check}"
        if (kondo_check is true)
          req.result = "Accept"
        else
          req.result = "Wrong Answer"
          break
      else
        req.result = "Accept"
      i++
  callBack(null, 8)
# get_correct end ---------
# saveResult ------------
# データベースへプログラムを格納
saveResult = (req, questionNo, username, source, submitTable, correcterTable, callBack) ->
  time = getTimestamp()
  insert_obj = {
    userID      : username
    questionNo  : questionNo
    source      : source
    time        : time
    result      : req.result
  }
  saveData = submitTable.build(insert_obj)
  saveData.save().success () ->
    console.log('DB save success')
    callBack(null, 9)
# saveResult end ---------
# getTimestamp -----------
# 年月日・曜日・時分秒の取得
getTimestamp = () ->
  d     = new Date()
  year  = d.getFullYear()
  month = d.getMonth() + 1
  day   = d.getDate()
  hour  = d.getHours()
  minute = d.getMinutes()
  second = d.getSeconds()

  # 1桁を2桁に変換する
  month = '0' + month if (month < 10)
  day   = '0' + day if (day < 10)
  hour  = '0' + hour if (hour < 10)
  minute = '0' + minute if (minute < 10)
  second = '0' + second if (second < 10)
  time   = "#{year}-#{month}-#{day} #{hour}:#{minute}:#{second}"
  return time
# getTimestamp end ---------
# remove_dir --------------
# 作業ファイルの削除
removeDir = (questionNo, path, exec, callBack) ->
  cmd = "rm -rf #{path}/"
  exec(cmd, {}, (error, stdout, stderr) ->
    if (error)
      console.log "rm error -> #{error}"
  )
  callBack(null, 10)
# remove_dir end ----------
# removeQueue -------------
# キューの削除
removeQueue = (queueID, submitQueueTable, callBack) ->
  submitQueueTable.find({where: {id: queueID}}).success (columns) ->
    # LAST_INSERT_IDは最も最近に実行された INSERT 文の結果としてAUTO_INCREMENT
    # カラムに正常に インサートされたカラムのIDを取得するが
    # 正常にインサートされた値が無いとき、0を返す
    # 確実な解決策：ALTER TABLE <テーブル名> AUTO_INCREMENT = 1;
    if (columns?)
      columns.destroy()
      console.log 'delete SubmitQueue_table ------'
    callBack(null, 11)
  .error (error) ->
    console.log "submit SubmitQueue_table err > #{error}"
# removeQueue --------------
# send_message -------------
# 結果の送信
sendMsg = (req, res, callBack) ->
 # 結果を送信した時間の表示
  startTime = req.startTime
  endTime = getTimestamp()
  console.log "#{req.ip} -> start:#{startTime} - #{endTime}"

  obj = {
    cmperr : req.compile_error
    stderr : req.stderr
    result : req.result
  }
  res.send('200', obj)
  callBack(null, 12)
# send_message end --------

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
  translation = string.replace(/[！-～]/g, (str) ->
    return String.fromCharCode(str.charCodeAt(0) - 0xFEE0)
  )
  return translation
# replaceFullsizeChar ----
# toUpper ----------------
toUpper = (string) ->
  # 小文字 -> 大文字に変換
  translation = string.toUpperCase()
  return translation
# toUpper ----------------
# replaceEqualsign -------
replaceEqualsign = (string) ->
  translation = string.replace(/:/g, '=')
  return translation
# replaceEqualsign -------
# skipTable --------------
skipTable = (string) ->
  # スキップテーブル (空白を削除)
  translation = string.replace(/[ ]+/g, '')
  return translation
# skipTable --------------
# pulloutDecimal ---------
pulloutNumber = (string) ->
  # プログラムの解答から小数を抜き出す
  # 数値が少ない場合は自動的に小数第二位まで0詰め
  i = 0
  len = string.length
  number = ''
  while (i < len)
    if ('0' <= string[i] <= '9')
      number += string[i]
    if (string[i] is '.')
      decimal1 = string[i + 1] ? '0'
      decimal2 = string[i + 2] ? '0'
      number += decimal1 + decimal2
      break
    i++
  return number
# pulloutDecimal ---------
