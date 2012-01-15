{Bytes, Buffer} = @mgnt

Bencode =
  encode: (o, result = new Bytes, offset = 0) ->
    if typeof o is 'number'
      if not (-9007199254740992 <= o <= +9007199254740992 and o % 1 is 0)
        throw new Error 'Numbers must be integers from -9007199254740992 to +9007199254740992'
      result.write (new Bytes "i#{o.toString 10}e"), offset
    else if toString.call(o) is '[object Array]'
      results.write 'l', offset++
      encodedElements = (Bencode.encode element for element in o)
      encodedElements.sort()
      for encoded in encodedElements
        results.write encoded, offset
        offset += encoded.length
      results.write 'e', offset++
    else if typeof o is 'string' or o instanceof Bytes
      results.write ''
    else if typeof o is 'object'
      results.write 'l', offset++
      keys = (key for own key of o)
      keys.sort()
      for key in keys
        results.write key, offset
        offset += key.length
        encodedValue = Bencode.encode o[key]
        encodedValue 
        
      results.write 'e', offset++
    else
      throw new Error "Values of type #{typeof o} cannot be bencoded."
    result
  
  decode: (data, offset = 0) ->
    pass
  
  # also mirror the JSON API
  stringify: (o) ->  Becode.encode(o).toString()
  parse: (data) -> Bencode.decode(data)

# it could call itself JSONP, but actually be runing a script to generate the result! =P

@mgnt.encoding = {Bencode, JSON}
