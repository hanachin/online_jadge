# 全体的に読みづらい
$ () ->
  # アップロードボタンを作成する
  uploadButton = $('<button/>')
    .addClass('btn')
    .text('アップロード')
    .on('click', () ->
      # アップロードボタンをclick -> 中断ボタンに
      $this = $(@)
      data = $this.data()
      $this
        .off('click')
        .text('アップロードを中断する...')
        .on('click', () ->
          $this.remove()
          # AJAX通信を中断する
          data.abort()
        )
        data.submit().always(() ->
          # Ajax通信を中断するボタンの処理
          # 要素を削除する
          $this.remove()
          $this.text('アップロードを中断しました')
        )
    )
    # ファイルを選択したあとの処理
  $('#fileupload').fileupload({
      url: '/upload_questions'
      dataType: 'json'
      autoUpload: false
      acceptFileTypes: /(.xml|.csv)$/i
      # 5MB
      maxFileSize: 5000000
      # 15MB
      loadImageMaxFileSize: 15000000
  }).on('fileuploadadd', (e, data) ->
      # <div id="files">以下に、ファイル名とボタンを設置する
      data.context = $('#files')
      $.each(data.files, (index, file) ->
        node = $('<div/>').append($('<p/>').text(file.name))
        if (!index)
          node
            .append('<p/>')
            .append(uploadButton.clone(true).data(data))
          # HTMLに挿入
          node.appendTo(data.context)
      )
  ).on('fileuploadprocessalways', (e, data) ->
      # 受け取ったjson ファイルを元に送信が成功したかどうかを表示する
      index = data.index
      file = data.files[index]
      node = $(data.context.children()[index])
      if (file.error)
        node.append('</p>')
        node.append(file.error)
      if (index + 1 is data.files.length)
        data.context.find('button')
          .text('Upload')
          .prop('disabled', !!data.files.error)
  ).on('fileuploadprogressall', (e, data) ->
      progress = parseInt(data.loaded / data.total * 100, 10)
      $('#progress .bar').css('width', "#{progress}%")
  ).on('fileuploaddone', (e, data) ->
    $.each(data.result.files, (index, file) ->
      link = $('<p/>').text("#{file.filename} ファイルのアップロードが完了しました")
      $(data.context.children()[index]).wrap(link)
    )
    timer_id = setTimeout(() ->
      $('#progress .bar').css('width', "#{0}%")
    , 1000)
  ).on('fileuploadfail', (e, data) ->
    $.each(data.result.files, (index, file) ->
      error = $('<p/>')
      .text("#{file.error} >> #{file.filename} ファイルのアップロードに失敗しました")
      $(data.context.children()[index]).wrap(error)
    )
  )
