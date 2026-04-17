#!/bin/bash

if [ "$1" = "clean" ]; then
    dart run build_runner clean
    echo "Cleaned"
fi

dart run build_runner build --delete-conflicting-outputs
echo "Build done"

flutter pub get
echo "build.sh done"
