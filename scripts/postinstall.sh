#!/bin/sh

ln -s ../marketplace_client

cd ./server
rm -f ./public
ln -s ../public
cd -

cd ./vendor/js
rm -f ./*.js
ln -s ../../node_modules/vue/dist/vue.js
ln -s ../../node_modules/vue-awesome/dist/vue-awesome.js
cd -

cd ./vendor/css
rm -f ./*.css
ln -s ../../node_modules/spectre.css/dist/spectre.css
ln -s ../../node_modules/spectre.css/dist/spectre-icons.css
cd -

cd ./app/vue-awesome
rm -f ./components
ln -s ../../node_modules/vue-awesome/components
cd -

cd ./app/vue-awesome/icons
rm -f ./*.js
ln -s ../../../node_modules/vue-awesome/icons/bank.js
ln -s ../../../node_modules/vue-awesome/icons/question-circle-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-audio-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-text-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-video-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-archive-o.js
ln -s ../../../node_modules/vue-awesome/icons/picture-o.js
ln -s ../../../node_modules/vue-awesome/icons/file-pdf-o.js
cd -
