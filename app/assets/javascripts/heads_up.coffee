# App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",

#   entered_room: (data) ->
#     alert "aiue"
#     $('#users').append(data)
$(document).on 'turbolinks:load', -> 
  $('button.seat').click ()->
    App.heads_up_room.entered()

$(document).on 'turbolinks:load', -> 
  $('button.ready').click ()->
    console.log("st")
    App.heads_up_room.start()
# testfunc = ->
#   alert("here")
#   App.heads_up_room.entered()