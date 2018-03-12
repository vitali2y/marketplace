**Decentralized Marketplace (PoC)**

In order to run the demo just execute next commands:

```
git clone https://github.com/vitali2y/marketplace.git
git clone https://github.com/vitali2y/marketplace_client.git
git clone https://github.com/vitali2y/marketplace_rendezvous.git
cd marketplace
npm install

# now put some .PDF, .MP3, .AVI, etc files into 3 "stores":
# on Linux:
# ./marketplace_client/dist/linux/store_bob, ./marketplace_client/dist/linux/store_james,
# and ./marketplace_client/dist/linux/store_tom dirs, or
# on OSX:
# ./marketplace_client/dist/darwin/store_bob, ./marketplace_client/dist/darwin/store_james,
# and ./marketplace_client/dist/darwin/store_tom dirs,
# and continue with:

npm run dev
```

Continue online shopping from automatically opened [Alice's session](http://127.0.0.1:3000/?QmdFdWtiC9HdNWvRH3Cih9hJhLvRZmsDutz549s25CtQ61) in web browser.

![Marketplace (PoC) @ win10](https://rawgit.com/vitali2y/marketplace/master/docs/marketplace_demo_win10.png)

[Decentralized Marketplace Client (PoC)](https://github.com/vitali2y/marketplace_client) project is used here as a client app.

[Decentralized Marketplace Rendezvous Server (PoC)](https://github.com/vitali2y/marketplace_rendezvous) project is used here for discovery of other decentralized nodes.

In order to release the binary builds (_Linux_, _OSX_, and _Windows_ are supported) of both server and client (they will be found under _./dist_ and _./marketplace_client/dist_ accordingly under correspondent _linux_, _darwin_, and _windows_ dirs) just execute next command from the root _marketplace_ dir, and follow further instructions:

`npm run release`
