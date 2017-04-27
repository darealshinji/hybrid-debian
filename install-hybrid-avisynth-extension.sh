#!/bin/sh -e
title="$1"
pkg_ver=$2
out=$(mktemp)
wget -q -c -O $out https://raw.githubusercontent.com/darealshinji/hybrid-debian/avisynth-extension/install.sh
sh $out "$title" $pkg_ver
rm $out
