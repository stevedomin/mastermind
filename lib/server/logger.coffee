# -------------------------
# Dependencies
# -------------------------

winston = require 'winston'

module.exports = logger = new (winston.Logger)
  transports: [
    new (winston.transports.Console)
      level: 'verbose'
      colorize: true
      timestamp: true
    #new (winston.transports.File)({ filename: 'masterpliz.log' })
  ]