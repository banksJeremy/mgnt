class Bytes
  constructor: (bytes = [], persistent = true) ->
    if @ not instanceof Bytes then return new Bytes bytes
    
    # if not persistent then data not betwen read/write pointers may be cleared.
    # this will corrupt the string for use with methods other than read/write!!
    # but no errors will be thrown. maybe I should just subclass bytes as Buffer?
    # yeah, bytes are always persistent, Buffer is the non-persistent subclass.
    # buffers can be used for byte-like operatations before read() is called and
    # their data goes away (that is to say, while readOffset = 0 and writeOffset = length)
    @persistent = persistent
    @_readOffset = 0
    @_writeOffset = 0 # end of strin
    
    # maybe be really abusive (or just prototype) on top of openkeyval
    # try looking up each the info hashes in there, and then try
    # looking up infohash-year-month-day[-N] for UTC today
    
    # https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
    # use the mozilla local APIs to write the data as soon as the torrent is loaded
    # https://developer.mozilla.org/en/Code_snippets/File_I%2F%2FO
    
    # oh and have some way of putting these literally in the URL but beware of how long the
    # urls become. so those could be at mgnt.ca/ but it wouldn't give you any data,
    # just feed you a cached offline-able extension-able app that can take the data you give
    # it. the URL could have the minimum but you need to install the extension to get the rest.2
    
    # but first just make the basic things work. do the simple things first.
    
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
    @_verifyEqualLength other
    
    new Bytes (@[i] | other[i] for i in [0...@length])
  
  and: (other) ->
    @_verifyEqualLength other
    
    new Bytes (@[i] & other[i] for i in [0...@length])
  
  add: (other) -> (new Bytes @).iadd other
  # TODO
  ixor: -> @xor arguments...
  iand: -> @and arguments...
  ior: -> @or arguments...
  
  xor: (other) ->
    @_verifyEqualLength other
    
    new Bytes (@[i] ^ other[i] for i in [0...@length])
  
  not: ->
    new Bytes (~byte + 256 for byte in @)
  
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
  
  # file-like interface: seek, peek, read, write
  
  peek: ->
    @_offset
  
  seek: (offset, whence) ->
    if (not whence) or whence is 'start' or whence is 'SET'
      @_offset = offset
    else if whence is 1 or whence is 'relative' or whence is 'CUR'
      @_offset += offset
    else if whence is 2 or whence is 'end' or whence is 'END'
      @_offset = @length = offset
    @
  
  read: (length) ->
    
  
  write: (bytes) ->
    bytes = Bytes.cast bytes
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
    @_index += bytes.length
    @
  
  extend: (bytes) ->
    @write bytes
    @
  
  concat: (bytes) ->
    (new Bytes @).extend(bytes)

class Buffer extends Bytes
	
@mgnt = {Bytes, Buffer}
