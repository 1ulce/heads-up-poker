App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    #alert "hell"

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    $('#users').append(data)
    #alert data['user']
    console.log(data)
    #App.heads_up_room.entered_room(data)
  entered: ->
    @perform 'entered'
    alert "hello"
    console.log('hi')

  finished: ->
    @perform 'finished'

  put_message: (msg) ->
    alert "hell"
    @perform('put_message', { message: msg })

  stop_stream: () ->
    @perform 'stop_stream'

