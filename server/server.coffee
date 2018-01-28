#
# Marketplace Server
#

express = require "express"
path = require "path"
io = require "socket.io"
low = require "lowdb"
# TODO: to use FileAsync
FileSync = require "lowdb/adapters/FileSync"

# unique counter of transactions
counter = low(new FileSync("counter.json"))
counter.defaults(counter: 0).write()

# init local db with exist users
users = low(new FileSync("users.json"))
users.defaults(users: []).write()

# init local db for keeping sellers' stores & their items
stores = low(new FileSync("stores.json"))
stores.defaults(stores: []).write()

# temp storage for transactions
txs = {}

# NOTE: plz comment next line and last 'cb()' one too, plus shift the code in between
# to the left in order to run a standalone server without 'brunch'
module.exports = (port, path, cb) ->
  app = express()
  app.set 'port', process.env.PORT or 3000
  app.use('/', express.static(__dirname + '/public'))
  server = app.listen(app.get('port'))
  console.log 'marketplace server listening on port', app.get('port')


  io.listen(server).sockets.on 'connection', (skt) ->

    # new CLI client (buyer or seller) is connected
    skt.on 'new-client', (data) ->
      console.log 'on new-client:',  JSON.stringify(data)
      if users.get("users").filter({ email: data.data.user.email }).size().value() > 0
        users.get("users").remove({ email: data.data.user.email }).write()
      users.get("users").push(data.data.user).write()
      if data.data.user.mode == "seller"
        if stores.get("stores").filter({ id: data.data.stores.id }).size().value() > 0
          stores.get("stores").remove({ id: data.data.stores.id }).write()
        data.data.stores.stars = parseInt(Math.random() * 10)
        stores.get("stores").push(data.data.stores).write()
      skt.emit 'new-client-connected', data
      return

    # new web user (buyer) is connected
    skt.on 'new-user', (userHash) ->
      console.log 'on new-user:', users.get("users").filter({ id: userHash.hash }).value(), 'hash:', userHash.hash
      skt.emit 'new-user-connected',
        { users: users.get("users").filter({ id: userHash.hash }).value() }
      return

    # get list of stores
    skt.on 'get-stores', ->
      skt.emit 'get-stores-returned',
        { stores: stores.get("stores").value() }
      return

    # get list of files on selected store
    skt.on 'get-files', (storeId) ->
      console.log 'on get-files:', storeId
      skt.emit 'get-files-returned',
        { files: stores.get("stores").filter({ id: storeId.id }).value() }
      return

    skt.on 'get-transaction', (txId) ->
      console.log 'on get-transaction:', txId
      skt.emit 'get-transaction-returned', txs[txId]
      # TODO: to clean up the tx when both parties obtained it
      return

    # request for buying some file
    skt.on 'buy', (txReplica) ->
      console.log 'on buy:', txReplica
      # forming the transaction
      for _i in stores.get("stores").filter({ id: txReplica.store_id }).value()[0].items
        # searching for file's price ...
        if _i.id == txReplica.id
          console.log 'price:', _i.price
          txReplica.price = _i.price
          # ... and, seller's id
          _sellerId = stores.get("stores").filter({ id: txReplica.store_id }).value()[0].user_id
          console.log 'seller id:', _sellerId
          _sellerAddress = users.get("users").filter({ id: _sellerId }).value()[0].address
          console.log 'seller address:', _sellerAddress
          # ... and, getting unique tx id
          counter.update('counter', (n) ->
            n += 1
          ).write()
          _txId = counter.get("counter").value()
          txReplica.id = _txId
          console.log 'tx id:', _txId
          # keeping transaction temp until both parties will request for it
          console.log 'txReplica:', txReplica
          txs[_txId] = txReplica
          # TODO: to chk clients' IPs for security
          skt.emit 'buy-executed', _txId
          skt.broadcast.emit 'transaction-broadcasted', id: _txId, parties: [ txReplica.buyer, _sellerAddress ]
          break
      return

    # TODO:
    skt.on 'disconnected', ->
      console.log 'disconnected:', skt.username
    return

  cb()
