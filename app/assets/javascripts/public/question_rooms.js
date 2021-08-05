/*global $*/

/*対戦終了画面(finish.html.erb)の処理
  <処理内容>
    観覧なら「対戦詳細」リンクを表示しない
*/

$(document).on('turbolinks:load', function(){
  let is_audience = $('.follow-modal-area').data('is-audience');  // 観覧(true)/参戦(false)
  // 観覧の場合、対戦結果詳細リンクを削除する
  if(is_audience){
    $('#finish__result-button').remove()
  }
});