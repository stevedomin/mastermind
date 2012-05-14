# -------------------------
# Dependencies
# -------------------------

Model = require '../../shared/model'

logger = require '../logger'

# -------------------------
# Class Implementation
# -------------------------

module.exports = class Controller extends Model
  # this allows sub-class to hook into initialize
  #@initialize.apply this, arguments
  
  create: (req, res) ->
    res.error "Method #{req.method} not implemented."
  
  read: (req, res) ->
    res.error "Method #{req.method} not implemented."
  
  update: (req, res) ->
    res.error "Method #{req.method} not implemented."
    
  destroy: (req, res) ->
    res.error "Method #{req.method} not implemented."
    
  #index
  handle: (req, res) ->
    logger.info "[Controller][handle] Handling request #{req.controller} / #{req.method}"
    @[req.method](req, res)