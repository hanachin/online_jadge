# ---- main --------------------------------------------------
exports.main = (req, res) ->
  async = require 'async'
  time = 100

  async.series([
    (callback) ->
      destroy_session(req)
      setTimeout(() ->
        callback(null, 1)
      , time)
    (callback) ->
      rooting(req, res)
      setTimeout(() ->
        callback(null, 2)
      , time)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect '/'
    console.log "destroy all done. #{result}"
  )
# ---- end main ----------------------------------------------

# ---- login -------------------------------------------------
destroy_session = (req) ->
  req.session.destroy()
# ---- end login ----------------------------------------------

# ---- rooting ------------------------------------------------
rooting = (req, res) ->
  res.redirect '/'
# ---- rooting end --------------------------------------------
