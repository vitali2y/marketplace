#
# Marketplace Front-End
#

require "vueify/lib/insert-css"

# importing particular icons from Font Awesome set
Icon = require 'vue-awesome/components/Icon'
Vue.component('icon', Icon)
require 'vue-awesome/icons/question-circle-o'
require 'vue-awesome/icons/file-audio-o'
require 'vue-awesome/icons/file-text-o'
require 'vue-awesome/icons/file-video-o'
require 'vue-awesome/icons/file-archive-o'
require 'vue-awesome/icons/picture-o'

require 'vue-awesome/icons/bank'
require 'vue-awesome/icons/commenting'
require 'vue-awesome/icons/shopping-cart'
require 'vue-awesome/icons/star'
require 'vue-awesome/icons/eye'
require 'vue-awesome/icons/bars'

Core = require "../browser/core"


# inter-components global event bus
bus = new Vue
Object.defineProperties Vue.prototype, $bus: get: ->
  bus


# # TODO: to split into separated component files
# Search = require './components/Search.vue'  # template: '<div>search</div>'


# bridge component for collaboration with external services thru libp2p stack
bridge = new Vue(
  el: '#bridge'

  mounted: ->
    @hostPeerB58Id  = document.location.href.split('?')[1][0..45]
    @$bus.$on 'start-buy', (@tx, cb) =>
      console.log 'purchasing: 3 of Y:', @tx
      cb 'Initiating a purchase transaction...'
    @$bus.$on 'get-all-txs', (cb) =>
      @isAllTxsRequest = true
    @$bus.$on 'get-my-info', (cb) =>
      @isMyInfoRequest = true

  # see @core.bridge
  data:
    tx: '{}'           # purchase transaction, if any
    txs: false         # all executed transactions request, if any
    hostPeerB58Id : '' # my host (on the client, not this browser's) peer id
    isMyInfoRequest: false
    isAllTxsRequest: false

  methods:
    setMyInfo: (data) ->
      @$bus.$emit 'get-my-info-received', data
    setSellerInfo: (data) ->
      @$bus.$emit 'seller-info-received', data
    informPurchaseStatus: (data) ->
      @$bus.$emit 'notify-user', 'success', data, ->
        console.log 'purchasing:', data
    setAllTxs: (txs) ->
      @$bus.$emit 'get-all-txs-received', txs
)


# starting up the node inside the browser
startNode new Core(bridge), (err) ->
  console.log "starting browser's node:", err


# navigation bar component
new Vue(
  el: '#navbar'

  methods:
    modal: (app) ->
      @$bus.$emit "open-modal-#{app}"
    app: (appName) ->
      @$bus.$emit 'activate-app', name: '#app-' + appName
)


# home component
new Vue(
  el: '#app-home'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true

  data:
    isActive: true
)


# my transactions component
new Vue(
  el: '#app-tx'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
        @$bus.$emit 'get-all-txs'
    @$bus.$on 'get-tx', (txId) =>
      for t in @txs
        if txId == t.id
          @$bus.$emit 'get-tx-returned', t
    @$bus.$on 'get-all-txs-received', (txs) =>
      console.log 'on get-all-txs-received:', txs
      @txs = JSON.parse(txs).data
      # sorting by timestamp
      @txs.sort @sortByProperty('ts')
      # TODO: how to do it better?
      for i in @txs
        i.all = JSON.stringify(i)
        i.ts = @getFormattedDate(i.ts)

  data:
    isActive: false
    txs:      []

  methods:
    getFormattedDate: (ts) ->
      date = new Date(ts * 1000)
      month = date.getMonth() + 1
      day = date.getDate()
      hour = date.getHours()
      min = date.getMinutes()
      sec = date.getSeconds()
      month = (if month < 10 then '0' else '') + month
      day = (if day < 10 then '0' else '') + day
      hour = (if hour < 10 then '0' else '') + hour
      min = (if min < 10 then '0' else '') + min
      sec = (if sec < 10 then '0' else '') + sec
      str = date.getFullYear() + '-' + month + '-' + day + ' ' + hour + ':' + min
      str
    sortByProperty: (prop) ->
      (x, y) ->
        if x[prop] == y[prop] then 0 else if x[prop] > y[prop] then -1 else 1
    txView: (evt) ->
      @$bus.$emit "open-modal-txview", evt.path[4].id
)


# search component
new Vue(
  el: '#app-search'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true

  data:
    isActive: false
)


# list of stores component
myStores = new Vue(
  el: '#app-stores'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
    @$bus.$on 'get-seller-by-file-id', (id, cb) =>
      console.log 'on get-seller-by-file-id:', id
      for s in @stores
        for i in s.items
          if i.id == id
            cb s.id, s.user_id, s.name
            return
    @$bus.$on 'seller-info-received', (data) =>
      console.log 'on seller-info-received:', data
      i = 0
      for s in @stores
        if s?
          if s.id == data.stores[0].id
            @stores.splice(i, 1)
            break
          i+=1
      @stores.push data.stores[0]

  data:
    currentStoreId:   ''
    currentStoreName: ''
    stores:    []
    isActive:  true

  props: [ 'selected' ]

  methods:
    getFiles: (selectedStoreId) ->
      for s in @stores
        if s.id == selectedStoreId
          return s.items
    storeSelected: (evt) ->
      @currentStoreId = evt.path[1].id
      for s in @stores
        if s.id == @currentStoreId
          @currentStoreName = s.name
      console.log 'currentStoreId:', @currentStoreId, 'currentStoreName:', @currentStoreName
      @$bus.$emit 'get-files', @currentStoreId, @currentStoreName, @getFiles(@currentStoreId)
)


# list of files component
new Vue(
  el: '#app-files'

  mounted: ->
    @$bus.$on 'get-files', (@currentStoreId, @currentStoreName, @files) =>
      @$bus.$emit 'activate-app', name: '#app-files'
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true

  data:
    files: []
    currentStoreId: ''
    currentStoreName: ''
    isActive: false

  # # TODO:
  # computed:
  #   ts: ->
  #     @ts[0..9]

  methods:
    storeComments: (evt) ->
      console.log 'storeComments:', @currentStoreId
      @$bus.$emit 'open-modal-tbd', 'Others Talk About Store'
    storeRating: (evt) ->
      console.log 'storeRating:', @currentStoreId
      @$bus.$emit 'open-modal-tbd', 'Store Rating'
    fileComments: (evt) ->
      console.log 'fileComments:', evt.path[7].id
      @$bus.$emit 'open-modal-tbd', 'Others Talk About Product'
    fileRating: (evt) ->
      console.log 'fileRating:', evt.path[7].id
      @$bus.$emit 'open-modal-tbd', 'Product Rating'
    filePreview: (evt) ->
      console.log 'filePreview:', evt.path[7].id
      @$bus.$emit 'open-modal-tbd', 'Product Preview'
    fileBuy: (evt) ->
      # TODO: redo
      _id = ''
      if evt.path[7].nodeName == "TR"
        _id = evt.path[7].id
      else
        _id = evt.path[8].id
      console.log 'fileBuy:', _id
      for _i in @files
        if _i.id == _id
          @$bus.$emit 'open-modal-buy', data: _i
          break
)


# TBD popup
new Vue(
  el: '#modal-tbd'

  mounted: ->
    @$bus.$on 'open-modal-tbd', (msg) =>
      console.log 'on open-modal-tbd:', msg
      @msg = msg
      @isActive = true

  methods:
    close: ->
      @isActive = false

  data:
    msg: ''
    isActive: false
)


# network map popup
new Vue(
  el: '#modal-map'

  mounted: ->
    @$bus.$on 'open-modal-map', =>
      console.log 'on open-modal-map'
      @isActive = true
      @render()
  
  methods:
    close: ->
      @isActive = false
    render: ->

      # TODO: do it in Vue style?
      # TODO: is it possible to use "vue-awesome" instead of current "font-awesome.css"?
      optionsMap =
        groups:
          browsers:
            shape: 'icon'
            icon:
              face: 'FontAwesome'
              code: '\uf108'
              size: 50
              color: 'red'
          buyers:
            shape: 'icon'
            icon:
              face: 'FontAwesome'
              code: '\uf07a'
              size: 50
              color: 'red'
          sellers:
            shape: 'icon'
            icon:
              face: 'FontAwesome'
              code: '\uf0ac'
              size: 50
              color: 'orange'
          witnesses:
            shape: 'icon'
            icon:
              face: 'FontAwesome'
              code: '\uf0a0'
              size: 50
              color: 'limegreen'

      # create an array with nodes
      nodesArray = [
        {
          id: 1
          label: "Alice's browser"
          title: 'This is a marketplace under your browser'
          group: 'browsers'
        }
        {
          id: "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61"
          label: 'Alice'
          title: 'Node: QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61, balance: X'
          group: 'buyers'
        }
        {
          id: "QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h"
          label: 'Bob'
          title: 'Node: QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h, balance: X'
          group: 'sellers'
        }
        {
          id: "Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg"
          label: 'Tom'
          title: 'Node: Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg, balance: X'
          group: 'sellers'
        }
        {
          id: "QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL"
          label: 'James'
          title: 'Node: QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL, balance: X'
          group: 'sellers'
        }
        {
          id: "QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ"
          label: 'CL-1'
          title: 'Node: QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ, balance: X'
          group: 'witnesses'
        }
      ]
      nodes = new (vis.DataSet)(nodesArray)

      # create an array with edges
      edgesArray = [
        {
          from: "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61"
          to: 1
          # arrows: 'to, from'
          dashes: true
        }
        {
          from: "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61"
          to: "QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h"
        }
        {
          from: "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61"
          to: "Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg"
        }
        {
          from: "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61"
          to: "QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL"
        }
        {
          from: "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61"
          to: "QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ"
        }
        {
          from: "QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h"
          to: "QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL"
        }
        {
          from: "QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h"
          to: "QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ"
        }
        {
          from: "Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg"
          to: "QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h"
        }
        {
          from: "Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg"
          to: "QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL"
        }
        {
          from: "Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg"
          to: "QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ"
        }
        {
          from: "QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL"
          to: "QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ"
        }
      ]
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

  data:
    isActive: false
    # users: [ "QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61": "Alice", "QmWNi2wgUGDm7weopRAe7WKvr38M5EA6HBjsUA8UNTQk3h": "Bob", "Qmcc6oWA9Mz4e1u7Bgg4j7E9KYmG5UrckwCH1oDh6CTfyg": "Tom", "QmYLhqmsZYUTcVPWhoJK1UFDK2E9wWPJ6S5x1dTf3PRbSL": "James", "QmNrw7pSJNvW1VDUHePb2M6oPWB6zMW2yRfJXDZyrphyVZ": "CL-1" ]
)


# login as popup
new Vue(
  el: '#modal-loginas'

  mounted: ->
    @$bus.$on 'open-modal-loginas', =>
      console.log 'on open-modal-loginas'
      @isActive = true

  methods:
    close: ->
      @isActive = false
    loginAs: ->
      console.log 'loginAs()'
      q = document.getElementById("loginas")
      location.href = location.href.split("?")[0] + "?" + q.options[q.selectedIndex].id

  data:
    isActive: false
)


# my info popup
new Vue(
  el: '#modal-user'

  mounted: ->
    @$bus.$on 'get-user-address', (cb) =>
      cb @address
      return
    @$bus.$on 'get-my-info-received', (user) =>
      console.log 'on get-my-info-received:', user
      @name = user.name
      @email = user.email
      @mode = user.mode
      @balance = user.balance
      @address = user.id
      @isActive = true
    @$bus.$on 'open-modal-user', (message) =>
      @$bus.$emit 'get-my-info'

  data:
    name: ''
    email: ''
    mode: ''
    balance: ''
    address: ''
    isActive: false

  methods:
    close: ->
      @isActive = false
)


# purchase item popup
new Vue(
  el: '#modal-buy'

  mounted: ->
    @$bus.$on 'open-modal-buy', (msg) =>
      console.log 'on open-modal-buy:', msg.data
      @id = msg.data.id
      @name = msg.data.name
      @mime = msg.data.mime
      @type = msg.data.type
      @price = msg.data.price
      @checked = [ 'email' ]
      @picked = [ '0' ]

      @$bus.$emit('get-seller-by-file-id', @id, (@store_id, @sellerAddress, @sellerName) =>
        @$bus.$emit 'get-user-address', (addr) =>
          @address = addr
        @isActive = true
      )

  data:
    id: ''
    name: ''
    mime: ''
    type: ''
    price: ''
    sellerName: ''
    sellerAddress: ''
    store_id: ''
    checked: [ ]
    picked: [ ]
    address: ''
    isActive: false

  methods:
    close: ->
      @isActive = false
    buy: ->
      @close()
      @$bus.$emit 'notify-user', 'success', 'Preparing for purchase transaction, please wait...', =>
        console.log 'purchasing: 1 of Y'
        @$bus.$emit 'start-buy', JSON.stringify({ buyer: @address, seller: @sellerAddress, price: @price, store_id: @store_id, file_id: @id }), (msg) =>
          console.log 'purchasing: 2 of Y:', msg
          @$bus.$emit 'notify-user', 'success', msg, =>
            console.log 'purchasing: 5 of Y'
)


# view transaction popup
new Vue(
  el: '#modal-txview'

  mounted: ->
    @$bus.$on 'get-tx-returned', (txBody) =>
      delete txBody.all
      # TODO: how to ignore 'ts' conversion?
      @txContent = JSON.stringify(txBody, null, 2)
      @isActive = true
    @$bus.$on 'open-modal-txview', (@txId) =>
      console.log 'on open-modal-txview:', @txId
      @$bus.$emit 'get-tx', @txId

  data:
    txId: ''
    txContent: ''
    isActive: false

  methods:
    close: ->
      @isActive = false
)


# notify user toast component
new Vue(
  el: '#toast'

  mounted: ->
    # notify user thru raising toast popup
    @$bus.$on 'notify-user', (@isSuccess, @msg, cb) =>
      @isActive = true
      setTimeout (=>
        @isActive = false
        cb()
        return
      ), 3000
      return

  data:
    msg:       ''
    isActive:  false
    isSuccess: true
)
