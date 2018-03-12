#!/bin/sh

#
# Script for preparing server's binary builds
#

mkdir -p ./build

cp ./package.json ./build

cp -r ./public ./build

mkdir -p ./dist/linux ./dist/darwin ./dist/windows

MAJOR_VERSION=$(node -v | awk '{ split($0,v,"."); print substr(v[1], 2) }')

(cd ./build &&
../node_modules/.bin/coffee -o . -c ../server/*.coffee &&
# adding name, version number, and timestamp for output during booting
cat ../package.json | ../node_modules/.bin/json -A -a description version | awk -F, 'BEGIN { "date +%y%m%d-%H%M" | getline d } { print "console.log(\""$0" ("d") is starting...\");" }' > ./server.js.tmp && cat ./server.js >> ./server.js.tmp && mv ./server.js.tmp ./server.js &&
# do not use local rendezvous server on production
sed -i -e 's/.\/dns4\/localhost\/tcp\.*/peerInfo.multiaddrs.add(multiaddr("\/dns4\/ws-star-signal-4.servep2p.com\/tcp\/443\/wss\/p2p-websocket-star"));/' ./public/js/libp2p-bundle.js &&
APP_NAME="server-linux-x64.bin" && TARGET="node"$MAJOR_VERSION"-linux-x64" && echo $APP_NAME && ../node_modules/.bin/pkg --targets $TARGET --output ./$APP_NAME ./package.json &&
mv ./$APP_NAME ../dist/linux &&
APP_NAME="server-macos-x64.bin" && TARGET="node"$MAJOR_VERSION"-macos-x64" && echo $APP_NAME && ../node_modules/.bin/pkg --targets $TARGET --output ./$APP_NAME ./package.json &&
mv ./$APP_NAME ../dist/darwin &&
APP_NAME="server-win-x86.exe" && TARGET="node"$MAJOR_VERSION"-win-x86" && echo $APP_NAME && ../node_modules/.bin/pkg --targets $TARGET --output ./$APP_NAME ./package.json &&
mv ./$APP_NAME ../dist/windows &&
cd -)
if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi

GREEN='\033[0;32m'; NOCOLOR='\033[0m'
echo "start server (Linux: ${GREEN}server-linux-x64.bin${NOCOLOR}, Mac OS X: ${GREEN}server-macos-x64.bin${NOCOLOR}, Winduz: ${GREEN}server-win-x86.exe${NOCOLOR})"
