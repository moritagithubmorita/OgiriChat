/* マッチメイクに関するjs
  1.htmlのdata属性からマッチメイク対象のQuestionRoom(部屋)のidを連想配列で取得
  2.サブスクライブ依頼をサーバーに出し、全ての部屋の接続が成功したら入室したことを最後のチャンネルに伝え、ログインユーザ情報をブロードキャストする。
  3.receivedでユーザ情報をキャッチし、ユーザ情報を表示する
*/

/*global $*/

var connected_room_count = 0  // 接続に成功したチャンネル数

$(document).on('turbolinks:load', function() {
  var qr_ids = $('#match-make').data('question-room-ids');  //全question_room(3つ)のidを連想配列で取得
  var roomChannels = {} // チャンネルサブスクリプション用ハッシュ

  // チャンネルサブスクリプションを作成し、連想配列に格納する
  var count = 1
  $.each(qr_ids, function(key, value){
    var key_name = "roomChannel"+count  // キー作成
     roomChannels[key_name] = App.cable.subscriptions.create({ channel: 'RoomChannel', question_room_id: value },{

      // チャンネルに接続されたら接続カウンタを+1
      // もし全部の部屋に接続できたら入室したことを"最後の部屋のみ"に通知し、ログインユーザ情報をブロードキャストさせる
      connected: function() {
        connected_room_count+=1;

        if(connected_room_count == Object.keys(qr_ids).length){
          this.perform('entered_room',{})
        }
      },

      disconneted: function() {
      },

      // 入室したユーザ情報(外部テンプレート)を受け取り表示する(append)
      received: function(data){
        return $('#match-make').append(data['message']);
      }
    });

    count +=1

  })

});
