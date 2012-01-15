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
      b = b .add ((((a .iadd f) .iadd k[i]) .iadd w[g]) .lrot r[i])
      a = temp
    
    state.write (state[0...4] .iadd a), 0
    state.write (state[4...8] .iadd b), 4
    state.write (state[8...12] .iadd c), 8 
    state.write (state[12...16] .iadd d), 12
  
  r = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22
    5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23  
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
  ]
  
  k = [
    new Bytes [0xd7, 0x6a, 0xa4, 0x78]
    new Bytes [0xe8, 0xc7, 0xb7, 0x56]
    new Bytes [0x24, 0x20, 0x70, 0xdb]
    new Bytes [0xc1, 0xbd, 0xce, 0xee]
    new Bytes [0xf5, 0x7c, 0x0f, 0xaf]
    new Bytes [0x47, 0x87, 0xc6, 0x2a]
    new Bytes [0xa8, 0x30, 0x46, 0x13]
    new Bytes [0xfd, 0x46, 0x95, 0x01]
    new Bytes [0x69, 0x80, 0x98, 0xd8]
    new Bytes [0x8b, 0x44, 0xf7, 0xaf]
    new Bytes [0xff, 0xff, 0x5b, 0xb1]
    new Bytes [0x89, 0x5c, 0xd7, 0xbe]
    new Bytes [0x6b, 0x90, 0x11, 0x22]
    new Bytes [0xfd, 0x98, 0x71, 0x93]
    new Bytes [0xa6, 0x79, 0x43, 0x8e]
    new Bytes [0x49, 0xb4, 0x08, 0x21]
    new Bytes [0xf6, 0x1e, 0x25, 0x62]
    new Bytes [0xc0, 0x40, 0xb3, 0x40]
    new Bytes [0x26, 0x5e, 0x5a, 0x51]
    new Bytes [0xe9, 0xb6, 0xc7, 0xaa]
    new Bytes [0xd6, 0x2f, 0x10, 0x5d]
    new Bytes [0x02, 0x44, 0x14, 0x53]
    new Bytes [0xd8, 0xa1, 0xe6, 0x81]
    new Bytes [0xe7, 0xd3, 0xfb, 0xc8]
    new Bytes [0x21, 0xe1, 0xcd, 0xe6]
    new Bytes [0xc3, 0x37, 0x07, 0xd6]
    new Bytes [0xf4, 0xd5, 0x0d, 0x87]
    new Bytes [0x45, 0x5a, 0x14, 0xed]
    new Bytes [0xa9, 0xe3, 0xe9, 0x05]
    new Bytes [0xfc, 0xef, 0xa3, 0xf8]
    new Bytes [0x67, 0x6f, 0x02, 0xd9]
    new Bytes [0x8d, 0x2a, 0x4c, 0x8a]
    new Bytes [0xff, 0xfa, 0x39, 0x42]
    new Bytes [0x87, 0x71, 0xf6, 0x81]
    new Bytes [0x6d, 0x9d, 0x61, 0x22]
    new Bytes [0xfd, 0xe5, 0x38, 0x0c]
    new Bytes [0xa4, 0xbe, 0xea, 0x44]
    new Bytes [0x4b, 0xde, 0xcf, 0xa9]
    new Bytes [0xf6, 0xbb, 0x4b, 0x60]
    new Bytes [0xbe, 0xbf, 0xbc, 0x70]
    new Bytes [0x28, 0x9b, 0x7e, 0xc6]
    new Bytes [0xea, 0xa1, 0x27, 0xfa]
    new Bytes [0xd4, 0xef, 0x30, 0x85]
    new Bytes [0x04, 0x88, 0x1d, 0x05]
    new Bytes [0xd9, 0xd4, 0xd0, 0x39]
    new Bytes [0xe6, 0xdb, 0x99, 0xe5]
    new Bytes [0x1f, 0xa2, 0x7c, 0xf8]
    new Bytes [0xc4, 0xac, 0x56, 0x65]
    new Bytes [0xf4, 0x29, 0x22, 0x44]
    new Bytes [0x43, 0x2a, 0xff, 0x97]
    new Bytes [0xab, 0x94, 0x23, 0xa7]
    new Bytes [0xfc, 0x93, 0xa0, 0x39]
    new Bytes [0x65, 0x5b, 0x59, 0xc3]
    new Bytes [0x8f, 0x0c, 0xcc, 0x92]
    new Bytes [0xff, 0xef, 0xf4, 0x7d]
    new Bytes [0x85, 0x84, 0x5d, 0xd1]
    new Bytes [0x6f, 0xa8, 0x7e, 0x4f]
    new Bytes [0xfe, 0x2c, 0xe6, 0xe0]
    new Bytes [0xa3, 0x01, 0x43, 0x14]
    new Bytes [0x4e, 0x08, 0x11, 0xa1]
    new Bytes [0xf7, 0x53, 0x7e, 0x82]
    new Bytes [0xbd, 0x3a, 0xf2, 0x35]
    new Bytes [0x2a, 0xd7, 0xd2, 0xbb]
    new Bytes [0xeb, 0x86, 0xd3, 0x91]
  ]

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