# Matching grammar scope names
# I'm expecting this to grow a lot.  We'll also need configuration
# that can be added to dynamically, I think.
symbol = /// ^ (
    entity.name.type.class
  | entity.name.function
  | entity.other.attribute-name.class
) ///

# Grammar scope name negations
# More specific negations will override less specific matches
notSymbol = /// ^ (
) ///

# A simplistic regexp that is used to match the item immediately following.  I'll eventually
# need something a bit more complex.
before =  /// ^ (
  meta.rspec.behaviour
) ///

module.exports = { symbol, notSymbol, before }
