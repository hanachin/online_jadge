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
      # checkJadgeServer(req, callBack, 0)
      callBack(null, 2)
    (callBack) ->
      requestJadgeServer(req, http.get, callBack)
    (callBack) ->
      resJadgeResult(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "requestJadgeServer all done. #{result}"
  )
  console.log "requestJadgeServer ---------- #{ip_address}"
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
## checkJadgeServer -------
###
httpリクエスト投げすぎるとsocket hung up ?というエラーが起きるのでひとまずコメントアウト
checkJadgeServer = (req, reqHttp, callBack, jadgeServerID) ->
  # チェックした結果すべてのジャッジサーバが作業中の場合、１秒待ったあとに再度この関数を実行する
  cpu_num = require('os').cpus().length
  if (jadgeServerID > 3001 + cpu_num - 1)
    setTimeout(checkJadgeServer, 1000, req, reqHttp, callBack, 0)
    return

  # リクエスト先の設定
  options = {
    hostname : 'localhost'
    port     : "#{3001 + jadgeServerID}"
    path     : '/check_jadge'
  }

  # httpリクエストを送信する
  # checkの結果 -> true：callBack関数を実行し、実際にジャッジを頼むリクエストを発行する
  #             -> false：他のジャッジサーバが空いていないかチェックする
  requestCheck = reqHttp(options,  (res) ->
    console.log "StatusCode : #{res.statusCode}"
    res.on('data', (check_result) ->
      console.log "JadgeServer #{jadgeServerID} check Response:  #{res}"
      if (check_result is true)
        req.jadgeServerID = jadgeServerID
        callBack(null, 2)
        return
      else
        checkJadgeServer(req, reqHttp, callBack, jadgeServerID + 1)
    )
  ).on('error', (error) ->
    console.log "check err #{error}"
  )
###
# end checkJadgeServer -----
# requestJadgeServer -------
# jadgeServerの管理Table true -> 使用中 false -> 未使用
# 今借りているサクラのサーバだと2つまでしか立ち上げられない
serverTable = [false, false]
requestJadgeServer = (req, reqHttp, callBack) ->
  # 未使用のjadgeServerを見つけて、リクエストを送信する
  # 全てのJadgeServerが使用済みだった場合、1秒後にこの関数を呼び出す
  i = 0
  while (i < serverTable.length)
    if (serverTable[i] is false)
      serverTable[i] = true
      # リクエスト先の設定
      options = {
        hostname : 'localhost'
        port     : 3001 + i
        path     : '/request_jadge'
      }
      # httpリクエストを送信する
      # ここで？たまに502エラーが起こっている模様（確認できていない
      # ジャッジサーバからのレスポンス：jsonオブジェクトを受け取る
      requestJadge = reqHttp(options,  (res) ->
        serverTable[i] = false
        console.log "request Server #{3001 + i}"
        console.log "StatusCode : #{res.statusCode}"
        res.setEncoding('utf8')
        res.on('data', (jadge_result) ->
          console.log "JadgeServer Response:  #{jadge_result}"
          req.result = jadge_result
          callBack(null, 2)
          return
        ).on('error', (error) ->
          console.log "problem with request : #{error}"
        )
      )
      return
    i++
  setTimeout(requestJadgeServer, 1000, req, reqHttp, callBack)
# end requestJadgeServer -----
# resJadgeResult -------------
resJadgeResult = (req, res, callBack) ->
  res.json req.result
  callBack(null, 3)
# resJadgeResult end ---------
