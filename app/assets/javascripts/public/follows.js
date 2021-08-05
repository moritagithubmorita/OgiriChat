/* フォローモーダルのjs
    処理内容
    1.イベントが発生したら「フォーロー確認モーダル」を表示
    2.モーダルに対しイベントが発生したらトップ画面に遷移
*/

/*global $*/

// フォローモーダルに「対戦に参加したユーザ(未フォロー)のチェックボックス」を配置する
$(document).on('turbolinks:load', function(){
  var panelist_ids = $('.follow-modal-area').data('panelist-ids');  // 参戦者のうち未フォローのユーザのuser_ids
  var panelist_names = $('.follow-modal-area').data('panelist-names');  // 上記に当てはまるユーザの名前s
  
  // 未フォローユーザが参戦していた場合各ユーザのチェックボックスを表示
  if(panelist_ids != undefined){
    if(Object.keys(panelist_ids).length>0){
      var cnt = 1
      $.each(panelist_ids, function(key, value){
        var user = "user"+cnt;
        // $('#follow-modal__user-area').append(`<%= render partial: 'public/question_rooms/finish_modal_user', locals: {user_id: ${value}, key: ${key}} %>`)
        $('#follow-modal__user-area').append(`<label>${panelist_names.panelist1_name}</label><input type="checkbox" name="${user}_flag">`);
        $('#follow-modal__user-area').append(`<input type="hidden" name="${user}_id" value="${value}">`);
        cnt+=1;
      })
    }
  }

  // 終了ページで「トップへ」が押されたらフォローモーダルを表示する
  $('#finish__top-button').on('click', function(){
    console.log("トップボタンが押された");
    $('.follow-modal').css('display', 'block');
  })

  // 対戦詳細ページで「トップへ」が押されたらフォローモーダルを表示する
  $('#result__top-button').on('click', function(){
    console.log("トップボタンが押された");
    $('.follow-modal').css('display', 'block');
  })
})
