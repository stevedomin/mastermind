# -------------------------
# Dependencies
# -------------------------

View = require './view'

Player = require '../shared/player'
Peg = require '../shared/peg'

_ = require 'underscore'

# -------------------------
# Class Implementation
# -------------------------

module.exports = class BoardView extends View
  
  initialize: () ->
    # Bind all 
    #_.bindAll(@, 'render', 'cellClicked');
    
    @board = @model.board
    
    @activeEmptyPeg = null
    @activeMasterEmptyPeg = null
    @activeRow = 0
    @masterRow = null
    
    # hange th board scafolding
    @render()
    
    # reflect the cellValue change in view on Backbone <b>change</b> event
    @board.on 'change', (params) =>
      console.log "[BoardView] board change handler", params
      
      cellID = "#cell-#{params.row}-#{params.column}"
      
      # Update the cell
      # TODO check if there is not a better way to do it (method payload)
      cellValue = @board.getCell params.row, params.column
      $(cellID).text cellValue
      $(cellID).addClass "peg-#{cellValue.toLowerCase()}"
      
      # If all the pegs value have been choosed
      # we enable the lock button and add a click handler on it
      if (el for el in $('tr').eq(@activeRow).find("span") when $(el).html() is Peg.EMPTY).length is 0
        $("#lock-button-#{params.row}").removeAttr 'disabled', ''
        $("#lock-button-#{params.row}").click @lockButton_clickHandler
    
    @board.on 'lock', (params) =>
      console.log "[BoardView] board lock handler", params
      
      # If player is not the active player
      # and nextLock row > lastLock row
      # he should check new locked row
      if @model.get('activePlayerID') isnt @model.get('meID')
        console.log "Player isn't active player"
        
        # Show the check response form
        $("#check-response").removeClass 'hide'
        
        # Enable the check button and add a click handler on it
        $("#check-button-#{params.row}").removeAttr 'disabled'
        $("#check-button-#{params.row}").click @checkButton_clickHandler
      else
        # Remove the lock button
        $("#lock-button-#{params.row}").html '<i class="icon-lock icon-white"></i>'
        $("#lock-button-#{params.row}").attr 'disabled', 'disabled'
        
    @board.on 'checked', (params) =>
      console.log "[BoardView] board check handler", params
      
      if @model.get('activePlayerID') isnt @model.get('meID')
        # Remove the check button
        $("#check-button-#{params.row}").remove()
      
      # If the player didn't win
      if params.gcgp isnt 4
        # We show the check response in the column 4
        $("#column-#{params.row}-4").html "#{params.gcgp} - #{params.gcwp}"
        
        # Increment the active row counter
        @setActiveRow @activeRow + 1
      #else
  
  
  render: () ->
    $('#board-container').removeClass 'hide'
    
    l = if @model.get('activePlayerID') isnt @model.get('meID') then @board.attempts else @board.attempts - 1
    for i in [0..l]
      row = $("<tr></tr>").appendTo @$el.find('tbody:last')
      for j in [0..@board.level]
        column = $("<td id='column-#{i}-#{j}'></td>").appendTo row
        if j < @board.level
          # We add Peg cell
          $(column).html @buildEmptyPeg(i, j)
        else
          if @model.get('activePlayerID') is @model.get('meID')
            console.log "Building lock buttons"
            # We add Validation cell
            $(column).html @buildLockButton(i)
          else
            console.log "Building validation buttons"
            # We add Validation cell
            $(column).html @buildCheckButton(i)
            if i is l
              @masterRow = i
              $(column).html @buildMasterButton()
              @addMasterPopoverHandler(i)
    
    @setActiveRow(0)
  
  # Add handler and popover on peg row
  #
  # index    - Row index
  setActiveRow: (index) -> 
    console.log "[BoardView] setActiveRow"
    @activeRow = index 
    
    if @model.get('activePlayerID') is @model.get('meID')
      $("#lock-button-#{index}").toggle 'hide'
      @addPopoverHandler(index)
    else
      $("#check-button-#{index}").removeClass 'hide'
      # Make sure the check response form is hidden
      $("#check-response").addClass 'hide'
             
  
  # Add handler and popover on peg row
  #
  # index    - Row index
  addPopoverHandler: (index) ->
    # We initialize popover
    $("tr").eq(index).find('[rel="popover"]').popover(
      trigger:'manual'
      , content: => return @buildPegChooser()
    )
    .click @emptyPeg_clickHandler
  
  # Add handler and popover on peg row
  #
  # index    - Row index
  addMasterPopoverHandler: (index) ->
    # We initialize popover
    $("tr").eq(index).find('[rel="popover"]').popover(
      trigger:'manual'
      , content: => return @buildPegChooser()
    )
    .click @masterEmptyPeg_clickHandler
  
  # Remove handler and popover on peg row
  #
  # index    - Row index
  removePopoverHandler: (index) ->
    # We initialize popover
    $("tr").eq(index).find('[rel="popover"]').popover('disable').popover("hide")
  
  # Remove all handler and popover on peg row
  #
  # index    - Row index
  removeAllPopoverHandler: () ->
    # We remove all popover
    $("tr").find('[rel="popover"]').popover('disable').popover("hide")
    
  # Build a line of pegs from the peg pool
  #
  buildPegChooser: () ->
    # We build a peg chooser with the pegs from our peg pool
    pegChooser = """<div class="peg-chooser">"""
    for pegIndex in [0..Peg.POOL.length-1]
      pegChooser += @buildPeg(pegIndex)
    pegChooser += "</div>"
    return pegChooser
  
  # Build an empty peg
  #
  # row    - Row of the peg
  # column - Column of the peg.
  buildEmptyPeg: (row, column, badgeType = '') ->
    # We build an empty peg
    return """<span id="cell-#{row}-#{column}" class="badge #{badgeType} peg" rel="popover">#{Peg.EMPTY}</span>"""
  
  # Build a peg for the peg chooser
  #
  # index   - Index of the peg in Peg.POOL
  buildPeg: (index) ->
    # We build a peg from the peg pool
    return """<span class='badge badge-success peg peg-#{Peg.POOL[index]}'>#{Peg.POOL[index].toUpperCase()}</span> """
 
  # Build a lock button
  #
  # index   - Row index
  buildLockButton: (index) ->
    return """
        <a id="lock-button-#{index}" class="btn btn-warning lock-button hide" disabled href="#">Lock</a>
      """
  
  # Build a check button
  #
  # index   - Row index
  buildCheckButton: (index) ->
    return """
        <a id="check-button-#{index}" class="btn btn-success check-button hide" disabled href="#"><i class="icon-ok icon-white"></i>  Check</a>
      """
  
  # Build master button
  #
  # index   - Row index
  buildMasterButton: () ->
    return """
        <a id="master-button" class="btn btn-success check-button" disabled href="#">Ok</a>
      """
  
  resetBoard: () ->
    console.log "[BoardView] Reset board"
    
    @activeEmptyPeg = null
    @activeMasterEmptyPeg = null
    @activeRow = 0
    @masterRow = null
    
    @removeAllPopoverHandler()
    
    $('response-form').addClass 'hide'
    $('#board tbody > tr').remove()
    
    @render()
  
  # -------------------------
  #  Event Handlers
  # -------------------------
  
  emptyPeg_clickHandler: (e) =>
    return unless @model.get('master')
    
    console.log "[BoardView] empty peg click handler"
    
    if @model.get('activePlayerID') is @model.get('meID')
      console.log @model.get('nextLock')?.row, @activeRow
      if @model.get('nextLock')?.row isnt @activeRow or @model.get('nextLock')?.row < @activeRow
        pegDOM = e.target
                
        if @activeEmptyPeg
           @activeEmptyPeg.popover 'toggle'
        
        $(pegDOM).popover 'toggle'
        
        # We set the active empty peg to $(this) in order to keep a reference to it
        @activeEmptyPeg = $(pegDOM)
        
        # We add handlers for click on peg in pegChooser
        $('.peg-chooser > .peg').click @pegChooser_pegClickHandler
          
        e.preventDefault()
      else
        console.log "[BoardView] The row is locked"  
    else
      console.log "[BoardView] You're not the active player so you can't click"
  
  masterEmptyPeg_clickHandler: (e) =>
    console.log "[BoardView] master empty peg click handler"
    
    console.log @model.get('activePlayerID'), @model.get('meID')
    
    if @model.get('activePlayerID') isnt @model.get('meID')
      pegDOM = e.target
            
      $(pegDOM).popover 'toggle'
      
      # We set the active empty peg to $(this) in order to keep a reference to it
      @activeMasterEmptyPeg = $(pegDOM)
      
      # We add handlers for click on peg in pegChooser
      $('.peg-chooser > .peg').click @masterPegChooser_pegClickHandler
        
      e.preventDefault()
    else
      console.log "[BoardView] You're the active player so you can't define master combination"
  
  # Handler for pegs in the peg chooser
  pegChooser_pegClickHandler: (e) =>
    console.log "[BoardView] peg chooser peg click handler"
    
    pegDOM = e.target
    
    # We toggle the popover of the empty peg to hide it
    @activeEmptyPeg.popover 'toggle'
    
    cellRC = (@activeEmptyPeg.attr 'id').split "-"
    cellRow = cellRC[1]
    cellColumn = cellRC[2]
    console.log "[BoardView][cell_clickHandler] Cell row @ #{cellRow} and column @ #{cellColumn}"
    
    @trigger 'pegClick',
      row: cellRow
      column: cellColumn
      peg: $(pegDOM).html()
    
    @activeEmptyPeg = null
  
  # Handler for pegs in the peg chooser
  masterPegChooser_pegClickHandler: (e) =>
    console.log "[BoardView] master peg chooser peg click handler"
    
    pegDOM = e.target
    
    # We toggle the popover of the empty peg to hide it
    @activeMasterEmptyPeg.popover 'toggle'
    
    cellRC = (@activeMasterEmptyPeg.attr 'id').split "-"
    cellRow = cellRC[1]
    cellColumn = cellRC[2]

    cellID = "#cell-#{cellRow}-#{cellColumn}"
    cellValue = $(pegDOM).html()  
    
    # Update the cell
    # TODO check if there is not a better way to do it (method payload)
    $(cellID).text cellValue
    $(cellID).addClass "peg-#{cellValue.toLowerCase()}"
    
    # If all the pegs value have been choosed
    # we enable the lock button and add a click handler on it
    if (el for el in $('tr').eq(@board.attempts).find("span") when $(el).html() is Peg.EMPTY).length is 0
      $("#master-button").removeAttr 'disabled'
      $("#master-button").click @masterButton_clickHandler
  
  lockButton_clickHandler: (e) =>
    console.log "[BoardView] Lock button click handler"
    
    # If there's still empty peg in the row we don't log
    # and display an alert (TODO)
    return unless (el for el in $('tr').eq(@activeRow).find("span") when $(el).html() is Peg.EMPTY).length is 0
    
    @trigger 'rowLocked',
      row: @activeRow
      
  checkButton_clickHandler: (e) =>
    console.log "[BoardView] Check button click handler"
    
    goodColorGoodPlace = $('#goodColorGoodPlaceSelect').val()
    goodColorWrongPlace = $('#goodColorWrongPlaceSelect').val()
    
    console.log "Good color, good place: #{goodColorGoodPlace}"
    console.log "Good color, wrong place: #{goodColorWrongPlace}"
    
    @trigger 'rowChecked'
      row: @activeRow
      gcgp: goodColorGoodPlace
      gcwp: goodColorWrongPlace
  
  masterButton_clickHandler: (e) =>
    console.log "[BoardView] Master button click handler"
    
    $(e.target).remove()
    @removePopoverHandler @board.attempts
    
    @trigger 'masterIsDefined'

    
    
    
