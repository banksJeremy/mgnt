{Bytes, Buffer} = @mgnt

class AMerkleDamgardHash
  # Abstract class for a byte-based Merkle–Damgård hash function.
  # Implementations require @_blockSize, @_digestSize, @_pad(buffer, length), @_compress(state, block)
  
  constructor: (bytes) ->
    if @constructor is AMerkleDamgardHash
      throw new Error 'Abstract class AMerkleDamgardHash can\'t be instantiated.'
    
    @state = new Bytes @_initializationVector
    
    @length = 0
    @buffer = new Bytes
    
    if bytes?
      @update new Bytes bytes
  
  @digest: (data) ->
    @_instance ?= new @
    @_instance.digest data
  
  update: (bytes) ->
    @length += bytes.length
    @buffer.write bytes
    
    offset = 0
    while offset + @_blockSize <= @buffer.length
      @_compress @state, @buffer[offset..offset + @_blockSize]
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
      @_compress state, buffer[offset..offset + @_blockSize]
      offset += @_blockSize
    
    state
  
  _padWith1Then0sThenLengthAsBigEndianUint64: (buffer, messageLength) ->
    # The padding scheme used by MD5, SHA-1, SHA-2
    
    buffer.write [0x80]
    currentLastBlockSize = buffer.length % @_blockSize
    desiredLastBlockSize = @_blockSize - 8
    
    offset = if currentLastBlockSize < desiredLastBlockSize
      buffer.length + desiredLastBlockSize - currentLastBlockSize
    else if currentLastBlockSize > desiredLastBlockSize
      buffer.length + desiredLastBlockSize - currentLastBlockSize + @_blockSize
    
    n = Bytes.fromHex((messageLength * 8).toString 16)
    nPadded = new Bytes
    nPadded.write n, 8 - n.length
    buffer.write nPadded, offset

class Md5 extends AMerkleDamgardHash
  _blockSize: 64
  _digestSize: 16
  
  _initializationVector: new Bytes [
    0x67, 0x45, 0x23, 0x01,
    0xEF, 0xCD, 0xAB, 0x89,
    0x98, 0xBA, 0xDC, 0xFE,
    0x10, 0x32, 0x54, 0x76
  ]
  
  _pad: AMerkleDamgardHash::_padWith1Then0sThenLengthAsBigEndianUint64
  
  _compress: (state, block) ->
    a = state[0...4]
    b = state[4...8]
    c = state[8...12]
    d = state[12...16]
    
    w = (block[i * 4...(i + 1) * 4] for i in [0...16])
    
    for i in [0..63]
      if 0 <= i <= 15
        f = (b .and c) .ior (b.not() .iand d)
        g = i
      else if 16 <= i <= 31
        f = (d .and b) .ior (d.not() .iand c)
        g = (5 * i + 1) % 16
      else if 32 <= i <= 47
        f = b .xor c .xor d
        g = (3 * i + 5) % 16
      else if 48 <= i <= 63
        f = c .xor (b .or d.not())
        g = (7 * i) % 16
      
      temp = d
      d = c
      c = b
      b = b .add ((((a .iadd f) .iadd K[i]) .iadd w[g]) .lrot R[i])
      a = temp
    
    state.write (state[0...4] .iadd a), 0
    state.write (state[4...8] .iadd b), 4
    state.write (state[8...12] .iadd c), 8 
    state.write (state[12...16] .iadd d), 12
  
  R = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22
    5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23  
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
  ]
  
  K = (Bytes.fromHex digits for digits in [ 'd76aa478', 'e8c7b756', '242070db',
        'c1bdceee', 'f57c0faf', '4787c62a', 'a8304613', 'fd469501', '698098d8',
        '8b44f7af', 'ffff5bb1', '895cd7be', '6b901122', 'fd987193', 'a679438e',
		    '49b40821', 'f61e2562', 'c040b340', '265e5a51', 'e9b6c7aa', 'd62f105d',
        '02441453', 'd8a1e681', 'e7d3fbc8', '21e1cde6', 'c33707d6', 'f4d50d87',
        '455a14ed', 'a9e3e905', 'fcefa3f8', '676f02d9', '8d2a4c8a', 'fffa3942',
        '8771f681', '6d9d6122', 'fde5380c', 'a4beea44', '4bdecfa9', 'f6bb4b60',
        'bebfbc70', '289b7ec6', 'eaa127fa', 'd4ef3085', '04881d05', 'd9d4d039',
        'e6db99e5', '1fa27cf8', 'c4ac5665', 'f4292244', '432aff97', 'ab9423a7',
        'fc93a039', '655b59c3', '8f0ccc92', 'ffeff47d', '85845dd1', '6fa87e4f',
        'fe2ce6e0', 'a3014314', '4e0811a1', 'f7537e82', 'bd3af235', '2ad7d2bb',
	      'eb86d391'])

class Sha1 extends AMerkleDamgardHash
  _blockSize: 64
  _digestSize: 20
  
  _initializationVector: new Bytes [
    0x67, 0x45, 0x23, 0x01,
    0xEF, 0xCD, 0xAB, 0x89,
    0x98, 0xBA, 0xDC, 0xFE,
    0x10, 0x32, 0x54, 0x76,
    0xC3, 0xD2, 0xE1, 0xF0
  ]
  
  _pad: AMerkleDamgardHash::_padWith1Then0sThenLengthAsBigEndianUint64
  
  _compress: (state, block) ->
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

@mgnt.hash = {AMerkleDamgardHash, Sha1, Md5}
