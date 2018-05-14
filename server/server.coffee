#
# Marketplace Server
#

express = require 'express'
fs = require 'fs'
https = require 'https'

key = fs.readFileSync './server.key'
cert = fs.readFileSync './server.crt'
options = 
  key: key
  cert: cert

app = express()
https.createServer(options, app).listen 43443
app.use '/', express.static(process.cwd() + '/public')
console.log 'Marketplace Server is listening on 43443...'
