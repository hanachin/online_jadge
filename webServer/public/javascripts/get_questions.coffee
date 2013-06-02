# HTMLのtemplate一覧
TABLE_TMP = '''
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

AC_TMP = '''
  <img src="images/ac.png" alt="ac" style="height: 30%;">
  <span style="margin-left: 1em;">正解</span>
'''

WA_TMP = '''
  <img src="images/wa.png" alt="wa" style="height: 30%;">
  <span style="margin-left: 1em;">未提出</span>
'''

$(() ->
  if (document.cookie.length isnt '')
    cookies = document.cookie.split(';')
    i = 0
    len = cookies.length
    while (i < len)
      parse = cookies[i].split('=')
      # クッキーの名前をキーとして 配列に追加する
      cookies[parse[0]] = decodeURIComponent(parse[1])
      i++
    get_question(cookies['gradeNo'], cookies[' lessonNo'])

  $('select').change () ->
    gradeNo  = $('#gradeNo option:selected').val()
    lessonNo = $('#lessonNo option:selected').val()
    get_question(gradeNo, lessonNo)
)

get_question = (gradeNo, lessonNo) ->
  # 入力値のチェック
  if (gradeNo isnt 'null' and lessonNo isnt 'null')
    # ローディングcanvasの描画
    loadingIcon = "<div id='loadingIcon' style='text-align: center; width: 100%;'></div>"
    $('#questions').html(loadingIcon)
    $('#loadingIcon').append(loadImg.canvas)

    # Ajax通信
    # サーバから問題一覧を取得する
    $.ajax(
      url  : "/get_questions"
      type : "get"
      data : {
        gradeNo  : gradeNo
        lessonNo : lessonNo
      }
      dataType : 'text'
    )
    .done (data) ->
      # cookieに値を保存する
      document.cookie = "gradeNo=#{gradeNo};"
      document.cookie = "lessonNo=#{lessonNo};"

      # 受け取ったJSONをパース
      resJSON = $.parseJSON(data)

      # 問題のリストの作成
      $('#questions').html(TABLE_TMP)
      for obj in resJSON
        # progress barの値を設定する
        correcters = obj.correcters
        progress = parseInt(correcters / 43 * 100, 10)

        # 提出済か判定しHTMLファイルのテンプレートを作成する
        if (obj.state is 'AC')
          state = AC_TMP
        else
          state = WA_TMP

        # tableに挿入するリストを作成する
        content = """
          <tr data-href="/coding?questionNo=#{obj.questionNo}" class="clickable">
            <td>
              <a href="/coding?questionNo=#{obj.questionNo}">#{obj.questionNo}</a>
            </td>
            <td>#{state}</td>
            <td>
              <div class="progress" style="width:80%">
                <div class="bar" style="color:black; width:#{progress}%;"></div>
              </div>
              <span>クラスの正答者：#{correcters}/43 人</span>
            </td>
          </tr>
        """
        # listに問題を挿入
        $('#list').append(content)

      # table要素をクリック可能に
      $('tr[data-href]').addClass('clickable').click (e) ->
        if (!$(e.target).is('a'))
          window.location = $(e.target).closest('tr').data('href')
    .fail () ->
      alert('サーバ通信エラー')

