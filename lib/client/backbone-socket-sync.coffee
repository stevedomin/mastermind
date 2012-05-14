Backbone = require 'backbone'

_ = require 'underscore'
socket = require './socket'

# -------------------------
#  Variables
# -------------------------

# requestId counter to insure sync message are
# paired correctly
counter = 0

modelRegistryByID = {}

# -------------------------
#  Utility Methods
# -------------------------

# Stolen from Backbone
# Let you safely get the value of the property
# applying function for value, if function provided
getValue = (object, prop) ->
  return null unless (object and object[prop])
  return if _.isFunction(object[prop]) then object[prop]() else object[prop]

# mockey patch this flag so that we can distinguish between Model and
# Collection for the server
# when the socket sync happens, the server can know collection
# vs singleton
Backbone.Collection.prototype.isCollection = true

# -------------------------
#  Overriden Methods
# -------------------------

Backbone.sync = (method, model, options) ->
  console.log "Backbone.sync called"
  
  # TODO options.timeout?
  params = getValue(model, 'params') || {}
  controller = getValue model, 'controller'
  requestID = counter++

  console.log model
  console.log model.toJSON()

  syncRequest =
    requestID: requestID,
    controller: controller,
    method: method,
    model: model.toJSON(),
    params: _.extend _.clone(params), options

  # replace collection read and index to disambiguate singleton and
  # collection
  if model.isCollection
    # map 'read' on collection to 'index'
    syncRequest.method = 'index';
  else if syncRequest.method is 'delete'
    # map 'delete' to 'destroy' since 'delete' is a keyword
    syncRequest.method = 'destroy'

  console.log "Emit sync request"
  socket.emit 'syncRequest', syncRequest

  # TODO: need to handle errors
  socket.once "syncResponse-#{requestID}", (res) ->
    console.log 'Received sync response'
    if res.error
      options.error res.error
    else if res.success
      # side-effect model attrs first to deal with initial id setting
      console.log 'Sync response with update'
      
      options.success res.success

      # make sure we only hook callback once per model
      registerModelForUpdates model
      
      # when sync is called an implicit subscription
      # for server changes is established
      # set up automated subsciption from server
      # which will trigger 'change' event
      socket.on 'instanceChange', (attrs) ->
        console.log 'Client received instanceChange message'
        updateAllModels(attrs.id, attrs)

# -------------------------
#  Methods
# -------------------------

registerModelForUpdates = (model) ->
  console.log "registering model: #{model.id}"
  if modelRegistryByID[model.id] is undefined
    # hold a reference to the model
    # TODO: add unsubscribe, dangling ref
    modelRegistryByID[model.id] = [model]
  else
    # add to the list of models by registerd to this id
    if _.indexOf(modelRegistryByID[model.id], model) is -1
      modelRegistryByID[model.id].push model

updateAllModels = (id, attrs) ->
  models = modelRegistryByID[id]
  _.each models, (model) ->
    console.log "instance change notified #{model.id}"
    model.set attrs