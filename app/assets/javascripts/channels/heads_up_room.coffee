actions = {}
timeoutId = null
timebankId = null

$(document).on 'turbolinks:load', -> 
  App.heads_up_room.load_page()

$(document).on 'turbolinks:load', -> 
  $(document).off 'click', 'button.seat'
  $(document).on 'click', 'button.seat', ->
    App.heads_up_room.entered()

  $(document).off 'click', 'button.ready'
  $(document).on 'click', 'button.ready', ->
    this.disabled = true
    App.heads_up_room.ready()

  $(document).off 'click', 'button.clear_table'
  $(document).on 'click', 'button.clear_table', ->
    App.heads_up_room.clear_table()

  $(document).off 'click', 'button.fold'
  $(document).on 'click', 'button.fold', ->
    App.heads_up_room.action("f")
    $('.actions').html("")
    clearTimeout(timeoutId)
    clearTimeout(timebankId)

  $(document).off 'click', 'button.check'
  $(document).on 'click', 'button.check', ->
    App.heads_up_room.action("x")
    $('.actions').html("")
    clearTimeout(timeoutId)
    clearTimeout(timebankId)

  $(document).off 'click', 'button.call'
  $(document).on 'click', 'button.call', ->
    App.heads_up_room.action("c")
    $('.actions').html("")
    clearTimeout(timeoutId)
    clearTimeout(timebankId)

  $(document).off 'click', 'button.bet'
  $(document).on 'click', 'button.bet', ->
    ranges = $('.actions .hidden').text().split("~")
    amount = 0
    until parseInt(ranges[0], 10) <= amount <= parseInt(ranges[1], 10)
      return if amount == null
      amount = prompt("額を入力してください(#{ranges[0]}~#{ranges[1]})")
    App.heads_up_room.action("b", amount)
    $('.actions').html("")
    clearTimeout(timeoutId)
    clearTimeout(timebankId)

  $(document).off 'click', 'button.raise'
  $(document).on 'click', 'button.raise', ->
    ranges = $('.actions .hidden').text().split("~")
    amount = 0
    until parseInt(ranges[0], 10) <= amount <= parseInt(ranges[1], 10)
      return if amount == null
      amount = prompt("額を入力してください(#{ranges[0]}~#{ranges[1]})")
    App.heads_up_room.action("r", amount)
    $('.actions').html("")
    clearTimeout(timeoutId)
    clearTimeout(timebankId)

App.heads_up_room = App.cable.subscriptions.create "HeadsUpRoomChannel",
  connected: ->
    # Called when the subscription is ready for use on the server
    #alert "hell"

  disconnected: ->
    # Called when the subscription has been terminated by the server
    console.log "someone(you) disconnected"
    @perform 'stop_stream'

  received: (data) ->
    actions[data.action](data, this)
    
  entered: ->
    @perform 'entered'
    $('#seat_button').html("")

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

  load_page: ->
    @perform 'load_page'

  clear_table: ->
    @perform 'clear_table'
    $(".result").html("")
    $(".user#me").html("")
    $(".user#rival").html("")
    $(".board").html("")
    $(".pot").html("")
    $(".actions").html("")
    $('#ready').html("")

  # clear_people: ->
  #   @perform 'clear_people'

  action: (name, amount=0) ->
    @perform 'action', data: [name, amount]

  actions['clear_table'] = ->
    $(".result").html("")
    $(".user#me").html("")
    $(".user#rival").html("")
    $(".board").html("")
    $(".pot").html("")
    $(".actions").html("")
    $('#ready').html("")

  actions['clear_seat_button'] = ->
    $('#seat_button').html("")

  actions['clear_ready_button'] = ->
    $('#ready').html("")

  actions['show_seating_button'] = ->
    $('#seat_button').html('<button class="seat"> 着席 </button>')

  actions['render_users_count'] = (data)->
    $('#heads_up_users_count').html("user: #{data.count}/2")

  actions['join_me'] = (data)->
    $('#users #me').html(data.users)

  actions['join_rival'] = (data)->
    $('#users #rival').html(data.users)

  actions['filled'] = (data)->
    $('#ready').html('<button class="ready"> ready </button>')

  actions['deal_hand'] = (data) ->
    result = data.cards.split(",")
    $('#me .hand').html("#{hand_to_img(result[0])}#{hand_to_img(result[1])}")
    $("#rival .hand").html("#{hand_to_img('uk')}#{hand_to_img('uk')}")

  actions['deal_button'] = (data) ->
    $(".button").html("")
    $(".board").html("")
    $(".player_#{data.id} .button").html("dealer button")

  actions['deal_board'] = (data) ->
    cards = data.board.split(",")
    $(".board").html("board: #{hand_to_img(cards[0])}#{hand_to_img(cards[1])}#{hand_to_img(cards[2])}#{hand_to_img(cards[3])}#{hand_to_img(cards[4])}")

  actions['set_id'] = (data) ->
    for user,idx in data.players
      for n in [0..$('.user').length-1]
        name = $(".user .user_session:eq(#{n})").text()
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
          $('.actions').append("<div class='hidden'>#{data.bet_amounts[0]}~#{data.bet_amounts[1]}</div>")
        when "r" 
          $('.actions').append('<button class="raise"> raise </button>')
          $('.actions').append("<div class='hidden'>#{data.raise_amounts[0]}~#{data.raise_amounts[1]}</div>")
        when "a" then $('.actions').append('<button class="allin"> allin </button>')
    $('.actions').append('<div class="timebank"></div>')
    if "f" in data.actions
      set_timebank(20)
      timeoutId = setTimeout ->
        console.log("auto fold")
        App.heads_up_room.action("f")
        $('.actions').html("")
      , 20000
    if "x" in data.actions
      set_timebank(20)
      timeoutId = setTimeout ->
        console.log("auto check")
        App.heads_up_room.action("x")
        $('.actions').html("")
      , 20000

  actions['start'] = (data) ->
    alert "let's start"

  actions['info'] = (data) ->
    console.log(data.info)

  actions['show_stack'] = (data) ->
    $(".player_#{data.id} .stack").html("stack: #{data.stack}")

  actions['show_betting'] = (data) ->
    $(".player_#{data.id} .betting").html("betting: #{data.betting}")

  actions['show_pot'] = (data) ->
    $(".pot").html("pot: #{data.pot}")

  actions['fold'] = (data) ->
    $(".player_#{data.id} .hand").html('<span style="color:red;">fold</span>')
    # $(".player_#{data.id} .hand").html("")

  actions['showdown_opp_hand'] = (data) ->
    result = data.cards.split(",")
    $(".player_#{data.id} .hand").html("#{hand_to_img(result[0])}#{hand_to_img(result[1])}")

  actions['show_result'] = (data) ->
    my_player_num = parseInt($("#me").attr('class').split(" ")[1].slice(-1))
    switch data.result[my_player_num - 1]
      when "win"
        $(".result").html("you win!!")
      when "lose"
        $(".result").html("you lose..")
      else
        $(".result").html("result???")

  hand_to_img = (string) ->
    return "<card><img src='/png/#{string}.png'></card>"

  set_timebank = (int) ->
    counter = 0
    foo = () ->
      $(".timebank").html("#{int-counter}")
      counter++
      timebankId = setTimeout ->
        foo()
      , 1000
      if counter > int
        clearTimeout(timebankId)
    foo()

