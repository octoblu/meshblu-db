MeshbluDb = require '../../src/meshblu-db'

describe 'MeshbluDb', ->
  beforeEach ->
    @meshbluHttp = {}
    @MeshbluHttp = sinon.spy => @meshbluHttp
    @sut = new MeshbluDb {}, MeshbluHttp : @MeshbluHttp

  describe '->find', ->
    describe 'when called with a property "type"', ->
      beforeEach ->
        @meshbluHttp.devices = sinon.stub().yields null, devices: [ {uuid: 'u1'}, {uuid: 'u2'} ]
        @sut.find type: 'eggs', (@error, @devices) =>

      it 'should yield the devices from meshblu', ->
        expect(@devices).to.deep.equal [ {uuid: 'u1'}, {uuid: 'u2'} ]

      it 'should call meshblu.devices', ->
        expect(@meshbluHttp.devices).to.have.been.calledWith type : 'eggs'

    describe 'when called and meshblu returns different devices', ->
      beforeEach ->
        @meshbluHttp.devices = sinon.stub().yields null, devices: [ {uuid: 'u1', type: 'meat'}, {uuid: 'u2', type: 'meat'} ]
        @sut.find type: 'meat', (@error, @devices) =>

      it 'should yield the devices from meshblu', ->
        expect(@devices).to.deep.equal [ {uuid: 'u1', type: 'meat'}, {uuid: 'u2', type: 'meat'} ]

      it 'should call meshblu.devices', ->
        expect(@meshbluHttp.devices).to.have.been.calledWith type : 'meat'

    describe "when meshblu.devices yields an error", ->
      beforeEach (done) ->
        @meshbluHttp.devices = sinon.stub().yields new Error('electric eels')
        @sut.find {type : 'this will fail'}, (@error) => done()

      it 'should yield an error', ->
        expect(@error).to.exist

  describe '->findOne', ->
    it 'should exist', ->
      expect(@sut.findOne).to.exist

    describe 'when called with a uuid', ->
      beforeEach ->
        @meshbluHttp.devices = sinon.stub()
        @uuid = 'U1'
        @pin = '12345'

      it 'should call meshblu.devices', ->
        @sut.findOne uuid: @uuid
        expect(@meshbluHttp.devices).to.have.been.calledWith uuid: @uuid

      describe 'and when devices yields a device', ->
        beforeEach ->
          @callback = sinon.stub()

        it 'it should return a record that matches the findOne query', ->
          @meshbluHttp.devices.yields( null, devices: [{
            uuid: @uuid
            pin : @pin
          }])
          @sut.findOne {uuid: @uuid}, @callback
          expect(@callback).to.have.been.calledWith null, uuid: @uuid, pin: @pin

        it 'it should return a record that matches the findOne query', ->
          @uuid = '56789'
          @pin = '1337'
          @meshbluHttp.devices.yields( null, devices: [{
            uuid: @uuid
            pin : @pin
          }])
          @sut.findOne {uuid: @uuid}, @callback
          expect(@callback).to.have.been.calledWith null, uuid: @uuid, pin: @pin

        describe 'when findOne is called with a query for a device that doesn\'t exist', ->
          beforeEach ->
            @meshbluHttp.devices.yields new Error('this will happen, give in')

          it 'should yield an error', ->
            @sut.findOne {uuid: 'Erik'}, @callback
            expect(@callback.args[0][0]).to.exist

  describe '->insert', ->
    describe 'when called', ->
      beforeEach ->
        @uuid = '84DA55'
        @pin = '80085'
        @meshbluHttp.register = sinon.stub()
        @callback = sinon.stub()

      it 'should call meshblu.register', ->
        @sut.insert uuid: @uuid, pin: @pin
        expect(@meshbluHttp.register).to.have.been.calledWith uuid: @uuid, pin: @pin

      describe 'and register yields a different device', ->
        beforeEach ->
          @device = uuid: 2, alarm: false
          @meshbluHttp.register.yields null, @device

        it 'should call meshblu.register with the device record with a "pins" key containing the pin', ->
          @sut.insert @device
          expect(@meshbluHttp.register).to.have.been.calledWith @device

        describe 'when meshblu.register yields the device', ->
          beforeEach ->
            @meshbluHttp.register.yields null, @device
          it 'should call it\'s callback the node way', ->
            @sut.insert @rec3, @callback
            expect(@callback).to.have.been.calledWith null, @device

  describe '->update', ->
    beforeEach ->
      @meshbluHttp.devices = sinon.stub().yields null, {devices:[{}]}

    describe 'when called', ->
      beforeEach (done) ->
        @meshbluHttp.update = sinon.stub().yields( null, peter: 'wrong' )
        @sut.update({}, { uuid: 'trapped in a blizzard'}, (@error, @device) => done())

      it 'should not yield an error', ->
        expect(@error).to.not.exist

      it 'should not yield the device', ->
        expect(@device).to.deep.equal peter: 'wrong'

      it 'should call meshblu.update', ->
        expect(@meshbluHttp.update).to.have.been.calledWith { uuid: 'trapped in a blizzard' }

    describe 'when called and meshblu yields a different device', ->
      beforeEach (done) ->
        @meshbluHttp.update = sinon.stub().yields( null, peter: 'not-so-right' )
        @sut.update({}, { uuid: 'trapped not in a blizzard'}, (@error, @device) => done())

      it 'should not yield the device', ->
        expect(@device).to.deep.equal peter: 'not-so-right'

    describe 'when called and meshblu yields an error', ->
      beforeEach (done) ->
        @meshbluHttp.update = sinon.stub().yields( new Error 'Peter is usually incorrect' )
        @sut.update({}, { uuid: 'trapped not in a blizzard'}, (@error, @device) => done())

      it 'should yield an error', ->
        expect(@error).to.exist

      it 'should not yield the device', ->
        expect(@device).to.not.exist

    describe 'when called with a different device', ->
      beforeEach ->
        @callback = sinon.spy()
        @meshbluHttp.update = sinon.stub().yields null, { uuid: 'trapped in confusing firestorm'}
        @sut.update({}, { uuid: 'trapped in a firestorm'}, @callback)

      it 'should call the callback', ->
        expect(@callback).to.have.been.called

      it 'should call meshblu.update', ->
        expect(@meshbluHttp.update).to.have.been.calledWith { uuid: 'trapped in a firestorm' }
