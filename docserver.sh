#!/bin/bash
set -euo pipefail

function ensure_package() {
  if ! rpm -q --quiet $1; then
    pkcon -y install $1
  fi
}

ensure_package python3-sphinx
ensure_package python3-sphinx-autobuild
ensure_package python3-sphinx-theme-alabaster
ensure_package python3-port-for

# Fix for broken Fedora package
PKDEF=/usr/lib/python3.?/site-packages/sphinx_autobuild-*.egg-info/requires.txt
if grep -q port_for $PKDEF; then
  sudo sed -i '/port_for/d' $PKDEF
fi 

sphinx-autobuild-3 -p 8080 -H 127.0.0.1 source build/html -n "$@"
