actions = {}

App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    #alert "hell"

  disconnected: ->
    # Called when the subscription has been terminated by the server
    alert "someone(you) disconnected"
    @perform 'stop_stream'

  received: (data) ->
    #$('#users').html(data)
    #alert data['user']
    console.log(data.action)
    actions[data.action](data, this)
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

  start: () ->
    alert 'game start'
    @perform 'start2'

  ready: () ->
    @perform 'ready'

  clear: ->
    @perform 'clear'

  actions['join'] = (data)->
    $('#users').html(data.users)

  actions['filled'] = (data)->
    $('#ready').html('<button class="ready"> ready </button>')

  actions['finished'] = (data)->
    $('#ready').remove()
    alert "game finished"

  actions['deal'] = (data) ->
    console.log(data.cards)
    result = data.cards.split(",")
    $('#me .hand').html("<card>#{result[0]}</card><card>#{result[1]}</card>")

  actions['start'] = (data) ->
    alert "let's start"

