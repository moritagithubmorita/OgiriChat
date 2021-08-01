/*global $*/

/* 対戦の各フェーズのdelay。battle()で使用
   1.各お題の開始時間からのdelay
    SET_DELAY/START_ANSWER_DELAY/FINISH_ANSWER_DELAY
   2.対戦終了時間からのdelay
    FINISH_BATTLE_DELAY
*/
var SET_DELAY = 2000
var START_ANSWER_DELAY = 3000
var FINISH_ANSWER_DELAY = 123000
var FINISH_BATTLE_DELAY = 2000

var connected_channel_count = 0 // 接続済みチャンネル数
var submit_is_active = false  //submit送信の有効/無効
var enter_is_active = false //エンターキーの有効/無効
var answerChannels = {} // チャンネルサブスクリプションs
var qr_ids = {} // QuestionRoomのids
var current_ac_key = "qr1"  // 現在のお題に紐づいたAnswerChannelを指すキー(answerChannels)
var qr_bodies = {}  // QuestionRoomのお題s

$(document).on('turbolinks:load', function(){
  qr_ids = $('#question').data('question-room-ids') // 今回使う問題のidを取得
  qr_bodies = $('#question').data('question-room-bodies') // 今回使う問題のbodyを取得

  // 回答用のチャンネルをサブスクライブする
  var cnt = 1
  $.each(qr_ids, function(key, value){
    var keyName = "qr"+cnt
    answerChannels[keyName] = App.cable.subscriptions.create({channel: "AnswerChannel", question_room_id: value}, {

      // 全ての回答用チャンネルをサブスクライブできたら対戦を開始する
      connected: function() {
        // Called when the subscription is ready for use on the server
        console.log('connected')
        connected_channel_count+=1

        // 全ての接続が完了したらお題をスタートする
        if(connected_channel_count==Object.keys(qr_ids).length){
          battle_manager()  //対戦を管理する関数
        }
      },

      disconnected: function() {
        // Called when the subscription has been terminated by the server
      },

      // 回答を受け取り表示(append())する
      received: function(data) {
        return $('#answers').append(data['message'])
      },

      // 回答
      // サーバーに回答を送信する
      answering: function(answer) {
        return this.perform('answer', {
              answer: answer
            });
      },

    });
    cnt+=1
  })
})

// 対戦を管理する
function battle_manager(){
  /* 処理内容
    ・対戦をスケジューリングする
      ※setIntervalは使用せず、1回のeachで全ての問題に関するスケジューリングをしてしまう
  */

  // 対戦をスケジューリング
  // 1問目の準備〜3問目の終了処理までのスケジューリング
  var cnt = 1
  $.each(answerChannels, function(key, value){
    battle(cnt)
    cnt+=1
  })

  // 対戦終了
  finish_battle()
}

// 1回の対戦そのもの
function battle(cnt){
  //cnt...現在の出題数

  var elapsed_time = FINISH_ANSWER_DELAY*cnt // 前の問題終了時点までに経過した時間

  // お題を表示
  set_question(qr_bodies[`qr${cnt}_body`], SET_DELAY+elapsed_time)
  // 回答開始
  start_answering(START_ANSWER_DELAY+elapsed_time)
  // 終了
  finish_answering(FINISH_ANSWER_DELAY+elapsed_time, cnt)
}

// お題出題
function set_question(question_room_body, delay){
  setTimeout(function(){
    $('#question').text(question_room_body)
    }
    , delay)
}

// 回答準備
function prepare_answering(){
  // 送信ボタンを有効化
  enable_submit(true)
  // エンターキーを有効化
  enable_enter(true)
}

// 回答開始
function start_answering(delay){
  // 回答準備
  setTimeout(function(){
    prepare_answering()
  }
  ,delay)
}

// 回答終了
function finish_answering(delay, cnt){
  setTimeout(function(){
    $('question').text('終了！');
    // 次のお題の準備
    prepare_for_next(cnt);
  }
  ,delay)
}

// 終了処理、次のお題の準備
function prepare_for_next(cnt){
  // cnt...現在の出題数

  /* 処理内容
    1.enterとsubmitを無効化
    2.フォームに入力中の内容を消す
    3.お題を進める(current_ac_key処理)
  */

  // enterとsubmitを無効化
  enable_enter(false)
  enable_submit(false)

  //フォームに入力中の内容を消す
  $('answer-form').value=""

  // current_ac_keyを進める
  current_ac_key = "qr"+(cnt+1)

}

// 対戦終了
function finish_battle(){
  setTimeout(function(){
    // ねぎらいページへ遷移
    window.location.href = '<%= Rails.application.routes.url_helpers.finish_path %>'+'?qr_id='+qr_ids['qr1_id']
  })
}

// submitボタンを有効/無効
function enable_submit(flag){
  submit_is_active=flag // フラグ処理
  $('#submit').toggleClass("submit--active")  // 色を変える
}

// エンターを有効化
function enable_enter(flag){
  enter_is_active = flag
}

// エンターが押されたらサーバに回答を送信する
// enter_is_activeがfalseなら回答を送らない。
$(document).on('keydown', function(event) {
  if ((event.keyCode === 13)&&(enter_is_active)) {
    answerChannels[current_ac_key].answer($('#answer-form').value);
    $('#answer-form').value = '';
    return event.preventDefault();
  }
});

// submitボタンが押されたらサーバに回答を送信する
// submit_is_activeがfalseなら回答を送らない
$('#submit').on('click', function(event){
  if(submit_is_active){
    answerChannels[current_ac_key].answer($('#answer-form').value);
    $('#answer-form').value = '';
  }
})