/*global $*/
$(document).on('turbolinks:load', function() {
  var qr_ids = $('#match-make').data('question-room-ids');

  var roomChannels = {}
  
  console.log(App.cable);

  var count = 1
  $.each(qr_ids, function(key, value){
    console.log(value)

    var key_name = "roomChannel"+count
     roomChannels[key_name] = App.cable.subscriptions.create({ channel: 'RoomChannel', question_room_id: value },{
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

    count +=1

  })


});
