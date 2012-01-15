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
    n = (n % (@length * 8) + (@length * 8)) % (@length * 8)
    
    byteshift = (n / 8) | 0
    bitshift = n % 8
    
    bytes = for i in [0...@length]
      ((@[(i + byteshift + @length) % @length] << bitshift) & 255) +
      ((@[(i + byteshift + @length + 1) % @length] >> (8 - bitshift)) & 255)
    
    new Bytes(bytes)
  
  brrot: (n) ->
    @blrot -n
  
  brshift: (n) ->
    if n < 0 then throw 'shit'
    
    byteshift = (n / 8) | 0
    bitshift = n % 8
    
    bytes = for i in [0...@length]
      (((@[i - byteshift + @length] ? 0) >> bitshift) & 255) +
      (((@[i - byteshift + @length - 1] ? 0) << (8 - bitshift)) & 255)
    
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

do Bytes.math ->
  a = $state[ 0... 4]
  b = $state[ 4... 8]
  c = $state[ 8...12]
  d = $state[12...16]
  e = $state[16...20]


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
    
    @
  
  blockSize = 64
  
  process = (state, block) ->
    a = state[0...4]
    b = state[4...8]
    c = state[8...12]
    d = state[12...16]
    e = state[16...20]
    
    w = (block[i * 4...(i + 1) * 4] for i in [0...16])
    
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
    
    if messageLength or true
      hexLength = (messageLength * 8).toString(16)
      n = Bytes.fromHex(hexLength)
    else
      n = new Bytes
    
    nPadded = new Bytes
    nPadded.write n, 8 - n.length
    buffer.write nPadded
  
  digest: (data) ->
    state = new Bytes(@state)
    buffer = new Bytes(@buffer)
    if data?
      buffer.write data
      length = @length + data.length
    else
      length = @length
    pad buffer, length
    offset = 0
    
    while offset < buffer.length
      process(state, buffer.slice(offset, offset + blockSize))
      offset += blockSize
    state


class Sha256
  constructor: (bytes) ->
    @state = new Bytes([
      0x6a, 0x09, 0xe6, 0x67,
      0xbb, 0x67, 0xae, 0x85,
      0x3c, 0x6e, 0xf3, 0x72,
      0xa5, 0x4f, 0xf5, 0x3a,
      0x51, 0x0e, 0x52, 0x7f,
    0x9b, 0x05, 0x68, 0x8c,
    0x1f, 0x83, 0xd9, 0xab,
    0x5b, 0xe0, 0xcd, 0x19
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
    
    @
  
  blockSize = 64
  
  k = [
    new Bytes([0x42, 0x8a, 0x2f, 0x98]),
    new Bytes([0x71, 0x37, 0x44, 0x91]),
    new Bytes([0xb5, 0xc0, 0xfb, 0xcf]),
    new Bytes([0xe9, 0xb5, 0xdb, 0xa5]),
    new Bytes([0x39, 0x56, 0xc2, 0x5b]),
    new Bytes([0x59, 0xf1, 0x11, 0xf1]),
    new Bytes([0x92, 0x3f, 0x82, 0xa4]),
    new Bytes([0xab, 0x1c, 0x5e, 0xd5]),
    new Bytes([0xd8, 0x07, 0xaa, 0x98]),
    new Bytes([0x12, 0x83, 0x5b, 0x01]),
    new Bytes([0x24, 0x31, 0x85, 0xbe]),
    new Bytes([0x55, 0x0c, 0x7d, 0xc3]),
    new Bytes([0x72, 0xbe, 0x5d, 0x74]),
    new Bytes([0x80, 0xde, 0xb1, 0xfe]),
    new Bytes([0x9b, 0xdc, 0x06, 0xa7]),
    new Bytes([0xc1, 0x9b, 0xf1, 0x74]),
    new Bytes([0xe4, 0x9b, 0x69, 0xc1]),
    new Bytes([0xef, 0xbe, 0x47, 0x86]),
    new Bytes([0x0f, 0xc1, 0x9d, 0xc6]),
    new Bytes([0x24, 0x0c, 0xa1, 0xcc]),
    new Bytes([0x2d, 0xe9, 0x2c, 0x6f]),
    new Bytes([0x4a, 0x74, 0x84, 0xaa]),
    new Bytes([0x5c, 0xb0, 0xa9, 0xdc]),
    new Bytes([0x76, 0xf9, 0x88, 0xda]),
    new Bytes([0x98, 0x3e, 0x51, 0x52]),
    new Bytes([0xa8, 0x31, 0xc6, 0x6d]),
    new Bytes([0xb0, 0x03, 0x27, 0xc8]),
    new Bytes([0xbf, 0x59, 0x7f, 0xc7]),
    new Bytes([0xc6, 0xe0, 0x0b, 0xf3]),
    new Bytes([0xd5, 0xa7, 0x91, 0x47]),
    new Bytes([0x06, 0xca, 0x63, 0x51]),
    new Bytes([0x14, 0x29, 0x29, 0x67]),
    new Bytes([0x27, 0xb7, 0x0a, 0x85]),
    new Bytes([0x2e, 0x1b, 0x21, 0x38]),
    new Bytes([0x4d, 0x2c, 0x6d, 0xfc]),
    new Bytes([0x53, 0x38, 0x0d, 0x13]),
    new Bytes([0x65, 0x0a, 0x73, 0x54]),
    new Bytes([0x76, 0x6a, 0x0a, 0xbb]),
    new Bytes([0x81, 0xc2, 0xc9, 0x2e]),
    new Bytes([0x92, 0x72, 0x2c, 0x85]),
    new Bytes([0xa2, 0xbf, 0xe8, 0xa1]),
    new Bytes([0xa8, 0x1a, 0x66, 0x4b]),
    new Bytes([0xc2, 0x4b, 0x8b, 0x70]),
    new Bytes([0xc7, 0x6c, 0x51, 0xa3]),
    new Bytes([0xd1, 0x92, 0xe8, 0x19]),
    new Bytes([0xd6, 0x99, 0x06, 0x24]),
    new Bytes([0xf4, 0x0e, 0x35, 0x85]),
    new Bytes([0x10, 0x6a, 0xa0, 0x70]),
    new Bytes([0x19, 0xa4, 0xc1, 0x16]),
    new Bytes([0x1e, 0x37, 0x6c, 0x08]),
    new Bytes([0x27, 0x48, 0x77, 0x4c]),
    new Bytes([0x34, 0xb0, 0xbc, 0xb5]),
    new Bytes([0x39, 0x1c, 0x0c, 0xb3]),
    new Bytes([0x4e, 0xd8, 0xaa, 0x4a]),
    new Bytes([0x5b, 0x9c, 0xca, 0x4f]),
    new Bytes([0x68, 0x2e, 0x6f, 0xf3]),
    new Bytes([0x74, 0x8f, 0x82, 0xee]),
    new Bytes([0x78, 0xa5, 0x63, 0x6f]),
    new Bytes([0x84, 0xc8, 0x78, 0x14]),
    new Bytes([0x8c, 0xc7, 0x02, 0x08]),
    new Bytes([0x90, 0xbe, 0xff, 0xfa]),
    new Bytes([0xa4, 0x50, 0x6c, 0xeb]),
    new Bytes([0xbe, 0xf9, 0xa3, 0xf7]),
    new Bytes([0xc6, 0x71, 0x78, 0xf2])
  ]
  
  process = (state, block) ->
    a = state.slice(0, 4)
    b = state.slice(4, 8)
    c = state.slice(8, 12)
    d = state.slice(12, 16)
    e = state.slice(16, 20)
    f = state.slice(20, 24)
    g = state.slice(24, 28)
    h = state.slice(28, 32)
    
    w = (block.slice(i * 4, (i + 1) * 4) for i in [0...16])
    
    w.length = 80
    for i in [16..79]
      s0 = w[i - 15].brrot(7).bxor(w[i - 15].brrot(18)).bxor(w[i - 15].brshift(3))
      s1 = w[i - 2].brrot(17).bxor(w[i - 2].brrot(19)).bxor(w[i - 2].brshift(10))
      
      w[i] = new Bytes(w[i - 16]).biadd(s0).biadd(w[i - 7]).biadd(s1)
    
    
    for i in [0..63]
      s0 = a.brrot(2).bxor(a.brrot(13)).bxor(a.brrot(22))
      maj = a.band(b).bxor(a.band(c)).bxor(b.band(c))
      t2 = (new Bytes(s0)).biadd(maj)
      s1 = e.brrot(6).bxor(e.brrot(11)).bxor(e.brrot(25))
      ch = e.band(f).bxor(e.bnot().band(g))
      
      t1 = (new Bytes(h)).biadd(s1).biadd(ch).biadd(k[i]).biadd(w[i])
      
      h = g
      g = f
      f = e
      e = (new Bytes d).biadd(t1)
      d = c
      c = b
      b = a
      a = (new Bytes t1).biadd(t2)
    
    state.write(state.slice(0, 4).biadd(a), 0)
    state.write(state.slice(4, 8).biadd(b), 4)
    state.write(state.slice(8, 12).biadd(c), 8)
    state.write(state.slice(12, 16).biadd(d), 12)
    state.write(state.slice(16, 20).biadd(e), 16)
    state.write(state.slice(20, 24).biadd(f), 20)
    state.write(state.slice(24, 28).biadd(g), 24)
    state.write(state.slice(28, 32).biadd(h), 28)
  
  pad = (buffer, messageLength) ->
    buffer.write([0x80])
    
    if messageLength % 64 != 56
      buffer.write([], messageLength - (messageLength % 64) + 56)
    
    if messageLength or true
      hexLength = (messageLength * 8).toString(16)
      n = Bytes.fromHex(hexLength)
    else
      n = new Bytes
    
    nPadded = new Bytes
    nPadded.write n, 8 - n.length
    buffer.write nPadded
  
  digest: (data) ->
    state = new Bytes(@state)
    buffer = new Bytes(@buffer)
    if data?
      buffer.write data
      length = @length + data.length
    else
      length = @length
    pad buffer, length
    offset = 0
    
    while offset < buffer.length
      process(state, buffer.slice(offset, offset + blockSize))
      offset += blockSize
    state

commonSha1 = new Sha1
commonSha256 = new Sha256

sha1 = (data) -> commonSha1.digest data
sha256 = (data) -> commonSha256.digest data

@crypto.hash = {Sha1, Sha256, sha1, sha256}
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
