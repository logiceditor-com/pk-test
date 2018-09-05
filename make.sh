#! /bin/bash

set -e

echo "----> Linking git hook"
ROOT=$(dirname ${BASH_SOURCE[0]})
rm -r "${ROOT}/.git/hooks"
ln -s ../etc/git/hooks ${ROOT}/.git/hooks

echo "----> Making a rock"
sudo luarocks make rockspec/pk-test-scm-1.rockspec

echo "----> OK"
