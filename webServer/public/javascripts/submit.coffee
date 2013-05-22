$(() ->
  # DOMにアクセスできるようにする
  sourcecodeErea = $('#textarea')
  resultErea = $('#resultarea')
  loadingErea = $('#loadingerea')
  submit_mode = $('#submit_mode')
  debag_mode = $('#debag_mode')

  # ローディングcanvasの描画
  $('#loadingerea').append(loadImg.canvas)

  $('#displaymodal').click(() ->
    sourcecodeErea.css('display', 'block')
    loadingErea.css('display', 'none')
    resultErea.css('display', 'none')
    debag_mode.css('display', 'none')
    submit_mode.css('display', 'block')
  )

  # ソースコードを見直すをクリックしたときの処理
  $('#debag').click(() ->
    sourcecodeErea.css('display', 'block')
    loadingErea.css('display', 'none')
    resultErea.css('display', 'none')
    debag_mode.css('display', 'none')
    submit_mode.css('display', 'block')
  )

  $('#submit').click(() ->
    # テキストエリアと問題名の値を取得
    questionNo = $("#questionNo").text()
    source = editAreaLoader.getValue("code_area")

    # ローディングcanvasの描画
    sourcecodeErea.css('display', 'none')
    loadingErea.css('display', 'block')

    # debag_modeボタンの表示
    submit_mode.css('display', 'none')

    # Ajax通信
    $.ajax(
      url: '/submit_source'
      type: 'post'
      data:{
        questionNo  : questionNo
        source      : source
      }
      cache: true
    )
    .done (data) ->
      console.log data
      alert(data)

      result = data.result
      sourcecodeErea.css('display', 'none')
      loadingErea.css('display', 'none')
      debag_mode.css('display', 'block')
      resultErea.css('display', 'block')

      # 不正解の場合
      switch (result)
        when ('Accept')
          displayresult = """
            <h1 style='font-family: times new roman; font-size: 100px; padding: 80px; line-height: 85px;'>#{result}</h1>
            <p>正解です。</p>
            <p>おめでとうございます！</p>
          """
        when ("Time Limit Exceeded")
          displayresult = """
            <h1 style='font-family: times new roman; font-size: 100px; padding: 80px; line-height: 85px;'>#{result}</h1>
            <p>不正解です。プログラムの実行に時間がかかっています。</p>
            <p>ループのチェックをしてみましょう！</p>
          """
        when ("Compile Error")
          displayresult = """
            <h1 style='font-family: times new roman; font-size: 100px; padding: 80px; line-height: 85px;'>#{result}</h1>
            <p>不正解です。コンパイルができません。</p>
            <p>C言語の文法をチェックしてみましょう！</p>
          """
        when ("Segmentation Fault")
          displayresult = """
            <h1 style='font-family: times new roman; font-size: 100px; padding: 80px; line-height: 85px;'>#{result}</h1>
            <p>不正解です。プログラムがメモリ空間に異常を与えています。</p>
            <p>ループの異常、またはポインタやscanfの文法をチェックしてみましょう！</p>
          """
        else
          displayresult = """
            <h1 style='font-family: times new roman; font-size: 100px; padding: 80px; line-height: 85px;'>#{result}</h1>
            <p>不正解です。出力と出力例を見比べてみましょう！</p>
          """
      resultErea.html(displayresult)
    .fail () ->
      alert 'サーバ通信エラー'
  )
)
