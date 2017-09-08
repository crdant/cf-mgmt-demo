#!/usr/bin/env bash
BASEDIR=`dirname $0`/..

git checkout -b demo
sed -i '' 's#ci.*$##' ${BASEDIR}/.gitignore
sed -i '' 's#config.*$##' ${BASEDIR}/.gitignore
sed -i '' '#^$#d' ${BASEDIR}/.gitignore

cf-mgmt init-config
git add ${BASEDIR}/.gitignore
git add config

git commit -m "Updated .gitignore to allow config and ci to be committed"
