**Marketplace PoC**

In order to run the demo just execute next commands:
```
git clone https://github.com/vitali2y/marketplace.git
git clone https://github.com/vitali2y/marketplace_client.git
cd marketplace
npm install

# now put some .PDF, .MP3, .AVI, etc files into 3 "stores":
# ./marketplace_client/store_bob, ./marketplace_client/store_james,
# and ./marketplace_client/store_ragnar directories

npm run dev
```
Continue online shopping from automatically opened [Alice's session](http://127.0.0.1:3000/?64489c85dc2fe0787b85cd87214b3810#).

[Marketplace Client PoC](https://github.com/vitali2y/marketplace_client) project is used for a client app.

To release the binary builds of server and clients for both _Linux_ and _Winduz_ to execute next from _marketplace_ dir:
`npm run release_bin`
