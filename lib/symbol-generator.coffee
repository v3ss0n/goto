{Point} = require 'atom'
patterns = require './symbol-pattern-definitions'
logToConsole = atom.config.get('goto.logToConsole') ? false

module.exports = (path, grammar, text) ->
  lines = grammar.tokenizeLines(text)

  symbols = []

  nextIsSymbol = false

  for tokens, lineno in lines
    offset = 0
    prev = null
    for token in tokens
      if nextIsSymbol or isSymbol(token)
        nextIsSymbol = false

        symbol = cleanSymbol(token)
        if symbol
          if not mergeAdjacent(prev, token, symbols, offset)
            symbols.push({ name: token.value, path: path, position: new Point(lineno, offset) })
            prev = token

      nextIsSymbol = isBefore(token)

      offset += token.value.length

  symbols

cleanSymbol = (token) ->
  # Return the token name.  Will return null if symbol is not a valid name.
  name = token.value.trim().replace(/"/g, '')
  name || null

isSymbol = (token) ->
  # I'm a little unclear about this :\ so this might be much easier than
  # I've made it out to be.  If we really can use a single regular expression we can
  # switch to array.some() and eliminate this method all together

  # Check scopes in reverse (from most specific to least specific)
  # Includes negative regular expression check, which is overridden by match at same specificity
  # However, a scope match will be overridden by a more specific scope negation
  # Unless a general symbol match matches a more specific scope
  if token.value.trim().length and token.scopes
    for scope in token.scopes.reverse()
      if patterns.symbol.test(scope)
        return true
      if patterns.notSymbol.test(scope)
        return false
  return false

isBefore = (token) ->
  # Does this token indicate that the following token is a symbol?
  if token.value.trim().length and token.scopes
    for scope in token.scopes
      console.log('checking', scope, '=', patterns.before.test(scope)) if logToConsole
      if patterns.before.test(scope)
        return true
  return false

mergeAdjacent = (prevToken, thisToken, symbols, offset) ->
  # I'm not sure why but first-mate is breaking function names (at least Coffeescript ones)
  # into two - the last character is being returned by itself.  For now I'll merge any
  # two adjacent symbols since I can't see how there could actually ever be two adjacent
  # ones.
  #
  # Returns true if the two symbols are adjacent and will merge `thisToken` into the
  # previous symbol.  Return false if thisToken is not adjacent to the previous symbol.
  if offset and prevToken
    prevSymbol = symbols[symbols.length-1]
    if offset is prevSymbol.position.column + prevToken.value.length
      prevSymbol.name += thisToken.value
      return true

  return false
