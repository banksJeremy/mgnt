

describe 'mgnt.hash', ->
  goog.require 'goog.crypt'
  
  describe 'Sha1', ->
    knownAsHex =
      '': 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
      '00': '5ba93c9db0cff93f52b521d7420e43f6eda2784f'
      'FF': '85e53271e14006f0265921d02d4d736cdc580b0b'
      
    
    goog.require 'goog.crypt.Sha1'
    gShaHex = (data) ->
      sha1 = new goog.crypt.Sha1
      sha1.update data
      goog.crypt.byteArrayToHex sha1.digest()
    
    mShaHex = (data) ->
      mgnt.hash.Sha1.digest(data).toHex() 
    
    generateInputs = ->
      # all-0 arrays of bytes from length 0 to length 1050
      result = []
      for length in [0..1050]
        result.push (0 for _ in [0...length])
      
      # [0], [1, 0], [2, 1], [3, 2, 1], [4, 3, 2]
      state = [0]
      for n in [0...550]
        state = [n % 256].concat state
        if n % 2 is 1
          state.pop()
        if n > 400
          result.push state
      
      low-entropy strings from small to quite large
      state = ""
      for _ in [0...12]
        result.push state = "#{state.length}#{state}#{state.length}#{state}#{state.length}" 
      
      result
    
    xit 'must match the output of Closure\'s goog.crypt.Sha1 for various test inputs', ->
      for input in generateInputs()
        (expect mShaHex input) .toEqual (gShaHex input)
