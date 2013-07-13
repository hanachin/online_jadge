# main root -----------
exports.main = (data, socket, sio, dataBase) ->
  # module ------------
  async = require 'async'
  http  = require 'http'

  # user info -------------
  username = socket.handshake.sessionID
  questionNo = data.questionNo
  source     = data.source
  data.judgeServerID = ''
  data.resultJSON = ''

  # database -------------
  submitQueueTable = dataBase.submitQueueTable

  async.series([
    (callBack) ->
      checkJudgeServer(data, callBack)
    (callBack) ->
      requestJudgeServer(data, username, http.get, callBack)
    (callBack) ->
      resJudgeResult(data, sio, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "requestJudgeServer all done. #{result}"
  )

# checkJudgeServer ---------
# judgeServerの管理Table true -> 使用中 false -> 未使用
# 今借りているサクラのサーバだと2つまでしか立ち上げられない
# judgeServerの管理テーブルみたいなものを作りたい
judgeServerTable = [false, false]
checkJudgeServer = (data, callBack) ->
  # 空いているジャッジサーバを探索していく
  for _, judgeID in judgeServerTable
    if (judgeServerTable[judgeID] is false)
      judgeServerTable[judgeID] = true
      data.judgeServerID = judgeID
      callBack(null, 1)
      return

# requestJudgeServer -------
requestJudgeServer = (data, username, reqHttp, callBack) ->
  # ポート番号の指定
  req_port = 3001 + data.judgeServerID
  # リクエスト先の設定
  options = {
    hostname : 'localhost'
    port     : req_port
    path     : "/request_judge?username=#{username}&questionNo=#{data.questionNo}&source=#{data.source}"
  }

  # httpリクエストを送信する
  # ジャッジサーバからのレスポンス：jsonオブジェクトを受け取る
  requestJudge = reqHttp options,  (res) ->
    console.log "request Server #{req_port}"
    console.log "StatusCode : #{res.statusCode}"
    res.setEncoding('utf8')
    res.on 'data', (result) ->
      console.log "JudgeServer Response:  #{result}"
      data.result = result
      # 使用していたjudgeServerを解放
      judgeServerTable[data.judgeServerID] = false
      callBack(null, 2)
      return
    .on 'error', (err) ->
      console.log "problem with request : #{err}"

# resJudgeResult -------------
resJudgeResult = (data, sio, callBack) ->
  sio.sockets.emit 'result_judge', data.result
  callBack(null, 3)

