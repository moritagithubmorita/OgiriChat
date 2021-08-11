/*global $*/

$(document).on('turbolinks:load', function(){
  let is_rankup = $('#rankup-modal__area').data('rankup');

  // ランクアップ可能な場合ランクアップモーダルを"表示"する
  if(is_rankup==true){
    $('.rankup-modal').css('display', 'block');
  }
});

$(document).on('turbolinks:load', function(){
// ランクアップモーダルで「やったね！」もしくは「ランクアップする」ボタンが押されたらモーダルを消し、ランクアップ処理をする(ajax)
$('.rankup-modal__ok-button').on('click', function(){
  $('.rankup-modal').css('display', 'none');
  $.ajax({
      url: 'homes/rankup',
      type: 'GET',
      data: {
        do_rankup: true
      }
    })
    .done(function(response){
      // 成功しても特に何もしない
    })
    .fail(function(response){
    });
});

// ランクアップモーダルで「辞退する」もしくは「モーダルを消す」ボタンが押されたらモーダルを消す
$('.rankup-modal__decline-button').on('click', function(){
  $('.rankup-modal').css('display', 'none');
  $.ajax({
      url: 'homes/rankup',
      type: 'GET',
      data: {
        do_rankup: false,
        from_veteran_to_master: true
      }
    })
    .done(function(response){
      // 成功しても特に何もしない
    })
    .fail(function(response){
    });
});

});