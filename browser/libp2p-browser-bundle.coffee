#
# Marketplace browser's libp2p-based peer
#

PeerId = require "peer-id"
PeerInfo = require "peer-info"
multiaddr = require "multiaddr"
WSStar = require "libp2p-websocket-star"
MulticastDNS = require "libp2p-mdns"
pull = require "pull-stream"

Node = require "./libp2p-bundle"
proto = require "./proto"


browserPeerNode = undefined


window.startNode = (@core, cb) ->

  # request for my own info
  requestMyInfo = ->
    hostId = PeerId.createFromB58String @core.bridge.hostPeerB58Id 
    hostPeerInfo = new PeerInfo(hostId)     
    browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_GET_MY_INFO, (err, connOut) =>
      console.log 'browserPeerNode=', browserPeerNode
      if err is null
        tx = { data: browserPeerNode.peerInfo.id.toB58String() }
        pull pull.values(tx), connOut, pull.collect((err, connIn) =>
          if err
            cb err, connIn
            return
          @core.setMyInfo connIn
        )
      else
        # ignoring 'Error: "/new/0.0.1" not supported', etc
        m = /Error: (.*) not supported/i.exec err.toString()
        if m == null
          cb err, connOut
        else
          cb true, err.toString()


  PeerInfo.create (err, peerInfo) ->
    if err
      cb err
      return
    # TODO: how to prevent this multiaddr hardcode?
    peerInfo.multiaddrs.add multiaddr '/dns4/localhost/tcp/9090/ws/p2p-websocket-star'
    # peerInfo.multiaddrs.add multiaddr '/dns4/ws-star-signal-4.servep2p.com/tcp/443/wss/p2p-websocket-star'
    ws = new WSStar(id: peerInfo)
    mdns = new MulticastDNS(peerInfo, { interval: 2000 })
    modules = 
      transport: [ ws ]
      mdns: mdns
      discovery: [ ws.discovery, mdns.discovery ]
    browserPeerNode = new Node(peerInfo, undefined, modules)


    # browser's node cannot be witness
    browserPeerNode.handle proto.PROTO_TX_STEP2, (protocol, conn) =>
      pull conn, pull.map((v) =>
        console.log 'protocol:', protocol, 'v=', v.toString()
        '{ "code": "1" }'
      ), conn


    # ignore witness's dial to browser's node
    browserPeerNode.handle proto.PROTO_TX_STEP4, (protocol, conn) =>
      pull conn, pull.map((v) =>
        console.log 'protocol:', protocol, 'v=', v.toString()
        '{ "code": "1" }'
      ), conn

    # ignore witness's dial to browser's node
    browserPeerNode.handle proto.PROTO_TX_STEP5, (protocol, conn) =>
      pull conn, pull.map((v) =>
        console.log 'protocol:', protocol, 'v=', v.toString()
        '{ "code": "1" }'
      ), conn

    # good news about successfully executed transaction
    browserPeerNode.handle proto.PROTO_TX_STEP6, (protocol, conn) =>
      pull conn, pull.map((v) =>
        console.log "protocol:", protocol, 'v=', v.toString()
        # TODO: to chk 'code'
        @core.getTxStep6(JSON.parse(v.toString()).id)
      ), conn

    browserPeerNode.on 'peer:connect', (peerConnected) =>
      peerConnectedB58Id = peerConnected.id.toB58String()
      console.log 'got connection to:', peerConnectedB58Id
      if @core.bridge.hostPeerB58Id  == peerConnectedB58Id
        console.log '@core:', @core
        requestMyInfo()

      # request for online seller's stores/products, if seller
      browserPeerNode.dialProtocol peerConnected, proto.PROTO_GET_SELLER_INFO, (err, data) =>
        if err is null
          tx = { data: 'seller-info' }
          pull pull.values(tx), data, pull.collect((err, data) =>
            console.log "#{proto.PROTO_GET_SELLER_INFO}: err:", err, "data:", data
            if err
              cb err, data
              return
            @core.setSellerInfo data
          )
        else
          # ignoring 'Error: "/new/0.0.1" not supported', etc
          m = /Error: (.*) not supported/i.exec err.toString()
          if m == null
            cb err, data
          else
            cb true, err.toString()
      return


    browserPeerNode.on 'peer:discovery', (peerDiscovered) =>
      peerDiscoveredB58Id = peerDiscovered.id.toB58String()
      console.log 'discovered a peer:', peerDiscoveredB58Id

      # initiating the purchase request
      # TODO: to make purchase initiation faster
      if @core.bridge.hostPeerB58Id  == peerDiscoveredB58Id
        t = @core.getPurchaseTxRequest()
        # TODO: chk tx properly
        if JSON.parse(t).seller?   # is transaction already initiated?
          browserPeerNode.dialProtocol peerDiscovered, proto.PROTO_TX_STEP1, (err, connOut) =>
            if err is null
              tx = { data: t }
              console.log 'tx:', tx
              pull pull.values(tx), connOut, pull.collect((err, connIn) =>
                console.log "#{proto.PROTO_TX_STEP1}: err:", err, "connIn:", connIn
                if err
                  cb err, connIn
                  return
                @core.getTxStep1 connIn
              )
            else
              # ignoring 'Error: "/new/0.0.1" not supported', etc
              m = /Error: (.*) not supported/i.exec err.toString()
              if m == null
                cb err, connOut
              else
                cb true, err.toString()
      else
        browserPeerNode.dial(peerDiscovered, () => {})
      return


    browserPeerNode.on 'peer:disconnect', (peerLost) ->
      console.log 'lost connection to:', peerLost.id.toB58String()
      return


    # polling and reacting on external events
    window.setInterval (=>
      if @core.getMyInfoRequest()
        requestMyInfo()
        @core.resetMyInfoRequest()

      if @core.getAllTxsRequest()
        # sending request to host node for getting all transactions
        hostId = PeerId.createFromB58String @core.bridge.hostPeerB58Id 
        hostPeerInfo = new PeerInfo(hostId)         
        browserPeerNode.dialProtocol hostPeerInfo, proto.PROTO_GET_ALL_TXS, (err, connOut) =>
          if err is null
            tx = { data: 'something' }
            pull pull.values(tx), connOut, pull.collect((err, connIn) =>
              console.log "#{proto.PROTO_GET_ALL_TXS}: err:", err, "connIn:", connIn.toString()
              if err
                cb err, connIn
                return
              @core.resetAllTxsRequest()
              @core.setAllTxs connIn.toString()
            )
          else
            # ignoring 'Error: "/new/0.0.1" not supported', etc
            m = /Error: (.*) not supported/i.exec err.toString()
            if m == null
              cb err, connOut
            else
              cb true, err.toString() 
    ), 1000


    browserPeerNode.start (err) ->
      if err
        cb err
        return
      cb null, browserPeerNode