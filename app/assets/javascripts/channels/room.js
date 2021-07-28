/*global $*/
$(document).on('turbolinks:load', function() {
  console.log("create")
  var room_id = $('#match-make').data('question-room-id');
  console.log(room_id)
  var roomChannel = App.cable.subscriptions.create({ channel: 'RoomChannel', question_room_id: room_id },{
    connected: function() {
      console.log("connected")
    },

    disconneted: function() {
      console.log("disconnected")
    },

    received: function(data){
      console.log("received")
      return $('#match-make').append(data['message']);
    }

  });

});
