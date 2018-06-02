#
# Marketplace browser's core module
#

class Core

  constructor: (@globalEmitter) ->


  getMyData: (evtName, data) ->
    console.log "getMyData (#{evtName}, <data>)"
    data = JSON.parse(JSON.stringify(data))
    @globalEmitter.emit evtName + '-done', data
    rslt =
      code: 0


module.exports = Core
