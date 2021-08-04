/*global $*/

let niceChannel = null

$(document).on('turbolinks:load', function(){
  niceChannel = App.cable.subscriptions.create("NiceChannel", {
    connected: function() {
      console.log('nice_connected!');
      // Called when the subscription is ready for use on the server
    },

    disconnected: function() {
      // Called when the subscription has been terminated by the server
    },

    // 「押されたナイス要素」の横の「カウンタ要素」を更新する処理(ナイスの数が動的に表示される仕組み)
    received: function(data) {
      // 押されたナイス要素横のカウンタ要素を取得し、値を更新する

      console.log("received!");
      $(`[data-answer-id-total=${data['answer_id']}]`).text(data['total_nice_count'])
    },

    nice: function(answer_id, is_plus, question_room_id){
      console.log("nice")

      return this.perform('nice', {
            answer_id: answer_id,
            is_plus: is_plus,
            question_room_id: question_room_id
          });
    }
  });

})

// niceマークが押されたらブラウザに知らせる
// その際に画像を変える
$(document).on('click', '.answer__nice', function(){
  console.log("niceが押されました");

  //画像を変える
  $(this).toggleClass('answer__nice--active');
  console.log($(this).hasClass('answer__nice--active'));

  //サーバに知らせる
  let answer_id = $(this).data('answer-id');
  niceChannel.nice(answer_id, $(this).hasClass('answer__nice--active'), $('.answer').data('question-room-id'));
});
