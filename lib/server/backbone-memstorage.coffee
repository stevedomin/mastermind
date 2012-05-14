# Taken from Backbone examples 

# A simple module to replace `Backbone.sync` with *localStorage*-based
# persistence. Models are given GUIDS, and saved into a JSON object. Simple
# as that.

# -------------------------
# Dependencies
# -------------------------

_ = require 'underscore'
Backbone = require 'backbone'

# Generate four random hex digits.
S4 = () ->
   return (((1+Math.random())*0x10000)|0).toString(16).substring(1)

# Generate a pseudo-GUID by concatenating random hexadecimal.
guid = () ->
   return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

data = {}

# Our Store is represented by a single JS object in *localStorage*. Create it
# with a meaningful name, like the name you'd give a table.
module.exports = class Store
  constructor: (@name) ->
    #store = localStorage.getItem this.name
    #@data = (store && JSON.parse store) or {}
    #@data = {}

  # Save the current state of the **Store** to *localStorage*.
  save: () ->
    console.log "[Store] save"
    #localStorage.setItem this.name, JSON.stringify(this.data)

  # Add a model, giving it a (hopefully)-unique GUID, if it doesn't already
  # have an id of it's own.
  create: (model) ->
    model.id = model.attributes.id = guid() unless model.id
    data[model.id] = model
    @save()
    return model

  # Update a model by replacing its copy in `this.data`.
  update: (model) ->
    data[model.id] = model
    @save()
    return model

  # Retrieve a model from `this.data` by id.
  find: (model) ->
    return data[model.id]

  # Return the array of all models currently in storage.
  findAll: () ->
    return _.values data
    
  # Delete a model from `this.data`, returning it.
  destroy: (model) ->
    delete data[model.id]
    @save()
    return model

# Override `Backbone.sync` to use delegate to the model or collection's
# *localStorage* property, which should be an instance of `Store`.
Backbone.sync = (method, model, options) ->
  resp = null
  store = model.localStorage or model.collection.localStorage;
  
  console.log "[Backbone] sync : #{method}"
  
  switch method
    when "read"
      resp = if model.id then store.find model else store.findAll()
    when "create"  
      resp = store.create model
    when "update"
      # pass along the notication opts
      # trigger an instance change if available on model
      model.triggerInstanceChange && model.triggerInstanceChange options
      resp = store.update model                       
    when "delete"  
      resp = store.destroy model
  
  if resp 
    options.success resp
  else
    options.error "Record not found"