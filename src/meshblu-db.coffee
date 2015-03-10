_ = require 'lodash'
debug = require('debug')('meshblu:meshblu-db')

class MeshbluDb
  constructor: (@meshblu) ->
    @isConnected = true
    @meshblu.on 'disconnect', =>
      @isConnected = false

    @meshblu.on 'ready', =>
      @isConnected = true

  find: (query, callback=->)=>
    debug "Requesting devices with #{JSON.stringify(query)}"
    return _.defer(callback, new Error 'not connected') unless @isConnected
    @meshblu.devices query, (response) =>
      debug response
      return callback new Error response.error?.message if response.error?
      callback null, response.devices

  findOne: (query, callback=->)=>
    @find query, (error, devices) => callback error, _.first(devices)

  update: (query, record, callback=->) =>
    return _.defer(callback, new Error 'not connected') unless @isConnected
    @findOne query, (error, device) =>
      return callback error, null if error
      extendedDevice = _.extend device, record
      @meshblu.update extendedDevice, (response) =>
        return callback new Error(response.error?.message) if response.error? && !response.uuid
        callback null, response

  insert: (record, callback=->) =>
    return _.defer(callback, new Error 'not connected') unless @isConnected
    debug "writing", record
    @meshblu.register record, (device) =>
      debug "insert response", device
      callback null, device

module.exports = MeshbluDb
