MeshbluDb = require '../../src/meshblu-db'

describe 'MeshbluDb', ->
  beforeEach ->
    @meshblu = {}
    @meshblu.register = sinon.stub()
    @meshblu.on = (eventName, callback) =>
      @meshblu[eventName] = callback
    @sut = new MeshbluDb @meshblu

  describe 'constructor', ->
    it 'should instantiate a MeshbluDb', ->
      expect(@sut).to.exist

    it 'should set isConnected to true', ->
      expect(@sut.isConnected).to.be.true

  describe 'when meshblu.on fires a disconnect', ->
    beforeEach ->
      @meshblu.disconnect()

    it 'should set isConnected to false on disconnect', ->
      expect(@sut.isConnected).to.be.false

  describe 'when meshblu.on fires a ready', ->
    beforeEach ->
      @meshblu.ready()

    it 'should set isConnected to true', ->
      expect(@sut.isConnected).to.be.true

  describe '->find', ->
    it 'should exist', ->
      expect(@sut.find).to.exist

    describe 'when it is disconnected from meshblu', ->
      beforeEach (done) ->
        @meshblu.disconnect()
        @sut.find {}, (@error) => done()

      it 'should throw an error', ->
        expect(@error).to.exist

    describe 'when called with a property "type"', ->
      beforeEach ->
        @meshblu.devices = sinon.stub().yields devices: [ {uuid: 'u1'}, {uuid: 'u2'} ]
        @sut.find type: 'eggs', (@error, @devices) =>

      it 'should yield the devices from meshblu', ->
        expect(@devices).to.deep.equal [ {uuid: 'u1'}, {uuid: 'u2'} ]

      it 'should call meshblu.devices', ->
        expect(@meshblu.devices).to.have.been.calledWith type : 'eggs'

    describe 'when called and meshblu returns different devices', ->
      beforeEach ->
        @meshblu.devices = sinon.stub().yields devices: [ {uuid: 'u1', type: 'meat'}, {uuid: 'u2', type: 'meat'} ]
        @sut.find type: 'meat', (@error, @devices) =>

      it 'should yield the devices from meshblu', ->
        expect(@devices).to.deep.equal [ {uuid: 'u1', type: 'meat'}, {uuid: 'u2', type: 'meat'} ]

      it 'should call meshblu.devices', ->
        expect(@meshblu.devices).to.have.been.calledWith type : 'meat'

    describe "when meshblu.devices yields an error", ->
      beforeEach (done) ->
        @meshblu.devices = sinon.stub().yields error: 'electric eels'
        @sut.find {type : 'this will fail'}, (@error) => done()

      it 'should yield an error', ->
        expect(@error).to.exist

  describe '->findOne', ->
    it 'should exist', ->
      expect(@sut.findOne).to.exist

    describe 'when called with a uuid', ->
      beforeEach ->
        @meshblu.devices = sinon.stub()
        @uuid = 'U1'
        @pin = '12345'

      it 'should call meshblu.devices', ->
        @sut.findOne uuid: @uuid
        expect(@meshblu.devices).to.have.been.calledWith uuid: @uuid

      describe 'and when devices yields a device', ->
        beforeEach ->
          @callback = sinon.stub()

        it 'it should return a record that matches the findOne query', ->
          @meshblu.devices.yields( devices: [{
            uuid: @uuid
            pin : @pin
          }])
          @sut.findOne {uuid: @uuid}, @callback
          expect(@callback).to.have.been.calledWith null, uuid: @uuid, pin: @pin

        it 'it should return a record that matches the findOne query', ->
          @uuid = '56789'
          @pin = '1337'
          @meshblu.devices.yields( devices: [{
            uuid: @uuid
            pin : @pin
          }])
          @sut.findOne {uuid: @uuid}, @callback
          expect(@callback).to.have.been.calledWith null, uuid: @uuid, pin: @pin

        describe 'when findOne is called with a query for a device that doesn\'t exist', ->
          beforeEach ->
            @meshblu.devices.yields error: 'this will happen, give in'

          it 'should yield an error', ->
            @sut.findOne {uuid: 'Erik'}, @callback
            expect(@callback.args[0][0]).to.exist

  describe '->insert', ->
    it 'should exist',  ->
      expect(@sut.insert).to.exist

    describe 'when it is disconnected from meshblu', ->
      beforeEach (done) ->
        @meshblu.disconnect()
        @sut.insert {}, (@error) => done()

      it 'should throw an error', ->
        expect(@error).to.exist

    describe 'when called', ->
      beforeEach ->
        @uuid = '84DA55'
        @pin = '80085'
        @meshblu.register = sinon.stub()
        @callback = sinon.stub()

      it 'should call meshblu.register', ->
        @sut.insert uuid: @uuid, pin: @pin
        expect(@meshblu.register).to.have.been.calledWith uuid: @uuid, pin: @pin

      describe 'and register yields a different device', ->
        beforeEach ->
          @device = uuid: 2, alarm: false
          @meshblu.register.yields @device

        it 'should call meshblu.register with the device record with a "pins" key containing the pin', ->
          @sut.insert @device
          expect(@meshblu.register).to.have.been.calledWith @device

        describe 'when meshblu.register yields the device', ->
          beforeEach ->
            @meshblu.register.yields @device
          it 'should call it\'s callback the node way', ->
            @sut.insert @rec3, @callback
            expect(@callback).to.have.been.calledWith null, @device

  describe '->update', ->
    beforeEach ->
      @meshblu.devices = sinon.stub().yields {devices:[{}]}

    it 'should exist', ->
      expect(@sut.update).to.exist

    describe 'when it is disconnected from meshblu', ->
      beforeEach (done) ->
        @meshblu.disconnect()
        @sut.update {}, {}, (@error) => done()

      it 'should throw an error', ->
        expect(@error).to.exist

    describe 'when called', ->
      beforeEach (done) ->
        @meshblu.update = sinon.stub().yields( peter: 'wrong' )
        @sut.update({}, { uuid: 'trapped in a blizzard'}, (@error, @device) => done())

      it 'should not yield an error', ->
        expect(@error).to.not.exist

      it 'should not yield the device', ->
        expect(@device).to.deep.equal peter: 'wrong'

      it 'should call meshblu.update', ->
        expect(@meshblu.update).to.have.been.calledWith { uuid: 'trapped in a blizzard' }

    describe 'when called and meshblu yields a different device', ->
      beforeEach (done) ->
        @meshblu.update = sinon.stub().yields( peter: 'not-so-right' )
        @sut.update({}, { uuid: 'trapped not in a blizzard'}, (@error, @device) => done())

      it 'should not yield the device', ->
        expect(@device).to.deep.equal peter: 'not-so-right'

    describe 'when called and meshblu yields an error', ->
      beforeEach (done) ->
        @meshblu.update = sinon.stub().yields( error: 'Peter is usually incorrect' )
        @sut.update({}, { uuid: 'trapped not in a blizzard'}, (@error, @device) => done())

      it 'should yield an error', ->
        expect(@error).to.exist

      it 'should not yield the device', ->
        expect(@device).to.not.exist

    describe 'when called with a different device', ->
      beforeEach ->
        @callback = sinon.spy()
        @meshblu.update = sinon.stub().yields { uuid: 'trapped in confusing firestorm'}
        @sut.update({}, { uuid: 'trapped in a firestorm'}, @callback)

      it 'should call the callback', ->
        expect(@callback).to.have.been.called

      it 'should call meshblu.update', ->
        expect(@meshblu.update).to.have.been.calledWith { uuid: 'trapped in a firestorm' }
