// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.
//
//= require action_cable
//= require_self
//= require_tree ./channels

(function() {
  this.App || (this.App = {});

  /*global ActionCable*/
  App.cable = ActionCable.createConsumer();
  console.log('cable.js#App.cable:');
  console.log(`${App.cable}`);
  
}).call(this);