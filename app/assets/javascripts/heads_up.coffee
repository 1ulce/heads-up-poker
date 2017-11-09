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

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.fold', ->
    App.heads_up_room.action("f")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.check', ->
    App.heads_up_room.action("x")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.call', ->
    App.heads_up_room.action("c")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.bet', ->
    amount = prompt("額を入力してください")
    App.heads_up_room.action("b", amount)

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.raise', ->
    amount = prompt("額を入力してください")
    App.heads_up_room.action("r", amount)

# $(document).on 'turbolinks:load', -> 
#   $(document).on 'click', 'button.allin', ->
#     App.heads_up_room.action("a")

# testfunc = ->
#   alert("here")
#   App.heads_up_room.entered()