#!/bin/sh

#
# Postinstall script
#

rm -f ./marketplace_server
ln -s ../marketplace_server

rm -f ./marketplace_client
ln -s ../marketplace_client

rm -f ./marketplace_rendezvous
ln -s ../marketplace_rendezvous

cd marketplace_server
rm -f ./public
ln -s ../marketplace/public
cd -

cd ./browser
rm proto.coffee filetransfer.coffee
ln -s ../marketplace_client/util/proto.coffee
ln -s ../marketplace_client/util/filetransfer.coffee
cd -

mkdir -p ./vendor/js ./vendor/css
cd ./vendor/js
rm -f ./*.js
ln -s ../../node_modules/vue/dist/vue.js
ln -s ../../node_modules/vue-awesome/dist/vue-awesome.js
cd -

# ./scripts/spectre.sh

mkdir -p ./app/vue-awesome/icons
cd ./app/vue-awesome/icons
rm -f ./*.js

ln -s ../../../node_modules/vue-awesome/icons/question-circle-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-audio-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-text-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-video-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-archive-o.js
ln -s ../../../node_modules/vue-awesome/icons/picture-o.js

ln -s ../../../node_modules/vue-awesome/icons/bank.js
ln -s ../../../node_modules/vue-awesome/icons/bars.js
ln -s ../../../node_modules/vue-awesome/icons/eye.js
ln -s ../../../node_modules/vue-awesome/icons/star.js
ln -s ../../../node_modules/vue-awesome/icons/shopping-cart.js
ln -s ../../../node_modules/vue-awesome/icons/commenting.js
ln -s ../../../node_modules/vue-awesome/icons/cloud.js
ln -s ../../../node_modules/vue-awesome/icons/hdd-o.js

ln -s ../../../node_modules/vue-awesome/icons/link.js
ln -s ../../../node_modules/vue-awesome/icons/info-circle.js
ln -s ../../../node_modules/vue-awesome/icons/cubes.js
ln -s ../../../node_modules/vue-awesome/icons/sitemap.js
ln -s ../../../node_modules/vue-awesome/icons/search.js
ln -s ../../../node_modules/vue-awesome/icons/plug.js
ln -s ../../../node_modules/vue-awesome/icons/compass.js
ln -s ../../../node_modules/vue-awesome/icons/exchange.js
ln -s ../../../node_modules/vue-awesome/icons/download.js

ln -s ../../../node_modules/vue-awesome/icons/linux.js
ln -s ../../../node_modules/vue-awesome/icons/apple.js
ln -s ../../../node_modules/vue-awesome/icons/windows.js

ln -s ../../../node_modules/vue-awesome/icons/eye-slash.js

ln -s ../../../node_modules/vue-awesome/icons/user-circle.js
cd -

cd ./app/vue-awesome
rm -rf ./components
ln -s ../../node_modules/vue-awesome/components
cd -

mkdir -p ./public/js
