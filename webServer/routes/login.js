// Generated by CoffeeScript 1.6.2
var getNextpage, userCheck, variableCheck;

exports.main = function(req, res, database) {
  var async, ip_address, password, userTable, username;

  async = require('async');
  username = req.body.username;
  password = req.body.password;
  userTable = database.userTable;
  ip_address = req.ip;
  async.series([
    function(callBack) {
      return variableCheck(res, username, password, callBack);
    }, function(callBack) {
      return userCheck(req, res, username, password, userTable, callBack);
    }, function(callBack) {
      return getNextpage(req, res, callBack);
    }
  ], function(err, result) {
    if (err) {
      throw err;
      res.redirect('/');
    }
    return console.log("login all done. " + result);
  });
  return console.log("login ---------- " + ip_address);
};

variableCheck = function(res, username, password, callBack) {
  if (username !== '' && password !== '') {
    return callBack(null, 1);
  } else {
    return res.redirect('/');
  }
};

userCheck = function(req, res, username, password, userTable, callBack) {
  return userTable.find({
    where: {
      userID: username
    }
  }).success(function(column) {
    if ((column != null) && password === column.password) {
      req.session.username = username;
      req.session.loginflag = true;
      return callBack(null, 2);
    } else {
      return res.redirect('/');
    }
  }).error(function(err) {
    console.log("login User_table err >> " + err);
    return res.redirect('/');
  });
};

getNextpage = function(req, res, callBack) {
  if (req.session.loginflag) {
    res.redirect('/select');
  } else {
    res.redirect('/');
  }
  return callBack(null, 3);
};
