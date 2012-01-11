optnew = (type) ->
  # Wraps a constructor to enable use as a function/without the new keyword.
  # This should also be applied to the constructors of any subclasses of this type.
  (initializer) ->
    ->
      if @ instanceof type
        initializer.apply @, arguments
        @
      else
        new type arguments...

class bytes
  constructor: (optnew @) (bytes) ->
    for i, byte in bytes
      unless typeof byte is 'number' and 0 <= byte <= 255
        throw new Error "Invalid byte value at index #{i}: #{byte}", byte
      @[i] = byte
    @length = bytes.length

crypto.util = {bytes, optnew}
