# main root -----------
exports.main = (req, res, dataBase) ->
  # module ------------
  async = require 'async'
  # module end --------

  # user info ---------
  ip_address = req.ip
  # user info --------

  req.ranking = []

  # database --------
  submitTable = dataBase.submitTable
  # database --------

  async.series([
    (callBack) ->
      getSubmits(req, submitTable, callBack)
    (callBack) ->
      sendRanking(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "get_ranking all done. #{result}"
  )
  console.log "get_ranking ---------- #{ip_address}"
# main root end --------
# getSubmits -----------
# 送信された問題の履歴を作成する
getSubmits = (req, submitTable, callBack) ->
  submitTable.findAll({order: "time DESC", limit: 100}).success (columns) ->
    if (columns?)
      i = 0
      len = columns.length
      while (i < len)
        req.ranking[i] = {
          questionNo  : columns[i].questionNo
          userID      : columns[i].userID
          result      : columns[i].result
          time        : columns[i].time
        }
        i++
    callBack(null, 1)
  .error (error) ->
    console.log "submitTable err > #{error}"
# get_submits end ------
# sendRanking ----------
# json形式にして、レスポンスを返す
sendRanking = (req, res, callBack) ->
  res.json req.ranking
  callBack(null, 2)
# sendRanking end -----
