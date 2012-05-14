# -------------------------
# Dependencies
# -------------------------

_ = require 'underscore'
SharedGame = require '../../shared/game'

# Add the localStorage plug-in for player
Store = require '../backbone-memstorage'

# -------------------------
# Class Implementation
# -------------------------

# Define the server game
module.exports = class Game extends SharedGame
  # server game objects keep track of live gamess
  initialize: () ->
    # super
    super this, arguments
    
    @localStorage = new Store()
