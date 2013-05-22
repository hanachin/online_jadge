editAreaLoader.init({
  id : "code_area",             // テキストエリアのID
  syntax: "c",                  // シンタックスハイライトの対象とする言語
  start_highlight: true,        // シンタックスハイライトを行なうかどうか?
  language: "ja",               // 言語
  allow_toggle: false,          // 元のテキストエリアを切り替える機能をoff
  font_family:"Andale Mono",    // font
  replace_tab_by_spaces:4,      // tab space
  // ツールバーの機能一覧
  toolbar: "new_document, |, search, go_to_line, fullscreen, |, undo, redo, reset_highlight, highlight, select_font, |, help "
});
