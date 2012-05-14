# -------------------------
# Dependencies
# -------------------------

Model = require './model'

# -------------------------
# Class Implementation
# -------------------------

# Game consists of player*(s), a gameId and a lastMove
module.exports = class SharedGame extends Model
  # Make model schema explicit
  defaults:
    hostPlayerID:null
    clientPlayerID:null
    nextMove:null
    nextLock:null
    winnerID:null

  controller: 'Game'
