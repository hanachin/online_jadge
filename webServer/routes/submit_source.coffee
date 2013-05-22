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
# requestJadgeServer ------
requestJadgeServer = (req, reqHttp, callBack) ->
  options = {
    hostname : 'localhost'
    port     : '3001'
    path     : '/request_jadge'
  }

  requestJadge = reqHttp(options,  (res) ->
    console.log "StatusCode : #{res.statusCode}"
    res.setEncoding('utf8')
    res.on('data', (jadge_result) ->
      console.log "JadgeServer Response:  #{jadge_result}"
      req.result = jadge_result
      callBack(null, 2)
    ).on('error', (err) ->
      console.log "problem with request : #{err.message}"
      req.error = err
    )
  )
# end requestJadgeServer -----
# resJadgeResult -------------
resJadgeResult = (req, res, callBack) ->
  res.json req.result
  callBack(null, 3)
# resJadgeResult end ---------
