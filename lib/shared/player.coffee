# -------------------------
# Dependencies
# -------------------------

Model = require './model'

# -------------------------
# Class Implementation
# -------------------------

module.exports = class Player extends Model
  defaults:
    name: null
  
  controller: 'Player'
