App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    #alert "hell"

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    $('#users').append data['user']
    #alert data['user']

  entered: ->
    @perform 'entered'

  finished: ->
    @perform 'finished'

  $ ->
    $('a').click (e)->
      App.heads_up_room.entered()