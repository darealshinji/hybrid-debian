#!/bin/sh
out=$(mktemp)
wget -c -O $out "https://raw.githubusercontent.com/darealshinji/hybrid-debian/avisynth-extension/install.sh"
sh $out
rm $out
