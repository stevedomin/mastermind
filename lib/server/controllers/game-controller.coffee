# -------------------------
# Dependencies
# -------------------------

Promise = require('node-promise').Promise
all = require('node-promise').all

RealTimeController = require './realtime-controller'
Game = require '../models/game'
ServerPlayer = require '../models/server-player'

_ = require 'underscore'
logger = require '../logger'

# -------------------------
# Class Implementation
# -------------------------

module.exports = class GameController extends RealTimeController
  Model: Game
  
  initialize: () ->
    super this, arguments
  
  create: (req, res) ->
    if @pendingPlayer && not _.isEqual req.address, @pendingPlayer.address
      hostPlayer = @playerPromise new ServerPlayer {id:@pendingPlayer.playerID}
      clientPlayer = @playerPromise new ServerPlayer {id:req.model.meID}
      
      all(hostPlayer, clientPlayer).then (results) =>
        logger.info "[GameController][create] All promises resolved"
        newGame = new Game 
          hostPlayerID: results[0].get 'id'
          clientPlayerID: results[1].get 'id'
          activePlayerID: results[0].get 'id' # hostPlayer is the first active
        
        newGame.save null, 
          success: (newGame) =>
            logger.verbose "[GameController][create] newGame.save success"
            
            res.success newGame
            @pendingPlayer.res.success newGame
            
            # anytime an realtime model is created
            # the client socket is added to the set
            # updateChannel listeners
            @updateChannel.addListener newGame.get('id'), @pendingPlayer.socket
            @updateChannel.addListener newGame.get('id'), req.socket
            
          error: (err) ->
            res.error err
    else
      logger.info "[GammeController][create] Setting player in pending state"
      @pendingPlayer = 
        playerID: req.model.meID
        socket: req.socket
        res: res
        address: req.address
  
  playerPromise: (player) ->
    promise = new Promise()
    player.fetch
      success: (fetchedPlayer) ->
        # deliver fetched player        
        console.log fetchedPlayer   
        promise.resolve fetchedPlayer
      error: (err) ->
        promise.reject err
    
    return promise

