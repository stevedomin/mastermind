# -------------------------
# Dependencies
# -------------------------

RealTimeController = require './realtime-controller'
ServerPlayer = require '../models/server-player'

_ = require 'underscore'

# -------------------------
# Class Implementation
# -------------------------

module.exports = class PlayerController extends RealTimeController
  Model: ServerPlayer
