# -------------------------
# Dependencies
# -------------------------

Controller = require './controller'
UpdateChannel = require './update-channel'

logger = require '../logger'

pendingUpdatesByClient = {}

# -------------------------
# Class Implementation
# -------------------------

module.exports = class RealTimeController extends Controller
  initialize: () ->
    # wire the asynchronous updates
    @updateChannel = new UpdateChannel {channelID: 'instanceChange'}
    
    # add the update channel to the Model class, binding
    # in the newly instanced channel
    self = this
    @Model = @Model.extend
      # the natural is to add intialize and self on('instanceChange'...
      # check for gargbage collection issues
      triggerInstanceChange: (opts) ->
        logger.info "[Model] Triggering change notification"
        # filter any pending updates, to avoid getting
        # signaled back on your own change
        # server updates go unfiltered
        logger.info '[Model] Server change', opts.serverUpdate
        self.updateChannel.broadcast @, if opts.serverUpdate then {} else pendingUpdatesByClient
    
  # any objects read through the real-time controller
  # have real-time channels associated with the objects
  read: (req, res) ->
    logger.verbose "[RealTimeController] read"
    # model should come in with enough info to
    # perform a fetch
    model = new @Model req.model
    # model has to be populated with at least an id
    model.fetch
      success: (fetchedModel) =>
        # anytime client successfuly reads a
        # realtime model
        # the client socket as a listner
        # to the update channel
        res.success fetchedModel
        @updateChannel.addListener fetchedModel.id, req.socket
      error: (err) ->
        res.error err

  # updates that come through the controller
  # propogate change through open client channels
  update: (req, res) ->
    logger.verbose "[RealTimeController] update"
    updatedModel = new @Model req.model
    logger.info "[RealTimeController][update] Adding to client filter: #{req.socket.id}"
    pendingUpdatesByClient[req.socket.id] = true
    updatedModel.save null,
      success: (updatedModel) ->
        logger.info "[RealTimeController][update] Removing to client filter: #{req.socket.id}"
        delete pendingUpdatesByClient[req.socket.id]
        res.success updatedModel
      error: (err) ->
        logger.info "[RealTimeController][update] Removing to client filter: #{req.socket.id}"
        delete pendingUpdatesByClient[req.socket.id]
        res.error err

  # any objects create through a real-time controller
  # have a real-time channel associted with the object
  create: (req, res) ->
    logger.verbose "[RealTimeController] create" 
    # register the player
    newModel = new this.Model req.model
    
    newModel.save null,
      success: (newModel) =>
        logger.info "[RealTimeController][create] Save succes"
        res.success newModel
        # anytime a realtime model is created the client socket is added to 
        # updateChannel listeners
        @updateChannel.addListener newModel.id, req.socket
     error: (err) ->
       logger.error "[RealTimeController][create] Create error for model", err
       res.error err