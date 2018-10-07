#!/bin/sh
# Commit GitHub pages build
# TODO: move this to our CI server and stop using GH pages

git commit -m "Build html" docs
