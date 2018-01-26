#!/bin/sh

#
# Script for preparing the binary builds
#

rm -rf ./build
mkdir ./build
cp ./package.json ./build
cp -r ./public ./build

if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi

TARGETS="node6-linux-x64"
(cd ./build; ../node_modules/.bin/coffee -o . -c ../server/*.coffee; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi; \
	../node_modules/.bin/pkg --targets $TARGETS --output ./server-linux-x64.bin ./package.json; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 2; fi; \
	mv ./server-linux-x64.bin ../dist/linux; echo "./dist/linux/server-linux-x64.bin: done"; cd -)

TARGETS="node6-win-x86"
(cd ./build; ../node_modules/.bin/coffee -o . -c ../server/*.coffee; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi; \
	../node_modules/.bin/pkg --targets $TARGETS --output ./server-win-x86.exe ./package.json; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 2; fi; \
	mv ./server-win-x86.exe ../dist/windows; echo "./dist/linux/server-win-x86.exe: done"; cd -)

GREEN='\033[0;32m'; NOCOLOR='\033[0m'
echo "start server (Linux ${GREEN}server-linux-x64.bin${NOCOLOR} or, Winduz ${GREEN}server-win-x86.exe${NOCOLOR})"
