# main root -----------
exports.main = (req, res, database) ->
  # module ------------
  async = require 'async'
  # module end --------

  # tmp --------------
  ip_address = req.ip
  time = 300
  # tmp end ----------

  # instance ---------
  req.ranking = req.ranking
  req.resJSON = req.resJSON
  # instance end -----

  async.series([
    (callback) ->
      get_submits(req, database)
      setTimeout(() ->
        callback(null, 1)
      , time)
    (callback) ->
      response(req, res)
      setTimeout(() ->
        callback(null, 2)
      , time)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "get_ranking all done. #{result}"
  )

  console.log "get_ranking ---------- #{ip_address}"
# main root end --------

# get_submits ----------
# 送信された問題の履歴（status）を作成する
get_submits = (req, database) ->
  database.Submit_table.findAll({order:"time DESC", limit: 100}).success((calum) ->
    if (calum?)
      i = 0
      len = calum.length
      while (i < len)
        req.ranking[i] = {
          volumeNo: calum[i].num
          username: calum[i].register
          result: calum[i].jadge
          time: calum[i].time
        }
        i++
  )
# get_submits end -----

# response ------------
# json形式にして、レスポンスを返す
response = (req, res) ->
  res.json req.ranking
# response end -------

