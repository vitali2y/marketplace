#
# Marketplace Front-End
#

require('vueify/lib/insert-css')

# importing particular icons from Font Awesome set
Icon = require 'vue-awesome/components/Icon'
Vue.component('icon', Icon)
require 'vue-awesome/icons/bank'
require 'vue-awesome/icons/file-pdf-o'
require 'vue-awesome/icons/question-circle-o'
require 'vue-awesome/icons/file-audio-o'
require 'vue-awesome/icons/file-text-o'
require 'vue-awesome/icons/file-video-o'
require 'vue-awesome/icons/file-archive-o'
require 'vue-awesome/icons/picture-o'


# inter-components global event bus
bus = new Vue
Object.defineProperties Vue.prototype, $bus: get: ->
  bus


# # TODO: to split into separated components
# Search = require './components/Search.vue'  # template: '<div>search</div>'


# socket.io interaction with server-side
skt = io.connect('http://localhost:3000')
skt.emit('new_user', { hash: document.location.href.split('?')[1][0..31] })


# notify user thru raising toasts
notifyUser = (type, msg, cb) ->
  console.log "notifyUser (#{type}, #{msg}, <cb>)"
  document.querySelector('#toast').querySelector('span').innerText = msg
  document.querySelector("#toast").classList.add("toast-#{type}")
  document.querySelector("#toast").classList.remove("inactive")
  setTimeout (->
    document.querySelector("#toast").classList.add("inactive")
    document.querySelector("#toast").classList.remove("toast-#{type}")
    cb()
    return
  ), 3000
  return



# open popup (modal) window
window.modalMy = modal = (popupEl) ->
  popupEl.classList.add("active")



# close popup window
window.closeMy = close = (popupEl) ->
  popupEl.classList.remove("active")



# navigation bar component
new Vue(
  el: '#navbar'

  mounted: ->
    # keeping all available apps
    for _a in document.getElementsByClassName('app')
      # if _a.id.startsWith('app-')
      @allApps.push _a
    # activate app event
    @$bus.$on 'activate-app', (msg) =>
      console.log 'on activate-app:', msg
      for _a in @allApps
        document.querySelector('#' + _a.id).classList.add("inactive")
      document.querySelector(msg['app']).classList.remove("inactive")
      console.log 'active app:', msg['app']
      filesMy.getFiles()

  data:
    allApps: []
    appSelected: ''

  methods:
    modal: (app) ->
      @$bus.$emit "open-modal-#{app}"
    app: (appName) ->
      console.log 'app=', appName
      @appSelected = appName
      @$bus.$emit 'activate-app', app: '#app-' + appName
)



# search component
window.searchMy = new Vue(
  el: '#app-search'

  methods:
    search: (evt) ->
      @$bus.$emit 'open-modal-tbd'
)



# list of stores component
window.storesMy = new Vue(
  el: '#app-stores'

  mounted: ->
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
    storeId: ''
    stores: []

  props: [ 'selected' ]

  methods:
    storeSelected: (evt) ->
      @storeId = evt.path[1].id
      console.log '@storeId=', @storeId
      @$bus.$emit 'activate-app', { app: '#app-files', id: evt.path[1].id }
    getStores: ->
      skt.on 'get_stores_returned', (data) =>
        console.log 'server: get_stores_returned=', JSON.stringify(data)
        @stores = data["stores"]
        console.log "@stores=", @stores
      skt.emit('get_stores')
)


# list of files component
window.filesMy = new Vue(
  el: '#app-files'

  mounted: ->

  data:
    files: []
  # # TODO:
  # computed: tsFixed: ->
  #   @ts[0..9]

  methods:
    fileComments: (evt) ->
      console.log 'fileComments=', evt.path[7].id
      @$bus.$emit 'open-modal-tbd'
    fileRating: (evt) ->
      console.log 'fileRating=', evt.path[7].id
      @$bus.$emit 'open-modal-tbd'
    filePreview: (evt) ->
      console.log 'filePreview=', evt.path[7].id
      @$bus.$emit 'open-modal-tbd'
      # @$bus.$emit 'open-modal-preview', data: evt.path[7].id
    fileBuy: (evt) ->
      console.log 'fileBuy=', evt.path[7].id
      for _i in @files
        if _i.id == evt.path[7].id
          @$bus.$emit 'open-modal-buy', data: _i
          break
    getFiles: ->
      skt.on 'get_files_returned', (data) =>
        console.log 'server: get_files_returned=', JSON.stringify(data)
        @files = data.files[0].items
        console.log "@files=", @files
      skt.emit('get_files', { id: storesMy.storeId })
)


new Vue(
  el: '#modal-tbd'

  mounted: ->
    @$bus.$on 'open-modal-tbd', (message) =>
      console.log 'open-modal-tbd:', message
      @modal()

  methods:
    modal: ->
      modal @$el
    close: ->
      close @$el
)


window.userMy = new Vue(
  el: '#modal-user'

  mounted: ->
    @$bus.$on 'get-user-address', (cb) =>
      console.log 'on get-user-address', cb
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
      console.log 'open-modal-user:', message
      @modal()

  data:
    name: ''
    email: ''
    mode: ''
    balance: ''
    address: ''

  methods:
    modal: ->
      modal @$el
    close: ->
      close @$el
)


window.buyMy = new Vue(
  el: '#modal-buy'

  mounted: ->
    skt.on 'buy_executed', (data) ->
      console.log 'server: buy_executed=', data
      console.log 'step 3 of 3'
      notifyUser 'success', 'Transaction done - please check your file!', ->
        console.log 'buying item done'

    @$bus.$on 'open-modal-buy', (msg) =>
      console.log 'open-modal-buy:', msg.data
      @id = msg.data.id
      @name = msg.data.name
      @mime = msg.data.mime
      @price = msg.data.price
      @checked = [ 'email' ]
      @picked = [ '0' ]

      _cbGetSellerId = (id) =>
        @seller = id

        _cbGetUserAddress = (addr) =>
          @address = addr
          @modal()

        @$bus.$emit 'get-user-address', _cbGetUserAddress

      @$bus.$emit 'get-store-id-by-file-id', @id, _cbGetSellerId

  data:
    id: ''
    name: ''
    mime: ''
    price: ''
    seller: ''
    checked: [ ]
    picked: [ ]
    address: ''

  methods:
    modal: ->
      modal @$el
      # TODO:
      document.querySelector('#witness').checked = true
    close: ->
      close @$el
    buy: ->
      console.log 'starting buying item'
      close @$el
      notifyUser 'success', 'Fetching the file, please wait...', =>
        console.log 'step 1 of 3'
        notifyUser 'success', 'Successful payment, few more secs...', =>
          console.log 'sending to server:', { buyer: @address, store_id: @seller, id: @id }
          skt.emit('buy', { buyer: @address, store_id: @seller, id: @id })
          console.log 'step 2 of 3'
)
