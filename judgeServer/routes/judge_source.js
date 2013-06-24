// Generated by CoffeeScript 1.6.2
var compareSource, compileSource, executeError, executeSource, getQueueContents, getTimestamp, inputExecute, kondoMethod, makeDir, noinputExecute, pulloutNumber, removeDir, removeQueue, replaceEqualsign, replaceFullsizeChar, replaceSource, saveResult, sendMsg, skipTable, toUpper, writeSource, writeTestcase;

exports.main = function(req, res, dataBase) {
  var answerTable, async, child_process, correcterTable, fs, seq, submitQueueTable, submitTable, testcaseTable;

  fs = require('fs');
  child_process = require('child_process');
  async = require('async');
  seq = dataBase.seq;
  submitTable = dataBase.submitTable;
  answerTable = dataBase.answerTable;
  testcaseTable = dataBase.testcaseTable;
  correcterTable = dataBase.correcterTable;
  submitQueueTable = dataBase.submitQueueTable;
  req.username = "";
  req.questionNo = "";
  req.source = "";
  req.dir = "";
  req.dir_path = "";
  req.queueID = "";
  req.argTestcase = [];
  req.argStdout = [];
  req.argAnswer = [];
  req.compile_error = "";
  req.stderr = "";
  req.result = "";
  req.startTime = getTimestamp();
  req.endTime = "";
  return async.series([
    function(callBack) {
      return process.env["WORKER_STATE"] = true;
    }, function(callBack) {
      return getQueueContents(req, seq, submitQueueTable, callBack);
    }, function(callBack) {
      return replaceSource(req, req.source, callBack);
    }, function(callBack) {
      return makeDir(req.dir_path, fs.mkdir, callBack);
    }, function(callBack) {
      return writeSource(req.questionNo, req.source, req.dir_path, fs.writeFile, callBack);
    }, function(callBack) {
      return writeTestcase(req, req.questionNo, req.dir_path, answerTable, fs.writeFileSync, callBack);
    }, function(callBack) {
      return compileSource(req, req.questionNo, req.dir_path, child_process.exec, callBack);
    }, function(callBack) {
      return executeSource(req, req.questionNo, req.dir_path, child_process.exec, callBack);
    }, function(callBack) {
      return compareSource(req, callBack);
    }, function(callBack) {
      req.endTime = getTimestamp();
      return saveResult(req, req.questionNo, req.username, req.source, submitTable, correcterTable, callBack);
    }, function(callBack) {
      return removeDir(req.questionNo, req.dir_path, child_process.exec, callBack);
    }, function(callBack) {
      return removeQueue(req.queueID, submitQueueTable, callBack);
    }, function(callBack) {
      return sendMsg(req, res, callBack);
    }
  ], function(err, result) {
    if (err) {
      throw err;
      removeQueue(seq, submitQueueTable);
      res.send(500, err);
    }
    process.env["WORKER_STATE"] = false;
    return console.log("" + req.ip + " -> submit all done. " + result);
  });
};

getQueueContents = function(req, seq, submitQueueTable, callBack) {
  var find_cmd, lock_cmd;

  lock_cmd = 'UPDATE SubmitQueue_table SET id=LAST_INSERT_ID(id),\nlocked_until=NOW() + INTERVAL 5 SECOND\nWHERE locked_until < NOW() ORDER BY id LIMIT 1;';
  find_cmd = 'SELECT LAST_INSERT_ID();';
  return seq.query(lock_cmd).success(function() {
    return seq.query(find_cmd).success(function(id) {
      return submitQueueTable.find({
        where: {
          id: id[0]['LAST_INSERT_ID()']
        }
      }).success(function(columns) {
        req.queuID = columns.id;
        req.username = columns.userID;
        req.questionNo = columns.questionNo;
        req.source = columns.source;
        req.dir = "" + req.socket._idleStart + "-" + req.username;
        req.dir_path = "" + __dirname + "/../public/source/" + req.dir;
        return callBack(null, 1);
      });
    });
  }).error(function(error) {
    return console.log("submit SubmitQueue_table err > " + error);
  });
};

replaceSource = function(req, source, callBack) {
  req.source = source.replace(/\r\n/g, '\n');
  return callBack(null, 2);
};

makeDir = function(path, mkdir, callBack) {
  return mkdir(path, '0777', function(err) {
    if (err) {
      console.log("" + path + " make_dir err -> " + err);
      return;
    }
    console.log("mkdir -> " + path);
    return callBack(null, 3);
  });
};

writeSource = function(questionNo, source, path, fswrite, callBack) {
  return fswrite("" + path + "/" + questionNo + ".c", source, function(err) {
    if (err) {
      console.log("" + path + " fswrite error -> " + err);
      return;
    }
    console.log("fswrite -> " + path);
    return callBack(null, 4);
  });
};

writeTestcase = function(req, questionNo, path, answerTable, fswrite, callBack) {
  return answerTable.findAll({
    where: {
      questionNo: questionNo
    },
    order: 'id'
  }).success(function(columns) {
    var column, i, testcase_path, _i, _len;

    for (i = _i = 0, _len = columns.length; _i < _len; i = ++_i) {
      column = columns[i];
      testcase_path = "" + path + "/" + questionNo + i + ".txt";
      fswrite(testcase_path, column.testcase);
      req.argTestcase[i] = "" + questionNo + i + ".txt";
      req.argAnswer[i] = column.answer;
      console.log("fswrite_test -> " + path);
    }
    return callBack(null, 5);
  });
};

compileSource = function(req, questionNo, path, exec, callBack) {
  return exec("gcc -Wall -o " + path + "/" + questionNo + ".out " + path + "/" + questionNo + ".c", function(error, stdout, stderr) {
    var tmp;

    if (error) {
      req.result = 'Compile Error';
      error = new String(error);
      tmp = new RegExp(req.dir_path, 'g');
      req.compile_error = error.replace(tmp, '');
      console.log("Compile Error -> " + error);
    }
    console.log("" + path + " -> compile!");
    return callBack(null, 6);
  });
};

executeSource = function(req, questionNo, path, exec, callBack) {
  if (req.result !== '') {
    callBack(null, 7);
    return;
  }
  if (0 < req.argTestcase.length) {
    inputExecute(req, questionNo, path, exec, callBack, 0);
    return;
  }
  return noinputExecute(req, questionNo, path, exec, callBack, 0);
};

noinputExecute = function(req, questionNo, path, exec, callBack, num) {
  var exePath;

  exePath = "" + path + "/" + questionNo + ".out";
  return exec(exePath, {
    timeout: 3000,
    maxBuffer: 65536
  }, function(error, stdout, stderr) {
    var tmp;

    if (error) {
      error = new String(error);
      tmp = new RegExp(req.dir_path, 'g');
      req.stderr = error.replace(tmp, '');
      req.result = executeError(num, error);
      callBack(null, 7);
    }
  }, req.argStdout[num] = stdout.replace(/\r\n$/, ''), callBack(null, 7));
};

inputExecute = function(req, questionNo, path, exec, callBack, num) {
  var cmd, exePath, testPath;

  if (num >= req.argTestcase.length) {
    callBack(null, 7);
    return;
  }
  exePath = "" + path + "/" + questionNo + ".out";
  testPath = "" + path + "/" + req.argTestcase[num];
  cmd = "" + exePath + " < " + testPath;
  return exec(cmd, {
    timeout: 3000,
    maxBuffer: 65536
  }, function(error, stdout, stderr) {
    var tmp;

    if (error) {
      error = new String(error);
      tmp = new RegExp(req.dir_path, 'g');
      req.stderr = error.replace(tmp, '');
      req.result = executeError(num, error);
      callBack(null, 7);
      return;
    }
    req.argStdout[num] = stdout.replace(/\r?\n$/, '');
    return inputExecute(req, questionNo, path, exec, callBack, num + 1);
  });
};

executeError = function(num, error) {
  var signal;

  signal = error.toString();
  if (0 < signal.indexOf('maxBuffer')) {
    return 'Segmentation Fault';
  }
  if (0 < signal.indexOf('Command')) {
    return 'Time Limit Exceeded';
  }
  return "不明なエラーです";
};

compareSource = function(req, callBack) {
  var ans, answer, i, kondo_check, result, stdout, _i, _len;

  stdout = req.argStdout;
  answer = req.argAnswer;
  result = req.result;
  console.log(stdout);
  console.log(answer);
  if (result !== '') {
    console.log("" + req.ip + " result error : " + result);
  } else {
    for (i = _i = 0, _len = answer.length; _i < _len; i = ++_i) {
      ans = answer[i];
      if (stdout[i] !== ans) {
        kondo_check = kondoMethod(stdout[i], ans);
        console.log("kondo_check: " + kondo_check);
        if (kondo_check === true) {
          req.result = "Accept";
        } else {
          req.result = "Wrong Answer";
          break;
        }
      } else {
        req.result = "Accept";
      }
    }
  }
  return callBack(null, 8);
};

saveResult = function(req, questionNo, username, source, submitTable, correcterTable, callBack) {
  var insert_obj, saveData, time;

  time = getTimestamp();
  insert_obj = {
    userID: username,
    questionNo: questionNo,
    source: source,
    time: time,
    result: req.result
  };
  saveData = submitTable.build(insert_obj);
  return saveData.save().success(function() {
    console.log('DB save success');
    return callBack(null, 9);
  });
};

getTimestamp = function() {
  var d, day, hour, minute, month, second, time, year;

  d = new Date();
  year = d.getFullYear();
  month = d.getMonth() + 1;
  day = d.getDate();
  hour = d.getHours();
  minute = d.getMinutes();
  second = d.getSeconds();
  if (month < 10) {
    month = '0' + month;
  }
  if (day < 10) {
    day = '0' + day;
  }
  if (hour < 10) {
    hour = '0' + hour;
  }
  if (minute < 10) {
    minute = '0' + minute;
  }
  if (second < 10) {
    second = '0' + second;
  }
  time = "" + year + "-" + month + "-" + day + " " + hour + ":" + minute + ":" + second;
  return time;
};

removeDir = function(questionNo, path, exec, callBack) {
  var cmd;

  cmd = "rm -rf " + path + "/";
  exec(cmd, {}, function(error, stdout, stderr) {
    if (error) {
      return console.log("rm error -> " + error);
    }
  });
  return callBack(null, 10);
};

removeQueue = function(queueID, submitQueueTable, callBack) {
  return submitQueueTable.find({
    where: {
      id: queueID
    }
  }).success(function(columns) {
    if ((columns != null)) {
      columns.destroy();
      console.log('delete SubmitQueue_table ------');
    }
    return callBack(null, 11);
  }).error(function(error) {
    return console.log("submit SubmitQueue_table err > " + error);
  });
};

sendMsg = function(req, res, callBack) {
  var endTime, obj, startTime;

  startTime = req.startTime;
  endTime = getTimestamp();
  console.log("" + req.ip + " -> start:" + startTime + " - " + endTime);
  obj = {
    cmperr: req.compile_error,
    stderr: req.stderr,
    result: req.result
  };
  res.send('200', obj);
  return callBack(null, 12);
};

kondoMethod = function(stdout, answer) {
  stdout = replaceFullsizeChar(stdout);
  answer = replaceFullsizeChar(answer);
  if (stdout === answer) {
    return true;
  }
  stdout = toUpper(stdout);
  answer = toUpper(answer);
  if (stdout === answer) {
    return true;
  }
  stdout = replaceEqualsign(stdout);
  if (stdout === answer) {
    return true;
  }
  stdout = skipTable(stdout);
  if (stdout === answer) {
    return true;
  }
  stdout = pulloutNumber(stdout);
  answer = pulloutNumber(answer);
  if (stdout === '' || answer === '') {
    return false;
  }
  if (stdout === answer) {
    return true;
  }
  return false;
};

replaceFullsizeChar = function(string) {
  var translation;

  translation = string.replace(/[！-～]/g, function(str) {
    return String.fromCharCode(str.charCodeAt(0) - 0xFEE0);
  });
  return translation;
};

toUpper = function(string) {
  var translation;

  translation = string.toUpperCase();
  return translation;
};

replaceEqualsign = function(string) {
  var translation;

  translation = string.replace(/:/g, '=');
  return translation;
};

skipTable = function(string) {
  var translation;

  translation = string.replace(/[ ]+/g, '');
  return translation;
};

pulloutNumber = function(string) {
  var decimal1, decimal2, i, len, number, _ref, _ref1, _ref2;

  i = 0;
  len = string.length;
  number = '';
  while (i < len) {
    if (('0' <= (_ref = string[i]) && _ref <= '9')) {
      number += string[i];
    }
    if (string[i] === '.') {
      decimal1 = (_ref1 = string[i + 1]) != null ? _ref1 : '0';
      decimal2 = (_ref2 = string[i + 2]) != null ? _ref2 : '0';
      number += decimal1 + decimal2;
      break;
    }
    i++;
  }
  return number;
};
