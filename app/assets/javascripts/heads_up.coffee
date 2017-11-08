# App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",

#   entered_room: (data) ->
#     alert "aiue"
#     $('#users').append(data)
$(document).on 'turbolinks:load', -> 
  $('button.seat').click ()->
    App.heads_up_room.entered()

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.ready', ->
    console.log("st")
    App.heads_up_room.ready()

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.clear', ->
    console.log("clear")
    App.heads_up_room.clear()
# testfunc = ->
#   alert("here")
#   App.heads_up_room.entered()