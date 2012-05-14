# -------------------------
# Dependencies
# -------------------------

SharedGame = require '../shared/game'
Board = require './board'

_ = require 'underscore'

# -------------------------
# Class Implementation
# -------------------------

module.exports = class Game extends SharedGame
  
  initialize: (attrs) ->
    super this, arguments
    
    @set 'level', 4
    @set 'attempts', 2
    
    @gameClientID = Math.round Math.random() * 10000
    @board = new Board @get('level'), @get('attempts')
    
    @hostPlayerScore = 0
    @clientPlayerScore = 0
    
    @moves = []
    @locks = []
    @checks = []

    # hostPlayer is the first active player
    @set 'activePlayerID', @get('hostPlayerID')
    @set 'activeRow', 0
    
    @bindModel()
  
  bindModel: () ->
    console.log ("[Game] Bind model")
    
    #any time the next move changes, update the game
    # Add event listener for nextMove
    @on 'change:nextMove', () =>
      console.log "[Game] nextMove changed"
      
      return unless @get('nextMove') isnt null
      
      # every game instance updates itself
      # attenuate self notifications
      if @get('nextMove').gameClientID is @gameClientID
        # broadcast this game's lastMove change
        console.log '[Game] calling save'
        @save()
        
      # propogate changes in this game
      @updateGame('move')
    
    @on 'change:nextLock', () =>
      console.log "[Game] nextLock changed"
      # every game instance updates itself
      # attenuate self notifications
      if @get('nextLock').gameClientID is @gameClientID
        # broadcast this game's lastLock change
        console.log '[Game] calling save'
        @save()
        
      # propogate changes in this game
      @updateGame('lock')
      
    @on 'change:nextCheck', () =>
      console.log "[Game] nextCheck changed"
      # every game instance updates itself
      # attenuate self notifications
      if @get('nextCheck').gameClientID is @gameClientID
        # broadcast this game's lastCheck change
        console.log '[Game] calling save'
        @save()
        
      # propogate changes in this game
      @updateGame('check')
    
    @on 'change:master', () =>
      console.log "[Game] master change", @get('master')
      # every game instance updates itself
      # attenuate self notifications
      if @get('master').gameClientID is @gameClientID
        # broadcast this game's lastCheck change
        console.log '[Game] calling save'
        @save()
        
      # Propogate changes in this game
      @updateGame('masterIsDefined')
  
  
  isValidNextMove: (nextMove) ->
    # If the two players ain't here
    return false unless @get('hostPlayerID') and @get('clientPlayerID')
          
    # If @activePlayer win we need to reset the board
    return false unless not @get 'winnerID'
  
    # If nextMove player isn't activePlayer
    return false unless nextMove.playerID is @get 'activePlayerID'
    
    return true
  
  move: (row, column, peg, playerID) ->
    console.log "[Game] move"
    nextMove = 
      gameClientID: @gameClientID
      playerID: playerID
      row: row
      column: column
      peg: peg
    
    console.log "[Game][move] nextMove", nextMove
    
    if @isValidNextMove nextMove
      @set 'nextMove', nextMove
  
  lock: (row, playerID) ->
    console.log "[Game] lock"
    
    nextLock = 
      gameClientID: @gameClientID
      playerID: playerID
      row: row
      
    console.log "[Game][lock] lockedRow", nextLock
    
    @set 'nextLock', nextLock
    
  check: (row, gcgp, gcwp, playerID) ->
    console.log "[Game] check"
    
    nextCheck = 
      gameClientID: @gameClientID
      playerID: playerID
      row: row
      gcgp: gcgp
      gcwp: gcwp
      
    console.log "[Game][check] checkedRow", nextCheck
    
    console.log @get('nextCheck'), nextCheck
    @set 'nextCheck', nextCheck
  
  updateGame: (type) ->
    console.log "[Game] updateGame"
    
    if type is 'move'
      # Get the next move
      nextMove = @get 'nextMove'
      
      # If this is the first move, we hide alert
      if @moves.length is 0
        @trigger 'closeAlert'
      
      # keep our move log
      @moves.push nextMove
      
      console.log "[Game][updateGame] nextMove", nextMove
      
      @board.setCell nextMove.row, nextMove.column, nextMove.peg
    
    if type is 'lock'
      # Get the next lock
      nextLock = @get 'nextLock'
      
      # If this is the first move, we hide alert
      if @locks.length is 0
        @trigger 'showFirstLockAlert'
      
      @locks.push nextLock
      
      @board.lockRow nextLock.row
    
    if type is 'check'
      # Get the next check
      nextCheck = @get 'nextCheck'
      console.log "Next check", nextCheck
      
      # If this is the first move, we hide alert
      if @checks.length is 0
        @trigger 'closeAlert'
      
      @checks.push nextCheck
      
      # when winning move activePlayer
      @set 'winnerID', if nextCheck.gcgp is "4" then @get('activePlayerID') else null

      # If no winner we check for remaining attempts
      if not @get('winnerID')
        
        console.log "There is no winner yet", @locks.length, @get('attempts')
        if @locks.length < @get('attempts')
          console.log "You have attempts left"
          
          @board.setCellCheckResponse nextCheck.row, nextCheck.gcgp, nextCheck.gcwp
          
        else
          @set 'winnerID', -1
        
          @computeScore()
      else
        console.log "Winner : #{@get('winnerID')}"

        @computeScore()
              
      
    if type is 'masterIsDefined'
      @trigger 'masterIsDefined'
      
    # signal that the game state has
    # been updated, this is a custom event as
    # it distinguishes from 'change' events that
    # would be triggered off model changes like active
    # state change
    @trigger 'gameUpdate'
  
  computeScore: () ->
    if @get('activePlayerID') is @get('hostPlayerID')
      console.log "active is host", @get('attempts'), @locks.length
      @hostPlayerScore += @get('attempts') - @locks.length
    else
      console.log "client is host", @get('attempts'), @locks.length
      @clientPlayerScore += @get('attempts') - @locks.length
  
  invertRole: () ->    
    console.log '[Game] invertRole'
    
    # Toggle the active player
    @set 'activePlayerID', if @get('activePlayerID') is @get('hostPlayerID') then @get('clientPlayerID') else @get('hostPlayerID')
    console.log "Active player is now #{if @get('meID') is @get('activePlayerID') then 'me' else 'ther other guy'}"
    
    @dumpGame()
  
  dumpGame: () ->
    console.info '[Game] Dump game'
    
    @moves = []
    @locks = []
    @checks = []
    
    @.off("change:nextMove")
    @.off("change:nextLock")
    @.off("change:nextCheck")
    @.off("change:master")
    
    @set 'activeRow', 0
    console.log "ACTIVE ROW", @get('activeRow')
    @set 'nextMove', null
    console.log "NEXT MOVE", @get('nextMove')
    @set 'nextLock', null
    console.log "NEXT LOCK", @get('nextLock')
    @set 'nextCheck', null
    console.log "NEXT CHECK", @get('nextCheck')
    @set 'master', null
    console.log "MASTER", @get('master')
    
    @bindModel()
    
    @board.dumpBoard()
    
  toJSON: () ->
    json = SharedGame.prototype.toJSON.apply this, arguments
    
    # Don't sync the client computed values
    delete json.activePlayerID
    delete json.winnerID
    
    # in intial unjoined game state, send else remove meId
    delete json.meID unless not @get('hostPlayerID') and not @get('clientPlayerID')
    
    return json

  # overide parse function
  parse: (attrs) ->
    console.log "[Game] parse"
    parsed = SharedGame.prototype.parse.apply this, arguments
    # we only sync the next move

    # state the client game computes
    parsed.meID = @get 'meID'
    parsed.winnerID = @get 'winnerID'

    return parsed

