#!/bin/sh

#
# Script for applying te customized version of Spectre.css
#

cd ./node_modules/spectre.css
sed -i 's/#5755d9/#2dbe60/g' ./src/_variables.scss
npm install
./node_modules/.bin/gulp build
cd -

cd ./vendor/css
rm -f ./*.css
ln -s ../../node_modules/spectre.css/dist/spectre.css
cd -
