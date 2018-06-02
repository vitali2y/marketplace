#!/bin/sh

#
# Script for preparing server's binary builds
#

mkdir -p ./build

cp ./package.json ./build

cp -r ./public ./build

echo "TODO: to use Rust server instead of NodeJs!"
