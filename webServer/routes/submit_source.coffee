# main root -----------
exports.main = (req, res, dataBase) ->
  # module ------------
  async = require 'async'
  http  = require 'http'
  # module end --------

  # user info -------------
  username = req.session.username
  questionNo = req.body.questionNo
  source = req.body.source
  ip_address = req.ip
  # user info end --------

  # database -------------
  submitQueueTable = dataBase.submitQueueTable
  # database end ---------

  async.series([
    (callBack) ->
      insertQueue(username, questionNo, source, submitQueueTable, callBack)
    (callBack) ->
      # checkJudgeServer(req, callBack, 0)
      callBack(null, 2)
    (callBack) ->
      requestJudgeServer(req, http.get, callBack)
    (callBack) ->
      resJudgeResult(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "requestJudgeServer all done. #{result}"
  )
  console.log "requestJudgeServer ---------- #{ip_address}"
# main root end --------
# insertQueue -------------
insertQueue = (username, questionNo, source, submitQueueTable, callBack) ->
  insert_obj = {
    userID       :  username
    questionNo   :  questionNo
    source       :  source
  }
  saveData = submitQueueTable.build(insert_obj)

  saveData.save().success () ->
    console.log('submitQueueTable save success')
    callBack(null, 1)
  .error (error) ->
    console.log("submitQueueTable save Error >> #{error}")
# insertQueue end ---------
## checkJudgeServer -------
###
httpリクエスト投げすぎるとsocket hung up ?というエラーが起きるのでひとまずコメントアウト
checkJudgeServer = (req, reqHttp, callBack, judgeServerID) ->
  # チェックした結果すべてのジャッジサーバが作業中の場合、１秒待ったあとに再度この関数を実行する
  cpu_num = require('os').cpus().length
  if (judgeServerID > 3001 + cpu_num - 1)
    setTimeout(checkJudgeServer, 1000, req, reqHttp, callBack, 0)
    return

  # リクエスト先の設定
  options = {
    hostname : 'localhost'
    port     : "#{3001 + judgeServerID}"
    path     : '/check_judge'
  }

  # httpリクエストを送信する
  # checkの結果 -> true：callBack関数を実行し、実際にジャッジを頼むリクエストを発行する
  #             -> false：他のジャッジサーバが空いていないかチェックする
  requestCheck = reqHttp(options,  (res) ->
    console.log "StatusCode : #{res.statusCode}"
    res.on('data', (check_result) ->
      console.log "JudgeServer #{judgeServerID} check Response:  #{res}"
      if (check_result is true)
        req.judgeServerID = judgeServerID
        callBack(null, 2)
        return
      else
        checkJudgeServer(req, reqHttp, callBack, judgeServerID + 1)
    )
  ).on('error', (error) ->
    console.log "check err #{error}"
  )
###
# end checkJudgeServer -----
# requestJudgeServer -------
# judgeServerの管理Table true -> 使用中 false -> 未使用
# 今借りているサクラのサーバだと2つまでしか立ち上げられない
serverTable = [false, false]
requestJudgeServer = (req, reqHttp, callBack) ->
  # 未使用のjudgeServerを見つけて、リクエストを送信する
  # 全てのJudgeServerが使用済みだった場合、1秒後にこの関数を呼び出す
  for _, i in serverTable
    if (serverTable[i] is false)
      serverTable[i] = true
      # リクエスト先の設定
      options = {
        hostname : 'localhost'
        port     : 3001 + i
        path     : '/request_judge'
      }
      # httpリクエストを送信する
      # ここで？たまに502エラーが起こっている模様（確認できていない
      # ジャッジサーバからのレスポンス：jsonオブジェクトを受け取る
      requestJudge = reqHttp(options,  (res) ->
        serverTable[i] = false
        console.log "request Server #{3001 + i}"
        console.log "StatusCode : #{res.statusCode}"
        res.setEncoding('utf8')
        res.on('data', (judge_result) ->
          console.log "JudgeServer Response:  #{judge_result}"
          req.result = judge_result
          callBack(null, 2)
          return
        ).on('error', (error) ->
          console.log "problem with request : #{error}"
        )
      )
      return
  setTimeout(requestJudgeServer, 1000, req, reqHttp, callBack)
# end requestJudgeServer -----
# resJudgeResult -------------
resJudgeResult = (req, res, callBack) ->
  res.json req.result
  callBack(null, 3)
# resJudgeResult end ---------
