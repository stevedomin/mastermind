# -------------------------
#  Dependencies
# -------------------------

Game = require './models/game'
Player = require './shared/player'

GameView = require './views/game-view'

require('backbone').setDomLibrary $

# Override of Backbone.sync
require './backbone-socket-sync'

# -------------------------
#  Methods
# -------------------------

# Configure modal window

playerNameEntered = false

$('#loginForm').submit () ->
  false

# Detect name changing and enable enterGame button
$('#inputName').bind "change keyup input", () ->
  playerNameEntered = true
  $('#enterGame').removeClass 'disabled'

# enterGame button click handler
$('#enterGame').click (e) ->
  if not playerNameEntered
    e.preventDefault()
    return false
  
  # Hide intro modal
  $('#introModal').modal('toggle')
  
  # Show waiting player modal
  #$('#waitingPlayerModal').modal('toggle')
  
  # Add waiting spinner
  opts =
    lines:13 # The number of lines to draw
    length: 7 # The length of each line
    width: 4 # The line thickness
    radius: 13 # The radius of the inner circle
    rotate: 0 # The rotation offset
    color: '#000' # #rgb or #rrggbb
    speed: 0.9 # Rounds per second
    trail: 60 # Afterglow percentage
    shadow: true # Whether to render a shadow
    hwaccel: false # Whether to use hardware acceleration
    className: 'spinner' # The CSS class to assign to the spinner
    zIndex: 2e9 # The z-index (defaults to 2000000000)
    top: 'auto' # Top position relative to parent in px
    left: 'auto' # Left position relative to parent in px
  target = document.getElementById('spinner-container')
  spinner = new Spinner(opts).spin(target)
  
  # Create a new player
  window.player = new Player {name:$('#inputName').val()}
  window.player.save null, 
    success: () ->
      window.playerID = player.get('id')
      console.log player
      window.game = new Game {meID: player.get 'id'}
      game.save null,
        success: (model, response) ->
          # Hide waiting player modal
          #$('#waitingPlayerModal').modal('toggle')
          console.log "The game is joined", game
          
          # Add game view
          window.gameView = new GameView {model:game}
    error: () ->
      console.log arguments
  

# Display intro modal
$('#introModal').modal 'toggle'
