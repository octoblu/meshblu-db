_ = require 'lodash'
debug = require('debug')('meshblu:meshblu-db')

class MeshbluDb
  constructor: (meshbluJSON, dependencies={}) ->
    @MeshbluHttp = dependencies.MeshbluHttp ? require 'meshblu-http'
    @meshbluHttp = new @MeshbluHttp meshbluJSON

  find: (query, callback=->)=>
    debug "Requesting devices with #{JSON.stringify(query)}"
    @meshbluHttp.devices query, (error, response) =>
      debug response
      return callback error if error?
      callback null, response.devices

  findOne: (query, callback=->)=>
    @find query, (error, devices) => callback error, _.first(devices)

  update: (query, record, callback=->) =>
    @findOne query, (error, device) =>
      return callback error, null if error
      extendedDevice = _.extend device, record
      @meshbluHttp.update extendedDevice, (error, response) =>
        return callback error if error?
        callback null, response

  insert: (record, callback=->) =>
    debug "writing", record
    @meshbluHttp.register record, (error, device) =>
      debug "insert response", device
      return callback error if error?
      callback null, device

module.exports = MeshbluDb
