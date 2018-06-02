#
# Marketplace browser's network map module
#

class Map

  constructor: (hostPeerB58Id, browserType) ->
    console.log "Map (#{hostPeerB58Id}, #{browserType})"
    optionsMap =
      groups:
        browser:
          shape: 'icon'
          icon:
            face: 'FontAwesome'
            code: '\uf108'
            size: 50
            color: 'red'
        buyer:
          shape: 'icon'
          icon:
            face: 'FontAwesome'
            code: '\uf07a'
            size: 50
            color: 'red'
        seller:
          shape: 'icon'
          icon:
            face: 'FontAwesome'
            code: '\uf0ac'
            size: 50
            color: 'orange'
        witness:
          shape: 'icon'
          icon:
            face: 'FontAwesome'
            code: '\uf0a0'
            size: 50
            color: 'limegreen'

    if browserType == "seller"
      optionsMap.groups.browser.icon.color = 'orange'
    if browserType == "witness"
      optionsMap.groups.browser.icon.color = 'limegreen'

    console.log 'core.browserPeerB58Id=', core.browserPeerB58Id, 'core.peerModes:', core.peerModes, 'core.peerNames:', core.peerNames, 'core.peerNicks:', core.peerNicks, 'core.peerPings:', core.peerPings

    # create an array with nodes
    nodesArray = []
    for u of core.peerModes
      if core.peerModes[u] == 'browser'
        [ i, l, t ] = [ u, 'My Browser', 'This marketplace site in browser<br>Address: ' + u ]
      else
        [ i, l, t ] = [ u, core.peerNicks[u], "Address: #{u}<br>Location: #{core.peerLocations[u]}<br>Balance: TBD<br>Click to login under this account: TBD" ]
      nodesArray.push { id: u, label: l, title: t, group: core.peerModes[u] }
    nodes = new (vis.DataSet)(nodesArray)

    # create an array with edges
    edgesArray = []
    junk = {}
    for f of core.peerModes
      for t of core.peerModes
        if (f != t) and (core.peerModes[f] != 'browser') and (core.peerModes[t] != 'browser') and (not junk[f + t]?) and (not junk[t + f]?)
          edgesArray.push { from: f, to: t }  # arrows: 'to, from'
          junk[f + t] = true

          # setting pings
          for e in edgesArray
            # console.log 'e:', e, e.to == hostPeerB58Id, core.peerPings[e.from]?, e.from == hostPeerB58Id, core.peerPings[e.to]?
            if e.to == hostPeerB58Id and core.peerPings[e.from]?
              e.label = "<i>#{core.peerPings[e.from]} ms</i>"
              e.font =
                multi: true
                align: "horizontal"
            if e.from == hostPeerB58Id and core.peerPings[e.to]?
              e.label = "<i>#{core.peerPings[e.to]} ms</i>"
              e.font =
                multi: true
                align: "horizontal"

    for n of core.peerModes
      if core.peerModes[n] == 'browser'
        edgesArray.push { from: n, to: hostPeerB58Id, dashes: true }
        break
    edges = new (vis.DataSet)(edgesArray)

    # re-render map dynamically
    rerender = ->
      nodes.clear()
      edges.clear()
      nodes.add nodesArray
      edges.add edgesArray
      # network.stabilize()
      return

    # create a network
    containerMap = document.getElementById('network-map')
    dataMap = 
      nodes: nodesArray
      edges: edgesArray
    networkMap = new (vis.Network)(containerMap, dataMap, optionsMap)
    networkMap.on 'click', (params) ->
      console.log 'clicked on node:', @getNodeAt(params.pointer.DOM)
      return
    rerender()


module.exports = Map
