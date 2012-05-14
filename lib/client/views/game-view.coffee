# -------------------------
# Dependencies
# -------------------------

Player = require '../shared/player'

View = require './view'
BoardView = require './board-view'

_ = require 'underscore'


# -------------------------
# Class Implementation
# -------------------------

# <b>GameView</b> is constructed as a composite of a <b>BoardView</b>
# and additional elements that show the current game states
module.exports = class GameView extends View
  el: $('#game')
  
  initialize: () ->
    console.log "[GameView] initialize"
    
    # Create Player model and fetch them
    @hostPlayer = new Player {id: @model.get 'hostPlayerID'}
    @clientPlayer = new Player {id: @model.get 'clientPlayerID'}
    
    # Handle player name change
    @hostPlayer.on 'change', (updatedPlayer) =>
      @setNameAndAvatar '#hostPlayer', updatedPlayer

    @clientPlayer.on 'change', (updatedPlayer) =>
      @setNameAndAvatar '#clientPlayer', updatedPlayer
    
    # Fetch player models
    @hostPlayer.fetch()
    @clientPlayer.fetch()
    # Initialize active player
    @setActivePlayer()
    
    # Add event handler to show game update
    @model.on 'gameUpdate', () =>
      @updateGame()
      
    # Add event handler for master defined
    @model.on 'masterIsDefined', () =>
      @masterIsDefinedHandler()
    
    # Add event handler for hiding alet
    @model.on 'closeAlert', () =>
      @closeAlert()
      
    @model.on 'showFirstLockAlert', () =>
      if @model.get('meID') is @model.get('activePlayerID')
        @displayAlert '-info', 'Ok.', 'Now you need to wait that your opponent check your attempt'
      else
        @displayAlert '-info', '', 'You can now check your opponent first guess !'
    
    @boardView = new BoardView {el:$('#board'), model:@model}
    @addBoardHandlers()
    
    # Remove waiting spinner and text
    $('#waiting').remove()
    
    # Add handler on end game modal's invert button
    $('#invertRoleButton').click (e) =>
      @model.invertRole()
      @boardView.resetBoard()
      $('#endGameModal').modal('toggle')
    
    # Display alert while master combination isn't set
    console.log @model.get('meID'), @model.get('activePlayerID')
    if @model.get('meID') is @model.get('activePlayerID')
      @displayAlert '-info', '', 'You need to wait that your opponent set his master combination'
    else
      @displayAlert '-info', 'First,', 'you need to set your master combination. This is the last line in the board. Click on the pegs to define it'
  
  addBoardHandlers: () ->
    # attach the element and model dynamically
    # the board element is not known until the game
    # element is rendered
    @boardView.on 'pegClick', (params) =>
      console.log "[GameView] BoardView peg click", params
      @model.move params.row, params.column, params.peg, @model.get('meID')
    
    @boardView.on 'rowLocked', (params) =>
      console.log "[GameView] BoardView row locked", params
      @model.lock params.row, @model.get('meID')
      
    @boardView.on 'rowChecked', (params) =>
      console.log "[GameView] BoardView row checked", params
      @model.check params.row, params.gcgp, params.gcwp, @model.get('meID')
    
    # Add an handler to track when master is defined
    @boardView.on 'masterIsDefined', () =>
      console.log "[GameView] BoardView master is defined"
      
      console.log @model.get('master')
      
      @model.set 'master', 
        state: true
        gameClientID: @model.gameClientID
      
  render: () ->
        
  updateGame: () ->
    console.log "[GameView] updateGame"
        
    # Switch active player
    # @setActivePlayer()
    
    # if there is a winner, show
    
    winnerID = @model.get 'winnerID'
    if winnerID
      endGameHeader = ''
      endGameBody = ''
      
      if winnerID isnt -1
        console.log 'Got winner'
        
        # We display an alert to indicate that the player win
        if @model.get('meID') isnt @model.get('activePlayerID')
          endGameHeader = "Your opponent find your combination"
          endGameBody = "It's now your turn to find his combination. <br />Click ok to start a new round."
        else
          endGameHeader = "Great ! You find your opponent's combination !"
          endGameBody = "It's now your turn to define a combination for him. <br />Click ok to start a new round."
      else    
        # We display an alert to indicate that the player win
        if @model.get('meID') isnt @model.get('activePlayerID')
          endGameHeader = "Your opponent failed to find your combination"
          endGameBody = "It's now your turn to find his combination. <br />Click ok to start a new round."
        else
          endGameHeader = "Too bad ! You didn't find your opponent's combination !"
          endGameBody = "It's now your turn to define a combination for him. <br />Click ok to start a new round."
      
      $('#endGameModal .modal-header h3').html endGameHeader
      $('#endGameModal .modal-body p').html endGameBody
      
      $('#endGameModal').modal('toggle')      
        
      # Hide the check response form
      $("#check-response").addClass 'hide'
        
      $('#score h2').text "#{@model.hostPlayerScore} - #{@model.clientPlayerScore}"
  
  displayAlert: (type = "", title = "", message = "", autoHide = false, delay = 5000) ->
    # We create the alert
    alert = """
      <div class="alert alert#{type} fade in hide">
        <button class="close" data-dismiss="alert">×</button>
        <strong>#{title}</strong> #{message}
      </div>
      """
    # We add it to the alert area
    $("#alert-area").append $(alert)
    # We show it with a slideDown effect from jQuery
    $('.alert').slideDown()
    
    if (autoHide)
      # We hide it 2000s later
      @delay delay, ->
        $('.alert').slideUp 400, ->
          $('.alert').alert('close')
  
  closeAlert: () ->
    # Close all alerts
    $('.alert').alert('close')
  
  setActivePlayer: () ->
    console.log "Set active player"
    if @model.get('activePlayerID') is @model.get('hostPlayerID')
      $('#hostPlayer').addClass 'active-player'
      $('#clientPlayer').removeClass 'active-player'
    else
      $('#hostPlayer').removeClass 'active-player'
      $('#clientPlayer').addClass 'active-player'
  
  setNameAndAvatar: (playerDOM, player) ->
    console.log "setNameAndAvatar : #{player.get 'name'} / #{player.get 'avatarImg'}"
    if player.get 'avatarImg'
      $(playerDOM+"-img").attr "src", player.get 'avatarImg'
      
    $(playerDOM + " h2").html player.get('name')
  
  # -------------------------
  #  Event Handlers
  # -------------------------
  
  masterIsDefinedHandler: () ->
    console.log "[GameView] masterIsDefinedHandler"
    # Close "master combination" alert
    $('.alert').alert('close')
    
    if @model.get('meID') is @model.get('activePlayerID')
      @displayAlert '-info', 'Master combination is set !', 'You can start choosing pegs color'
    else
      @displayAlert '-info', 'Great !', 'Now you need to wait that your opponent make it\'s first guess'
  
  # -------------------------
  #  Utility Methods
  # -------------------------
  
  # Wrapper for setTimeout with a cleaner syntax (callback is the last arg)
  delay: (ms, func) -> setTimeout func, ms
