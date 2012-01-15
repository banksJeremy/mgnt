setTimeout ->
  alert (sha1 'Hello world!').toHex()
, 0

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
  
  _verifyEqualLength: (other) ->
    if @length isnt other.length
      throw new Error "binary operations require Bytes of equal length (#{@length} != #{other.length})"
  
  _verifyIntegrality: (n) -> # har
    if typeof n isnt 'number' or n % 1 isnt 0
      throw new Error "right-side must be an integer, is #{typeof n} #{n}"
  
  iadd: (other) ->
    @_verifyEqualLength other
    
    i = @length - 1
    carry = 0
    while i >= 0
      sum = @[i] + other[i] + carry
      carry = sum >> 8
      @[i] = sum & 255
      i -= 1
    @
  
  lrot: (n) ->
    @_verifyIntegrality n
    
    n = (n % (@length * 8) + (@length * 8)) % (@length * 8)
    
    byteshift = (n / 8) | 0
    bitshift = n % 8
    
    bytes = for i in [0...@length]
      ((@[(i + byteshift + @length) % @length] << bitshift) & 255) +
      ((@[(i + byteshift + @length + 1) % @length] >> (8 - bitshift)) & 255)
    
    new Bytes(bytes)
  
  rrot: (n) ->
    @_verifyIntegrality n
    
    @blrot -n
  
  rshift: (n) ->
    @_verifyIntegrality n
    
    if n < 0 then throw 'shit'
    
    byteshift = (n / 8) | 0
    bitshift = n % 8
    
    bytes = for i in [0...@length]
      (((@[i - byteshift + @length] ? 0) >> bitshift) & 255) +
      (((@[i - byteshift + @length - 1] ? 0) << (8 - bitshift)) & 255)
    
  or: (other) ->
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    Bytes(@[i] | other[i] for i in [0...@length])
  
  and: (other) ->
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    Bytes(@[i] & other[i] for i in [0...@length])
  
  # TODO
  ixor: -> @xor arguments...
  iand: -> @and arguments...
  ior: -> @or arguments...
  
  xor: (other) ->
    if @length != other.length then throw new Error 'Bytes must have equal length'
    
    Bytes(@[i] ^ other[i] for i in [0...@length])
  
  ixor: -> @xor arguments...
  
  not: ->
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
    new Bytes Array::slice.apply(@, arguments)
  
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
    @
  
  concat: (bytes) ->
    (new Bytes @).extend(bytes)

@crypto.util = {Bytes}

class ABlockHash
  constructor: (bytes) ->
    if @constructor is ABlockHash
      throw new Error 'Abstract class ABlockHash can\'t be instantiated.'
    
    @state = new Bytes @_initialState
    
    @length = 0
    @buffer = new Bytes
    
    if bytes?
      @update new Bytes bytes
  
  update: (bytes) ->
    @length += bytes.length
    @buffer.write bytes
    
    offset = 0
    while offset + @_blockSize <= @buffer.length
      @_process @state, @buffer[offset..offset + @_blockSize]
      offset += @_blockSize
    
    if offset > 0
      @buffer = @buffer[offset..]
    
    @
  
  digest: (data) ->
    state = new Bytes @state
    buffer = new Bytes @buffer
    
    if data?
      buffer.write data
      length = @length + data.length
    else
      length = @length
    
    @_pad buffer, length
    offset = 0
    
    while offset < buffer.length
      @_process state, buffer[offset..offset + @_blockSize]
      offset += @_blockSize
    
    state

class Sha1 extends ABlockHash
  _blockSize: 64
  
  _initialState: new Bytes [
    0x67, 0x45, 0x23, 0x01,
    0xEF, 0xCD, 0xAB, 0x89,
    0x98, 0xBA, 0xDC, 0xFE,
    0x10, 0x32, 0x54, 0x76,
    0xC3, 0xD2, 0xE1, 0xF0
  ]
  
  _pad: (buffer, messageLength) ->
    buffer.write [0x80]
    
    if messageLength % 64 != 56
      buffer.write [], messageLength - (messageLength % 64) + 56
    
    if messageLength or true
      hexLength = (messageLength * 8).toString(16)
      n = Bytes.fromHex(hexLength)
    else
      n = new Bytes
    
    nPadded = new Bytes
    nPadded.write n, 8 - n.length
    buffer.write nPadded
  
  _process: (state, block) ->
    a = state[0...4]
    b = state[4...8]
    c = state[8...12]
    d = state[12...16]
    e = state[16...20]
    
    w = (block[i * 4...(i + 1) * 4] for i in [0...16])
    w.length = 80
    for i in [16..79]
      w[i] = ((new Bytes w[i - 3]) .ixor w[i - 8] .ixor w[i - 14] .ixor w[i - 16]) .lrot 1
    
    for i in [0..79]
      if 0 <= i <= 19
        f = (b .and c) .ior (b.not() .iand d)
        k = new Bytes [0x5A, 0x82, 0x79, 0x99]
      else if 20 <= i <= 39
        f = b .xor c .xor d
        k = new Bytes [0x6E, 0xD9, 0xEB, 0xA1]
      else if 40 <= i <= 59
        f = (b .and c) .ior (b .and d) .ior (c .and d)
        k = new Bytes [0x8F, 0x1B, 0xBC, 0xDC]
      else if 60 <= i <= 79
        f = b .xor c.ixor d
        k = new Bytes [0xCA, 0x62, 0xC1, 0xD6]
      
      temp = ((((a .lrot 5) .iadd f) .iadd e) .iadd k) .iadd w[i]
      e = d
      d = c
      c = b .lrot 30
      b = a
      a = temp
    
    state.write (state[0...4] .iadd a), 0
    state.write (state[4...8] .iadd b), 4
    state.write (state[8...12] .iadd c), 8 
    state.write (state[12...16] .iadd d), 12
    state.write (state[16...20] .iadd e), 16

commonSha1 = new Sha1

sha1 = (data) -> commonSha1.digest data

@crypto.hash = {ABlockHash, Sha1, sha1}

###

crypto
- .async - the digest functions return Deferred values.
- .sync

(crypto.hash.sha1.async data).then ->

# Have an IV-prepended format, and random 
# ((crypt.block.aes128.ctr key, iv=(rand)).encrypt block, ctrIndex=null)
# (((crypt.hash.sha1 data="").update "").digest)
# let this shit run async in web workers
# falling back to sync in browsers that don't support
# (but the default is sync, because async just maps to another thread
# that will run the sync)
