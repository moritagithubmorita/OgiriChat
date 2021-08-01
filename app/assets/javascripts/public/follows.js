/* フォローモーダルのjs
    処理内容
    1.イベントが発生したら「フォーロー確認モーダル」を表示
    2.モーダルに対しイベントが発生したらトップ画面に遷移
*/

/*global $*/

// フォローモーダルに対戦に参加したユーザ各人のチェックボックスを配置する
$(document).on('turbolinks:load', function(){
  var panelist_ids = $('#').data('panelist-ids')  
  $.each(panelist_ids, function(key, value){
    
    
    
  })
})

// 「トップへ」が押されたらフォローモーダルを表示する
$('#finish__top-button').on('click', function(){
  $('#follow-modal').css('display', 'none')
})