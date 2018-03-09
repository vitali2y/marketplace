#!/bin/sh

#
# Script for preparing the binary builds
#

rm -rf ./build
mkdir ./build
cp ./package.json ./build
cp -r ./public ./build

if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi

(cd ./build &&
../node_modules/.bin/coffee -o . -c ../server/*.coffee &&
TARGETS="node8-linux-x64" && ../node_modules/.bin/pkg --targets $TARGETS --output ./server-linux-x64.bin ./package.json &&
mv ./server-linux-x64.bin ../dist/linux &&
TARGETS="node8-macos-x64" && ../node_modules/.bin/pkg --targets $TARGETS --output ./server-macos-x64.bin ./package.json &&
mv ./server-macos-x64.bin ../dist/darwin &&
TARGETS="node8-win-x86" && ../node_modules/.bin/pkg --targets $TARGETS --output ./server-win-x86.exe ./package.json &&
mv ./server-win-x86.exe ../dist/windows &&
cd -)

GREEN='\033[0;32m'; NOCOLOR='\033[0m'
echo "start server (Linux: ${GREEN}server-linux-x64.bin${NOCOLOR}, Mac OS X: ${GREEN}server-macos-x64.bin${NOCOLOR}, Winduz: ${GREEN}server-win-x86.exe${NOCOLOR})"
