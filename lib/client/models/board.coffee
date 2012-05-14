# -------------------------
# Dependencies
# -------------------------

Model = require '../shared/Model'

_ = require 'underscore'


# -------------------------
# Class Implementation
# -------------------------

module.exports = class Board extends Model
  
  initialize: (level = 4, attempts = 9) ->
    
    @level = level # level defines the number of columns
    @attempts = attempts # attempts defines the number of rows
    
    @cells = []
    
    for i in [0..@attempts - 1]
      @cells[i] = []
      for j in [0..@level-1]
        @cells[i][j] = null
  
  # Safely get the content of a cell
  getCell: (row, column) ->
    return unless column < @level and row < @attempts
    return @cells[row][column]
  
  # Safely set the content of a cell
  setCell: (row, column, value) ->
    return unless column < @level and row < @attempts
    @cells[row][column] = value
    @trigger 'change', {row: row, column: column}
  
  lockRow: (row) ->
    @trigger 'lock', {row: row}
  
  setCellCheckResponse: (row, gcgp, gcwp) ->
    console.log "[Board] setCellCheckResponse"
    @trigger 'checked', 
      row: row
      gcgp: gcgp
      gcwp: gcwp
  
  dumpBoard: () ->
    for i in [0..@attempts - 1]
      @cells[i] = []
      for j in [0..@level-1]
        @cells[i][j] = null