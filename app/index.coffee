#
# Marketplace Front-End
#

require "vueify/lib/insert-css"
mitt = require "mitt"

require "./icons"
Core = require "./core"
Map = require "./map"


OP_SUCCESS = 0
OP_WARNING = 1
OP_ERROR = 2

globalEmitter = mitt()


isHostPeerDefined = ->
  document.location.href.split('?').length > 1


getHostPeerB58Id = ->
  document.location.href.split('?')[1][0..45]


sortByProperty = (prop) ->
  (x, y) ->
    if x[prop] == y[prop] then 0 else if x[prop] > y[prop] then -1 else 1


getFormattedDate = (ts) ->
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


getTs = (ts) ->

  _pad = (val) ->
    if (val.toString().length < 2) then "0" + val else val

  nts = /^(\d{4})-0?(\d+)-0?(\d+)[T ]0?(\d+):0?(\d+):0?(\d+)/i.exec ts
  nts[2] + '/' + _pad nts[3] + '/' + nts[1] + ' ' + _pad nts[4] + ':' + _pad nts[5]


# inter-components global event bus
bus = new Vue
Object.defineProperties Vue.prototype, $bus: get: ->
  bus


# # TODO: to split into separated component files
# Search = require './components/Search.vue'  # template: '<div>search</div>'


# starting up the node inside the browser
core = new Core(globalEmitter)
startNode core, (err) ->
  document.getElementsByClassName("container")[0].classList.remove("inactive")

  if isHostPeerDefined()
    globalEmitter.emit 'global-hostPeerInform', getHostPeerB58Id()


# navigation bar component
new Vue(
  el: '#navbar'

  mounted: ->
    @$bus.$on 'declare-user', (userInfo) =>
      console.log 'on declare-user:', userInfo
      if userInfo.hai == 'witness'
        @isDisabled = true
      @name = userInfo.name
    globalEmitter.on "global-BuyTxRequest-done", (msg) =>
      console.log "on global-BuyTxRequest-done:", msg
      @$bus.$emit 'notify-user', OP_SUCCESS, msg
      @purchasedIndicator += 1
      @$bus.$emit 'changed-indicator', 1
      # getting new balance after transaction
      globalEmitter.emit 'global-MyInfo'
      @$bus.$emit 'stop-progressbar'
    globalEmitter.on "global-Transfer-done", (msg) =>
      console.log "on global-Transfer-done:", msg
      @$bus.$emit 'stop-progressbar'
      @$bus.$emit 'notify-user', OP_SUCCESS, msg
      # getting new balance after transaction
      globalEmitter.emit 'global-MyInfo'
    @$bus.$on 'changed-indicator', (amount) =>
      @globalIndicator += amount
    @$bus.$on 'reset-indicator-purchased', =>
      @globalIndicator -= @purchasedIndicator
      @purchasedIndicator = 0

  methods:
    modal: (appName) ->
      @$bus.$emit "open-modal-#{appName}"
    app: (appName) ->
      @$bus.$emit 'activate-app', name: '#app-' + appName

  data:
    name: ''
    isDisabled: false
    globalIndicator: 0
    purchasedIndicator: 0
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
        globalEmitter.emit 'global-AllPrivateTxsRequest'
        @$bus.$emit 'start-progressbar'
    @$bus.$on 'get-private-tx', (txId) =>
      for t in @txs
        if txId == t.id
          @$bus.$emit 'get-private-tx-returned', t
    globalEmitter.on 'global-AllPrivateTxsRequest-done', (txs) =>
      console.log 'on global-AllPrivateTxsRequest-done:', txs
      @$bus.$emit 'stop-progressbar'
      @txs = JSON.parse txs
      # sorting by timestamp
      @txs.sort sortByProperty('ts')
      # TODO: how to do it better?
      for i in @txs
        i.all = JSON.stringify(i)
        i.ts = getFormattedDate(i.ts)

  data:
    isActive: false
    txs:      []

  methods:
    txView: (txId) ->
      @$bus.$emit "open-modal-txview", "private", txId
)


# "My Purchased Goods" component
new Vue(
  el: '#app-purchased'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
        globalEmitter.emit 'global-PurchasedRequest'
        @$bus.$emit 'start-progressbar'
    globalEmitter.on 'global-PurchasedRequest-done', (files) =>
      console.log 'on global-PurchasedRequest-done:', files
      @files = JSON.parse files
      @$bus.$emit 'stop-progressbar'
      @$bus.$emit 'reset-indicator-purchased'
      # sorting by timestamp
      @files.sort sortByProperty('ts')
      # TODO: how to do it better?
      for i in @files
        i.all = JSON.stringify(i)
        i.ts = getFormattedDate(i.ts)

  data:
    files: []
    isActive: false

  methods:
    getName: (hostedType, fileName) ->
      if hostedType == 'online'
        t = fileName.split '.'
        t.splice(t.length - 2, 2)
        return t.join '.'
      fileName
    purchasedPreview: (hostedType, fileId, fileName, fileMime, fileSize) ->
      console.log "purchasedPreview (#{hostedType}, #{fileId}, #{fileName}, #{fileMime}, #{fileSize})"
      @$bus.$emit "open-modal-preview", hostedType, fileId, fileName, fileMime, fileSize
)


# "Blockchain Explorer" component
new Vue(
  el: '#app-explorer'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
        globalEmitter.emit 'global-AllPublicTxsRequest'
        @$bus.$emit 'start-progressbar'
    @$bus.$on 'get-public-tx', (txId) =>
      for t in @txs
        if txId == t.id
          @$bus.$emit 'get-public-tx-returned', t
    globalEmitter.on 'global-AllPublicTxsRequest-done', (txs) =>
      console.log 'on global-AllPublicTxsRequest-done:', txs
      @txs = JSON.parse txs
      @$bus.$emit 'stop-progressbar'
      # sorting by timestamp
      @txs.sort sortByProperty('ts')
      # TODO: how to do it better?
      for i in @txs
        i.all = JSON.stringify(i)
        i.ts = getFormattedDate(i.ts)

  data:
    isActive: false
    txs:      []

  methods:
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
    # a workaround to open 'Login As' popup in 2 secs after last seller connected
    if not isHostPeerDefined()  # is account address pre-selected in browser's address bar?
      @timerId = setInterval @chkStoresUpdate, 100
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
            cb s.id, s.user_id, s.name, s.base, s.download
            return
    globalEmitter.on 'global-SellerInfo-done', (data) =>
      @$bus.$emit 'stop-progressbar'
      console.log 'on global-SellerInfo-done:', data
      console.log '@stores:', @stores
      data = JSON.parse data
      core.peerNames[data.user_id] = data.name
      if data.icon == 'cloud'
        data.root
      # updating stores list (new - added to the end, exist - replaced)
      i = 0
      isExist = false
      for s in @stores
        if s.id == data.id
          @stores.splice(i, 1, data)
          isExist = true
          break
        i += 1
      if not isExist
        @stores.push data

  data:
    currentStoreId:   ''
    currentStoreName: ''
    stores:    []
    isActive:  true
    amountStores: 0
    cnt: 0
    timerId: 0

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
    chkStoresUpdate: ->
      @cnt += 1
      if @cnt == 20  # time to open popup?
        clearTimeout @timerId
        @$bus.$emit 'notify-user', OP_SUCCESS, 'Welcome to our Marketplace! In order to start please download apps from "Download" menu, and run the client app!'
        @$bus.$emit 'open-modal-loginas'
        @$bus.$emit 'stop-progressbar'
        return
      if @stores.length > @amountStores
        @amountStores = @stores.length
        @cnt = 0
)


# list of files component
new Vue(
  el: '#app-files'

  mounted: ->
    @$bus.$on 'share-hai', (hai) =>
      console.log 'on share-hai:', hai
      if hai == 'witness'
        @isDisabled = true
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
    isDisabled: false

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
      getTs ts
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
      if isHostPeerDefined()
        @$bus.$emit 'get-user-mode', (mode) =>
          new Map(getHostPeerB58Id(), mode)
      else
        @$bus.$emit 'notify-user', OP_WARNING, 'No host peer connected!'

  data:
    isActive: false
)


# "Login As" popup
new Vue(
  el: '#modal-loginas'

  mounted: ->
    @$bus.$on 'open-modal-loginas', =>
      console.log 'on open-modal-loginas'
      @isActive = true
      for u of core.peerModes
        if core.peerModes[u] == 'browser'  then continue
        @users[u] = core.peerNicks[u] + ' (' + core.peerModes[u] + ')'

  methods:
    close: ->
      @isActive = false
    loginAs: ->
      console.log 'loginAs()'
      console.log '@selectedUser=', @selectedUser
      if @selectedUser == ''
        @$bus.$emit 'notify-user', OP_WARNING, 'User should be selected!'
        return
      u = location.href.split("?")[0]
      if u[-1..] == '#'  then u = u[0..u.length-2]
      # TODO: to send PROTO_BYEBYE preliminary
      location.href = u + "?" + @selectedUser

  data:
    users: {}
    isActive: false
    selectedUser: ''
)


# "Download" popup
new Vue(
  el: '#modal-download'

  mounted: ->
    @version = document.getElementsByTagName('title')[0].innerText.split('- v.')[1]
    @$bus.$on 'open-modal-download', =>
      console.log 'on open-modal-download'
      @isActive = true

  methods:
    close: ->
      @isActive = false
    download: ->
      console.log 'download()'

  data:
    version: ''
    isActive: false
)


# 'My Info' popup
new Vue(
  el: '#modal-user'

  mounted: ->
    @$bus.$on 'get-balance', (cb) =>
      console.log "on get-balance"
      cb @balance
    @$bus.$on 'get-user-address', (cb) =>
      cb @address
    @$bus.$on 'get-user-cwd', (cb) =>
      cb @cwd
    @$bus.$on 'get-user-mode', (cb) =>
      cb @mode
    globalEmitter.on 'global-MyInfo-done', (user) =>
      console.log 'on global-MyInfo-done:', user
      user = JSON.parse user
      @name = user.user.name
      @email = user.user.email
      @mode = user.user.mode
      @balance = user.user.balance
      @address = user.user.id
      @cwd = user.cwd
      @isActive = true
      @$bus.$emit 'declare-user', { name: @name, mode: @mode }
    @$bus.$on 'open-modal-user', (message) ->
      console.log 'on open-modal-user:', message
      globalEmitter.emit 'global-MyInfo'

  data:
    name: ''
    email: ''
    mode: ''
    balance: ''
    address: ''
    cwd: ''
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
      @size = msg.data.size
      @hosted = msg.data.hosted
      @checked = [ 'email' ]
      @picked = [ '0' ]

      @$bus.$emit('get-seller-by-file-id', @id, (@store_id, @sellerAddress, @sellerName, @sellerBaseUrl, @sellerDownloadUrl) =>
        console.log 'get-seller-by-file-id:', @store_id, @sellerAddress, @sellerName, @sellerBaseUrl, @sellerDownloadUrl
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
    size: ''
    sellerName: ''
    sellerAddress: ''
    sellerBaseUrl: ''
    sellerDownloadUrl: ''
    store_id: ''
    checked: [ ]
    picked: [ ]
    address: ''
    hosted: ''
    balance: ''
    isActive: false

  methods:
    close: ->
      @isActive = false
    buy: ->
      @$bus.$emit 'get-balance', (@balance) =>
        if parseInt(@balance) < parseInt(@price)
          @$bus.$emit 'notify-user', OP_WARNING, 'Not enough coins!'
          return
        @$bus.$emit 'start-progressbar'
        @close()
        @$bus.$emit 'notify-user', OP_SUCCESS, 'Preparing for purchase transaction, please wait...', =>
          globalEmitter.emit 'global-BuyTxRequest',
            JSON.stringify({ buyer: @address, seller: @sellerAddress, price: @price, size: @size, store_id: @store_id,
            file_id: @id, file_name: @name, hosted: @hosted })
)


# 'My Wallet' popup
new Vue(
  el: '#modal-wallet'

  mounted: ->
    globalEmitter.on 'global-MyWalletInfo-done', (user) =>
      console.log 'on global-MyWalletInfo-done:', user, typeof user
      user = JSON.parse user

      for u of core.peerModes
        if core.peerModes[u] in [ 'browser', 'witness' ] or u == user.user.id  then continue
        @users[u] = core.peerNicks[u] + ' (...' + u[13..] + ')'

      @balance = user.user.balance
      @sender = user.user.id

      @isActive = true

    @$bus.$on 'open-modal-wallet', (msg) =>
      console.log 'on open-modal-wallet:', JSON.stringify msg
      globalEmitter.emit 'global-MyWalletInfo'

  data:
    users: {}
    balance: ''
    sender: ''
    amount: ''
    isActive: false
    selectedRecipient: ''

  methods:
    close: ->
      @isActive = false
    transfer: ->
      if @selectedRecipient == ''
        @$bus.$emit 'notify-user', OP_WARNING, 'Recipient should be selected!'
        return
      if @amount == ''
        @$bus.$emit 'notify-user', OP_WARNING, 'Amount cannot be empty!'
        return
      if parseInt(@balance) < parseInt(@amount)
        @$bus.$emit 'notify-user', OP_WARNING, 'Not enough coins!'
        return
      @$bus.$emit 'start-progressbar'
      @close()
      @$bus.$emit 'notify-user', OP_SUCCESS, 'Coins transfer is in progress...', =>
        globalEmitter.emit 'global-Transfer', { senderAddr: @sender, recipientAddr: @selectedRecipient, amount: @amount }
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


# 'Open' popup
new Vue(
  el: '#modal-preview'

  mounted: ->
    @$bus.$on 'open-modal-preview', (@hostedType, @fileId, @fileName, @fileMime, fileSize) =>
      console.log 'on open-modal-preview:', @hostedType, @fileId, @fileName, @fileMime, fileSize
      @poster = '/img/loading.svg'
      @$bus.$emit 'start-progressbar'
      if @hostedType == 'online'
        [ @isActiveImage, @isActiveMedia, @isActiveEtc ] = [ false, false, true ]
        @$bus.$emit('get-seller-by-file-id', @fileId, (_1, _2, _3, sellerBaseUrl, sellerDownloadUrl) =>
          @url = "#{sellerBaseUrl}/#{sellerDownloadUrl.replace(/{fileId}/, @fileId)}"
        )
      else
        @url = "http://127.0.0.1:3000/#{@fileName}"
        switch @fileMime.split('/')[0]
          when 'video'
            # TODO: to grab thumbnail
            @poster = '/img/video.svg'
            [ @isActiveImage, @isActiveMedia, @isActiveEtc ] = [ false, true, false ]
          when 'audio'
            @poster = '/img/headphone.svg'
            [ @isActiveImage, @isActiveMedia, @isActiveEtc ] = [ false, true, false ]
          when 'image'
            [ @isActiveImage, @isActiveMedia, @isActiveEtc ] = [ true, false, false ]
          else
            [ @isActiveImage, @isActiveMedia, @isActiveEtc ] = [ false, false, true ]

      @$bus.$emit 'stop-progressbar'
      @isActive = true

  data:
    hostedType: ''
    fileId: ''
    filePath: ''
    fileName: ''
    fileMime: ''
    url: ''
    poster: ''
    isActiveImage: false
    isActiveMedia: false
    isActiveEtc: false
    isActive: false

  methods:
    close: ->
      @isActive = false
    # opening purchased the local file from 'purchased' dir or online URL
    open: ->
      if @hostedType == 'online'
        console.log "opening #{@url}"
        open @url
      else
        aEl = document.createElement 'a'
        aEl.href = "http://127.0.0.1:3000/#{@fileName}"
        aEl.target = '_blank'
        aEl.download = @fileName
        document.body.appendChild aEl
        aEl.click()
        document.body.removeChild aEl
)


# notify user component thru raising toast popup
new Vue(
  el: '#toast'

  mounted: ->
    globalEmitter.on 'global-ignoreNotSupported-done', (msgPack) =>
      console.log 'on global-ignoreNotSupported-done:', msgPack
    globalEmitter.on 'global-InProgress-done', (msgPack) =>
      console.log 'on global-InProgress-done:', msgPack
      @$bus.$emit 'notify-user', msgPack[0], msgPack[1]
    @$bus.$on 'notify-user', (@toastType, @msg, cb) =>
      console.log 'on notify-user:', @msg
      @isActive = true
      setTimeout (=>
        @isActive = false
        msg = ''
        if cb?  then cb()
        return
      ), 3000

  data:
    msg:       ''
    isActive:  false
    toastType: OP_SUCCESS
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
