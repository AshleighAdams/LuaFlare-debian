#!/bin/bash

set -e

./update.sh test # ensure that the changelog version matches the source version


[ -d packages ] && rm -rf packages
	debuild
mkdir -p packages
mv ../luaflare*.deb ../luaflare*.dsc ../luaflare*.changes ../luaflare*.build ../luaflare*.tar* packages/

dh_clean
