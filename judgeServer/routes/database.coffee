module.exports = (options) ->
  sequelize = require 'sequelize'

  # databaseの定義を記述する
  # database名、ユーザ、パスワード、ホストネーム、ポート
  # ホストネームはサーバのip?
  dbname = '*****'
  dbuser = '*****'
  dbpass = '*****'
  hostname = 'localhost'
  portnum = ****

  seq = new sequelize(dbname, dbuser, dbpass, {
    host: hostname
    port: portnum
  })

  database = new Object()

  # defaultで付与されるタイムスタンプを付けない
  # テーブルネームを複数形にしない（定義した名前を使用する）
  seq_option = {
    timestamps     : false
    freezeTableName: true
  }

  # O/Rマッパーがサポートしていない範囲のSQLを発行する
  database.seq = seq

  # Submit_table
  columns = {
    userID: {type:sequelize.STRING, primaryKey: true}
    questionNo: sequelize.STRING
    source: sequelize.TEXT
    result: sequelize.STRING
    time: type:sequelize.DATE
  }
  database.submitTable = seq.define("Submit_table", columns, seq_option)

  # Answer_table
  columns = {
    questionNo: {type: sequelize.STRING, primaryKey: true}
    answer: sequelize.TEXT
    testcase: sequelize.TEXT
  }
  database.answerTable = seq.define('Answer_table', columns, seq_option)

  # SubmitQueue_table
  columns = {
    id: {type: sequelize.INTEGER, primaryKey: true}
    questionNo: type: sequelize.STRING
    userID: sequelize.STRING
    source: sequelize.TEXT
  }
  database.submitQueueTable = seq.define('SubmitQueue_table', columns, seq_option)

  # Correcter_table
  columns = {
    questionNo: {type: sequelize.STRING, primaryKey: true}
    userID: sequelize.STRING
  }
  database.correcterTable = seq.define('Correcter_table', columns, seq_option)

  console.log 'Database is setup.'

  return database
# ------------------------------------
