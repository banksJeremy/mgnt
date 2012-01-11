@crypto =
	VERSION: '0.0.0.dev'

ns = ->
  if arguments.length is 1
    context = new Object
    [f] = arguments
  else
    [context, f] = arguments
  f.call context, context
  context

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

# Binary Operations
# These functions operate on Arrays of Numbers in [0, 1, ..., 255].
# Those that take multiple arguments require they be the same length.

class ByteArray
  constructor: (optnew @) (bytes) ->
    for i, byte in bytes
      unless typeof byte is 'number' and 0 <= byte <= 255
        throw new Error "Invalid byte value at index #{i}: #{byte}", byte
      @[i] = byte
    @length = bytes.length
  
  @fromHex: (digits) ->
    unless typeof digits is 'string'
      throw new Error 'Argument to ByteArray.fromHex() must be a string.'
    unless digits.length % 2 is 0
      throw new Error 'Argument to ByteArray.fromHex() must be of even length.'
    bytes = for i in [0...digits.length / 2]
      byte = parseInt digits.substr(i * 2, i * 2 + 2), 16
      if byte != byte # is NaN
        throw new Error 'Argument to ByteArray.fromHex() must be hex.'
      byte
    new @ bytes
  
  DIGITS = '0123456789abcdef'
  
  hex: ->
    pairs = for byte in @
      DIGITS[byte >> 4] + DIGITS[byte % (1 << 4)]
    pairs.join ''
  
  bin: ->
    octets = for byte in @
      digits = for i in [7..0]
        DIGITS[1 & (byte >> i)]
      digits.join ''
    octets.join ''
  
  iadd: (x) ->
    i = @length - 1
    carry = 0
    while i >= 0
      @[i] += x[i] + carry
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

blrot = (x, n) ->
  carry = 0
  i = x.length - 1
  result = while i > 0
    next_carry = byte >> (8 - n)
    result = (byte << n) % 255 + carry
    carry = next_carry
    i -= 1
    result
  result[x.length - 1] += carry
  result
  
bor = (a, b) ->
  ap | b[key] for key, ap in a
band = (a, b) ->
  ap & b[key] for key, ap in a
bxor = (a, b) ->
  ap ^ b[key] for key, ap in a
bnot = (x) ->
  ~xp + 0xFF for xp in x
  
bcmp = (a, b) ->
  for index, ap in a
    if a < b
      return -1
    else if a > b
      return +1
  return 0

class sha1
  # SHA-1, FIPS PUB 180-1 (1993) 
  # http://www.itl.nist.gov/fipspubs/fip180-1.htm
  # else
  @async: ->
    # Web Workers
    # fallback to update()ing at intervals
  
  constructor: (optnew @) (data) ->
    @state = [
      [0x67, 0x45, 0x23, 0x01]
      [0xEF, 0xCD, 0xAB, 0x89]
      [0x98, 0xBA, 0xDC, 0xFE]
      [0x10, 0x32, 0x54, 0x76]
      [0xC3, 0xD2, 0xE1, 0xF0]
    ]
    @length = 0
    @buffer = [] # the current block, which hasn't yet been fed in
    
    if data? then @update data
  
  update: (data) ->
    @length += data.length
    i = 0
    
    if @buffer.length + data.length >= 512
      if @buffer.length
        i = 512 - @buffer.length
        Array::push.apply @buffer, data.slice 0, i
        @_update @buffer
        @buffer = []
      
      while data.length - i
          what have I not done this?
    else
      Array::push.apply @buffer, data
    
    @
  
  _update: (block) ->
    [a, b, c, d, e] = @state
    
    for i in [0..79]
      if i <= 19
        f = bor (band b, c), (band (bnot b), d)
        k = [0x5A, 0x82, 0x79, 0x99]
      else if 20 <= i <= 39
        f = bxor (bxor b, c), d
        k = [0x6E, 0xD9, 0xEB, 0xA1]
      else if 40 <= i <= 59
        f = bor (bor (band b, c), (band b, d)), (band c, d) 
        k = [0x8F, 0x1B, 0xBC, 0xDC]
      else if 60 <= i
        f = bxor (bxor b, c), d
        k = [0xCA, 0x62, 0xC1, 0xD6]
      
      temp = (ubinc (ubinc (ubinc (ubinc blrot(a, 5), f), e), k), w[i])
      e = d
      d = c
      c = blrot b, 30
      b = a
      a = temp

    ubinc @state[0], a
    ubinc @state[1], b
    ubinc @state[2], c
    ubinc @state[3], d
    ubinc @state[4], e
  
  digest: ->
    state_stash = (Array::slice.apply bytes for bytes in @state)
    buffer_stash = Array.slice @buffer
    length_stash = @length
    
    # add padding
    @update [0x80]
    
    
    digest = [].concat @state...
    @digest = -> digest
    @state = state_stash                                                                                                                                                                                                                                                 
    digest
    
  hexDigest: ->
    digest = @digest()
    if @digest._hexDigest?
      return @digest._hexDigest
    @digest.hexDigest = hex digest
  
  toString: ->
    "sha1=#{@hexDigest()}"



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
