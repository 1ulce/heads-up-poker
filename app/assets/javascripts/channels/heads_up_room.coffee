App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    #alert "hell"

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel

  entered: ->
    alert "entered"
    #@perform 'entered'

  finished: ->
    @perform 'finished'

  $ ->
    $('a').click (e)->
      App.heads_up_room.entered()