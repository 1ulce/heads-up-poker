
# timeoutId = null
# timebankId = null

# $(document).on 'turbolinks:load', -> 
#   App.heads_up_room.load_page()

# $(document).on 'turbolinks:load', -> 
#   $(document).off 'click', 'button.seat'
#   $(document).on 'click', 'button.seat', ->
#     App.heads_up_room.entered()

#   $(document).off 'click', 'button.ready'
#   $(document).on 'click', 'button.ready', ->
#     this.disabled = true
#     App.heads_up_room.ready()

#   $(document).off 'click', 'button.clear_table'
#   $(document).on 'click', 'button.clear_table', ->
#     App.heads_up_room.clear_table()

#   $(document).off 'click', 'button.fold'
#   $(document).on 'click', 'button.fold', ->
#     App.heads_up_room.action("f")
#     $('.actions').html("")
#     console.log("timeoutid = #{timeoutId}")
#     console.log("timebankid = #{timebankId}")
#     clearTimeout(timeoutId)
#     clearTimeout(timebankId)

#   $(document).off 'click', 'button.check'
#   $(document).on 'click', 'button.check', ->
#     App.heads_up_room.action("x")
#     $('.actions').html("")
#     console.log("timeoutid = #{timeoutId}")
#     console.log("timebankid = #{timebankId}")
#     clearTimeout(timeoutId)
#     clearTimeout(timebankId)

#   $(document).off 'click', 'button.call'
#   $(document).on 'click', 'button.call', ->
#     App.heads_up_room.action("c")
#     $('.actions').html("")
#     console.log("timeoutid = #{timeoutId}")
#     console.log("timebankid = #{timebankId}")
#     clearTimeout(timeoutId)
#     clearTimeout(timebankId)

#   $(document).off 'click', 'button.bet'
#   $(document).on 'click', 'button.bet', ->
#     ranges = $('.actions .hidden').text().split("~")
#     amount = 0
#     until parseInt(ranges[0], 10) <= amount <= parseInt(ranges[1], 10)
#       return if amount == null
#       amount = prompt("額を入力してください(#{ranges[0]}~#{ranges[1]})")
#     App.heads_up_room.action("b", amount)
#     $('.actions').html("")
#     console.log("timeoutid = #{timeoutId}")
#     console.log("timebankid = #{timebankId}")
#     clearTimeout(timeoutId)
#     clearTimeout(timebankId)

#   $(document).off 'click', 'button.raise'
#   $(document).on 'click', 'button.raise', ->
#     ranges = $('.actions .hidden').text().split("~")
#     amount = 0
#     until parseInt(ranges[0], 10) <= amount <= parseInt(ranges[1], 10)
#       return if amount == null
#       amount = prompt("額を入力してください(#{ranges[0]}~#{ranges[1]})")
#     App.heads_up_room.action("r", amount)
#     $('.actions').html("")
#     console.log("timeoutid = #{timeoutId}")
#     console.log("timebankid = #{timebankId}")
#     clearTimeout(timeoutId)
#     clearTimeout(timebankId)
