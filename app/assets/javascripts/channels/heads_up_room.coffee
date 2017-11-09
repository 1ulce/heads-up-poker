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

  show_action: ->
    $('.actions').html("")
    $('.actions').append('<button class="fold"> fold </button>')
    $('.actions').append('<button class="call"> call </button>')
    $('.actions').append('<button class="check"> check </button>')
    $('.actions').append('<button class="pre_bet"> bet </button>')
    $('.actions').append('<button class="pre_raise"> raise </button>')
    $('.actions').append('<button class="allin"> allin </button>')
    $('.actions').append('<div class="amount"></div>')

  action: (name, amount = 0) ->
    switch name
      when "fold"
        console.log(name)
      when "check"
        console.log(name)
      when "call" 
        console.log(name)
        console.log(amount)
      when "bet"
        console.log(name)
        console.log(amount)
      when "raise" 
        console.log(name)
        console.log(amount)
      when "allin"
        console.log(name)
    $('.actions').html('<button class="show_action"> show_action </button>')

  actions['join_me'] = (data)->
    $('#users #me').html(data.users)

  actions['join_rival'] = (data)->
    $('#users #rival').html(data.users)

  actions['filled'] = (data)->
    $('#ready').html('<button class="ready"> ready </button>')

  actions['finished'] = (data)->
    $('#ready').remove()
    alert "game finished"

  actions['deal_hand'] = (data) ->
    console.log(data.cards)
    result = data.cards.split(",")
    $('#me .hand').html("<card>#{result[0]}</card><card>#{result[1]}</card>")

  actions['deal_button'] = (data) ->
    console.log(data.id)
    $(".player_#{data.id} .button").html("dealer button")

  actions['set_id'] = (data) ->
    for user,idx in data.players
      for n in [0..$('.user').length-1]
        name = $(".user:eq(#{n})").text()
        if user == name
          $(".user:eq(#{n})").addClass("player_#{idx + 1}")

  actions['start'] = (data) ->
    alert "let's start"

  actions['info'] = (data) ->
    console.log(data.info)

