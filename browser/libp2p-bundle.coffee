#
# Marketplace browser's libp2p bundle
#

TCP = require "libp2p-tcp"
MulticastDNS = require "libp2p-mdns"
WS = require "libp2p-websockets"
WebSocketStar = require "libp2p-websocket-star"
Railing = require "libp2p-railing"
KadDHT = require "libp2p-kad-dht"
Multiplex = require "libp2p-multiplex"
SECIO = require "libp2p-secio"
libp2p = require "libp2p"


class Node extends libp2p

  constructor: (peerInfo, peerBook, modules) ->
    modules = modules or {}
    wsstar = new WebSocketStar(id: peerInfo.id)
    modules = 
      transport: [
        new TCP
        new WS
        wsstar
      ]
      connection:
        muxer: [ Multiplex ]
        crypto: [ SECIO ]
      discovery: [ wsstar.discovery ]
    if modules.dht
      modules.DHT = KadDHT
    if modules.mdns
      mdns = new MulticastDNS(peerInfo, 'ipfs.local')
      modules.discovery.push mdns
    if modules.bootstrap
      r = new Railing(modules.bootstrap)
      modules.discovery.push r

    if modules.modules and modules.modules.transport
      modules.modules.transport.forEach (t) ->
        modules.transport.push t
    if modules.modules and modules.modules.discovery
      modules.modules.discovery.forEach (d) ->
        modules.discovery.push d

    super(modules, peerInfo, peerBook, modules)


module.exports = Node
