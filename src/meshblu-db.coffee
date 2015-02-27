_ = require 'lodash'
debug = require('debug')('meshblu:meshblu-db')

class MeshbluDb
  constructor: (@meshblu) ->

  find: (query, callback=->)=>
    @meshblu.devices query, (response) =>
      debug response
      return callback new Error response.error?.message if response.error?
      callback null, response.devices

  findOne: (query, callback=->)=>
    @find query, (error, devices) => callback error, _.first(devices)

  update: (device, callback=->) => 
    @meshblu.update device, (response) =>
      return callback new Error(response.error?.message) if response.error? && !response.uuid 
      callback null, response    

  insert: (record, callback=->) =>
    debug "writing", record
    @meshblu.register record, (device) =>
      debug "insert response", device
      callback null, device

module.exports = MeshbluDb
