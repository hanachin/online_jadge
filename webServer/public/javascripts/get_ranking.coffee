$(() ->
  get_ranking()
)

get_ranking = () ->
  table_tmp = """
    <table class="table table-bordered" style="padding: 20px; width: 1030px; margin: auto; margin-top: 15px;">
      <tbody id="list">
        <tr style="background-color: #E8E8E8;">
          <td>ユーザ名</td>
          <td>問題名</td>
          <td>解答状況</td>
          <td>送信時間</td>
        </tr>
      </tbody>
    </table>'
  """
  ac_temp = '<img src="images/ac.png" alt="ac" style="height: 30%;"><span style="margin-left: 1em;">正解</span>'
  wa_temp = '<img src="images/wa.png" alt="wa" style="height: 30%;"><span style="margin-left: 1em;">未正解</span>'


  $.ajax(
    url: "/get_ranking"
    type: "get"
    dataType: 'text'
    cache: true
  )
  .done (data) ->
    # 受け取ったJSONをパース
    resJSON = $.parseJSON(data)

    $('#status').html(table_tmp)

    #テーブルリストの作成
    table_calum = ""
    for obj in resJSON
      date = obj.time.split('T')
      time = date[1].split('.000Z')[0]
      fullyear = date[0]

      table_calum += """
        <tr>
          <td>#{obj.username}</td>
          <td>#{obj.volumeNo}</td>
          <td>#{obj.result}</td>
          <td><time>#{fullyear} #{time}</time></td>
        </tr>
      """
    #リストにランキングを挿入
    $('#list').append(table_calum)
  .fail () ->
    alert('サーバ通信エラー')

  timerID = setTimeout(get_ranking, 3000)
