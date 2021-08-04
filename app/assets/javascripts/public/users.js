// # Place all the behaviors and hooks related to the matching controller here.
// # All this logic will automatically be available in application.js.
// # You can use CoffeeScript in this file: http://coffeescript.org/

/*global $*/

// ユーザマイページでフォローのチェックが押されたらフォローとフォロワーを削除/作成
$(document).on('turbolinks:load', function(){
  $('.follow__check-box').on('click', function(){
    console.log('チェックボックス押されたぜ？')
    // public/followsコントローラにログインユーザidと対象者のidを送る
    // トグル処理はコントローラに一任する
    console.log($(this).data('the-other-id'))
    $.ajax({
      url: 'follows/toggle',
      type: 'GET',
      data: {
        the_other_id: $(this).data('the-other-id')
      }
    })
    .done(function(response){
      // 成功しても特に何もしない
    })
    .fail(function(response){
    });

  });
});