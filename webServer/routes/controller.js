// Generated by CoffeeScript 1.6.2
module.exports = function(option) {
  var app, dataBase, loginCheck, sio, sioIndex;

  app = option.app;
  dataBase = option.database;
  sioIndex = require('./socket_server');
  sio = sioIndex.socketio;
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
  sio.sockets.on('connection', function(socket) {
    console.log("test -----");
    console.log(socket.handshake);
    return socket.on('submit_source', function(data) {
      var submitSource;

      submitSource = require('./submit_source');
      return submitSource.main(data, socket, sio, dataBase);
    });
  });
  return "controller is setup";
};
