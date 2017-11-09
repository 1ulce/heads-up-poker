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
  $(document).on 'click', 'button.show_action', ->
    App.heads_up_room.show_action()

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.fold', ->
    App.heads_up_room.action("fold")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.check', ->
    App.heads_up_room.action("check")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.call', ->
    App.heads_up_room.action("call")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.pre_bet', ->
    $('.actions .amount').html("<div><h5>how much you bet?</h5><input name='_text' type='text' value='' /></div><button class=bet>bet!</button>")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.pre_raise', ->
    $('.actions .amount').html("<div><h5>how much you raise?</h5><input name='_text' type='text' value='' /></div><button class=raise>raise!</button>")

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.bet', ->
    amount = $(':text[name="_text"]').val()
    App.heads_up_room.action("bet", amount)

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.raise', ->
    amount = $(':text[name="_text"]').val()
    App.heads_up_room.action("raise", amount)

$(document).on 'turbolinks:load', -> 
  $(document).on 'click', 'button.allin', ->
    App.heads_up_room.action("allin")

# testfunc = ->
#   alert("here")
#   App.heads_up_room.entered()