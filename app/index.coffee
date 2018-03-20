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

require 'vue-awesome/icons/link'
require 'vue-awesome/icons/info-circle'
require 'vue-awesome/icons/cubes'
require 'vue-awesome/icons/sitemap'
require 'vue-awesome/icons/search'
require 'vue-awesome/icons/plug'
require 'vue-awesome/icons/compass'


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
    @$bus.$on 'get-all-private-txs', (cb) =>
      @isAllPrivateTxsRequest = true
    @$bus.$on 'get-all-public-txs', (cb) =>
      @isAllPublicTxsRequest = true
    @$bus.$on 'get-my-info', (cb) =>
      @isMyInfoRequest = true

  # see @core.bridge
  data:
    tx: '{}'           # purchase transaction, if any
    txs: false         # all executed transactions request, if any
    hostPeerB58Id : '' # my host (on the client, not this browser's) peer id
    isMyInfoRequest: false
    isAllPrivateTxsRequest: false
    isAllPublicTxsRequest: false

  methods:
    setMyInfo: (data) ->
      @$bus.$emit 'get-my-info-received', data
    setSellerInfo: (data) ->
      @$bus.$emit 'seller-info-received', data
    informPurchaseStatus: (data, isDone) ->
      if isDone?
        @$bus.$emit 'stop-progressbar'
      @$bus.$emit 'notify-user', 'success', data, ->
        console.log 'purchasing:', data
    setAllPrivateTxs: (txs) ->
      @$bus.$emit 'get-all-private-txs-received', txs
    setAllPublicTxs: (txs) ->
      @$bus.$emit 'get-all-public-txs-received', txs
)


# starting up the node inside the browser
if not startNode?   # sometimes during first start it's not initialized - so, reloading
  location.reload()
startNode new Core(bridge), (err) ->
  console.log "starting browser's node:", err


# navigation bar component
new Vue(
  el: '#navbar'

  methods:
    modal: (appName) ->
      @$bus.$emit "open-modal-#{appName}"
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

  methods:
    modal: (appName) ->
      @$bus.$emit "open-modal-#{appName}"
    app: (appName) ->
      @$bus.$emit 'activate-app', name: '#app-' + appName

  data:
    isActive: true
)


# "My Transactions" component
new Vue(
  el: '#app-tx'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
        @$bus.$emit 'get-all-private-txs'
        @$bus.$emit 'start-progressbar'
    @$bus.$on 'get-private-tx', (txId) =>
      for t in @txs
        if txId == t.id
          @$bus.$emit 'get-private-tx-returned', t
    @$bus.$on 'get-all-private-txs-received', (txs) =>
      @$bus.$emit 'stop-progressbar'
      console.log 'on get-all-private-txs-received:', txs
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
    txView: (txId) ->
      @$bus.$emit "open-modal-txview", "private", txId
)


# "Blockchain Explorer" component
new Vue(
  el: '#app-explorer'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
        @$bus.$emit 'get-all-public-txs'
        @$bus.$emit 'start-progressbar'
    @$bus.$on 'get-public-tx', (txId) =>
      for t in @txs
        if txId == t.id
          @$bus.$emit 'get-public-tx-returned', t
    @$bus.$on 'get-all-public-txs-received', (txs) =>
      @$bus.$emit 'stop-progressbar'
      console.log 'on get-all-public-txs-received:', txs
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
    txView: (txId) ->
      @$bus.$emit "open-modal-txview", "public", txId
)


# "Search" component
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
new Vue(
  el: '#app-stores'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
        @$bus.$emit 'start-progressbar'
    @$bus.$on 'get-seller-by-file-id', (id, cb) =>
      console.log 'on get-seller-by-file-id:', id
      for s in @stores
        for i in s.items
          if i.id == id
            cb s.id, s.user_id, s.name
            return
    @$bus.$on 'seller-info-received', (data) =>
      @$bus.$emit 'stop-progressbar'
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
    storeSelected: (@currentStoreId) ->
      for s in @stores
        if s.id == @currentStoreId
          @currentStoreName = s.name
      console.log 'currentStoreId:', @currentStoreId, 'currentStoreName:', @currentStoreName
      @$bus.$emit 'get-files', @currentStoreId, @currentStoreName, @getFiles(@currentStoreId)
      @$bus.$emit 'stop-progressbar'
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

  methods:
    storeComments: (storeId) ->
      console.log 'storeComments:', @currentStoreId, storeId
      @$bus.$emit 'open-modal-tbd', 'Others Talk About Store'
    storeRating: (storeId) ->
      console.log 'storeRating:', @currentStoreId, storeId
      @$bus.$emit 'open-modal-tbd', 'Store Rating'
    fileComments: (fileId) ->
      console.log 'fileComments:', fileId
      @$bus.$emit 'open-modal-tbd', 'Others Talk About Product'
    fileRating: (fileId) ->
      console.log 'fileRating:', fileId
      @$bus.$emit 'open-modal-tbd', 'Product Rating'
    filePreview: (fileId) ->
      console.log 'filePreview:', fileId
      @$bus.$emit 'open-modal-tbd', 'Product Preview'
    fileBuy: (fileId) ->
      console.log 'fileBuy:', fileId
      for i in @files
        if i.id == fileId
          @$bus.$emit 'open-modal-buy', data: i
          break
    getTs: (ts) ->

      _pad = (val) ->
        if (val.toString().length < 2) then "0" + val else val

      nts = /^(\d{4})-0?(\d+)-0?(\d+)[T ]0?(\d+):0?(\d+):0?(\d+)/i.exec ts
      nts[2] + '/' + _pad nts[3] + '/' + nts[1] + ' ' + _pad nts[4] + ':' + _pad nts[5]
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


# 'Network Map' popup
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


# 'My Info' popup
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


# 'Purchase Item' popup
new Vue(
  el: '#modal-buy'

  mounted: ->
    @$bus.$on 'open-modal-buy', (msg) =>
      console.log 'on open-modal-buy:', JSON.stringify msg.data
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
      @$bus.$emit 'start-progressbar'
      @close()
      @$bus.$emit 'notify-user', 'success', 'Preparing for purchase transaction, please wait...', =>
        console.log 'purchasing: 1 of Y'
        @$bus.$emit 'start-buy', JSON.stringify({ buyer: @address, seller: @sellerAddress, price: @price, store_id: @store_id, file_id: @id }), (msg) =>
          console.log 'purchasing: 2 of Y:', msg
          @$bus.$emit 'notify-user', 'success', msg, =>
            console.log 'purchasing: 5 of Y'
)


# "Transaction #" popup
new Vue(
  el: '#modal-txview'

  mounted: ->
    @$bus.$on 'get-private-tx-returned', (txBody) =>
      delete txBody.all
      # TODO: how to ignore 'ts' conversion?
      @txContent = JSON.stringify(txBody, null, 2)
      @isActive = true
    @$bus.$on 'open-modal-txview', (txType, @txId) =>
      console.log 'on open-modal-txview:', txType, @txId
      if txType == "private"
        @$bus.$emit 'get-private-tx', @txId
      if txType == "public"
        @$bus.$emit 'get-public-tx', @txId
    @$bus.$on 'get-public-tx-returned', (txBody) =>
      delete txBody.all
      # TODO: how to ignore 'ts' conversion?
      @txContent = JSON.stringify(txBody, null, 2)
      @isActive = true

  data:
    txId: ''
    txContent: ''
    isActive: false

  methods:
    close: ->
      @isActive = false
)


# notify user component thru raising toast popup
new Vue(
  el: '#toast'

  mounted: ->
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


# loading progress bar component
new Vue(
  el: '#progressbar'

  mounted: ->
    @$bus.$on 'start-progressbar', =>
      @start()
    @$bus.$on 'stop-progressbar', =>
      @stop()
    @start()

  data:
    progressBar: undefined
    percentProgressBar: 0

  computed: valProgressBar: ->
    "width: #{@percentProgressBar}%"

  methods:
    start: ->
      @progressBar = setInterval (=>
        @percentProgressBar+=5
        if @percentProgressBar >= 105  then @percentProgressBar = 0
        return
      ), 30

    stop: ->
      clearInterval @progressBar
      @percentProgressBar = 0
)
