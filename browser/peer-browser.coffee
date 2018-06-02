#
# Marketplace browser's libp2p-based peer
#

crypto = require "libp2p-crypto"
PeerId = require "peer-id"
PeerInfo = require "peer-info"
multiaddr = require "multiaddr"
WSStar = require "libp2p-websocket-star"
MulticastDNS = require "libp2p-mdns"
pull = require "pull-stream"

Node = require "./libp2p-bundle"
proto = require "./proto"
FileTransfer = require "./filetransfer"


# TODO: duplicated
OP_SUCCESS = 0
OP_WARNING = 1
OP_ERROR = 2


browserPeerNode = undefined
startCnt = undefined
endCnt = undefined
uri = document.querySelector("meta[property='uri']").getAttribute('content')
console.log 'uri=', uri


# TODO: duplicated
getUniqueIds = ->
  [ crypto.randomBytes(16).toString('hex'), Math.floor((new Date).getTime() / 1000) ]


window.startNode = (@core, cb) ->

  # ignoring 'Error: "/new/0.0.1" not supported', 'Error: Circuit not enabled!', etc
  ignoreNotSupported = (err, cb) ->
    console.log "ignoreNotSupported (#{err}, <cb>)"
    @core.getMyData 'global-ignoreNotSupported', [ OP_ERROR, 'Something weird happened: not connected to the network!' ]
    # cb null, err.toString()
    return


  # request for my own info
  requestMyInfo = (evtName) ->
    hostId = PeerId.createFromB58String @hostPeerB58Id 
    hostPeerInfo = new PeerInfo(hostId)
    browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_GET_MY_INFO, (err, connOut) =>
      if err is null
        # passing browser's peer id inside PROTO_GET_MY_INFO request
        tx = { data: @core.browserPeerB58Id }
        pull pull.values(tx), connOut, pull.collect((err, connIn) =>
          if err
            cb err, connIn
            return
          console.log 'connIn:', connIn
          @core.getMyData evtName, connIn.toString()
        )
      else
        ignoreNotSupported err, cb
        return '{ "code": "750" }'
    return


  PeerInfo.create (err, peerInfo) ->
    console.log "create:", err, peerInfo
    if err
      cb err
      return
    peerInfo.multiaddrs.add multiaddr(uri)
    ws = new WSStar(id: peerInfo)
    mdns = new MulticastDNS(peerInfo, { interval: 2000 })
    modules = 
      transport: [ ws ]
      mdns: mdns
      discovery: [ ws.discovery, mdns.discovery ]
    browserPeerNode = new Node(peerInfo, undefined, modules)
    console.log "browserPeerNode:", browserPeerNode

    ft = new FileTransfer()

    # additional info about connected nodes
    @core.peerNicks = {}
    @core.peerNames = {}
    @core.peerModes = {}
    @core.peerLocations = {}
    @core.peerPings = {}
    @core.peerPubs = {}
    @core.browserPeerB58Id = browserPeerNode.peerInfo.id.toB58String()
    @core.peerModes["#{@core.browserPeerB58Id}"] = 'browser'


    @core.globalEmitter.on 'global-hostPeerInform', (@hostPeerB58Id) ->
      console.log '@hostPeerB58Id=', @hostPeerB58Id


    @core.globalEmitter.on 'global-MyInfo', ->
      requestMyInfo 'global-MyInfo'


    # initiating the purchase request
    @core.globalEmitter.on 'global-BuyTxRequest', (tx) ->
      console.log 'new buy tx request here:', tx
      t = JSON.parse tx
      # TODO: chk tx properly
      if t.seller?   # is transaction already initiated?
        hostId = PeerId.createFromB58String @hostPeerB58Id 
        hostPeerInfo = new PeerInfo(hostId)
        console.log 'browserPeerNode.peerBook:', browserPeerNode.peerBook

        # adding witnesses into transaction
        witnesses = []
        for w of @core.peerModes
          if @core.peerModes[w] == 'witness'
            witnesses.push w
        t['witness'] = witnesses
        startCnt = new Date()

        browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_PURCHASE1, (err, connOut) =>
          if err is null
            tx = { data: JSON.stringify(t) }
            pull pull.values(tx), connOut, pull.collect((err, connIn) =>
              console.log "<== #{proto.PROTO_PURCHASE1}: err:", err, "connIn:", connIn.toString()
              if err
                cb err, connIn
                return
              @core.getMyData 'global-InProgress', [ OP_SUCCESS, "Purchase transaction is in progress..." ]
            )
          else
            ignoreNotSupported err, cb
        return '{ "code": "751" }'


    # getting all private ledger's executed transactions
    @core.globalEmitter.on 'global-AllPrivateTxsRequest', ->
      console.log 'all private txs request here'
      # sending request to host node for getting all private transactions
      hostId = PeerId.createFromB58String @hostPeerB58Id 
      hostPeerInfo = new PeerInfo(hostId)
      browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_GET_ALL_PRIVATE_TXS, (err, connOut) =>
        if err is null
          tx = { data: 'AllPrivateTxs' }
          pull pull.values(tx), connOut, pull.collect((err, connIn) =>
            console.log "<== #{proto.PROTO_GET_ALL_PRIVATE_TXS}: err:", err, "connIn:", connIn.toString()
            if err
              cb err, connIn
              return
            @core.getMyData 'global-AllPrivateTxsRequest', connIn.toString()
          )
        else
          ignoreNotSupported err, cb
          return '{ "code": "752" }'


    # getting all public blockchain's executed transactions
    @core.globalEmitter.on 'global-AllPublicTxsRequest', ->
      console.log 'all public txs request here'
      # sending request to host node for getting all public transactions
      hostId = PeerId.createFromB58String @hostPeerB58Id 
      hostPeerInfo = new PeerInfo(hostId)
      browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_GET_ALL_PUBLIC_TXS, (err, connOut) =>
        if err is null
          tx = { data: 'AllPublicTxs' }
          pull pull.values(tx), connOut, pull.collect((err, connIn) =>
            console.log "<== #{proto.PROTO_GET_ALL_PUBLIC_TXS}: err:", err, "connIn:", connIn.toString()
            if err
              cb err, connIn
              return
            @core.getMyData 'global-AllPublicTxsRequest', connIn.toString()
          )
        else
          ignoreNotSupported err, cb
          return '{ "code": "753" }'


    # getting purchased files
    @core.globalEmitter.on 'global-PurchasedRequest', ->
      console.log 'purchased files request here'
      # sending request to host node for getting purchased files
      hostId = PeerId.createFromB58String @hostPeerB58Id 
      hostPeerInfo = new PeerInfo(hostId)
      browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_GET_PURCHASED, (err, connOut) =>
        if err is null
          tx = { data: 'Purchased' }
          pull pull.values(tx), connOut, pull.collect((err, connIn) =>
            console.log "<== #{proto.PROTO_GET_PURCHASED}: err:", err, "connIn:", connIn.toString()
            if err
              cb err, connIn
              return
            @core.getMyData 'global-PurchasedRequest', connIn.toString()
          )
        else
          ignoreNotSupported err, cb
          return '{ "code": "754" }'


    # getting my wallet info
    @core.globalEmitter.on 'global-MyWalletInfo', ->
      requestMyInfo 'global-MyWalletInfo'


    # initiating the request for coins transfer from web UI
    @core.globalEmitter.on 'global-Transfer', (tx) ->
      console.log 'on global-Transfer:', tx, typeof tx
      hostId = PeerId.createFromB58String @hostPeerB58Id 
      hostPeerInfo = new PeerInfo(hostId)
      startCnt = new Date()
      browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_TRANSFER_WEB1, (err, connOut) =>
        if err is null
          [ tx.id, tx.ts ] = getUniqueIds()
          tx.amount = parseInt(tx.amount)
          pull pull.values([ JSON.stringify(tx) ]), connOut, pull.collect((err, connIn) =>
            console.log "<== #{proto.PROTO_TRANSFER_WEB1}: err:", err, "connIn:", connIn.toString()
            if err
              cb err, connIn
              return
            @core.getMyData 'global-Transfer', connIn.toString()
          )
        else
          ignoreNotSupported err, cb
          return '{ "code": "759" }'


    # good news about successfully executed transaction
    browserPeerNode.handle proto.PROTO_PURCHASE7, (protocol, conn) =>
      pull conn, pull.map((v) =>
        console.log "==>", protocol, 'v=', v.toString()
        endCnt = new Date()
        @core.getMyData 'global-BuyTxRequest', (v.toString().replace /{duration}/, endCnt - startCnt)
      ), conn
      return '{ "code": "755" }'


    # good news about successfully executed transfer
    browserPeerNode.handle proto.PROTO_TRANSFER_WEB3, (protocol, conn) =>
      pull conn, pull.map((v) =>
        console.log "==>", protocol, 'v=', v.toString()
        endCnt = new Date()
        @core.getMyData 'global-Transfer', (v.toString().replace /{duration}/, endCnt - startCnt)
      ), conn
      return '{ "code": "715" }'


    browserPeerNode.on 'peer:connect', (peerConnected) =>
      peerConnectedB58Id = peerConnected.id.toB58String()
      console.log 'got connection to:', peerConnectedB58Id

      # saving status/ping/country of connected node for further usage
      # TODO: https://github.com/libp2p/js-libp2p-ping to measure ping?
      startCnt = new Date()
      browserPeerNode.dialProtocol peerConnected, proto.PROTO_WHORU, (err, connOut) =>
        if err is null
          tx = { data: 'whoru' }
          pull pull.values(tx), connOut, pull.collect((err, connIn) =>
            console.log "<== #{proto.PROTO_WHORU}: err:", err, "connIn:", connIn.toString()
            if err
              cb err, connIn
              return
            t = JSON.parse(connIn.toString())
            @core.peerNicks[peerConnectedB58Id] = t.nick
            @core.peerModes[peerConnectedB58Id] = t.mode
            @core.peerLocations[peerConnectedB58Id] = t.location
            console.log "ping #{@core.browserPeerB58Id}-#{peerConnectedB58Id}:", new Date() - startCnt
            # TODO: to gather ping from host node, not from browser one
            @core.peerPings[peerConnectedB58Id] = new Date() - startCnt
            @core.peerPubs[peerConnectedB58Id] = t.pub
            if t.mode == 'seller'
              @core.getMyData 'global-SellerInfo', JSON.stringify(t.stores[0])
            return '{ "code": "127" }'
          )
        else
          ignoreNotSupported err, cb
          return '{ "code": "756" }'

      # request for my info from own host node
      if @hostPeerB58Id  == peerConnectedB58Id
        requestMyInfo 'global-MyInfo'
      return


    browserPeerNode.on 'peer:discovery', (peerDiscovered) =>
      peerDiscoveredB58Id = peerDiscovered.id.toB58String()
      # console.log 'discovered a peer:', peerDiscoveredB58Id
      browserPeerNode.dial(peerDiscovered, () -> {})
      return


    browserPeerNode.on 'peer:disconnect', (peerLost) =>
      # TODO: to display "offline" status under the correspondent store
      lostPeerB58Id = peerLost.id.toB58String()
      console.log 'lost connection to:', lostPeerB58Id
      if @core.peerNames[lostPeerB58Id]?
        delete @core.peerNames[lostPeerB58Id]
      delete @core.peerNicks[lostPeerB58Id]
      delete @core.peerModes[lostPeerB58Id]
      delete @core.peerLocations[lostPeerB58Id]
      delete @core.peerPings[lostPeerB58Id]
      delete @core.peerPubs[lostPeerB58Id]
      return


    browserPeerNode.start (err) ->
      if err
        console.log 'hmmm, err on start:', err
      cb null, browserPeerNode
