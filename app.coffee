# -------------------------
# Dependencies
# -------------------------

express = require 'express'
logger = require './lib/server/logger'
RedisStore = require('connect-redis') express

# -------------------------
# Constants
# -------------------------

PORT = 3000

# -------------------------
# Variables
# -------------------------

app = module.exports = express.createServer()

# ln -s ./lib/shared ./lib/client/shared
bundle = require('browserify')
  entry: __dirname + '/lib/client/index.coffee'
  watch: true

# Server Configuration
app.configure () ->
  app.use express.bodyParser()
  app.use express.methodOverride()

  # static files
  app.use express.static __dirname + '/public'
  
  app.use bundle

  # Session support
  app.use express.cookieParser()
  app.use express.session
    secret: "mindmasterpliz"
    store: new RedisStore()

# Server Routes
app.listen 3000

logger.info "Server listening at http://localhost:#{PORT}/"


io = require('socket.io').listen app
io.set 'log level', 1

io.sockets.on 'connection', (socket) ->
  require('./lib/server/controllers') socket
