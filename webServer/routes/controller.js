// Generated by CoffeeScript 1.4.0

module.exports = function(option) {
  var app, dataBase, loginCheck;
  app = option.app;
  dataBase = option.database;
  loginCheck = function(req, res, next) {
    console.log(req.session);
    if (req.session.loginflag) {
      return next();
    } else {
      return res.render('login');
    }
  };
  app.get('/', loginCheck, function(req, res, next) {
    var username;
    username = req.session.username;
    return res.render('select', {
      username: username
    });
  });
  app.post('/select', function(req, res, next) {
    var postLogininfo;
    postLogininfo = require('./login');
    return postLogininfo.main(req, res, dataBase);
  });
  app.get('/destroy', function(req, res, next) {
    var destroy;
    destroy = require('./destroy');
    return destroy.main(req, res);
  });
  app.get('/select', loginCheck, function(req, res, next) {
    return res.render('select', {
      username: "" + req.session.username
    });
  });
  app.get('/get_questions', function(req, res, next) {
    var getQuestions;
    getQuestions = require('./get_questions');
    return getQuestions.main(req, res, dataBase);
  });
  app.get('/coding', loginCheck, function(req, res, next) {
    var getCodingpage;
    getCodingpage = require('./coding');
    return getCodingpage.main(req, res, dataBase);
  });
  app.post('/submit_source', function(req, res, next) {
    var submitSource;
    submitSource = require('./submit_source');
    return submitSource.main(req, res, dataBase);
  });
  app.get('/ranking', loginCheck, function(req, res, next) {
    var questionNo;
    if ((req.query.questionNo != null)) {
      questionNo = req.query.questionNo;
    }
    return res.render('ranking', {
      username: "" + req.session.username
    });
  });
  app.get('/get_ranking', function(req, res, next) {
    var getRanking;
    getRanking = require('./get_ranking');
    return getRanking.main(req, res, dataBase);
  });
  app.get('/mypage', function(req, res, next) {
    var mypage;
    mypage = require('./mypage');
    return mypage.main(req, res, dataBase);
  });
  app.get('/get_corrects', function(req, res, next) {
    var correct_questions;
    correct_questions = require('./get_corrects');
    return correct_questions.main(req, res, dataBase);
  });
  app.get('/get_status', function(req, res, next) {
    var status_questions;
    status_questions = require('./get_status');
    return status_questions.main(req, res, dataBase);
  });
  app.post('/codeview', function(req, res, next) {
    var codeview;
    codeview = require('./codeview');
    return codeview.main(req, res, dataBase);
  });
  app.get('/management_console', function(req, res, next) {
    var management_console;
    management_console = require('./management_console');
    return management_console.main(req, res, dataBase);
  });
  app.get('database_page', function(req, res, next) {
    var database_page;
    database_page = require('./show_database');
    return database_page.main(req, res, dataBase);
  });
  app.get('/show_table', function(req, res, next) {
    var show_table;
    show_table = require('./show_table');
    return show_table.main(req, res, dataBase);
  });
  app.get('/delete_data', function(req, res, next) {
    var delete_data;
    delete_data = require('./delete_data');
    return delete_data.main(req, res, dataBase);
  });
  app.get('/upload_page', loginCheck, function(req, res, next) {
    var username;
    username = req.session.username;
    return res.render('upload', {
      username: username
    });
  });
  app.post('/upload_questions', function(req, res, next) {
    var uploadQuestions;
    uploadQuestions = require('./upload_questions');
    return uploadQuestions.main(req, res, dataBase);
  });
  app.get('/upload_students', function(req, res, next) {
    var upload_students;
    upload_students = require('./upload_students');
    return upload_students.main(req, res, dataBase);
  });
  app.get('/result_page', function(req, res, next) {
    var result_page;
    result_page = require('./result_page');
    return result_page.main(req, res, dataBase);
  });
  app.get('/show_result', function(req, res, next) {
    var show_result;
    show_result = require('./show_result');
    return show_result.main(req, res, dataBase);
  });
  return "controller is setup";
};
