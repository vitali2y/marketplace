#!/bin/sh

#
# Postinstall script
#

rm -f ./marketplace_client
ln -s ../marketplace_client

rm -f ./marketplace_rendezvous
ln -s ../marketplace_rendezvous

cd ./server
rm -f ./public
ln -s ../public
cd -

cd ./browser
rm proto.coffee
ln -s ../marketplace_client/util/proto.coffee
cd -

mkdir -p ./vendor/js
cd ./vendor/js
rm -f ./*.js
ln -s ../../node_modules/vue/dist/vue.js
ln -s ../../node_modules/vue-awesome/dist/vue-awesome.js
cd -

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

ln -s ../../../node_modules/vue-awesome/icons/link.js
ln -s ../../../node_modules/vue-awesome/icons/info-circle.js
ln -s ../../../node_modules/vue-awesome/icons/cubes.js
ln -s ../../../node_modules/vue-awesome/icons/sitemap.js
ln -s ../../../node_modules/vue-awesome/icons/search.js
ln -s ../../../node_modules/vue-awesome/icons/plug.js
ln -s ../../../node_modules/vue-awesome/icons/compass.js
cd -

cd ./app/vue-awesome
rm -f ./components
ln -s ../../node_modules/vue-awesome/components
cd -

mkdir -p ./public/js
