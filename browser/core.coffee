#
# Marketplace browser's core module
#

class Core

  constructor: (@bridge) ->
    @resetPurchaseTxRequest()
    @resetMyInfoRequest()
    @resetAllTxsRequest()


  resetPurchaseTxRequest: ->
    @bridge.tx = "{}"


  resetAllTxsRequest: ->
    @bridge.isAllTxsRequest = false


  resetMyInfoRequest: ->
    @bridge.isMyInfoRequest = false


  setMyInfo: (data) ->
    console.log "setMyInfo (#{data})"
    @bridge.setMyInfo JSON.parse(data).user
    '{ "code": "0" }'


  setSellerInfo: (data) ->
    console.log "setSellerInfo (#{data})"
    r = JSON.parse(data)
    if r.stores? and r.stores.length > 0
      @bridge.setSellerInfo r
    '{ "code": "0" }'


  # it returns a purchase transaction once it was requested from the browser
  getPurchaseTxRequest: ->
    console.log 'new tx request here:', @bridge.tx  if @bridge.tx != "{}"
    @bridge.tx


  getTxStep1: (data) ->
    console.log "getTxStep1 (#{data})"
    @resetPurchaseTxRequest()
    @bridge.informPurchaseStatus "Purchase transaction is in progress..."
    '{ "code": "0" }'


  getTxStep6: (txId) ->
    console.log "getTxStep6 (#{txId})"
    @bridge.informPurchaseStatus "Purchase transaction ##{txId} has been successfully executed!"
    '{ "code": "0" }'


  getMyInfoRequest: ->
    console.log 'my info request here'  if @bridge.isMyInfoRequest
    @bridge.isMyInfoRequest


  # it returns a request for getting all executed transactions from the browser
  getAllTxsRequest: ->
    console.log 'all txs request here'  if @bridge.isAllTxsRequest
    @bridge.isAllTxsRequest


  setAllTxs: (txs) ->
    @bridge.setAllTxs txs


module.exports = Core
