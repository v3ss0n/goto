
{Point} = require 'atom'

# I'm expecting this to grow a lot.  We'll also need configuration
# that can be added to dynamically, I think.

resym = /// ^ (
    entity.name.type.class
  | entity.name.function
  | entity.other.attribute-name.class
  ) ///

# A simplistic regexp that is used to match the item immediately following.  I'll eventually
# need something a bit more complex.
rebefore =  /// ^ (
  meta.rspec.behaviour
) ///

module.exports = (path, grammar, text) ->
  lines = grammar.tokenizeLines(text)

  symbols = []

  nextIsSymbol = false

  for tokens, lineno in lines
    offset = 0
    prev = null
    for token in tokens
      if nextIsSymbol or issymbol(token)
        nextIsSymbol = false

        symbol = cleanSymbol(token)
        if symbol
          if not mergeAdjacent(prev, token, symbols, offset)
            symbols.push({ name: token.value, path: path, position: new Point(lineno, offset) })
            prev = token

      nextIsSymbol = isbefore(token)

      offset += token.bufferDelta

  symbols

cleanSymbol = (token) ->
  # Return the token name.  Will return null if symbol is not a valid name.
  name = token.value.trim().replace(/"/g, '')
  name.length ? name : null;

issymbol = (token) ->
  # I'm a little unclear about this :\ so this might be much easier than
  # I've made it out to be.  If we really can use a single regular expression we can
  # switch to array.some() and eliminate this method all together
  if token.value.trim().length and token.scopes
    for scope in token.scopes
      if resym.test(scope)
        return true
  return false

isbefore = (token) ->
  # Does this token indicate that the following token is a symbol?
  if token.value.trim().length and token.scopes
    for scope in token.scopes
      console.log('checking', scope, '=', rebefore.test(scope))
      if rebefore.test(scope)
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
