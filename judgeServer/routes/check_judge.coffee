# main root -----------
exports.main = (req, res) ->

  req.check_result = ''

  async.series([
    (callBack) ->
      serverProcessCheck(req, callBack)
    (callBack) ->
      sendMsg(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
    console.log "#{req.ip} -> submit all done. #{result}"
  )
# main root end --------
# server check ---------
serverprocesscheck = (req, callback) ->
  req.check_result = process.env["worker_state"]
  callback(null, 1)
# server check end -----
# sendMsg ---------
sendMsg = (req, res, callback) ->
  res.send req.check_result
  callBack(null, 2)
# server check end -----
#


