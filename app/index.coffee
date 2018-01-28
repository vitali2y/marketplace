#
# Marketplace Front-End
#

require('vueify/lib/insert-css')

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

# inter-components global event bus
bus = new Vue
Object.defineProperties Vue.prototype, $bus: get: ->
  bus


# # TODO: to split into separated component files
# Search = require './components/Search.vue'  # template: '<div>search</div>'


# socket.io interaction with server-side
skt = io.connect('http://localhost:3000')
skt.emit('new_user', { hash: document.location.href.split('?')[1][0..31] })


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

  data:
    isActive: false
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
new Vue(
  el: '#app-stores'

  mounted: ->
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true
    @$bus.$on 'get-store-id-by-file-id', (id, cb) =>
      console.log 'on get-store-id-by-file-id', id
      cb @storeId
      return
    @getStores()
    skt.on 'new_client_connected', (data) ->
      console.log 'server: new_client_connected=', data
      @stores = data["stores"]
      return

  data:
    storeId:   ''
    storeName: ''
    stores:    []
    isActive:  true

  props: [ 'selected' ]

  methods:
    storeSelected: (evt) ->
      [ @storeId, @storeName ] = [ evt.path[1].id, evt.path[0].innerText ]
      console.log 'storeId=', @storeId, 'storeName=', @storeName
      @$bus.$emit 'get-files', @storeId, @storeName
    getStores: ->
      skt.on 'get_stores_returned', (data) =>
        console.log 'server: get_stores_returned=', JSON.stringify(data)
        @stores = data["stores"]
        console.log "@stores=", @stores
      skt.emit('get_stores')
)


# list of files component
new Vue(
  el: '#app-files'

  mounted: ->
    @$bus.$on 'get-files', (@storeId, @storeName) =>
      @getFiles @storeId
      @$bus.$emit 'activate-app', name: '#app-files'
    @$bus.$on 'activate-app', (app) =>
      @isActive = false
      if app.name == @$options.el
        @isActive = true

  data:
    files: []
    storeId: ''
    storeName: ''
    isActive: false

  # # TODO:
  # computed:
  #   ts: ->
  #     @ts[0..9]

  methods:
    storeComments: (evt) ->
      console.log 'storeComments=', @storeId
      @$bus.$emit 'open-modal-tbd', 'Store Comments'
    storeRating: (evt) ->
      console.log 'storeRating=', @storeId
      @$bus.$emit 'open-modal-tbd', 'Store Rating'
    storePreview: (evt) ->
      console.log 'storePreview=', @storeId
      @$bus.$emit 'open-modal-tbd', 'Store View'
    fileComments: (evt) ->
      console.log 'fileComments=', evt.path[7].id
      @$bus.$emit 'open-modal-tbd', 'Product Comments'
    fileRating: (evt) ->
      console.log 'fileRating=', evt.path[7].id
      @$bus.$emit 'open-modal-tbd', 'Product Rating'
    filePreview: (evt) ->
      console.log 'filePreview=', evt.path[7].id
      @$bus.$emit 'open-modal-tbd', 'Product Preview'
      # @$bus.$emit 'open-modal-preview', data: evt.path[7].id
    fileBuy: (evt) ->
      console.log 'fileBuy=', evt.path[8].id
      for _i in @files
        if _i.id == evt.path[8].id
          @$bus.$emit 'open-modal-buy', data: _i
          break
    getFiles: (storeId)->
      skt.on 'get_files_returned', (data) =>
        console.log 'server: get_files_returned=', JSON.stringify(data)
        @files = data.files[0].items
        console.log "@files=", @files
      skt.emit('get_files', { id: storeId })
)


new Vue(
  el: '#modal-tbd'

  mounted: ->
    @$bus.$on 'open-modal-tbd', (msg) =>
      console.log 'open-modal-tbd:', msg
      @msg = msg
      @isActive = true

  methods:
    close: ->
      @isActive = false

  data:
    msg: ''
    isActive: false
)


new Vue(
  el: '#modal-user'

  mounted: ->
    @$bus.$on 'get-user-address', (cb) =>
      cb @address
      return
    skt.on 'new_user_connected', (data) =>
      console.log 'server: new_user_connected=', data
      @name = data.users[0].name
      @email = data.users[0].email
      @mode = data.users[0].mode
      @balance = data.users[0].balance
      @address = data.users[0].address
    @$bus.$on 'open-modal-user', (message) =>
      @isActive = true

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


new Vue(
  el: '#modal-buy'

  mounted: ->
    skt.on 'buy_executed', (data) =>
      console.log 'server: buy_executed=', data
      console.log 'step 3 of 3'
      @$bus.$emit 'notify_user', 'success', 'Transaction done - please check your file!', ->
        console.log 'buying item done'

    @$bus.$on 'open-modal-buy', (msg) =>
      console.log 'open-modal-buy:', msg.data
      @id = msg.data.id
      @name = msg.data.name
      @mime = msg.data.mime
      @type = msg.data.type
      @price = msg.data.price
      @checked = [ 'email' ]
      @picked = [ '0' ]

      _cbGetSellerId = (id) =>
        @seller = id

        _cbGetUserAddress = (addr) =>
          @address = addr
          @isActive = true

        @$bus.$emit 'get-user-address', _cbGetUserAddress

      @$bus.$emit 'get-store-id-by-file-id', @id, _cbGetSellerId

  data:
    id: ''
    name: ''
    mime: ''
    type: ''
    price: ''
    seller: ''
    checked: [ ]
    picked: [ ]
    address: ''
    isActive: false

  methods:
    close: ->
      @isActive = false
    buy: ->
      console.log 'starting buying item'
      @close()
      @$bus.$emit 'notify_user', 'success', 'Fetching the file, please wait...', =>
        console.log 'step 1 of 3'
        @$bus.$emit 'notify_user', 'success', 'Successful payment, few more secs...', =>
          console.log 'sending to server:', { buyer: @address, store_id: @seller, id: @id }
          skt.emit('buy', { buyer: @address, store_id: @seller, id: @id })
          console.log 'step 2 of 3'
)


# notify user toast component
new Vue(
  el: '#toast'

  mounted: ->
    # notify user thru raising toast popup
    @$bus.$on 'notify_user', (@isSuccess, @msg, cb) =>
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
