@crypto ?= {}

class Bytes
  constructor: (bytes) ->
    if @ not instanceof Bytes then return new Bytes bytes
    
    if typeof bytes is 'string'
      bytes = (bytes.charCodeAt(i) for i in [0...bytes.length])
    
    for byte, i in bytes
      unless typeof byte is 'number' and 0 <= byte <= 255
        throw new Error "Invalid byte value at index #{i}: #{byte}", byte
      @[i] = byte
    @length = bytes.length
  
  @cast: (o) -> if o instanceof @ then o else @ o
  
  iadd: (other) ->
    i = @length - 1
    carry = 0
    while i >= 0
      @[i] += other[i] + carry
      if carry = @[i] >> 8
        @[i] %= 0xFF
      i -= 1
    i = @length - 1
    while carry and i >= 0
      @[i] += carry
      if carry = @[i] >> 8
        @[i] %= 0xFF
      i -= 1
    @
  
  blrot: (n) ->
    byteshift = (n / 8) | 0
    bitshift = n % 8
    
    bytes = for i in [0...@length]
      ((@[(i + byteshift + @length) % @length] << bitshift) & 255) +
      ((@[(i + byteshift + @length + 1) % @length] >> (8 - bitshift)) & 255)
    
    new Bytes(bytes)
  
  brrot: (n) ->
    @brrot -n
  
  bor: (other) ->
    Bytes(@[i] | other[i] for i in [0...@length])
  
  band: (other) ->
    Bytes(@[i] & other[i] for i in [0...@length])
  
  bxor: (other) ->
    Bytes(@[i] ^ other[i] for i in [0...@length])
  
  bnot: ->
    Bytes(~byte + 0xFF for byte in @)
  
  @fromHex: (digits) ->
    unless typeof digits is 'string'
      throw new Error 'Argument to ByteArray.fromHex() must be a string.'
    unless digits.length % 2 is 0
      throw new Error 'Argument to ByteArray.fromHex() must be of even length.'
    bytes = for i in [0...digits.length / 2]
      byte = parseInt digits.substr(i * 2, 2), 16
      if byte != byte # is NaN
        throw new Error 'Argument to ByteArray.fromHex() must be hex.'
      byte
    new @ bytes
  
  DIGITS = '0123456789abcdef'
  
  toHex: ->
    pairs = for byte in @
      DIGITS[byte >> 4] + DIGITS[byte % (1 << 4)]
    pairs.join ''
  
  toString: -> String.fromCharCode (byte for byte in @)...
  toJSON: -> JSON.stringify @toString()


console.log "" + (Bytes "Hello world").blrot(0).toHex()
console.log "" + (Bytes  "Hello world").blrot(15).toHex()

@crypto.util = {Bytes}
# 
# class Sha1 extends AHash
#   blockSize: 512 / 8
#   
#   constructor: (data) ->
#     @state = [
#       new Bytes(0x67, 0x45, 0x23, 0x01),
#       new Bytes(0xEF, 0xCD, 0xAB, 0x89),
#       new Bytes(0x98, 0xBA, 0xDC, 0xFE),
#       new Bytes(0x10, 0x32, 0x54, 0x76),
#       new Bytes(0xC3, 0xD2, 0xE1, 0xF0)
#     ]
#     
#     buffer = Bytes(data)
#   
#   update: (data) ->
#     @buffer.extend(data)
#     while @buffer.length >= @blockSize
#       whoo
#       [block, @buffer] = @buffer.split(64)
#       @_advance @state, block
#   
#   _advance: (state, block) ->
#     
