**Marketplace (PoC)**

In order to run the demo just execute next commands:

```
git clone https://github.com/vitali2y/marketplace.git
git clone https://github.com/vitali2y/marketplace_client.git
git clone https://github.com/vitali2y/marketplace_rendezvous.git
cd marketplace
npm install

# now put some .PDF, .MP3, .AVI, etc files into "stores" (on Linux and OSX), i. e.:
# ./marketplace_client/dist/linux/bob/store_bob, ./marketplace_client/dist/linux/james/store_james,
# and ./marketplace_client/dist/linux/tom/store_tom directories,
# and continue with:

npm run dev

# or, alternatively:
# MARKETPLACE_BROWSER=firefox npm run dev  # start Firefox
# MARKETPLACE_BROWSER=no npm run dev       # do not start browser at all
```

Continue online shopping from automatically opened [Alice's session](http://127.0.0.1:43443/?QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61) in web browser.

![Marketplace (PoC) @ win10](/docs/marketplace_demo_win10.png)

[Marketplace Client (PoC)](https://github.com/vitali2y/marketplace_client) project is used here as a client app.

[Marketplace Rendezvous Server (PoC)](https://github.com/vitali2y/marketplace_rendezvous) project is used here for discovery of other decentralized nodes.

[Marketplace Server (PoC), in Rust](https://github.com/vitali2y/marketplace_server) project is a next stage of currently used [Marketplace Server (PoC), in CoffeeScript](https://github.com/vitali2y/marketplace/blob/master/server/server.coffee).

In order to release the binary builds (for all _Linux_, _OSX_, and _Windows_ platforms) of both server and client (they will be found under _./dist_ and _./marketplace_client/dist_ accordingly under correspondent _linux_, _darwin_, and _windows_ dirs) just execute next command from the root _marketplace_ dir, and follow further instructions:

`npm run release`
