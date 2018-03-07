#
# Marketplace Server
#

express = require "express"

app = express()
app.set 'port', process.env.PORT or 3000
app.use('/', express.static(__dirname + '/public'))
server = app.listen(app.get('port'))
console.log 'marketplace server listening on port', app.get('port')
