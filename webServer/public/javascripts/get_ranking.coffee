TABLE_TMP = '''
  <table class="table table-bordered" style="padding: 20px; width: 1030px; margin: auto; margin-top: 15px;">
    <tbody id="list">
      <tr style="background-color: #E8E8E8;">
        <td>ユーザ名</td>
        <td>問題名</td>
        <td>解答状況</td>
        <td>提出時間</td>
      </tr>
    </tbody>
  </table>
'''

$(() ->
  get_ranking()
)

get_ranking = () ->
  $.ajax(
    url: "/get_ranking"
    type: "get"
    dataType: 'text'
  )
  .done (data) ->
    console.log data
    # 受け取ったJSONをパース
    resJSON = $.parseJSON(data)

    # htmlへの挿入
    $('#status').html(TABLE_TMP)

    #テーブルリストの作成
    table_calum = ""
    for obj in resJSON
      date = obj.time.split('T')
      time = date[1].split('.000Z')[0]
      fullyear = date[0]
      # htmlの作成
      table_calum += """
        <tr>
          <td>#{obj.userID}</td>
          <td>#{obj.questionNo}</td>
          <td>#{obj.result}</td>
          <td><time>#{fullyear} #{time}</time></td>
        </tr>
      """

    #リストにランキングを挿入
    $('#list').append(table_calum)

  .fail () ->
    alert('サーバ通信エラー')

  timerID = setTimeout(get_ranking, 3000)
