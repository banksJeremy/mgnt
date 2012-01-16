describe 'mgnt.base', ->
  describe 'Bytes', ->
    {Bytes} = mgnt
    describe 'constructor', ->
      it 'should accept valid data', ->
        do expect(instance instanceof Bytes).toBeTruthy for instance in [
          new Bytes
          new Bytes 'Hello world'
          new Bytes [1, 2, 3, 255]
          new Bytes ''
          new Bytes []
          Bytes()
          Bytes 'Hello world'
          Bytes [1, 2, 3, 0]
          Bytes ''
          Bytes []
        ]

      it 'should reject invalid data', ->
        do expect(-> new Bytes data).toThrow for data in [
          [-1]
          [256]
          [1.5]
          [255, 1.5]
          ['a']
          [128, 'a']
          [0, 0, 512]
          [0, 0, 'a']
          'FooBar inc. \u0100'
          '\u0100 FooBar inc.'
        ]
      
      it 'should correctly handle empty-data corner cases', ->
        for o in [new Bytes, new Bytes [], new Bytes {length: 0}, new Bytes '']
          expect(o.length).toEqual 0
          expect(o._readOffset).toEqual 0
          expect(o._writeOffset).toEqual 0
          expect(o[0]).toBeUndefined()
