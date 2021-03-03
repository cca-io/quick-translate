#!/bin/bash
set -e

if [[ $# -eq 0 ]] ; then
    echo "Usage: yarn intf MyRescriptFile" 
    exit 1
fi

bsc -i  lib/bs/src/$1.cmi > src/$1.mli
bsc -format src/$1.mli > src/$1.resi
rm src/$1.mli