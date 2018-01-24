#!/bin/sh

#
# Script for preparing the binary builds
#

rm -rf ./build
mkdir ./build
cp ./package.json ./build
cp -r ./public ./build

TARGETS="node6-linux-x64"
(cd ./build; ../node_modules/.bin/coffee -o . -c ../server/*.coffee; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi; \
	../node_modules/.bin/pkg --targets $TARGETS --output ./server-linux-x64.bin ./package.json; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 2; fi; \
	cp ./server-linux-x64.bin ..; echo "./build/server-linux-x64.bin: done"; cd -)

TARGETS="node6-win-x86"
(cd ./build; ../node_modules/.bin/coffee -o . -c ../server/*.coffee; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 1; fi; \
	../node_modules/.bin/pkg --targets $TARGETS --output ./server-win-x86.exe ./package.json; if [ $? -ne 0 ]; then echo 'failed!!!'; cd -; exit 2; fi; \
	cp ./server-win-x86.exe ..; echo "./build/server-win-x86.exe: done"; cd -)
