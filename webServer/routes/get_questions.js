// Generated by CoffeeScript 1.6.2
var createJSON, getCorrecters, getQuestions, getUserCorrect, sendJSON;

exports.main = function(req, res, dataBase) {
  var async, correcterTable, gradeNo, ip_address, lessonNo, questionTable, seq, submitTable, username;

  async = require('async');
  username = req.session.username;
  gradeNo = req.query.gradeNo;
  lessonNo = req.query.lessonNo;
  ip_address = req.ip;
  req.argQuestions = [];
  req.argCorrecters = [];
  req.argStatus = [];
  req.argResJSON = [];
  seq = dataBase.seq;
  questionTable = dataBase.questionTable;
  submitTable = dataBase.submitTable;
  correcterTable = dataBase.correcterTable;
  async.series([
    function(callBack) {
      return getQuestions(req, gradeNo, lessonNo, questionTable, callBack);
    }, function(callBack) {
      var argQuestions;

      argQuestions = req.argQuestions;
      return getCorrecters(req, username, argQuestions, seq, callBack, 0);
    }, function(callBack) {
      var argQuestions;

      argQuestions = req.argQuestions;
      return getUserCorrect(req, username, argQuestions, submitTable, callBack, 0);
    }, function(callBack) {
      return createJSON(req, callBack);
    }, function(callBack) {
      return sendJSON(req, res, callBack);
    }
  ], function(err, result) {
    if (err) {
      throw err;
      res.redirect('/');
    }
    return console.log("getQuestions all done. " + result);
  });
  return console.log("getQuestions ---------- " + ip_address);
};

getQuestions = function(req, gradeNo, lessonNo, questionTable, callBack) {
  return questionTable.findAll({
    where: {
      gradeNo: gradeNo,
      lessonNo: lessonNo
    }
  }).success(function(columns) {
    var column, i, _i, _len;

    if ((columns[0] != null)) {
      for (i = _i = 0, _len = columns.length; _i < _len; i = ++_i) {
        column = columns[i];
        req.argQuestions[i] = column.questionNo;
      }
    }
    return callBack(null, 1);
  }).error(function(err) {
    return console.log("select QuestionTable Err >> " + err);
  });
};

getCorrecters = function(req, username, argQuestions, seq, callBack, num) {
  var cmd;

  if (num > argQuestions.length - 1) {
    callBack(null, 2);
    return;
  }
  cmd = "SELECT DISTINCT userID FROM Submit_table WHERE questionNo='" + argQuestions[num] + "' and result='Accept'";
  return seq.query(cmd, null, {
    raw: true
  }).success(function(columns) {
    if ((columns != null)) {
      req.argCorrecters[num] = columns.length;
    } else {
      req.argCorrecters[num] = 0;
    }
    return getCorrecters(req, username, argQuestions, seq, callBack, num + 1);
  }).error(function(err) {
    return console.log("select CorrecterTable Err >> " + err);
  });
};

getUserCorrect = function(req, username, argQuestions, submitTable, callBack, num) {
  if (num > argQuestions.length - 1) {
    callBack(null, 3);
    return;
  }
  return submitTable.find({
    where: {
      userID: username,
      questionNo: argQuestions[num],
      result: 'Accept'
    }
  }).success(function(columns) {
    if ((columns != null)) {
      req.argStatus[num] = "AC";
    } else {
      req.argStatus[num] = "WA";
    }
    return getUserCorrect(req, username, argQuestions, submitTable, callBack, num + 1);
  }).error(function(err) {
    return console.log("select CorrecterTable Err >> " + err);
  });
};

createJSON = function(req, callBack) {
  var i, _i, _ref;

  for (i = _i = 0, _ref = req.argQuestions.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
    req.argResJSON[i] = {
      questionNo: req.argQuestions[i],
      correcters: req.argCorrecters[i],
      state: req.argStatus[i]
    };
  }
  return callBack(null, 4);
};

sendJSON = function(req, res, callBack) {
  res.json(req.argResJSON);
  return callBack(null, 5);
};
