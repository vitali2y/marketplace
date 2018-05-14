#!/bin/sh

#
# Script for setting the development environment
#

./node_modules/.bin/json -f ./package.json description version uri dev_uri -e "this.uri=this.dev_uri; delete this.dev_uri" -o json-0 | awk '{ print "-\n  var cfg = [ "$0" ]" }' > ./app/cfg.jade
