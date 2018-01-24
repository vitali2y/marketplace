#!/bin/sh

rm -f ./marketplace_client
ln -s ../marketplace_client
cd ./marketplace_client
npm install
mkdir store_bob store_james store_ragnar
RED='\033[0;31m'; GREEN='\033[0;32m'; NOCOLOR='\033[0m'; echo -e "${RED}Attention:${GREEN} do not forget to put preliminary some files into 'stores' ('store_bob', 'store_james', and 'store_ragnar') dirs!${NOCOLOR}"
cd -

cd ./server
rm -f ./public
ln -s ../public
cd -

mkdir -p ./vendor/js
cd ./vendor/js
rm -f ./*.js
ln -s ../../node_modules/vue/dist/vue.js
ln -s ../../node_modules/vue-awesome/dist/vue-awesome.js
cd -

mkdir -p ./vendor/css
cd ./vendor/css
rm -f ./*.css
ln -s ../../node_modules/spectre.css/dist/spectre.css
ln -s ../../node_modules/spectre.css/dist/spectre-icons.css
cd -

mkdir -p cd ./app/vue-awesome/icons
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

cd ./app/vue-awesome
rm -f ./components
ln -s ../../node_modules/vue-awesome/components
cd -
