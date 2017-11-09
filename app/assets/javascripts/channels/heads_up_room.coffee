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

  put_message: (msg) ->
    alert "hell"
    @perform('put_message', { message: msg })

  stop_stream: () ->
    @perform 'stop_stream'

  start: () ->
    alert 'game start'
    @perform 'start2'

  ready: () ->
    $('#ready').remove()
    @perform 'ready'

  clear: ->
    @perform 'clear'

  show_action: ->
    $('.actions').html("")
    $('.actions').append('<button class="fold"> fold </button>')
    $('.actions').append('<button class="call"> call </button>')
    $('.actions').append('<button class="check"> check </button>')
    $('.actions').append('<button class="bet"> bet </button>')
    $('.actions').append('<button class="raise"> raise </button>')
    $('.actions').append('<button class="allin"> allin </button>')
    $('.actions').append('<div class="amount"></div>')

  action: (name, amount=0) ->
    @perform 'action', data: [name, amount]
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
    result = data.cards.split(",")
    $('#me .hand').html("<card>#{result[0]}</card><card>#{result[1]}</card>")

  actions['deal_button'] = (data) ->
    $(".button").html("")
    $(".board").html("")
    $(".player_#{data.id} .button").html("dealer button")

  actions['deal_board'] = (data) ->
    $(".board").html("#{data.board}")

  actions['set_id'] = (data) ->
    for user,idx in data.players
      for n in [0..$('.user').length-1]
        name = $(".user:eq(#{n})").text()
        if user == name
          $(".user:eq(#{n})").addClass("player_#{idx + 1}")

  actions['urge_action'] = (data) ->
    $('.actions').html("")
    for action in data.actions
      switch action
        when "f" then $('.actions').append('<button class="fold"> fold </button>')
        when "c" then $('.actions').append('<button class="call"> call </button>')
        when "x" then $('.actions').append('<button class="check"> check </button>')
        when "b" 
          $('.actions').append('<button class="bet"> bet </button>')
          $('.actions').append("<div class=hidden'>#{data.bet_amounts[0]}~#{data.bet_amounts[1]}</div>")
        when "r" 
          $('.actions').append('<button class="raise"> raise </button>')
          $('.actions').append("<div class='hidden'>#{data.raise_amounts[0]}~#{data.raise_amounts[1]}</div>")
        when "a" then $('.actions').append('<button class="allin"> allin </button>')
    $('.actions').append('<div class="amount"></div>')

  actions['start'] = (data) ->
    alert "let's start"

  actions['info'] = (data) ->
    console.log(data.info)

  actions['show_stack'] = (data) ->
    $(".player_#{data.id} .stack").html("#{data.stack}")

  actions['show_betting'] = (data) ->
    $(".player_#{data.id} .betting").html("#{data.betting}")

