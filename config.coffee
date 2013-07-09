exports.AppConfig = class AppConfig
  # ファイル名に拡張子を残すか
  _keepExtention = true
  _engine = "ejs"

  constructor : (port, dir) ->
    @appDir = dir
    @port = port
    # ディレクトリ
    @tmpDir = "#{@appDir}/tmp"
    @view   = "#{@appDir}/views"
    @public = "#{@appDir}/public"

  getPort  : () ->
    @port
  getView : () ->
    @view
  getPublic : () ->
    @public
  getEngine : () ->
    _engine
  upload : () ->
    {
      uploadDir        : @tmpDir
      isKeepExtensions : _keepExtention
    }

exports.LogConfig = class LogConfig
  _size = 1024 * 1024
  _date = '-yyyy-MM-dd'

  constructor : (dir) ->
    @dir = dir
  getName : () ->
    "#{@dir}/logs/pxp_log"
  getSize   : () ->
    _size
  getStdout : () ->
    false
  getPattern : () ->
    _date
  getNolog  : () ->
    [ '\\.css', '\\.js', '\\.gif', '\\.jpg', '\\.png' ]
  format : () ->
    JSON.stringify {
      'method'     : ':method'
      'request'    : ':url'
      'status'     : ':status'
      'user-agent' : ':user-agent'
    }
