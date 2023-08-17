#!/bin/bash
set -euo pipefail

VENDOR_DIR=$(dirname "$0")

mkdir $VENDOR_DIR/sqlite-amalgamation
curl -o $VENDOR_DIR/sqlite-amalgamation-3420000.zip https://www.sqlite.org/2023/sqlite-amalgamation-3420000.zip

unzip -q $VENDOR_DIR/sqlite-amalgamation-3420000.zip -d $VENDOR_DIR/sqlite-amalgamation && 
    cp -r $VENDOR_DIR/sqlite-amalgamation/sqlite-amalgamation-3420000/* $VENDOR_DIR/sqlite-amalgamation &&
    rm -rf $VENDOR_DIR/sqlite-amalgamation/sqlite-amalgamation-3420000 &&
    rm $VENDOR_DIR/sqlite-amalgamation-3420000.zip