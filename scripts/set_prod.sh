#!/bin/sh

#
# Script for setting the production environment
#

# do not use local rendezvous server on production
./node_modules/.bin/json -f ./package.json description version uri -o json-0 | awk '{ print "-\n  var cfg = [ "$0" ]" }' > ./app/cfg.jade
