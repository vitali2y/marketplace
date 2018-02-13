#
# Marketplace Server
#

crypto = require "crypto"
express = require "express"
path = require "path"
io = require "socket.io"
low = require "lowdb"
# TODO: to use FileAsync
FileSync = require "lowdb/adapters/FileSync"

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

    # returning partial info about seller to web user
    skt.on 'get-seller', (sellerId) ->
      # TODO: to return only required fields
      console.log 'on get-seller:', users.get("users").filter({ id: sellerId }).value(), 'sellerId:', sellerId
      skt.emit 'get-seller-returned',
        { seller: users.get("users").filter({ id: sellerId }).value() }
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

    # request for buying some file from web user
    skt.on 'buy', (txReplica) ->
      console.log 'on buy:', txReplica
      # forming the transaction
      for _i in stores.get("stores").filter({ id: txReplica.store_id }).value()[0].items
        # searching for file's price ...
        if _i.id == txReplica.file_id
          console.log 'price:', _i.price
          txReplica.price = _i.price
          # ... and, seller's id
          _sellerId = stores.get("stores").filter({ id: txReplica.store_id }).value()[0].user_id
          console.log 'seller id:', _sellerId
          _sellerAddress = users.get("users").filter({ id: _sellerId }).value()[0].address
          console.log 'seller address:', _sellerAddress
          # ... and, getting unique tx id
          txReplica.id = crypto.randomBytes(32).toString('hex')
          # keeping transaction temp until both parties will request for it
          console.log 'txReplica:', txReplica
          txs[txReplica.id] = txReplica
          # TODO: to chk clients' IPs for security
          # skt.emit 'buy-executed', txReplica.id
          skt.broadcast.emit 'transaction-broadcasted', id: txReplica.id, parties: [ txReplica.buyer, _sellerAddress ]
          break
      return

    skt.on 'success-transaction', (txId, txAll) ->
      console.log 'on success-transaction:', txId, txAll
      skt.broadcast.emit 'buy-executed', txId, txAll   # dirty notifying everyone (incl web user) about executed transaction

    # TODO:
    skt.on 'disconnected', ->
      console.log 'disconnected:', skt.username
    return

  cb()
