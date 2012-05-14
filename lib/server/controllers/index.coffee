_ = require 'underscore'
logger = require '../logger'


GameController = require './game-controller'
PlayerController = require './player-controller'

controllers =
  Game: new GameController()
  Player: new PlayerController()


module.exports = (socket) ->
  # TODO timeout?
  socket.on 'syncRequest', (req) ->
    logger.verbose "Received sync request"
    
    res =
      success: (res) ->
        logger.info "Emit sync response"
        socket.emit "syncResponse-#{req.requestID}", {success: res}
      error: (err) ->
        socket.emit "syncResponse-#{req.requestID}", {error: err}

    req.socket = socket
    req.address = socket.handshake.address
    
    controllers[req.controller].handle req, res
