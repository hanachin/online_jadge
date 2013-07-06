### ---- class --------------------- ###
class HTMLtemplate
  _accept = '''
    <h1 style='font-family: times new roman; font-size: 100px; padding: 80px; line-height: 85px;'>Accept</h1>
      <p>正解です。</p>
      <p>おめでとうございます！</p>
  '''
  _timelimit = '''
    <h2 style='font-family: times new roman; font-size: 80px; padding: 40px; line-height: 85px;'>TimeLimit Exceeded</h2>
    <p>不正解です。プログラムの実行に時間がかかっています。</p>
    <p>ループのチェックをしてみましょう！</p>
  '''
  _compile = '''
    <h2 style='font-family: times new roman; font-size: 80px; padding: 40px; line-height: 85px;'>Compile Error</h2>
    <p>不正解です。コンパイルができません。</p>
    <p>C言語の文法をチェックしてみましょう！</p>
  '''
  _segmentationFault = '''
    <h2 style='font-family: times new roman; font-size: 80px; padding: 40px; line-height: 85px;'>#{result}</h2>
    <p>不正解です。プログラムがメモリ空間に異常を与えています。</p>
    <p>ループの異常、またはポインタやscanfの文法をチェックしてみましょう！</p>
  '''
  _wrongAnswer = '''
    <h2 style='font-family: times new roman; font-size: 80px; padding: 40px; line-height: 85px;'>Wrong Answer</h2>
    <p>不正解です。実行にエラーはないので、出力と出力例を見比べてみましょう！</p>
  '''
  @getAC : () ->
    _accept
  @getTimelimit : () ->
    _timelimit
  @getCompileError : () ->
    _compile
  @getSegmentationFault : () ->
    _segmentationFault
  @getWrongAnswer : () ->
    _getWrongAnswer

### ---- main --------------------- ###
$( ->
  sourceErea = $('#textarea')
  resultErea = $('#resultarea')
  loadErea = $('#loadingerea')
  submitMode = $('#submit_mode')
  debugMode = $('#debag_mode')
  socket = io.connect('http://localhost:8080')

  $('#displaymodal').click( ->
    switchModalWindow()
  )

  # ソースコードを見直すをクリックしたときの処理
  $('#debag').click( ->
    switchDebugWindow()
  )

  $('#submit').click( ->
    # テキストエリアと問題名の値を取得
    questionNo = $("#questionNo").text()
    source = editAreaLoader.getValue("code_area")

    # ローディングcanvasの描画
    displayLoading()

    # debag_modeボタンの表示
    submitMode.css('display', 'none')

    # judgeServerへの送信
    requestJudgeServer(resultErea, questionNo, source)
  )

  ### ---- function --------------- ###
  switchModalWindow = () ->
    sourceErea.css  'display', 'block'
    loadErea.css    'display', 'none'
    resultErea.css  'display', 'none'
    debugMode.css   'display', 'none'
    submitMode.css  'display', 'block'

  switchDebugWindow = () ->
    sourceErea.css  'display', 'block'
    loadErea.css    'display', 'none'
    resultErea.css  'display', 'none'
    debugMode.css   'display', 'none'
    submitMode.css  'display', 'block'

  displayLoading = () ->
    $('#loadingerea').append(loadIcon.canvas)
    sourceErea.css  'display', 'none'
    loadErea.css  'display', 'block'

  requestJudgeServer = (resultErea, questionNo, source) ->
    # judgeServerへのリクエスト
    socket.emit 'submit_source', {
      questionNo : questionNo
      source     : source
    }

    # push通知の受け取り
    socket.on 'result_judge', (json) ->
      res    = $.parseJSON(json)
      result = displayResultMsg(res.result)
      error  = displayErrorMsg(res.cmperr, res.stderr)
      msg    = result + error
      resultErea.html(msg)
      switchAfterJudge()

  displayResultMsg = (result) ->
    msg = ''
    switch result
      when 'Accept'
        msg = HTMLtemplate.getAccept()
      when 'Time Limit Exceeded'
        msg = HTMLtemplate.getTimelimit()
      when 'Compile Error'
        msg = HTMLtemplate.getCompileError()
      when 'Segmentation Fault'
        msg = HTMLtemplate.getSegmentationFault()
      else
        msg = HTMLtemplate.getWrongAnswer()
    return msg

  displayErrorMsg = (cmperr, stderr) ->
    error = ''
    if (cmperr isnt '')
      error = "<pre style='overflow:auto; max-height:135px; text-align: left; width: 80%; margin: 40px auto; line-height: 27px;'>#{cmperr}</pre>"
    if (stderr isnt '')
      error = "<pre style='overflow:auto; max-height:135px; text-align: left; width: 80%; margin: 40px auto; line-height: 27px;'>#{stderr}</pre>"
    return error

  switchAfterJudge = () ->
    sourceErea.css 'display', 'none'
    loadErea.css   'display', 'none'
    debugMode.css  'display', 'block'
    resultErea.css 'display', 'block'
)
