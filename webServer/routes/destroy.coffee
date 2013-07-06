# ---- main --------------------------------------------------
exports.main = (req, res) ->
  async = require 'async'

  async.series([
    (callBack) ->
      destroySession(req, callBack)
    (callBack) ->
      getNextPage(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "destroy all done. #{result}"
  )
# ---- end main ----------------------------------------------

# ---- login -------------------------------------------------
destroySession = (req, callBack) ->
  req.session.destroy()
  callBack(null, 1)
# ---- end login ----------------------------------------------

# ---- rooting ------------------------------------------------
getNextPage = (req, res, callBack) ->
  res.redirect '/'
  callBack(null, 2)
# ---- rooting end --------------------------------------------
