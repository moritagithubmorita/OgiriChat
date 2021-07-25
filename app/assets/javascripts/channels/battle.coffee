$(function(){
  App.battle = App.cable.subscriptions.create {"BattleChannel", question_room_id: $('#match-make').data('question_room_id')}, {
    connected: ->
      # Called when the subscription is ready for use on the server

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (data) ->
      # Called when there's incoming data on the websocket for this channel

      # ユーザが入室するとそのユーザを表示する
      if(data['element']){
        $('#match_make').append(data['element']);
      }
  }
});
