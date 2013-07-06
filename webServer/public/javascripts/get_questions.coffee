class HtmlTemplate
    _table = '''
      <table class="table table-bordered" style="padding: 20px; width: 1030px; margin: auto; margin-top: 15px;">
        <tbody id="list">
          <tr style="background-color: #E8E8E8;">
            <td>問題名</td>
            <td>解答状況</td>
            <td>解答回数</td>
          </tr>
        </tbody>
      </table>
    '''
    _ac = '''
      <td>
        <img src="images/ac.png" alt="ac" style="height: 30%;">
        <span style="margin-left: 1em;">正解</span>
      </td>
    '''
    _wa = '''
      <td>
        <img src="images/wa.png" alt="wa" style="height: 30%;">
        <span style="margin-left: 1em;">未提出</span>
      </td>
    '''
    @getTable : () ->
      _table
    @getAC : () ->
      _ac
    @getWA : () ->
      _wa

### ----  main --------------------------------------- ###
$( ->
  if (document.cookie isnt '')
    cookies = document.cookie.split(';')
    for c in cookies
      parse = c.split('=')
      # クッキーの名前をキーとして 配列に追加する
      cookies[parse[0]] = decodeURIComponent(parse[1])
    # 問題の作成
    getQuestion(cookies[' gradeNo'], cookies[' lessonNo'], $)

  $('select').change () ->
    gradeNo  = $('#gradeNo option:selected').val()
    lessonNo = $('#lessonNo option:selected').val()
    getQuestion(gradeNo, lessonNo, $)
)

### ---- function ----------------------------------- ###
getQuestion = (gradeNo, lessonNo, $) ->
  # 入力値のチェック
  if (gradeNo isnt 'null' and lessonNo isnt 'null')
    # ローディングアイコンの表示
    displayLoading()

    # Ajax通信
    # サーバから問題一覧を取得する
    $.ajax(
      url  : "/get_questions"
      type : "GET"
      data : {
        gradeNo  : gradeNo
        lessonNo : lessonNo
      }
      dataType : 'text'
    )
    .done (json) ->
      # cookieに値を保存する
      saveCookie(gradeNo, lessonNo)
      # 受け取ったJSONをパース
      res = $.parseJSON(json)
      # 問題のリストの作成
      table = HtmlTemplate.getTable
      $('#questions').html(table)
      createList(res)
    .fail () ->
      alert('サーバ通信エラー')

displayLoading = () ->
  canvas = "<div id='loadingErea' style='text-align: center; width: 100%;'></div>"
  $('#questions').html(canvas)
  $('#loadingIcon').append(loadIcon.canvas)

saveCookie = (gradeNo, lessonNo) ->
  document.cookie = "gradeNo=#{gradeNo};"
  document.cookie = "lessonNo=#{lessonNo};"

createProgress = (correcters) ->
  correcters = correcters
  progress   = parseInt(correcters / 43 * 100, 10)
  bar = """
    <td>
      <div class="progress" style="width:80%">
        <div class="bar" style="color:black; width:#{progress}%;"></div>
      </div>
      <span>クラスの正答者：#{correcters}/43 人</span>
    </td>
  """

createQuestion = (questionNo) ->
  question = """
      <td>
        <a href="/coding?questionNo=#{questionNo}">#{questionNo}</a>
      </td>
  """

createState = (judge) ->
  if (state is 'AC')
    state = HtmlTemplate.getAC()
  else
    state = HtmlTemplate.getWA()
  return state

createList = (json) ->
  for obj in json
    question = createQuestion(obj.questionNo)
    progress = createProgress(obj.correcters)
    state = createState(obj.state)
    content = "<tr data-href='/coding?questionNo=#{obj.questionNo}' class='clickable'>#{question}#{state}#{progress}</tr>"
    $('#list').append(content)

    # table要素をクリック可能に
    $('tr[data-href]').addClass('clickable').click (e) ->
      if (!$(e.target).is('a'))
        window.location = $(e.target).closest('tr').data('href')


