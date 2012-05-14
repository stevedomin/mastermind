# -------------------------
# Dependencies
# -------------------------

Model = require '../../shared/model'

_ = require 'underscore'
logger = require '../logger'

# Sockets by model id
listenersByModelID = {}

# -------------------------
# Class Implementation
# -------------------------

module.exports = class UpdateChannel extends Model
  initialize: (opts) ->
    @channelID = opts.channelID

  broadcast: (updatedModel, clientFilter) ->
    logger.verbose "[UpdateChannel] broadcast"
    
    # broadcast message for all the sockets listening
    # on this channel id
    listeners = listenersByModelID[updatedModel.id]
    logger.info "[UpdateChannel][broadcast] Broadcasting update #{updatedModel.id} to : #{if listeners then listeners.length else 0}"
    
    _.each listeners, (socket) =>
      # broadcast to all those not in the client filter
      if not clientFilter[socket.id]
        console.log @channelID
        console.log updatedModel
        socket.emit @channelID, updatedModel
        logger.info "Broadcasting to #{socket.id}"
      logger.info "clientFilter", clientFilter

  addListener: (modelID, clientSocket) ->
    logger.verbose "[UpdateChannel] addListener"
    # channelID's are are bound to clientSockets  
    listeners = listenersByModelID[modelID]
    if listeners is undefined
      # start a new socket list
      listenersByModelID[modelID] = [clientSocket]
    else
      # add to the unique list of client sockets
      if _.indexOf(listeners, clientSocket) is -1
        listenersByModelID[modelID].push clientSocket
