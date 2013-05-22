# ---- main --------------------------------------------------
exports.main = (req, res, database) ->
  async = require 'async'
  username = req.body.username
  password = req.body.password
  userTable = database.userTable
  ip_address = req.ip

  async.series([
    (callBack) ->
      variableCheck(res, username, password, callBack)
    (callBack) ->
      userCheck(req, res, username, password, userTable, callBack)
    (callBack) ->
      getNextpage(req, res, callBack)
  ], (err, result) ->
    if (err)
      throw err
      res.redirect('/')
    console.log "login all done. #{result}"
  )

  console.log "login ---------- #{ip_address}"
# ---- end main ----------------------------------------------
#
# ---- variableChek ------------------------------------------
variableCheck = (res, username, password, callBack) ->
  # usernameとpasswordをちゃんと入力しているか確認する
  # 存在演算子だとnullとundefinedしか確認できない
  if (username isnt '' and password isnt '')
    # 次のasyncへジャンプする
    callBack(null, 1)
  else
    # usernameかpasswordが入力されていなかったときの処理
    res.redirect('/')
# ---- variableChek ------------------------------------------
# ---- userChek ----------------------------------------------
userCheck = (req, res, username, password, userTable, callBack) ->
  # User_tableからusernameで探索
  # パスワードが一致するか調べる
  userTable.find(
    where: {
      userID: username
    }
  ).success (columns) ->
    # usernameが見つかったらcolumnsがnullになる
    if (columns? and password is columns.password)
      req.session.username = username
      req.session.loginflag = true
      # 次のasyncへジャンプする
      callBack(null, 2)
    else
      # passwordを間違えていたときの処理
      res.redirect('/')
  .error (err) ->
    console.log "login User_table err >> #{err}"
    res.redirect('/')
# ---- userChek ----------------------------------------------
# ---- getNextpage -------------------------------------------
getNextpage = (req, res, callBack) ->
  if (req.session.loginflag)
    res.redirect '/select'
  else
    res.redirect('/')
  # 次のasyncへジャンプする
  callBack(null, 3)
# ---- getNextpage -------------------------------------------
