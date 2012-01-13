@crypto ?= {}

class Bytes
  constructor: (bytes = []) ->
    if @ not instanceof Bytes then return new Bytes bytes
    
    if typeof bytes is 'string'
      bytes = (bytes.charCodeAt(i) for i in [0...bytes.length])
    
    for byte, i in bytes
      unless typeof byte is 'number' and 0 <= byte <= 255
        throw new Error "Invalid byte value at index #{i}: #{byte}", byte
      @[i] = byte
    @length = bytes.length
  
  @cast: (o) -> if o instanceof @ then o else @ o
  
  biadd: (other) ->
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    i = @length - 1
    carry = 0
    while i >= 0
      sum = @[i] + other[i] + carry
      carry = sum >> 8
      @[i] = sum & 255
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
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    Bytes(@[i] | other[i] for i in [0...@length])
  
  band: (other) ->
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    Bytes(@[i] & other[i] for i in [0...@length])
  
  bxor: (other) ->
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    Bytes(@[i] ^ other[i] for i in [0...@length])
  
  bnot: ->
    Bytes(~byte + 256 for byte in @)
  
  @fromHex: (digits) ->
    unless typeof digits is 'string'
      throw new Error 'Argument to ByteArray.fromHex() must be a string.'
    unless digits.length % 2 is 0
      # throw new Error 'Argument to ByteArray.fromHex() must be of even length.'
      digits = '0' + digits
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
  
  slice: ->
    new Bytes(Array::slice.apply(@, arguments))
  
  write: (bytes, offset) ->
    if not offset?
      offset = @length
      @length += bytes.length
    else
      if offset > @length
        # fill with 0 if you start writing beyond the end of string
        for i in [@length...offset]
          @[i] = 0
      
      writeEnd = offset + bytes.length
      if writeEnd > @length
        @length = writeEnd
    
    if typeof bytes is 'string'
      bytes = (bytes.charCodeAt(i) for i in [0...bytes.length])
    
    for byte, i in bytes
      unless typeof byte is 'number' and 0 <= byte <= 255
        # oh, now this object is corrupt!
        throw new Error "Invalid byte value at index #{i}: #{byte}", byte
      @[offset + i] = byte
    
    @
  
  extend: (bytes) ->
    @write bytes
  
  concat: (bytes) ->
    (new Bytes(@)).extend(bytes)

@crypto.util = {Bytes}

class Sha1
  constructor: (bytes) ->
    @state = new Bytes([
      0x67, 0x45, 0x23, 0x01,
      0xEF, 0xCD, 0xAB, 0x89,
      0x98, 0xBA, 0xDC, 0xFE,
      0x10, 0x32, 0x54, 0x76,
      0xC3, 0xD2, 0xE1, 0xF0
    ])
    
    @length = 0
    @buffer = new Bytes
    
    if bytes?
      @update new Bytes bytes
  
  update: (bytes) ->
    @length += bytes.length
    @buffer.write bytes
    
    offset = 0
    while offset + blockSize <= @buffer.length
      process(@state, @buffer.slice(offset, offset + blockSize))
      offset += blockSize
    
    if offset > 0
      @buffer = @buffer.slice(offset)
  
  blockSize = 64
  
  process = (state, block) ->
    a = state.slice(0, 4)
    b = state.slice(4, 8)
    c = state.slice(8, 12)
    d = state.slice(12, 16)
    e = state.slice(16, 20)
    
    w = (block.slice(i * 4, (i + 1) * 4) for i in [0...16])
    
    w.length = 80
    for i in [16..79]
      w[i] = (new Bytes w[i - 3]).bxor(w[i - 8]).bxor(w[i - 14]).bxor(w[i - 16]).blrot(1)
    
    for i in [0..79]
      if 0 <= i <= 19
        f = (b.band c).bor(b.bnot().band d)
        k = new Bytes([0x5A, 0x82, 0x79, 0x99])
      else if 20 <= i <= 39
        f = b.bxor(c).bxor(d)
        k = new Bytes([0x6E, 0xD9, 0xEB, 0xA1])
      else if 40 <= i <= 59
        f = (b.band c).bor(b.band d).bor(c.band d)
        k = new Bytes([0x8F, 0x1B, 0xBC, 0xDC])
      else if 60 <= i <= 79
        f = b.bxor(c).bxor(d)
        k = new Bytes([0xCA, 0x62, 0xC1, 0xD6])
      
      temp = a.blrot(5).biadd(f).biadd(e).biadd(k).biadd(w[i])
      e = d
      d = c
      c = b.blrot(30)
      b = a
      a = temp
    
    state.write(state.slice(0, 4).biadd(a), 0)
    state.write(state.slice(4, 8).biadd(b), 4)
    state.write(state.slice(8, 12).biadd(c), 8)
    state.write(state.slice(12, 16).biadd(d), 12)
    state.write(state.slice(16, 20).biadd(e), 16)
  
  pad = (buffer, messageLength) ->
    buffer.write([0x80])
    
    if messageLength % 64 != 56
      buffer.write([], messageLength - (messageLength % 64) + 56)
    
    console.log buffer.length
    
    if messageLength or true
      hexLength = (messageLength * 8).toString(16)
      n = Bytes.fromHex(hexLength)
    else
      n = new Bytes
    
    nPadded = new Bytes
    nPadded.write n, 8 - n.length
    buffer.write nPadded
  
  digest: ->
    state = new Bytes(@state)
    buffer = new Bytes(@buffer)
    pad buffer, @length
    offset = 0
    
    while offset < buffer.length
      process(state, buffer.slice(offset, offset + blockSize))
      offset += blockSize
    state

@crypto.hashes = {Sha1}

console.log "" + (new Sha1 "").digest().toHex()
console.log "da39a3ee5e6b4b0d3255bfef95601890afd80709"
